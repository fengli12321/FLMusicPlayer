//
//  FLDataFile.m
//  FLMusicPlayer
//
//  Created by 冯里 on 2018/3/26.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "FLDataPath.h"

@implementation FLDataPath


#pragma mark - Public

+ (NSString *)chachesPath {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)documentPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}
+ (NSString *)musicSavePath {
    
    NSString *path = [[self chachesPath] stringByAppendingPathComponent:@"musics"];
    [self createDirIfNotExist:path];
    return path;
}


#pragma mark - Private
+ (void)createDirIfNotExist:(NSString *)path {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = false;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (!(isDir && isExist)) {
        
        BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        if (bCreateDir) {
            
            FLLog(@"文件路径创建成功");
        }
    }
}
@end
