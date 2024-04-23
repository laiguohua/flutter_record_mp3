//
//  Mp3EncodeOperation.h
//  NewGS
//
//  Created by newgs on 16/5/25.
//  Copyright © 2016年 cnmobi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface Mp3EncodeOperation : NSOperation

@property (nonatomic, assign) BOOL setToStopped ;

@property (nonatomic, assign) NSMutableArray *recordQueue;
@property (nonatomic, strong) NSString *currentMp3File;
@property (nonatomic, copy)  void (^onRecordError)(NSInteger);

@property (nonatomic,assign) BOOL isCoverToMp3;

@property (nonatomic, copy) FlutterResult  onRecordCompleBlock;

@end
