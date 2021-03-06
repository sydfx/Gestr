#import "GestureSetupController.h"

@interface GestureSetupController ()

@property BOOL awakedFromNib;

@property NSStatusItem *statusBarItem;
@property IBOutlet NSView *statusBarView;

@property NSThread *showGestureThread;

@property IBOutlet NSTextField *drawNotificationText;

@property int launchableSelectedIndex;
@property IBOutlet NSSegmentedControl *launchableTypePicker;
@property IBOutlet NSTableView *launchableTableView;
@property IBOutlet NSArrayController *launchableArrayController;

@property IBOutlet NSButton *assignGestureButton, *showGestureButton, *clearGestureButton;

@property IBOutlet NSTextField *minimumRecognitionScoreField, *readingDelayTimeField;
@property IBOutlet NSTextField *multitouchRecognitionLabel;
@property IBOutlet NSButton *multitouchOptionField, *fullscreenOptionField, *quickdrawOptionField;
@property IBOutlet NSButton *loginStartOptionField;

@end

@implementation GestureSetupController

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!_awakedFromNib) {
		_awakedFromNib = YES;

		_setupView.setupController = self;

		[self hideSetupWindow];

		_setupModel = [[GestureSetupModel alloc] init];
		[_setupModel setup];

		_statusBarItem = [NSStatusItemPrioritizer prioritizedStatusItem];
		_statusBarItem.title = @"";
		_statusBarView.alphaValue = 0.0;
        [[_statusBarView viewWithTag:3] image].M5_darkable = YES;
		_statusBarItem.view = _statusBarView;
	}
}

- (void)applicationDidFinishLaunching {
	[[_statusBarView animator] setAlphaValue:1.0];

	[_launchableTypePicker setSelectedSegment:0];
	_launchableArrayController.content = _setupModel.normalAppArray;

	if (_appController.gestureRecognitionController.recognitionModel.gestureDetector.loadedGestures.count < 1) {
		[self toggleSetupWindow:nil];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositionSetupWindow:) name:NSWindowDidMoveNotification object:_statusBarView.window];

	[self updateSetupControls];

	[self hideSetupWindow];
}

#pragma mark -

#pragma mark -
#pragma mark Tableview Management
- (NSMutableArray *)currentLaunchableArray {
	return (NSMutableArray *)_launchableArrayController.content;
}

- (NSTableView *)currentLaunchableTableView {
	return _launchableTableView;
}

- (IBAction)launchableTypeChanged:(id)sender {
	switch (_launchableTypePicker.selectedSegment) {
		case 0:
			[_setupModel fetchNormalAppArray];
			_launchableArrayController.content = _setupModel.normalAppArray;
			break;

		case 1:
			[_setupModel fetchWebPageArray];
			_launchableArrayController.content = _setupModel.webPageArray;
			break;

        case 2:
			[_setupModel fetchScriptArray];
			_launchableArrayController.content = _setupModel.scriptArray;
            [self shouldShowCustomScriptsAlert];
			break;

		case 3:
			[_setupModel fetchUtilitiesAppArray];
			_launchableArrayController.content = _setupModel.utilitiesAppArray;
			break;

		case 4:
			[_setupModel fetchSystemAppArray];
			_launchableArrayController.content = _setupModel.systemAppArray;
			break;

		default:
			break;
	}

	[_showGestureButton setEnabled:NO];
	[_assignGestureButton setEnabled:NO];
	[_clearGestureButton setEnabled:NO];
}

