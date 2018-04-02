//
//  FLAudioBuffer.h
//  FLMusicPlayer
//
//  Created by fengli on 2018/4/2.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLParsedAudioData.h"

@interface FLAudioBuffer : NSObject

+ (instancetype)buffer;

- (void)enqueueData:(FLParsedAudioData *)data;
- (void)enqueueFromDataArray:(NSArray *)dataArray;

- (BOOL)hasData;
- (UInt32)bufferedSize;

//descriptions needs free
- (NSData *)dequeueDataWithSize:(UInt32)requestSize packetCount:(UInt32 *)packetCount descriptions:(AudioStreamPacketDescription **)descriptions;

- (void)clean;

@end
