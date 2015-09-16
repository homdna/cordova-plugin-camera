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
    [overlay addSubview: [self toggleCameraButton]];
    [overlay addSubview: [self flashButton]];
    [overlay addSubview: [self photoLibraryButton]];
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
        self.cameraViewTransform = CGAffineTransformMakeScale(-1.0,1.0);
    } else {
        self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.cameraViewTransform = CGAffineTransformIdentity;
    }
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
    
    return _flashButton;
}

- (IBAction) flashAction:(id)sender {
   if (self.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
      self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
   } else {
      self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
   }
}

- (UIButton *) photoLibraryButton
{
   CGRect fullScreen = self.view.bounds;
   float screenHeight = CGRectGetMaxY(fullScreen);
   float buttonWidth = 44;
   float buttonHeight = 60;
   UIButton* _photoLibraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
   /*   [_photoLibraryButton setBackgroundColor:RGBColor(0xffffff, .1)];*/
   [_photoLibraryButton.layer setCornerRadius:4];
   [_photoLibraryButton.layer setBorderWidth:1];
   /*[_photoLibraryButton.layer setBorderColor:RGBColor(0xffffff, .3).CGColor];*/
   [_photoLibraryButton setFrame:(CGRect){ 0, screenHeight - buttonHeight, buttonWidth, buttonHeight }];
   [_photoLibraryButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
   [_photoLibraryButton addTarget:self action:@selector(libraryAction:) forControlEvents:UIControlEventTouchUpInside];

    return _photoLibraryButton;
}

- (void) libraryAction:(UIButton *)button
{
   [self openLibrary];
}

- (UIButton *) triggerButton
{
    CGRect fullScreen = self.view.bounds;
    float screenHeight = CGRectGetMaxY(fullScreen);
    float buttonWidth = 80;
    float buttonHeight = 80;
    UIButton* _triggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_triggerButton setBackgroundColor:[UIColor whiteColor]];
    [_triggerButton setFrame:(CGRect){CGRectGetMidX(fullScreen) - buttonWidth / 2, screenHeight - buttonHeight, buttonWidth, buttonHeight }];
    [_triggerButton setImage:[UIImage imageNamed:@"trigger"] forState:UIControlStateNormal];
    [_triggerButton addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return _triggerButton;
}

- (IBAction) triggerAction:(id)sender {
    [self takePicture];
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 150);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
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
    });
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
    UIView* controlBarView = [[UIView alloc] initWithFrame:(CGRect){0, screenHeight - barWidth, screenWidth, barWidth}];
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
