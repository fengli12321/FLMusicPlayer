//
//  FLAudioFileStream.m
//  FLMusicPlayer
//
//  Created by fengli on 2018/3/27.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "FLAudioFileStream.h"
#import "FLParsedAudioData.h"

#define BitRateEstimationMaxPackets 5000
#define BitRateEstimationMinPackets 10


@interface FLAudioFileStream() {
@private
    BOOL _discontinuous;
    AudioFileStreamID _audioFileStreamID;
    SInt64 _dataOffset;
    NSTimeInterval _packetDuration;
    
    UInt64 _processPacketsCount;
    UInt64 _processPacketsSizeTotal;
    
}


- (void)handleAudioFileStreamProperty:(AudioFileStreamPropertyID)propertyID;
- (void)handleAudioFileStreamPackets:(const void *)packets
                       numberOfBytes:(UInt32)numberOfBytes
                     numberOfPackets:(UInt32)numberOfPackets
                  packetDescriptions:(AudioStreamPacketDescription *)packetDescriptioins;

@end

#pragma mark - static callback
static void FLAudioFileStreamPropertyListener(void *inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 *ioFlags) {
    
    FLAudioFileStream *audioFileStream = (__bridge FLAudioFileStream *)inClientData;
    [audioFileStream handleAudioFileStreamProperty:inPropertyID];
}

static void FLAudioFileStreamPacketsCallBack(void *inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void *inInputData, AudioStreamPacketDescription *inPacketDescriptions) {
    
    FLAudioFileStream *audioFileStream = (__bridge FLAudioFileStream *)inClientData;
    [audioFileStream handleAudioFileStreamPackets:inInputData numberOfBytes:inNumberBytes numberOfPackets:inNumberPackets packetDescriptions:inPacketDescriptions];
}
@implementation FLAudioFileStream
//@synthesize fileType = _fileType;

#pragma mark - init & dealloc
- (instancetype)initWithFileType:(AudioFileTypeID)fileType fileSize:(unsigned long long)fileSize error:(NSError **)error {
    if (self = [super init]) {
        
        _discontinuous = NO;
        _fileType = fileType;
        _fileSize = fileSize;
        [self _openAudioFileStreamWithFileTypeHint:_fileType error:error];
    }
    return self;
}

- (void)dealloc {
    [self _closeAudioFileStream];
    
}

- (void)_errorForOSStatus:(OSStatus)status error:(NSError *__autoreleasing *)outError {
    if (outError != noErr && outError != NULL) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
}

#pragma mark - open & close
- (BOOL)_openAudioFileStreamWithFileTypeHint:(AudioFileTypeID)fileTypeHint error:(NSError *__autoreleasing *)error {
    OSStatus status = AudioFileStreamOpen((__bridge void *)self, FLAudioFileStreamPropertyListener, FLAudioFileStreamPacketsCallBack, fileTypeHint, &_audioFileStreamID);
    
    if (status != noErr) {
        FLLog(@"AudioFileStreamOpen 失败");
        _audioFileStreamID = NULL;
    }
    [self _errorForOSStatus:status error:error];
    return status == noErr;
}

- (void)_closeAudioFileStream {
    if (self.available) {
        AudioFileStreamClose(_audioFileStreamID);
        _audioFileStreamID = NULL;
    }
}

- (void)close {
    [self _closeAudioFileStream];
}

- (BOOL)available {
    return _audioFileStreamID != NULL;
}


#pragma mark - actions

- (NSData *)fetchMagicCookie {
    UInt32 cookieSize;
    Boolean writable;
    OSStatus status = AudioFileStreamGetPropertyInfo(_audioFileStreamID, kAudioFilePropertyMagicCookieData, &cookieSize, &writable);
    if (status != noErr) {
        return nil;
    }
    void *cookieData = malloc(cookieSize);
    status = AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
    if (status != noErr) {
        return nil;
    }
    NSData *cookie = [NSData dataWithBytes:cookieData length:cookieSize];
    free(cookieData);
    return cookie;
}
- (BOOL)parseData:(NSData *)data error:(NSError **)error {
    if (self.readyToProducePackets && _packetDuration == 0) {
        [self _errorForOSStatus:-1 error:error];
        return NO;
    }
    OSStatus status = AudioFileStreamParseBytes(_audioFileStreamID, (UInt32)[data length], [data bytes], _discontinuous ? kAudioUnitSubType_Distortion : 0);
    [self _errorForOSStatus:status error:error];
    return status == noErr;
}

- (SInt64)seekToTime:(NSTimeInterval *)time {
    SInt64 approximateSeekOffset = _dataOffset + (*time / _duration) * _audioDataByteCount;
    SInt64 seekToPacket = floor(*time / _packetDuration);
    SInt64 seekByteOffset;
    UInt32 ioFlags = 0;
    SInt64 outDataByteOffset;
    
    OSStatus status = AudioFileStreamSeek(_audioFileStreamID, seekToPacket, &outDataByteOffset, &ioFlags);
    if (status == noErr && !(ioFlags & kAudioFileStreamSeekFlag_OffsetIsEstimated)) {
        *time -= ((approximateSeekOffset - _dataOffset) - outDataByteOffset) * 8.0 / _bitRate;
        seekByteOffset = outDataByteOffset + _dataOffset;
    } else {
        _discontinuous = YES;
        seekByteOffset = approximateSeekOffset;
    }
    return seekByteOffset;
}

