//
//  WZYCameraConst.h
//  WZYCameraDemo
//
//  Created by 奔跑宝BPB on 2016/12/28.
//  Copyright © 2016年 wzy. All rights reserved.
//

#ifndef WZYCameraConst_h
#define WZYCameraConst_h

#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height

#define HEXCOLOR(hex) [UIColor colorWithRed:((float)((hex & 0xFF0000) >> 16)) / 255.0 green:((float)((hex & 0xFF00) >> 8)) / 255.0 blue:((float)(hex & 0xFF)) / 255.0 alpha:1]
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#endif /* WZYCameraConst_h */
