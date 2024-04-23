//
//  Mp3EncodeOperation.m
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import "Mp3EncodeOperation.h"
#import "lame.h"
#import <AVFoundation/AVFoundation.h>

// GLobal var
lame_t lame;

@implementation Mp3EncodeOperation

- (void)main {
    if(_isCoverToMp3){
        [self convertToMp3];
        return;
    }
    if (!_currentMp3File) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _currentMp3File = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3", [NSDate date]]];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_currentMp3File]) {
        [[NSFileManager defaultManager] createFileAtPath:_currentMp3File contents:[@"" dataUsingEncoding:NSASCIIStringEncoding] attributes:nil];
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:_currentMp3File];
    [handle seekToEndOfFile];
    
    // lame param init
    lame = lame_init();
    lame_set_num_channels(lame, 1);
    lame_set_in_samplerate(lame, 44100);
    lame_set_brate(lame, 128);
    lame_set_mode(lame, 1);
    lame_set_quality(lame, 2);
    lame_init_params(lame);
    
    BOOL flag  = true ;
    while (flag) {
        NSData *audioData = nil;
        // @synchronized 的作用是创建一个互斥锁，保证此时没有其它线程对self对象进行修改。这个是objective-c的一个锁定令牌，防止self对象在同一时间内被其它线程访问，起到线程的保护作用。 一般在公用变量的时候使用，如单例模式或者操作类的static变量中使
        @synchronized(_recordQueue){
            if (_recordQueue.count > 0) {
                audioData = [_recordQueue objectAtIndex:0];
                [_recordQueue removeObjectAtIndex:0];
            }
        }
        
        if (audioData.bytes > 0) {
            short *recordingData = (short *)audioData.bytes;
            NSUInteger pcmLen = audioData.length;
            NSUInteger nsamples = pcmLen / 2;
            
            unsigned char buffer[pcmLen];
            @try {
                // mp3 encode
                int recvLen = lame_encode_buffer(lame, recordingData, recordingData, (int)nsamples, buffer, (int)pcmLen);
                
                if (recvLen != -1) {
                    NSData *piece = [NSData dataWithBytes:buffer length:recvLen];
                    [handle writeData:piece];
                }
            } @catch (NSException *exception) {
                NSLog(@"exception = %@", exception);
                if(!_setToStopped) {
                    if( _onRecordError != nil) {
                        //IO_EXCEPTION
                        _onRecordError(15);
                        flag = false;
                    }
                }
            } @finally {
               
            }
        } else {
            if (_setToStopped) {
                break;
            } else {
                [NSThread sleepForTimeInterval:0.05];
            }
        }
    }
    NSLog(@"结束录音,输出文件");
    [handle closeFile];
    lame_close(lame);
    if(self.onRecordCompleBlock){
        NSLog(@"转码完成，执行结束录音");
        self.onRecordCompleBlock(@(YES));
    }
}


- (void)convertToMp3{
    
    // 输入 WAV 音频文件路径
    NSString *inputPath = self.currentMp3File;
    
    // 输出 MP3 文件路径
    NSString *outputMp3Path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSTimeInterval currentTimeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *astr = @(currentTimeStamp).stringValue;
    astr = [astr stringByReplacingOccurrencesOfString:@"." withString:@""];
    outputMp3Path = [NSString stringWithFormat:@"%@/%@.mp3",outputMp3Path,astr];

    // 获取音频采样率
//    Float64 sampleRate = basicDescription->mSampleRate;
    Float64 sampleRate = 44100;

    // 获取音频声道数
//    UInt32 channelCount = basicDescription->mChannelsPerFrame;
    UInt32 channelCount = 1;

    // 输出采样率和声道信息
    NSLog(@"Sample Rate: %.0f Hz", sampleRate);
    NSLog(@"Channel Count: %u", channelCount);

   
    int kChannels = 1;
    Float64 kSampleRate = 44100;
    BOOL isComple = YES;
    @try {
        int read, write;
        FILE *pcm = fopen([inputPath cStringUsingEncoding:NSUTF8StringEncoding], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header 跳过 PCM header 能保证录音的开头没有噪音
        FILE *mp3 = fopen([outputMp3Path cStringUsingEncoding:NSUTF8StringEncoding], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*kChannels];
        unsigned char mp3_buffer[MP3_SIZE];

        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, kSampleRate);
        lame_set_num_channels(lame,kChannels);//设置1为单通道，默认为2双通道
        lame_set_mode(lame, MONO);
        lame_set_brate(lame, 16);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);

        do {
            if(_setToStopped){
                read = 0;
                isComple = NO;
                break;
            }
            read = (int)fread(pcm_buffer, kChannels*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                if (kChannels == 1) {
                    write = lame_encode_buffer(lame, pcm_buffer, nil, read, mp3_buffer, MP3_SIZE);
                } else if (kChannels == 2) {
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }

            fwrite(mp3_buffer, write, 1, mp3);

        } while (read != 0);

        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@", [exception description]);
    }
    @finally {
        NSLog(@"MP3 file generated successfully: %@",outputMp3Path);
    }
    if(self.onRecordCompleBlock){
        NSLog(@"转码完成");
        self.onRecordCompleBlock(isComple? outputMp3Path:nil);
    }
}




@end
