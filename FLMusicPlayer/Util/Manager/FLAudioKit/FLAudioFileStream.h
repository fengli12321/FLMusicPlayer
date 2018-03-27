//
//  FLAudioFileStream.h
//  FLMusicPlayer
//
//  Created by fengli on 2018/3/27.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@class FLAudioFileStream;
@protocol FLAudioFileStreamDelegate <NSObject>

@required
- (void)audioFileStream:(FLAudioFileStream *)audioFileStream audioDataParsed:(NSArray *)audioData;
@optional
- (void)audioFileStreamReadyToProducePackets:(FLAudioFileStream *)audioFileStream;

@end

@interface FLAudioFileStream : NSObject

@property (nonatomic, weak) id <FLAudioFileStreamDelegate>delegate;

@property (nonatomic, assign, readonly) AudioFileTypeID fileType;

@property (nonatomic, assign, readonly) unsigned long long fileSize;

@property (nonatomic, assign, readonly) BOOL available;

@property (nonatomic, assign, readonly) BOOL readyToProducePackets;

@property (nonatomic, assign, readonly) UInt64 audioDataByteCount;

@property (nonatomic, assign, readonly) NSTimeInterval duration;

@property (nonatomic, assign, readonly) UInt32 bitRate;

@property (nonatomic, assign, readonly) UInt32 maxPacketSize;

@property (nonatomic, assign, readonly) AudioStreamBasicDescription format;

- (instancetype)initWithFileType:(AudioFileTypeID)fileType fileSize:(unsigned long long)fileSize error:(NSError **)error;

- (BOOL)parseData:(NSData *)data error:(NSError **)error;

- (SInt64)seekToTime:(NSTimeInterval *)time;

- (NSData *)fetchMagicCookie;

- (void)close;

@end
