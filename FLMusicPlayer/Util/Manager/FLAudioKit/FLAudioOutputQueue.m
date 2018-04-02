//
//  FLAudioOutputQueue.m
//  FLMusicPlayer
//
//  Created by fengli on 2018/4/2.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "FLAudioOutputQueue.h"

@interface FLAudioOutputQueue(){
@private
    AudioQueueRef _audioQueue;
    NSMutableArray *_buffers;
    NSMutableArray *reusableBuffers;
    
    BOOL isRunning;
    BOOL isStarted;
    NSTimeInterval _playedTime;
}

@end
@implementation FLAudioOutputQueue

#pragma mark - init & dealloc
- (instancetype)initWithFormat:(AudioStreamBasicDescription)format bufferSize:(UInt32)bufferSize macgicCookie:(NSData *)macgicCookie {
    if (self = [super init]) {
        _format = format;
        _volume = 1.0f;
        _bufferSize = bufferSize;
        
    }
}

@end
