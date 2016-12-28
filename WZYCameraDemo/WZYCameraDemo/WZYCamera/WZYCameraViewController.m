//
//  WZYCameraViewController.m
//  WZYCameraDemo
//
//  Created by 奔跑宝BPB on 2016/12/28.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import "WZYCameraViewController.h"

@interface WZYFlashlightButton : UIButton

@end

@implementation WZYFlashlightButton

- (void)setHighlighted:(BOOL)highlighted { }

@end

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMotion/CoreMotion.h>

@interface WZYCameraViewController () {
    BOOL isUsingFrontFacingCamera;  //切换前后镜头
}

/** AVCaptureSession对象来执行输入设备和输出设备之间的数据传递 */
@property (nonatomic, strong) AVCaptureSession *session;
/** 输入设备 */
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
/** 照片输出流 */
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
/** 预览图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/** 管理者对象 */
@property (nonatomic, strong) CMMotionManager *motionManger;
/** 拍照点击按钮 */
@property (nonatomic, weak) UIButton *btn_takePhoto;
/** 拍照返回按钮 */
@property (nonatomic, weak) UIButton *btn_backButton;
/** 横屏拍照提醒框 */
@property (nonatomic, weak) UILabel *alertLabel;
/** 竖屏提醒遮罩 */
@property (nonatomic, weak) UIView *coverView;
/** 开启闪光灯按钮 */
@property (nonatomic, weak) WZYFlashlightButton *ON_flashlightButton;
/** 关闭闪光灯按钮 */
@property (nonatomic, weak) WZYFlashlightButton *OFF_flashlightButton;
/** 自动闪光灯按钮 */
@property (nonatomic, weak) WZYFlashlightButton *AUTO_flashlightButton;

@end

@implementation WZYCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupAVCaptureSession];
    [self setupUI];
    
    if (!_isAllowedVertical) { // 不允许竖屏
        // 开启陀螺仪判定手机状态
        [self startGyroUpdate];
        // 设置遮罩
        [self setupCover];
    } else { // 允许竖屏，那么就不做任何处理
        return;
    }
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    
    if (self.session) {
        [self.session stopRunning];
    }
    if ([self.motionManger isDeviceMotionActive]) {
        [self.motionManger stopDeviceMotionUpdates];
    }
}

- (CMMotionManager *)motionManger {
    if (!_motionManger) {
        _motionManger = [[CMMotionManager alloc] init];
    }
    return _motionManger;
}

/** 设置只允许横屏拍摄蒙版 */
- (void)setupCover {
    // 提示横屏拍摄遮罩
    UIView *coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    coverView.backgroundColor = RGBA(0, 0, 0, 0.75);
    [self.view addSubview:coverView];
    _coverView = coverView;
    
    // 提示横屏拍摄label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_W - 300) * 0.5, 40, 300, 22)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"请使用横屏拍照";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"PingFang SC" size:20.0];
    [self.view addSubview:label];
    _alertLabel = label;
}

// 基本 UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    // 初始化拍照按钮
    UIButton *takePhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
    _btn_takePhoto = takePhotoButton;
    [takePhotoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    [takePhotoButton setImage:[UIImage imageNamed:@"photo_nor"] forState:UIControlStateNormal];
    [takePhotoButton setImage:[UIImage imageNamed:@"photo_high"] forState:UIControlStateHighlighted];
    [takePhotoButton setImage:[UIImage imageNamed:@"photo_dis"] forState:UIControlStateDisabled];
    takePhotoButton.center = CGPointMake(SCREEN_W * 0.5
                                         , SCREEN_H - _btn_takePhoto.frame.size.height - 10);
    [self.view addSubview:takePhotoButton];
    
    // 初始化返回按钮
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(45, 0, 26, 26)];
    _btn_backButton = backButton;
    [backButton setImage:[UIImage imageNamed:@"back_bottom"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    backButton.centerY = takePhotoButton.centerY;
    [self.view addSubview:backButton];
    
    // 闪光灯按钮标准尺寸
    CGFloat flashlightButtonW = 25;
    
    // 初始化闪光灯开启按钮
    WZYFlashlightButton *flashlightOnButton = [[WZYFlashlightButton alloc] initWithFrame:CGRectMake(20, 20, flashlightButtonW, flashlightButtonW)];
    _ON_flashlightButton = flashlightOnButton;
    [flashlightOnButton setImage:[UIImage imageNamed:@"flashlight_on"] forState:UIControlStateNormal];
    [flashlightOnButton setImage:[UIImage imageNamed:@"flashlight_on_sel"] forState:UIControlStateSelected];
    [flashlightOnButton addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    flashlightOnButton.tag = 31;
    [self.view addSubview:flashlightOnButton];
    
    // 初始化闪光灯自动按钮
    WZYFlashlightButton *flashlightAutoButton = [[WZYFlashlightButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(flashlightOnButton.frame) + 20, 20, flashlightButtonW, flashlightButtonW)];
    _AUTO_flashlightButton = flashlightAutoButton;
    [flashlightAutoButton setImage:[UIImage imageNamed:@"flashlight_auto"] forState:UIControlStateNormal];
    [flashlightAutoButton setImage:[UIImage imageNamed:@"flashlight_auto_sel"] forState:UIControlStateSelected];
    [flashlightAutoButton addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    flashlightAutoButton.tag = 32;
    [self.view addSubview:flashlightAutoButton];
    
    // 初始化闪光灯关闭按钮
    WZYFlashlightButton *flashlightOffButton = [[WZYFlashlightButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(flashlightAutoButton.frame) + 20, 20, flashlightButtonW, flashlightButtonW)];
    _OFF_flashlightButton = flashlightOffButton;
    [flashlightOffButton setImage:[UIImage imageNamed:@"flashlight_off"] forState:UIControlStateNormal];
    [flashlightOffButton setImage:[UIImage imageNamed:@"flashlight_off_sel"] forState:UIControlStateSelected];
    [flashlightOffButton addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    flashlightOffButton.tag = 33;
    [self.view addSubview:flashlightOffButton];
    
    // 什么都不选择，那么就关闭闪光灯
    _ON_flashlightButton.selected = NO;
    _AUTO_flashlightButton.selected = NO;
    _OFF_flashlightButton.selected = YES;
    
    // 前后摄像头按钮标准尺寸
    CGFloat topButtonW = 30;
    
    // 初始化前后摄像头切换按钮
    UIButton *cameraSwitchButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_W - 20 - topButtonW, 0, topButtonW, topButtonW)];
    cameraSwitchButton.centerY = flashlightOffButton.centerY;
    [cameraSwitchButton setImage:[UIImage imageNamed:@"sight_camera_switch"] forState:UIControlStateNormal];
    [cameraSwitchButton addTarget:self action:@selector(switchCameraSegmentedControlClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraSwitchButton];
    
}

/** 初始化对象 */
- (void)setupAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    [self.view.layer addSublayer:self.previewLayer];
    
}

/** 获取设备方向 */
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
        result = AVCaptureVideoOrientationLandscapeRight;
    else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

/** 拍照按钮方法 */
- (void)takePhoto {
    
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    [stillImageConnection setVideoScaleAndCropFactor:1];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *tempImage = [UIImage imageWithData:jpegData scale:1.0];
        UIImage *image = [UIImage imageWithCGImage:tempImage.CGImage scale:1.0 orientation:UIImageOrientationUp];
        
        // 将拍照所得照片返回
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didFinishPickingImage:)]) {
            [self.delegate cameraViewController:self didFinishPickingImage:image];
            
            NSLog(@"拍照完成!");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
}

