#import "AppController.h"

@implementation AppController

@synthesize gestureSetupController, gestureRecognitionController;

- (void)awakeFromNib {
	[[NSApplication sharedApplication] hide:self];
    
	[gestureSetupController setAppController:self];
	[gestureRecognitionController setAppController:self];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAndQuit:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
}

- (IBAction)closeAndQuit:(id)outlet {
	[[MultitouchManager sharedMultitouchManager] stopForwardingMultitouchEventsToListeners];
    
	if ([gestureSetupController.setupWindow alphaValue] > 0.5) {
		[gestureSetupController toggleGestureSetupWindow:nil];
	}
    
	[NSApp terminate:self];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification {
	if ([gestureRecognitionController.recognitionWindow alphaValue] > 0.5 && gestureRecognitionController.recognitionView.detectingInput) {
		[gestureRecognitionController.recognitionView finishDetectingGesture:YES];
	}
    
	if ([gestureSetupController.setupView alphaValue] > 0.5 && gestureSetupController.setupView.detectingInput) {
		[gestureSetupController.setupView finishDetectingGesture:YES];
	}
    
	[gestureSetupController updateSetupControls];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	[gestureSetupController updateSetupControls];
}

@end
