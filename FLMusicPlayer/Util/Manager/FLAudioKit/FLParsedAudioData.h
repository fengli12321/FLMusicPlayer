//
//  FLParsedAudioData.h
//  FLMusicPlayer
//
//  Created by 冯里 on 2018/3/29.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface FLParsedAudioData : NSObject

@property(nonatomic, strong, readonly) NSData *data;
@property(nonatomic, readonly) AudioStreamPacketDescription packetDescription;

+ (instancetype)parsedAudioDataWithBytes:(const void*)bytes
                       packetDescription:(AudioStreamPacketDescription)packetDescription;

@end
