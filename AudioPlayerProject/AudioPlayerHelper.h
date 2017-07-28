//
//  AudioPlayerHelper.h
//  ChongchongProject
//
//  Created by Linyoung on 16/8/3.
//  Copyright © 2016年 Linyoung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//播放进度 0-1
//@{@"second":@"",@"progress":@""}
typedef void(^ProgressBlock)(NSDictionary *progressInfo);
///准备完毕回调
typedef void(^PrepareCompleteBlock)(int duration);
//播放完毕
typedef void(^PlayCompleteBlock)();

@interface AudioPlayerHelper : NSObject

@property (copy, nonatomic) ProgressBlock progressBlock;
@property (copy, nonatomic) PlayCompleteBlock playComplete;
@property (copy, nonatomic) PrepareCompleteBlock prepareBlock;

+ (AudioPlayerHelper *)shareAudioPlayerHelper;

- (AVPlayer *)playingMusicWithMusicUrl:(NSString *)url;
- (float)getSongDuration;
- (void)play;
- (void)pause;
- (void)willSetProgress;
- (void)setProgress:(CGFloat)progress;
- (void)stopPlayer;

@end
