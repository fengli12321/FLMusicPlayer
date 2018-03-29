//
//  FLParsedAudioData.m
//  FLMusicPlayer
//
//  Created by 冯里 on 2018/3/29.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "FLParsedAudioData.h"

@implementation FLParsedAudioData

+ (instancetype)parsedAudioDataWithBytes:(const void *)bytes packetDescription:(AudioStreamPacketDescription)packetDescription {
    
    return [[self alloc] initWithBytes:bytes
                     packetDescription:packetDescription];
}

- (instancetype)initWithBytes:(const void *)bytes packetDescription:(AudioStreamPacketDescription)packetDescription {
    if (bytes == NULL || packetDescription.mDataByteSize == 0) {
        return nil;
    }
    if (self = [super init]) {
        
        _data = [NSData dataWithBytes:bytes length:packetDescription.mDataByteSize];
        _packetDescription = packetDescription;
    }
    return self;
}

@end
