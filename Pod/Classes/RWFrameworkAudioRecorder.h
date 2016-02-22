//
//  RWFrameworkAudioRecorder.h
//  RWFramework
//
//  Created by Joe Zobkiw on 4/17/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

#ifndef RWFramework_RWFrameworkAudioRecorder_h
#define RWFramework_RWFrameworkAudioRecorder_h

@interface RWFrameworkAudioRecorder : NSObject

+ (instancetype)sharedInstance;

- (void)setupAllCustomAudio;

- (void)setupAudioSession;
- (void)setupOutputFile;

- (void)startAudioGraph;
- (void)stopAudioGraph;
- (void)recordingDidTimeout;
- (void)manuallyStoppedRecording;

- (void)deleteRecording;
- (BOOL)hasRecording;
- (BOOL)isRecording;
- (NSTimeInterval)currentTime;

@property (nonatomic, strong, readonly) NSURL *outputURL;

//@property (nonatomic, strong) id<AudioControllerDelegate> delegate;

@end

#endif