- (IBAction)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}


/** 闪光灯 */
- (void)flashButtonClick:(UIButton *)sender {

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 修改前必须先锁定设备
    [device lockForConfiguration:nil];
    
    // 必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        if (sender.tag == 31) { // 开启闪光灯
            device.flashMode = AVCaptureFlashModeOn;
            _ON_flashlightButton.selected = YES;
            _AUTO_flashlightButton.selected = NO;
            _OFF_flashlightButton.selected = NO;
            
        } else if (sender.tag == 32) { // 自动闪光灯
            device.flashMode = AVCaptureFlashModeAuto;
            _ON_flashlightButton.selected = NO;
            _AUTO_flashlightButton.selected = YES;
            _OFF_flashlightButton.selected = NO;
            
        } else if (sender.tag == 33) { // 关闭闪光灯
            device.flashMode = AVCaptureFlashModeOff;
            _ON_flashlightButton.selected = NO;
            _AUTO_flashlightButton.selected = NO;
            _OFF_flashlightButton.selected = YES;
        }
        
    } else {
        NSLog(@"设备不支持闪光灯");
    }
    
    // 解锁设备
    [device unlockForConfiguration];
}

/** 切换前后镜头 */
- (void)switchCameraSegmentedControlClick:(UIButton *)sender {
   
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera) {
        desiredPosition = AVCaptureDevicePositionBack;
    } else {
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

/** 开启陀螺仪 */
- (void)startGyroUpdate {
    if ([self.motionManger isDeviceMotionAvailable]) {   //陀螺仪可用
        //        __weak typeof(self) weakSelf = self;
        [self.motionManger setDeviceMotionUpdateInterval:0.3];
        
        if (![self.motionManger isDeviceMotionActive]) {
            [self.motionManger startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
                
                // 01 Gravity 获取手机的重力值在各个方向上的分量，根据这个就可以获得手机的空间位置，倾斜角度等
                double gravityX = motion.gravity.x;
                double gravityY = motion.gravity.y;
                double gravityZ = motion.gravity.z;
                
                // 02 获取手机的倾斜角度(zTheta是手机与水平面的夹角， xyTheta是手机绕自身旋转的角度)：
                double zTheta = atan2 (gravityZ, sqrtf(gravityX * gravityX + gravityY * gravityY)) / M_PI * 180.0;
                double xyTheta = atan2 (gravityX, gravityY) / M_PI * 180.0;
                
                //                if ((zTheta < 30 && zTheta > -30) && (xyTheta > 75 && xyTheta < 105)) {
                if (xyTheta > 75 && xyTheta < 105) {
                    _alertLabel.hidden = YES;
                    _coverView.hidden = YES;
                    _btn_takePhoto.enabled = YES;
                } else if (xyTheta > -105 && xyTheta < -75) {
                    _alertLabel.hidden = YES;
                    _coverView.hidden = YES;
                    _btn_takePhoto.enabled = YES;
                } else {
                    _alertLabel.hidden = NO;
                    _coverView.hidden = NO;
                    _btn_takePhoto.enabled = NO;
                }
                NSLog(@"zTheta=%f xyTheta=%f", zTheta, xyTheta);
            }];
        }
        
    } else {
        NSLog(@"陀螺仪不可用!");
    }
    
}

/** 隐藏状态栏 */
- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
