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

static UIButton* triggerButtonRef;

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
    newOverlay.cameraViewTransform = [newOverlay makeCameraViewTransform];

    return newOverlay;
}

+ (instancetype) createFromPictureOptions:(CDVPictureOptions*)pictureOptions refToPlugin:(CDVCamera*)pluginRef {
    CustomCameraOverlay* newOverlay = [CustomCameraOverlay createFromPictureOptions:pictureOptions];
    newOverlay.plugin = pluginRef;
    return newOverlay;
}

- (CGAffineTransform) makeCameraViewTransform {
    // Calculate the amount to translate in the y-direction
    CGFloat yDelta = 50;
    CGFloat xDelta = 0;
    
    CGAffineTransform positionTransform = CGAffineTransformMakeTranslation(xDelta, yDelta);
    CGAffineTransform mirrorTransform;
    
    if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        mirrorTransform = CGAffineTransformIdentity;
    } else {
        mirrorTransform = CGAffineTransformMakeScale(-1.0,1.0);
    }
    return CGAffineTransformConcat(positionTransform, mirrorTransform);
    return positionTransform;
}

- (UIView*) getOverlayView {
    UIView *overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    overlay.backgroundColor = [UIColor clearColor];
    overlay.clipsToBounds = NO;
    triggerButtonRef = [self triggerButton];
    [overlay addSubview: triggerButtonRef];
    [overlay addSubview: [self closeButton]];
    [overlay addSubview: [self toggleCameraButton]];
    [overlay addSubview: [self flashButton]];
    return overlay;
}

- (UIButton *) toggleCameraButton
{
    CGRect fullScreen = self.view.bounds;
    float screenWidth = CGRectGetMaxX(fullScreen);
    float buttonWidth = 80;
    float buttonHeight = 60;
    UIButton* _toggleCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_toggleCameraButton setBackgroundColor:[UIColor clearColor]];
    [_toggleCameraButton setFrame:(CGRect){ screenWidth - buttonWidth, 0, buttonWidth, buttonHeight }];
    [_toggleCameraButton setImage:[UIImage imageNamed:@"flip"] forState:UIControlStateNormal];
    [_toggleCameraButton addTarget:self action:@selector(toggleCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return _toggleCameraButton;
}

- (IBAction) toggleCameraAction:(id)sender {
    if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    self.cameraViewTransform = [self makeCameraViewTransform];
}

- (UIButton *) flashButton
{
    float buttonWidth = 80;
    float buttonHeight = 60;
    UIButton* _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashButton setBackgroundColor:[UIColor clearColor]];
    [_flashButton setFrame:(CGRect){ 0, 0, buttonWidth, buttonHeight }];
    [_flashButton setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateNormal];
    [_flashButton addTarget:self action:@selector(flashAction:) forControlEvents:UIControlEventTouchUpInside];
    [_flashButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setProperLabelForFlashButton:_flashButton];
    return _flashButton;
}

// Sets the flash button label based on camera's current flash mode
- (void) setProperLabelForFlashButton:(UIButton*)_flashButton {
    if (self.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn) {
        [_flashButton setTitle:@"On" forState:UIControlStateNormal];
    } else if (self.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        [_flashButton setTitle:@"Off" forState:UIControlStateNormal];
    } else {
        [_flashButton setTitle:@"Auto" forState:UIControlStateNormal];
    }
}

- (IBAction) flashAction:(id)sender {
    // Toggling the flash mode across three states:
    // auto -> on -> off
    UIButton* _flashButton = (UIButton*)sender;
    if (self.cameraFlashMode == UIImagePickerControllerCameraFlashModeAuto) {
        self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
    } else if (self.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn) {
        self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    } else if (self.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        self.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
    }
    [self setProperLabelForFlashButton:_flashButton];
}

- (UIButton *) triggerButton
{
    CGRect fullScreen = self.view.bounds;
    float screenHeight = CGRectGetMaxY(fullScreen);
    float buttonWidth = 80;
    float buttonHeight = 80;
    UIButton* _triggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_triggerButton setBackgroundColor:[UIColor clearColor]];
    [_triggerButton setFrame:(CGRect){CGRectGetMidX(fullScreen) - buttonWidth / 2, screenHeight - buttonHeight, buttonWidth, buttonHeight }];
    [_triggerButton setImage:[UIImage imageNamed:@"trigger"] forState:UIControlStateNormal];
    [_triggerButton addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return _triggerButton;
}

- (IBAction) triggerAction:(id)sender {
	triggerButtonRef.enabled = NO;
    [self takePicture];
}


- (UIButton *) closeButton
{
    CGRect fullScreen = self.view.bounds;
    float screenHeight = CGRectGetMaxY(fullScreen);
    float screenWidth = CGRectGetMaxX(fullScreen);
    float buttonWidth = 80;
    float buttonHeight = 80;
    UIButton* _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setBackgroundColor:[UIColor clearColor]];
    [_closeButton setFrame:(CGRect){ screenWidth - buttonWidth, screenHeight - buttonHeight, buttonWidth, buttonHeight }];
    [_closeButton setTitle: @"Done" forState: UIControlStateNormal];
    [_closeButton setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
    return _closeButton;
}

- (IBAction) closeAction:(id)sender {
    // Call Take Picture
    [self.plugin imagePickerControllerDidCancel:self];
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

- (void)didFinishTakingPhoto {
    // Enable the trigger button after photo is done
    triggerButtonRef.enabled = YES;
    
    // Show off a white flashing animation as visual feedback for the user
    UIView* whiteFlashScreen = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [whiteFlashScreen setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:whiteFlashScreen];
    [UIView animateWithDuration:0.8
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

@end
