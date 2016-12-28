//
//  ViewController.m
//  WZYCameraDemo
//
//  Created by 奔跑宝BPB on 2016/12/28.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import "ViewController.h"

#import "WZYCamera.h"

@interface ViewController () <WZYCameraViewControllerDelegate>

/** 占位 image */
@property (nonatomic, strong) UIImage *placeholderImage;
/** 预览界面 imageView */
@property (nonatomic, strong) UIImageView *preView;
/** 取消预览 button */
@property (nonatomic, strong) UIButton *removeButton;

@end

@implementation ViewController

static NSInteger flag;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI {
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"WZYCalendar";
    _placeholderImage = [UIImage imageNamed:@"Combined Shape"];
    
    CGFloat HMargin = 10;
    CGFloat VMargin = 20;
    
    CGFloat photoW = self.view.bounds.size.width - 2 * HMargin;
    CGFloat photoH = photoW * 9 / 16;
    
    // 添加存放拍摄图片的photo
    UIImageView *photo = [[UIImageView alloc] initWithFrame:CGRectMake(HMargin, VMargin + 64, photoW, photoH)];
    photo.userInteractionEnabled = YES;
    photo.image = _placeholderImage;
    photo.tag = 11;
    photo.layer.borderColor = HEXCOLOR(0x757575).CGColor;
    photo.layer.borderWidth = 1.0;
    photo.contentMode = UIViewContentModeCenter;
    [self.view addSubview:photo];
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(preView:)];
    [photo addGestureRecognizer:tap];
    
    //删除按钮
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(photoW - 30, photoH - 30, 26, 26)];
    [btn setBackgroundImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(deleteImage:) forControlEvents:UIControlEventTouchUpInside];
    btn.tag = 21;
    [photo addSubview:btn];
}

// 预览 & 拍照
- (void)preView:(UITapGestureRecognizer *)sender {
    // 拍照时是不能返回的（只能通过 拍照/取消 来返回）
    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    // 拿到点击的 imageView.image（设置tag目的是考虑到可能会有很多的 imageView，用来区分拍照所得照片到底赋给哪一个）
    NSInteger tag = sender.self.view.tag;
    flag = tag; // 记录下当前点击的时哪个 imageView
    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:tag];
    UIImage *image = imageView.image;
    
    if (image == _placeholderImage) { // 是占位图 ---> 拍照
        [self.navigationController setNavigationBarHidden:NO];
        
        // 判断是否有摄像头
        if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            return;
        }
        
        // 弹出 WZYCamera
        WZYCameraViewController *cameraVC = [[WZYCameraViewController alloc] init];
        cameraVC.isAllowedVertical = YES; // 允许竖屏
        cameraVC.delegate = self;
        [self presentViewController:cameraVC animated:YES completion:nil];
        
    } else { // 不是占位图 ---> 预览
        [self.navigationController setNavigationBarHidden:YES];
        
        // 预览视图 preView
        UIImageView *preView = [[UIImageView alloc] init];
        preView.frame = CGRectMake(0, 0, SCREEN_H, SCREEN_W);
        preView.image = image;
        preView.center = CGPointMake(SCREEN_W * 0.5, SCREEN_H * 0.5);
        _preView = preView;
        
        // 将视图进行旋转展示(使用者可自行定义)
        CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
        preView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        preView.transform = transform;
        preView.userInteractionEnabled = YES;
        
        [self.view addSubview:preView];
        [self.view bringSubviewToFront:preView];
        
        // 点击预览界面就退出预览（将一个全屏尺寸的button放在了预览视图的上面）
        UIButton *removeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H)];
        removeBtn.backgroundColor = [UIColor clearColor];
        [removeBtn addTarget:self action:@selector(removePreImageView) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:removeBtn];
        [self.view bringSubviewToFront:removeBtn];
        _removeButton = removeBtn;
    }
}

/** 退出预览界面 */
- (void)removePreImageView {
    // 移除 预览视图 和 退出预览界面的button
    [_preView removeFromSuperview];
    [_removeButton removeFromSuperview];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

/** 删除已经拍好的photo */
- (void)deleteImage:(UIButton *)button {
    /** 为了方便自定义多个拍摄接口，和imageView上面的6按钮，那么 */
    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:button.tag - 10]; // 通过tag 让删除按钮和对应imageView相关联
    imageView.contentMode = UIViewContentModeCenter;
    imageView.image = _placeholderImage;
}

#pragma mark - WZYCamera View Controller Delegate
- (void)cameraViewController:(WZYCameraViewController *)cameraViewController didFinishPickingImage:(UIImage *)image {

    UIImageView *iv = (UIImageView *)[self.view viewWithTag:flag];
    iv.image = image;
    iv.contentMode = UIViewContentModeScaleToFill;
}

@end
