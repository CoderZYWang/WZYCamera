//
//  WZYCameraViewController.h
//  WZYCameraDemo
//
//  Created by 奔跑宝BPB on 2016/12/28.
//  Copyright © 2016年 wzy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WZYCameraConst.h"
#import "UIView+Frame.h"

@class WZYCameraViewController;

@protocol WZYCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(WZYCameraViewController *)cameraViewController didFinishPickingImage:(UIImage *)image;

@end

@interface WZYCameraViewController : UIViewController

@property (nonatomic, weak) id <WZYCameraViewControllerDelegate> delegate;
/** 允许竖屏拍摄 */
@property (nonatomic, assign) BOOL isAllowedVertical;

@end

