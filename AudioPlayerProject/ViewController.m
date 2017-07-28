//
//  ViewController.m
//  AudioPlayerProject
//
//  Created by Linyoung on 2017/7/28.
//  Copyright © 2017年 Linyoung. All rights reserved.
//

#import "ViewController.h"
#import "AudioPlayerHelper.h"

@interface ViewController ()

@property (strong, nonatomic) UIButton *playBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playBtn.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-80)/2.0, 60, 80, 35);
    [self.view addSubview:self.playBtn];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - event response

- (void)playAction:(UIButton *)sender {
    //播放
    NSString *urlStr = @"http://ws.stream.qqmusic.qq.com/1136744.m4a?fromtag=46";
    AudioPlayerHelper *playerHelper = [AudioPlayerHelper shareAudioPlayerHelper];
    [playerHelper playingMusicWithMusicUrl:urlStr];
}

#pragma mark - set and get

- (UIButton *)playBtn {
    if (_playBtn == nil) {
        _playBtn = [[UIButton alloc] init];
        _playBtn.layer.cornerRadius = 5;
        _playBtn.layer.masksToBounds = YES;
        [_playBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [_playBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
        [_playBtn setTitle:@"Play" forState:UIControlStateNormal];
        [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _playBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_playBtn setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:215.0/255.0 blue:0 alpha:1]];
        
        [_playBtn addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}



@end
