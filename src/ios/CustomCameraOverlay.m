//
//  CustomCameraOverlay.m
//  RapidFireCamera
//
//  Created by Chris Guevara on 2/23/15.
//
//

#import "CustomCameraOverlay.h"
#import "CDVCamera.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation CustomCameraOverlay

@synthesize plugin;

// Entry point method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

+ (instancetype) createFromPictureOptions:(CDVPictureOptions*)pictureOptions {
    CustomCameraOverlay* newOverlay = [[CustomCameraOverlay alloc] init];
    newOverlay.pictureOptions = pictureOptions;
    newOverlay.sourceType = pictureOptions.sourceType;
    newOverlay.allowsEditing = pictureOptions.allowsEditing;
    
    if (newOverlay.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // We only allow taking pictures (no video) in this API.
        newOverlay.mediaTypes = @[(NSString*)kUTTypeImage];
        // We can only set the camera device if we're actually using the camera.
        newOverlay.cameraDevice = pictureOptions.cameraDirection;
        
    } else if (pictureOptions.mediaType == MediaTypeAll) {
        newOverlay.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:newOverlay.sourceType];
    } else {
        NSArray* mediaArray = @[(NSString*)(pictureOptions.mediaType == MediaTypeVideo ? kUTTypeMovie : kUTTypeImage)];
        newOverlay.mediaTypes = mediaArray;
    }
    
    newOverlay.showsCameraControls = NO;
    newOverlay.cameraOverlayView = [newOverlay getOverlayView];
    
    return newOverlay;
}

+ (instancetype) createFromPictureOptions:(CDVPictureOptions*)pictureOptions refToPlugin:(CDVCamera*)pluginRef {
    
    CustomCameraOverlay* newOverlay = [CustomCameraOverlay createFromPictureOptions:pictureOptions];
    newOverlay.plugin = pluginRef;
    return newOverlay;
}


- (UIView*) getOverlayView {
    UIView *overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    overlay.backgroundColor = [UIColor clearColor];
    overlay.clipsToBounds = NO;

    [overlay addSubview: [self cameraControlBar]];
    [overlay addSubview: [self triggerButton]];
    [overlay addSubview: [self closeButton]];
    return overlay;
}


- (UIButton *) triggerButton
{
    CGRect fullScreen = self.view.bounds;
    float screenWidth = CGRectGetMaxX(fullScreen);
    float buttonWidth = 80;
    float buttonHeight = 60;
    UIButton* _triggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_triggerButton setBackgroundColor:[UIColor whiteColor]];
    [_triggerButton setFrame:(CGRect){ screenWidth - buttonWidth, CGRectGetMidY(fullScreen) - buttonHeight / 2, buttonWidth, buttonHeight }];
    [_triggerButton setImage:[UIImage imageNamed:@"trigger"] forState:UIControlStateNormal];
    [_triggerButton addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return _triggerButton;
}

- (IBAction) triggerAction:(id)sender {
    [self takePicture];
    CGRect fullScreen = self.view.bounds;
    UIView* whiteFlashScreen = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [whiteFlashScreen setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:whiteFlashScreen];
    [UIView animateWithDuration:0.4
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         whiteFlashScreen.alpha = 0;
                     }
                     completion:^(BOOL finished){
                         // Once the animation is done, remove flash view from the parent view controller
                         if (finished) {
                             [whiteFlashScreen performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:NO];
                         }
                     }];

}


- (UIButton *) closeButton
{
    CGRect fullScreen = self.view.bounds;
    float screenHeight = CGRectGetMaxY(fullScreen);
    float screenWidth = CGRectGetMaxX(fullScreen);
    float buttonWidth = 80;
    float buttonHeight = 60;
    UIButton* _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setBackgroundColor:[UIColor clearColor]];
    [_closeButton setFrame:(CGRect){ screenWidth - buttonWidth, screenHeight - buttonHeight, buttonWidth, buttonHeight }];
    [_closeButton setTitle: @"Done" forState: UIControlStateNormal];
    [_closeButton setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
 
    return _closeButton;
}

- (IBAction) closeAction:(id)sender {
    // Call Take Picture
    [self.plugin imagePickerControllerDidCancel:self];
}

- (UIView*) cameraControlBar {
    CGRect fullScreen = self.view.bounds;
    float screenHeight = CGRectGetMaxY(fullScreen);
    float screenWidth = CGRectGetMaxX(fullScreen);
    float barWidth = 80;
    UIView* controlBarView = [[UIView alloc] initWithFrame:(CGRect){screenWidth - barWidth, 0, barWidth, screenHeight}];
    [controlBarView setBackgroundColor:[UIColor whiteColor]];
    return controlBarView;
}

- (void)viewDidLoad {
    
    // When orientation changes, redraw the overlay view
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(deviceOrientationDidChangeNotification:)
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
}

- (void)deviceOrientationDidChangeNotification:(NSNotification*)note
{
    self.cameraOverlayView = [self getOverlayView];
}

@end
