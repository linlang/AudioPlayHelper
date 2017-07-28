//
//  AudioPlayerHelper.m
//  ChongchongProject
//
//  Created by Linyoung on 16/8/3.
//  Copyright © 2016年 Linyoung. All rights reserved.
//

#import "AudioPlayerHelper.h"

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

static AudioPlayerHelper *shareHelper = nil;

@interface AudioPlayerHelper ()

@property (strong, nonatomic) AVPlayer *player;
@property (weak, nonatomic) id timeObserve;
@property (assign, nonatomic) BOOL isPlaying;
@property (copy, nonatomic) NSString *currentUrl;

@end

@implementation AudioPlayerHelper

#pragma mark - life cycle

+ (AudioPlayerHelper *)shareAudioPlayerHelper
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //        shareHelper = [[AudioPlayerHelper alloc] init];
        shareHelper = [[super allocWithZone:NULL] init];
    });
    return shareHelper;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [AudioPlayerHelper shareAudioPlayerHelper];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [AudioPlayerHelper shareAudioPlayerHelper];
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _player = [[AVPlayer alloc] init];
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        [session setCategory:AVAudioSessionCategoryPlayAndRecord
                 withOptions:AVAudioSessionCategoryOptionMixWithOthers
                       error:nil];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];

    } else {
        [self addCompleteNotification];
    }
    return self;
}


#pragma mark - private methords

- (AVPlayer *)playingMusicWithMusicUrl:(NSString *)url
{
    [self pause];
    self.currentUrl = url;
    if(self.player.currentItem)
    {
        @try {
            [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        }
        @catch (NSException *exception) {
            NSLog(@"多次删除了");
        }
    }
    NSURL *songUrl = nil;
    if ([url hasPrefix:@"http"]||[url hasPrefix:@"https"]) {
        //网络
        songUrl = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } else {
        songUrl = [[NSURL alloc]initFileURLWithPath:url];
    }
    AVPlayerItem *songItem = [[AVPlayerItem alloc] initWithURL:songUrl];
    [self setVolumeWithPlayerItem:songItem];
    [songItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    if (self.timeObserve && _player)
    {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    _player = nil;
    _player = [AVPlayer playerWithPlayerItem:songItem];
    _player.volume = 1;
    [self addProgressKVO];
    return _player;
}

- (void)setVolumeWithPlayerItem:(AVPlayerItem *)item {
    NSArray *audioTracks = [item.asset tracksWithMediaType:AVMediaTypeAudio];
    
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =
        [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:1 atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    
    [item setAudioMix:audioMix];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        switch ([[change valueForKey:@"new"] integerValue]) {
            case AVPlayerItemStatusUnknown:
                [object removeObserver:self forKeyPath:@"status"];
                NSLog(@"不知道什么错误");
                break;
            case AVPlayerItemStatusReadyToPlay:
                // 只有观察到status变为这种状态,才会真正的播放.
                NSLog(@"准备成功");
                [self play];
                if(self.prepareBlock)
                {
                    float total = CMTimeGetSeconds(self.player.currentItem.duration);
                    self.prepareBlock((int)total);
                }
                break;
            case AVPlayerItemStatusFailed:
                // mini设备不插耳机或者某些耳机会导致准备失败.
                [object removeObserver:self forKeyPath:@"status"];
                NSLog(@"准备失败");
                break;
            default:
                break;
        }
    }
}

- (void)addProgressKVO
{
    if (self.timeObserve)
    {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    WS(weakSelf);
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        float progress = current/total;
        if (current)
        {
            if(weakSelf.progressBlock)
            {
                if(weakSelf.isPlaying)
                {
                    NSDictionary *progressInfo = @{@"second":@(current),@"progress":@(progress)};
                    weakSelf.progressBlock(progressInfo);
                }

            }
        }
    }];
}

- (void)addCompleteNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}
- (void)playbackFinished:(NSNotification *)notice
{
    [self pause];
    if(self.playComplete)
    {
        self.playComplete();
    }
}

- (float)getSongDuration
{
    float duration = 0;
    if(self.player.currentItem)
    {
        duration = CMTimeGetSeconds(self.player.currentItem.duration);
    }
    return duration;
}


- (void)play
{
    if(!self.player)
    {
        return;
    }
    self.isPlaying = YES;
    [self.player play];
}

- (void)pause
{
    if(!self.player)
    {
        return;
    }
    self.isPlaying = NO;
    [self.player pause];
}

- (void)willSetProgress
{
    [self pause];
}

- (void)setProgress:(CGFloat)progress
{
    if(self.player)
    {
        CMTime time = self.player.currentItem.duration;
        float total = CMTimeGetSeconds(self.player.currentItem.duration);
        CMTime currentTime = CMTimeMakeWithSeconds(total*progress, time.timescale);

        [self.self.player seekToTime:currentTime completionHandler:^(BOOL finish){
            if(finish)
            {
                if(self.isPlaying)
                {
                    [self play];
                }
            }
        }];
    }
}

- (void)stopPlayer
{
    if(self.player.rate == 1)
    {
        [self pause];
    }
    @try {
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception) {
        NSLog(@"多次删除了");
    }
    self.currentUrl = nil;
    [self.player removeTimeObserver:self.timeObserve];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - set and get

- (AVPlayer *)player
{
    if (_player == nil)
    {
        _player = [[AVPlayer alloc] init];
    }
    return _player;
}


@end