- (void)tableViewFocus:(BOOL)lost {
	if (lost) {
		[_showGestureButton setEnabled:NO];
		[_assignGestureButton setEnabled:NO];
		[_clearGestureButton setEnabled:NO];
	}
	else {
		[self updateSetupControls];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[_setupView finishDetectingGesture:YES];

	[self updateSetupControls];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

	Launchable *launchable;
	if ((launchable = [self currentLaunchableArray][row])) {
		result.imageView.image = launchable.icon;
		result.textField.stringValue = launchable.displayName;
	}

	return result;
}

#pragma mark -

#pragma mark -
#pragma mark Interface Control
- (void)updateSetupControls {
	[_setupView resetAll];

	[_setupWindow makeFirstResponder:[self currentLaunchableTableView]];

	_launchableSelectedIndex = (int)([[self currentLaunchableTableView] selectedRow]);

	if (_launchableSelectedIndex >= 0) {
		if ([_appController.gestureRecognitionController.recognitionModel getGestureWithIdentity:((Launchable *)[self currentLaunchableArray][_launchableSelectedIndex]).launchId] != nil) {
			[_showGestureButton setEnabled:YES];
			[_assignGestureButton setEnabled:YES];
			[_clearGestureButton setEnabled:YES];
		}
		else {
			[_showGestureButton setEnabled:NO];
			[_assignGestureButton setEnabled:YES];
			[_clearGestureButton setEnabled:NO];
		}
	}

	_minimumRecognitionScoreField.stringValue = [NSString stringWithFormat:@"%i", _setupModel.minimumRecognitionScore];
	_readingDelayTimeField.stringValue = [NSString stringWithFormat:@"%i", _setupModel.readingDelayTime];
	_multitouchOptionField.state = _setupModel.multitouchOption;
	_fullscreenOptionField.state = _setupModel.fullscreenOption;
	_loginStartOptionField.state = _setupModel.loginStartOption;
	_quickdrawOptionField.state = _setupModel.quickdrawOption;
}

- (void)showDrawNotification:(BOOL)show {
	if (_setupModel.multitouchOption) {
		_drawNotificationText.stringValue = @"Draw now!";
	}
	else {
		_drawNotificationText.stringValue = @"Draw here!";
	}

	if (show) {
		_drawNotificationText.alphaValue = 1.0;
	}
	else {
		_drawNotificationText.alphaValue = 0.0;
	}
}

#pragma mark -

#pragma mark -
#pragma mark Setup Utilities
- (void)saveGestureWithStrokes:(NSMutableArray *)gestureStrokes {
	Launchable *gestureToSaveLaunchable = [self currentLaunchableArray][_launchableSelectedIndex];

	[_appController.gestureRecognitionController.recognitionModel saveGestureWithStrokes:gestureStrokes andIdentity:gestureToSaveLaunchable.launchId];

	[self updateSetupControls];
}

#pragma mark -

#pragma mark -
#pragma mark Setup Actions
- (IBAction)assignSelectedGesture:(id)sender {
    [_showGestureButton setEnabled:NO];
    [_assignGestureButton setEnabled:NO];
    [_clearGestureButton setEnabled:NO];

	[_setupView startDetectingGesture];
}

- (IBAction)showSelectedGesture:(id)sender {
	if (_showGestureThread) {
		[_showGestureThread cancel];
		_showGestureThread = nil;
	}

	if (_launchableSelectedIndex >= 0) {
		Gesture *gestureToShow = [_appController.gestureRecognitionController.recognitionModel getGestureWithIdentity:((Launchable *)[self currentLaunchableArray][_launchableSelectedIndex]).launchId];
		if (gestureToShow) {
			_showGestureThread = [[NSThread alloc] initWithTarget:_setupView selector:@selector(showGesture:) object:gestureToShow];
			[_showGestureThread start];
		}
	}
}

- (IBAction)clearSelectedGesture:(id)sender {
	if (_launchableSelectedIndex >= 0) {
		[_appController.gestureRecognitionController.recognitionModel deleteGestureWithName:((Launchable *)[self currentLaunchableArray][_launchableSelectedIndex]).launchId];
	}

	[self updateSetupControls];
}

#pragma mark -

#pragma mark -
#pragma mark Custom Scripts
- (void)shouldShowCustomScriptsAlert {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"shownCustomScriptsAlert"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shownCustomScriptsAlert"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        showingAlert = YES;

        [[NSAlert alertWithMessageText:@"Custom AppleScripts" defaultButton:@"Cool!" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You can add your own AppleScripts to this list by placing them under ~/Library/Application Support/Gestr/Scripts"] beginSheetModalForWindow:_setupWindow modalDelegate:self didEndSelector:@selector(finishShowingCustomScriptsAlert) contextInfo:nil];
    }
}

- (void)finishShowingCustomScriptsAlert {
    showingAlert = NO;
}

#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)positionSetupWindow {
	NSRect menuBarFrame = [[[_statusBarItem view] window] frame];
	NSPoint pt = NSMakePoint(NSMidX(menuBarFrame), NSMidY(menuBarFrame));

	pt.y -= menuBarFrame.size.height / 2;
	pt.y -= _setupWindow.frame.size.height;
	pt.x -= _setupWindow.frame.size.width / 2;

	[_setupWindow setFrameOrigin:pt];
}

- (IBAction)toggleSetupWindow:(id)sender {
	[self positionSetupWindow];

	if (_setupWindow.alphaValue <= 0) {
		if (!_appController.gestureRecognitionController.recognitionView.detectingInput) {
			[self launchableTypeChanged:nil];

			[_setupWindow orderFrontRegardless];

			[NSAnimationContext beginGrouping];
			[[NSAnimationContext currentContext] setDuration:0.16];
			[[NSAnimationContext currentContext] setCompletionHandler: ^{
			    [_setupWindow makeKeyWindow];
			}];
			[_setupWindow.animator setAlphaValue:1.0];
			[NSAnimationContext endGrouping];
		}
	}
	else {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.16];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self hideSetupWindow];
		}];
		[_setupWindow.animator setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	}

	[self updateSetupControls];
}