#pragma mark - callBack

- (void)calculateBiteRate {
    if (_packetDuration && _processPacketsCount > BitRateEstimationMinPackets && _processPacketsCount < BitRateEstimationMaxPackets) {
        double averagePacketByteSize = _processPacketsSizeTotal / _processPacketsCount;
        _bitRate = 8.0 * averagePacketByteSize / _packetDuration;
    }
}

- (void)calculateDuration {
    if (_fileSize > 0 && _bitRate > 0) {
        _duration = (_fileSize - _dataOffset) * 8.0 / _bitRate;
    }
}

- (void)calculatepPacketDuration {
    if (_format.mSampleRate > 0) {
        _packetDuration = _format.mFramesPerPacket / _format.mSampleRate;
    }
}

- (void)handleAudioFileStreamProperty:(AudioFileStreamPropertyID)propertyID {
    if (propertyID == kAudioFileStreamProperty_ReadyToProducePackets) { // 音频属性信息已经获取到，准备好解析音频数据了
        _readyToProducePackets = YES;
        _discontinuous = YES;
        UInt32 sizeOfUInt32 = sizeof(_maxPacketSize);
        OSStatus status = AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &_maxPacketSize);
        
        if (status != noErr || _maxPacketSize == 0) {
            status = AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &_maxPacketSize);
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(audioFileStreamReadyToProducePackets:)] ) {
            [_delegate audioFileStreamReadyToProducePackets:self];
        }
    } else if (propertyID == kAudioFileStreamProperty_DataOffset) { // 音频数据偏移量
        
        UInt32 offsetSize = sizeof(_dataOffset);
        AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_DataOffset, &offsetSize, &_dataOffset);
        _audioDataByteCount = _fileSize - _dataOffset;
        [self calculateDuration];
    } else if (propertyID == kAudioFileStreamProperty_DataFormat) {
        UInt32 absdSize = sizeof(_format);
        AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_DataFormat, &absdSize, &_format);
        [self calculatepPacketDuration];
    } else if (propertyID == kAudioFileStreamProperty_FormatList) {
        
        Boolean outWriteable;
        UInt32 formatListSize;
        OSStatus status = AudioFileStreamGetPropertyInfo(_audioFileStreamID, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
        if (status == noErr) {
            AudioFormatListItem *formatList = malloc(formatListSize);
            OSStatus status = AudioFileStreamGetProperty(_audioFileStreamID, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
            if (status == noErr) {
                UInt32 supportedFormatSize;
                status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatSize);
                if (status != noErr) {
                    free(formatList);
                    return;
                }
                
                UInt32 supportedFormatCount = supportedFormatSize / sizeof(OSType);
                OSType *supportedFormats = (OSType *)malloc(supportedFormatSize);
                status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatSize, supportedFormats);
                if (status != noErr) {
                    free(formatList);
                    free(supportedFormats);
                    return;
                }
                
                for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i++) {
                    AudioStreamBasicDescription formate = formatList[i].mASBD;
                    for (UInt32 j = 0; j < supportedFormatSize; ++j) {
                        if (formate.mFormatID == supportedFormats[j]) {
                            _format = formate;
                            [self calculatepPacketDuration];
                            break;
                        }
                    }
                }
                free(supportedFormats);
            }
            
            free(formatList);
        }
    }
}

- (void)handleAudioFileStreamPackets:(const void *)packets numberOfBytes:(UInt32)numberOfBytes numberOfPackets:(UInt32)numberOfPackets packetDescriptions:(AudioStreamPacketDescription *)packetDescriptioins {
    
    
    if (_discontinuous) {
        _discontinuous = NO;
    }
    
    if (numberOfBytes == 0 || numberOfPackets == 0) {
        return;
    }
    BOOL deletePackDesc = NO;
    if (packetDescriptioins == NULL) {
        deletePackDesc = YES;
        UInt32 packetSize = numberOfBytes / numberOfPackets;
        AudioStreamPacketDescription *descriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * numberOfPackets);
        for (int i = 0; i < numberOfPackets; i++) {
            UInt32 packetOffset = packetSize * i;
            descriptions[i].mStartOffset = packetOffset;
            descriptions[i].mVariableFramesInPacket = 0;
            if (i == numberOfPackets - 1) {
                descriptions[i].mDataByteSize = numberOfBytes - packetOffset;
            } else {
                descriptions[i].mDataByteSize = packetSize;
            }
        }
        packetDescriptioins = descriptions;
    }
    
    NSMutableArray *parsedDataArray = [NSMutableArray array];
    for (int i = 0; i < numberOfPackets; ++i) {
        SInt64 packetOffset = packetDescriptioins[i].mStartOffset;
        FLParsedAudioData *parsedData = [FLParsedAudioData parsedAudioDataWithBytes:packets + packetOffset packetDescription:packetDescriptioins[i]];
        
        [parsedDataArray addObject:parsedData];
        
        if (_processPacketsCount < BitRateEstimationMaxPackets) {
            _processPacketsSizeTotal += parsedData.packetDescription.mDataByteSize;
            _processPacketsCount += 1;
            [self calculateBiteRate];
            [self calculateDuration];
        }
    }
    
    [_delegate audioFileStream:self audioDataParsed:parsedDataArray];
    if (deletePackDesc) {
        free(packetDescriptioins);
    }
}
@end
