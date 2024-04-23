//
//  Mp3RecordingClient.h
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "Recorder.h"
#import "Mp3EncodeOperation.h"


@interface Mp3RecordingClient : NSObject {
    Recorder *recorder;
    NSMutableArray *recordingQueue;
    Mp3EncodeOperation *encodeOperation;
    NSString *lastMp3File;
    NSOperationQueue *opetaionQueue;
}

@property (nonatomic, strong) NSString *currentMp3File;
@property (nonatomic, copy)  void (^onRecordError)(NSInteger);
@property (nonatomic, copy) FlutterResult  onRecordCompleBlock;

+ (instancetype)sharedClient;

- (void)start;
- (void)resume;
- (void)stop;//停止录音,并输出录音文件
- (void)pause;
- (void)releaseQueue;
- (void)startCoverToMp3;
- (void)stopCoverToMp3;

@end