- (void)hideSetupWindow {
	_setupWindow.alphaValue = 0.0;
	[_setupWindow orderOut:self];
	[_setupWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
}

static BOOL showingAlert = NO;
- (void)windowDidResignKey:(NSNotification *)notification {
    if (showingAlert) {
        return;
    }

	if (_setupWindow.alphaValue > 0) {
		if (_setupView.detectingInput) {
			[_setupView finishDetectingGesture:YES];
		}

		[self toggleSetupWindow:nil];
	}
}

- (void)repositionSetupWindow:(NSNotification *)notification {
	if (_setupWindow.alphaValue > 0) {
		[self positionSetupWindow];
	}
}

#pragma mark -

#pragma mark -
#pragma mark Recognition Options
- (IBAction)minimumRecognitionScoreChanged:(id)sender {
	[_setupView finishDetectingGesture:YES];

	int newScore = [_minimumRecognitionScoreField intValue];
	if (newScore >= 70 && newScore <= 100) {
		[_setupModel saveMinimumRecognitionScore:newScore];
	}

	[self updateSetupControls];
}

- (IBAction)readingDelayTimeChanged:(id)sender {
	[_setupView finishDetectingGesture:YES];

	int newTime = [_readingDelayTimeField intValue];
	if (newTime >= 1 && newTime <= 1000) {
		[_setupModel saveReadingDelayTime:newTime];
	}

	[self updateSetupControls];
}

- (IBAction)multitouchOptionChanged:(id)sender {
	[_setupView finishDetectingGesture:YES];

	[_setupModel saveMultitouchOption:_multitouchOptionField.state];

	[self updateSetupControls];
}

- (IBAction)fullscreenOptionChanged:(id)sender {
	[_setupView finishDetectingGesture:YES];

	[_setupModel saveFullscreenOption:_fullscreenOptionField.state];

	[self updateSetupControls];
}

- (IBAction)loginStartOptionChanged:(id)sender {
	[_setupView finishDetectingGesture:YES];

	[_setupModel saveLoginStartOption:_loginStartOptionField.state];

	_loginStartOptionField.state = [_setupModel fetchLoginStartOption];

	[self updateSetupControls];
}

- (IBAction)quickdrawOptionChanged:(id)sender {
	[_setupView finishDetectingGesture:YES];

	[_setupModel saveQuickdrawOption:_quickdrawOptionField.state];

	[self updateSetupControls];
}

#pragma mark -

@end
