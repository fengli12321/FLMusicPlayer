
//
//  FLMusicHeader.h
//  FLMusicPlayer
//
//  Created by 冯里 on 2018/3/26.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "UIView+FLCommon.h"
#import "FLDataPath.h"

#ifdef DEBUG // 处于开发阶段
#define FLLog(...) NSLog(__VA_ARGS__)
#else // 处于发布阶段
#define FLLog(...)
#endif

#define kNotificationCenter [NSNotificationCenter defaultCenter]
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kFont(f) [UIFont systemFontOfSize:(f)]
#define kUserDefault [NSUserDefaults standardUserDefaults]
#define kKeyWindow [UIApplication sharedApplication].keyWindow
// 判断是否是iPhone X
#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)
// 状态栏高度
#define STATUS_BAR_HEIGHT (iPhoneX ? 44.f : 20.f)
// 导航栏高度
#define NAVIGATION_BAR_HEIGHT (iPhoneX ? 88.f : 64.f)
// tabBar高度
#define TAB_BAR_HEIGHT (iPhoneX ? (49.f+34.f) : 49.f)
// home indicator
#define HOME_INDICATOR_HEIGHT (iPhoneX ? 34.f : 0.f)


