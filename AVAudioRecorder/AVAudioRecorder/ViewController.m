//
//  ViewController.m
//  AVAudioRecorder
//
//  Created by WangZhiWei on 16/5/13.
//  Copyright © 2016年 Yonyou. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const KRECORDAUDIOFILE = @"myRecord.caf";

@interface ViewController ()<AVAudioRecorderDelegate>

/*!
 	@property
 	@abstract	audioRecorder	音频录音机
 */
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;


/*!
 	@property
 	@abstract	audioPlayer	音频播放器，用于播放录音文件
 */
@property (nonatomic , strong) AVAudioPlayer *audioPlayer;


@property (nonatomic, strong) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UIButton *record;//开始录音
@property (weak, nonatomic) IBOutlet UIButton *pause;//暂停录音
@property (weak, nonatomic) IBOutlet UIButton *resume;//恢复录音
@property (weak, nonatomic) IBOutlet UIButton *stop;//停止录音
@property (weak, nonatomic) IBOutlet UIProgressView *audioPower;//音频波动

@end

@implementation ViewController

#pragma mark --生命周期方法
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置音频会话
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完成后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

#pragma mark --getter，setter方法
- (AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder) {
        NSURL *url = [self getSavaPath];
        
        NSDictionary *setting = [self getAudioSetting];
        
        NSError *error = nil;
        
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;
        if (error) {
            NSLog(@"创建录音对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return  _audioRecorder;
}

- (AVAudioPlayer *)audioPlayer
{
    if (!_audioPlayer) {
        NSURL *url = [self getSavaPath];
        
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        _audioPlayer.numberOfLoops = 0;
        [_audioPlayer prepareToPlay];
        if (error) {
            NSLog(@"创建播放器过程发生错误，错误信息：%@", error.localizedDescription);
            return nil;
        }
        
    }
    return _audioPlayer;
}

- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return  _timer;
}

#pragma mark --私有方法
/*!
 	@method
 	@abstract	录音文件路径
 	@discussion
 	@result
 */
- (NSURL *)getSavaPath

{
    NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr = [urlStr stringByAppendingPathComponent:KRECORDAUDIOFILE];
    NSURL *url = [NSURL fileURLWithPath:urlStr];
    return url;
}

/*!
 	@method
 	@abstract	录音设置
 	@discussion
 	@result
 */
- (NSDictionary *)getAudioSetting

{
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道，这里采用单声道
    [dicM setObject:@(2) forKey:AVNumberOfChannelsKey];
    //每个采样点位数，分为8，16，24，32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    return dicM;
    
}

- (void)audioPowerChange
{
    //更新测量值
    [self.audioRecorder updateMeters];
    //取得第一个通道的音频，注意音频强度范围时-160到0
    float power = [self.audioRecorder averagePowerForChannel:0];
    CGFloat progress = (1.0/160) * (power + 160);
    [self.audioPower setProgress:progress];
}


#pragma mark 控件方法
- (IBAction)recordClick:(UIButton *)sender
{
    if (![self.audioRecorder isRecording]) {
        [self.audioRecorder record];
        self.timer.fireDate = [NSDate distantPast];
    }
}

- (IBAction)pauseClick:(UIButton *)sender
{
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder pause];
        self.timer.fireDate = [NSDate distantFuture];
    }
}

- (IBAction)resumeClick:(UIButton *)sender
{
    [self recordClick:sender];
}

- (IBAction)stopClick:(UIButton *)sender
{
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
        self.timer.fireDate = [NSDate distantFuture];
        [self.audioPower setProgress:0];
    }
}

#pragma  mark --AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
    }
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
{
    
}

@end
