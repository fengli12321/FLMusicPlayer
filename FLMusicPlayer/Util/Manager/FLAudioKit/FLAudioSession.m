//
//  FLAudioSession.m
//  FLMusicPlayer
//
//  Created by 冯里 on 2018/3/26.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "FLAudioSession.h"
#import <AVFoundation/AVFoundation.h>

@interface FLAudioSession ()

@property(nonatomic, weak) AVAudioSession *session;

@end
@implementation FLAudioSession

#pragma mark - init
+ (instancetype)shareInstance {
    static FLAudioSession *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.session = [AVAudioSession sharedInstance];
    
    [kNotificationCenter addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    [kNotificationCenter addObserver:self selector:@selector(interruptionNotificationReceived:) name:AVAudioSessionInterruptionNotification object:nil];
    NSError *error;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    if (error != nil) {
        
        FLLog(@"session 设置category出错：%@", error);
        return;
    }
    
    [self.session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error != nil) {
        
        FLLog(@"session active出错：%@", error);
        return;
    }
    FLLog(@"初始化成功");
}



#pragma mark - Private
- (void)handleAudioSessionInterruptionWithState:(AVAudioSessionInterruptionType)interruptionState type:(AVAudioSessionInterruptionOptions)interruptionType
{
    if (interruptionState == kAudioSessionBeginInterruption)
    {
        //控制UI，暂停播放
    }
    else if (interruptionState == kAudioSessionEndInterruption)
    {
        if (interruptionType == AVAudioSessionInterruptionOptionShouldResume)
        {
            OSStatus status = AudioSessionSetActive(true);
            if (status == noErr)
            {
                //控制UI，继续播放
            }
        }
    }
}

#pragma mark - Notification

/**
 routeChange
 */
- (void)routeChange:(NSNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    FLLog(@"routeChange:  \n %@", userInfo);
}


/**
 被打断
 */
- (void)interruptionNotificationReceived:(NSNotification *)notification {
    
    FLLog(@"被打断");
    UInt32 interruptionState = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntValue];
    AVAudioSessionInterruptionOptions interruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntValue];
    
    FLLog(@"打断处理错误，记得更改");
    [self handleAudioSessionInterruptionWithState:interruptionState type:interruptionType];
}

@end
