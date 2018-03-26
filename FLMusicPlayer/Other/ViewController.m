//
//  ViewController.m
//  FLMusicPlayer
//
//  Created by 冯里 on 2018/3/26.
//  Copyright © 2018年 冯里. All rights reserved.
//

#import "ViewController.h"
#import "FLAudioSession.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    FLAudioSession *session = [FLAudioSession shareInstance];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
