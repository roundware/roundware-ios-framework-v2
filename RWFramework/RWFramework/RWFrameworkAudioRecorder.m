//
//  RWFrameworkAudioRecorder.m
//  RWFramework
//
//  Created by Joe Zobkiw on 4/17/15. Original code courtesy of Adam Larsen.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "RWFrameworkAudioRecorder.h"

#define DO_NOT_RECORD_SILENCE false

static RWFrameworkAudioRecorder *sharedInstance;

typedef enum {
    kRecordingStateNone,
    kRecordingStateStarting,
    kRecordingStateRecording,
    kRecordingStateStopping,
    kRecordingStateStopped
} RecordingState;

@interface RWFrameworkAudioRecorder ()

@property (nonatomic) AudioUnit ioUnitInstance;
@property (nonatomic) AUNode ioNode;

@property (nonatomic) AudioComponentDescription ioUnitDescription;
@property (nonatomic) AudioStreamBasicDescription streamFormatDescription;

@property (nonatomic) ExtAudioFileRef outputExtAudioFileInstance;
@property (nonatomic, strong, readwrite) NSURL *outputURL;
@property (nonatomic) AudioQueueRef playbackAudioQueue;

@property (nonatomic) AUGraph processingGraph;

@property (nonatomic) double sampleRate;

@property (nonatomic) NSTimeInterval durationOfContiguousSilence;

@property (nonatomic) NSTimeInterval timeRecordingStarted;

@property (nonatomic) RecordingState recordingState;
@property (nonatomic) BOOL shouldSaveAudio;

@end

@implementation RWFrameworkAudioRecorder

+ (instancetype)sharedInstance
{
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[self alloc] init];
        });
    }
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sampleRate = 44100;
        self.durationOfContiguousSilence = 0.0;
        self.recordingState = kRecordingStateNone;
        self.shouldSaveAudio = NO;
    }
    return self;
}

// Pretend we no longer have a recording
- (void)deleteRecording {
    self.outputURL = nil;
}

// Return YES if we have a recording
- (BOOL)hasRecording {
    return (self.outputURL != nil);
}

// Return YES if we are currently recording
- (BOOL)isRecording {
    return (self.recordingState == kRecordingStateRecording);
}

// Return the time we have been recording or 0 if not recording
- (NSTimeInterval)currentTime {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    return self.timeRecordingStarted == 0 || ![self isRecording] ? 0 : currentTime - self.timeRecordingStarted;
}

#pragma mark - Setup


// Go through all the steps required to setup the audio units and audio graph.
- (void)setupAllCustomAudio
{
    [self setupAudioSession];
    [self defineAudioDescriptions];
    //[self setupOutputFile];
    [self buildAudioProcessingGraph];
    [self attachRenderCallbackFunctions];
    [self connectNodesInAUGraph];
    [self initializeAudioGraph];
}


// Set the audio session to PlayAndRecord category, and get the preferred sample rate (after suggesting our own).
- (void)setupAudioSession
{
    NSError *error = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setPreferredSampleRate:self.sampleRate error:&error];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [audioSession setActive:YES error:&error];
    
    // Update AudioController's sample rate with the one that the audio session finally allowed (hopefully, the preferred sample rate was accepted).
    self.sampleRate = audioSession.preferredSampleRate;
}


// Specify the audio unit and stream descriptions.
- (void)defineAudioDescriptions
{
    // Specify the audio unit description that will be used to find a VoiceProcessiongIO Audio Unit.
    _ioUnitDescription.componentType = kAudioUnitType_Output;
    _ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDescription.componentFlags = 0;
    _ioUnitDescription.componentFlagsMask = 0;
    
    // Specify stream format that will be set as an audio unit property.
    // Currently using uncompressed raw audio preferred by iOS: signed 16-bit, little-endian, 44100 kHz, linear PCM
    UInt32 bytesPerSample = sizeof(SInt16);
    _streamFormatDescription.mSampleRate =       (Float64)self.sampleRate;
    _streamFormatDescription.mFormatID =         kAudioFormatLinearPCM; // kAudioFormatMPEG4AAC
    _streamFormatDescription.mFormatFlags =      kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger; // kMPEG4Object_AAC_Main
    _streamFormatDescription.mBytesPerPacket =   bytesPerSample; // AT&T allows 16-bit PCM WAV (= 2-byte), linear coding, single channel, 8 or 16 kHZ sampling
    _streamFormatDescription.mFramesPerPacket =  1;
    _streamFormatDescription.mBytesPerFrame =    bytesPerSample;
    _streamFormatDescription.mChannelsPerFrame = 1;
    _streamFormatDescription.mBitsPerChannel =   8 * bytesPerSample; // 2 bytes
    _streamFormatDescription.mReserved =         0;
}


// Create the temporary audio file we'll write to.
- (void)setupOutputFile
{
    NSString *fileName = @"audioRecording.caf";
    _outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];

    OSStatus result = ExtAudioFileCreateWithURL((__bridge CFURLRef)_outputURL,
                                                kAudioFileCAFType,
                                                &_streamFormatDescription,
                                                NULL,
                                                kAudioFileFlags_EraseFile,
                                                &_outputExtAudioFileInstance);
    [self handleOSStatusResult:result];
    
    if (noErr != result) {
        NSLog(@"Error writing to output file!");
    }
    else {
        // Set some properties (Apple codec and stream format) for the ExtAudioFile
        UInt32 codec = kAppleHardwareAudioCodecManufacturer;
        result = ExtAudioFileSetProperty(_outputExtAudioFileInstance,
                                         kExtAudioFileProperty_CodecManufacturer,
                                         sizeof(codec),
                                         &codec);
        [self handleOSStatusResult:result];
        
        result = ExtAudioFileSetProperty(_outputExtAudioFileInstance,
                                         kExtAudioFileProperty_ClientDataFormat,
                                         sizeof(_streamFormatDescription),
                                         &_streamFormatDescription);
        [self handleOSStatusResult:result];
    }
}


// Create an audio graph, add a node, instantiate the node as our desired audio unit and get a handle on it, and begin configuring the audio unit.
- (void)buildAudioProcessingGraph
{
    // Create an instance of a new Audio Processing Graph.
    NewAUGraph(&_processingGraph);
    
    // Find and add an audio unit, matching the given description, to the AUGraph as a node.
    OSStatus result = AUGraphAddNode(_processingGraph, &_ioUnitDescription, &_ioNode);
    [self handleOSStatusResult:result];
    
    // Check that the node was added successfully.
    UInt32 nodeCount;
    result = AUGraphGetNodeCount(_processingGraph, &nodeCount);
    [self handleOSStatusResult:result];
    NSAssert(nodeCount > 0, @"Failed to add node to graph!");
    
    // Open the AUGraph, which also instantiates the nodes we've attached to it.
    result = AUGraphOpen(_processingGraph);
    [self handleOSStatusResult:result];
    
    // Get an instance of the audio unit that was found by the AUGraph.
    result = AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnitInstance);
    [self handleOSStatusResult:result];
    
    // Set audio unit properties.
    [self configureAudioUnits];
}


// Configure the newly-instantiated audio unit by setting various properties.
- (void)configureAudioUnits
{
    // Output is enabled by default, but input is not. So enable input.
    UInt32 enableInput = 1;
    AudioUnitElement inputBus = 1;
    OSStatus result = AudioUnitSetProperty(_ioUnitInstance,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           inputBus,
                                           &enableInput,
                                           sizeof(enableInput));
    [self handleOSStatusResult:result];
    
    // And disable output, since we're only interested in writing the recorded audio to a file or sending it from memory.
    UInt32 enableOutput = 0;
    AudioUnitElement outputBus = 0;
    result = AudioUnitSetProperty(_ioUnitInstance,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  outputBus,
                                  &enableOutput,
                                  sizeof(enableOutput));
    [self handleOSStatusResult:result];
    
    // Set the audio unit's stream format property - INPUT.
    result = AudioUnitSetProperty(_ioUnitInstance,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &_streamFormatDescription,
                                  sizeof(_streamFormatDescription));
    [self handleOSStatusResult:result];
    
    // Set the audio unit's stream format property - OUTPUT.
    result = AudioUnitSetProperty(_ioUnitInstance,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1, // Not sure why this has to be 1, but 0 will cause a result status kAudioUnitErr_PropertyNotWritable.
                                  &_streamFormatDescription,
                                  sizeof(_streamFormatDescription));
    [self handleOSStatusResult:result];
}


// Define the function that will run every time the audio unit renders. The callback function is where we do the actual processing of the input audio, and where we pass it off for writing to disk or sending out for recognition.
- (void)attachRenderCallbackFunctions
{
    // Define the AURenderCallbackStruct
    AURenderCallbackStruct callbackStruct = {0};
    callbackStruct.inputProc = performRender; // The callback function itself is defined in a static function below.
    callbackStruct.inputProcRefCon = (__bridge void*)self; // Pass a pointer to the AudioController to the callback function, since it won't have access to the global _ioUnitInstance or the outputFile, being static. Alternatively, we could use another struct here that's been loaded only with the information that we need.
    
    // Set the AURenderCallbackStruct as a property of the io audio unit.
    // This registers an input callback to get called every time the Input bus of the I/O Audio Unit gets asked for more audio samples. In our case, the samples we're asking for are going to get written to a file immediately.
    OSStatus result = AudioUnitSetProperty(_ioUnitInstance,
                                           kAudioOutputUnitProperty_SetInputCallback,
                                           kAudioUnitScope_Global,
                                           1, // Input Element
                                           &callbackStruct,
                                           sizeof(callbackStruct));
    [self handleOSStatusResult:result];
}


// Connect the Voice Processing I/O Audio Unit's input to its output.
// TODO - Is this necessary if we only have the one IO unit? And we're not even using the output element, but just writing straight to disk via the input callback.
- (void)connectNodesInAUGraph
{
    AudioUnitElement ioUnitOutputBus = 0;
    AudioUnitElement ioUnitInputBus = 1;
    
    OSStatus result = AUGraphConnectNodeInput(_processingGraph,
                                              _ioNode,
                                              ioUnitInputBus,
                                              _ioNode,
                                              ioUnitOutputBus);
    [self handleOSStatusResult:result];
}


- (void)initializeAudioGraph
{
//    CAShow(_processingGraph); // Print the graph's properties to the console.
    
    OSStatus result = AUGraphInitialize(_processingGraph);
    [self handleOSStatusResult:result];
}

#pragma mark - Transport controls

- (void)startAudioGraph
{
    NSLog(@"Starting audio graph");
    [self setupOutputFile]; // start with fresh file
    AUGraphStart(_processingGraph);
    self.timeRecordingStarted = [[NSDate date] timeIntervalSince1970];
    self.recordingState = kRecordingStateRecording;
}


- (void)stopAudioGraph
{
    if (self.recordingState != kRecordingStateStopped) { // If we haven't already told the graph to stop...
        NSLog(@"Stopping audio graph");
        AUGraphStop(_processingGraph);
        self.recordingState = kRecordingStateStopped;
        self.timeRecordingStarted = 0;
        self.durationOfContiguousSilence = 0.0; // Reset the contiguous silence counter.
    }
}


// Public method called after the Talk button has been tapped again.
- (void)manuallyStoppedRecording
{
    self.recordingState = kRecordingStateStopping;
    [self stopAudioGraph];
}


// Public method called after the recording timer has timed out.
- (void)recordingDidTimeout
{
    self.recordingState = kRecordingStateStopping;
    [self stopAudioGraph];
    
    //[self.delegate didFinishRecording]; // Notify the view controller that recording is done,
}

#pragma mark - 

// Interpret the OSStatus result. Everything's OK if the result == noErr.
- (void)handleOSStatusResult:(OSStatus) result
{
    if (noErr != result) {
        NSLog(@"Encountered error: %d", (int)result);
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                             code:result
                                         userInfo:nil];
        NSLog(@"Error: %@", [error description]);
        
    }
    
    // Check common errors.
    if (result == kAudioUnitErr_PropertyNotWritable) {
        NSLog(@"The property could not be written");
    }
}


// Define a render callback function that conforms to the AURenderCallback prototype.
// This tells the Audio Unit to render the samples (processing it with VoiceI/O for echo cancellation), and then writes the result to a file.
static OSStatus performRender (void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames, // 256
                               AudioBufferList *ioData)
{
    // NOTE: We don't actually use ioData. Instead we render the data ourselves into our own bufferList once we call AudioUnitRender.
    
    OSStatus result = 0;
    
    // Create a buffer to hold the rendered audio.
    AudioBufferList bufferList;
    
    SInt16 samples[inNumberFrames]; // The audio amplitudes are going to be rendered into two-byte signed ints. An array with a slot for each frame is large enough to not worry about buffer overrun.
    memset (&samples, 0, sizeof(samples)); // Set everything at sample's memory address to 0 (prevent pre-existing artifacts)
    
    // Setup the bufferList we're outputting to.
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(SInt16); // Total size of the data
    
    // Get the audio unit instance from the inRefCon so we can render it.
    RWFrameworkAudioRecorder *audioController = (__bridge RWFrameworkAudioRecorder*)inRefCon;
    AudioUnit ioUnit = audioController->_ioUnitInstance;
    result = AudioUnitRender(ioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList); // Do the actual rendering of the audio.
    if (noErr != result) {
        printf("AudioUnitRender error: %d", (int)result);
    }
    
    // Start- and End-pointing
    // We will constantly be listening to and rendering audio, but only save it if it's not silence. Stop saving audio if we detect a certain duration of silence in a row.
#if DO_NOT_RECORD_SILENCE
    [audioController checkAudioBufferForSilence:bufferList inNumberFrames:inNumberFrames];
#else
    audioController.shouldSaveAudio = YES; // always save audio, don't stop during silence
#endif

    [audioController increaseVolumeOfSamples:bufferList inNumberFrames:inNumberFrames]; // Output audio is kind of soft after voice processing, so give it some gain.

    // Do the actual writing to file.
    if (audioController.shouldSaveAudio) { // Should save audio if the sample isn't just silence.
        //printf(".");
        result = ExtAudioFileWriteAsync(audioController->_outputExtAudioFileInstance,
                                        inNumberFrames,
                                        &bufferList);
        if (noErr != result) {
            printf("ExtAudioFileWriteAsync error: %d", (int)result);
        }
    }
    
    return result;
};


#if DO_NOT_RECORD_SILENCE
static const Float32 kDBOffset = -89.0; // Approx. lower-limit of the volume of sound, in decibels, that the iPhone hardware can detect.
static const Float32 kSilenceVolumeThresholdInDecibels = -20.0; // Cut-off below which we'll consider the rendered audio silence or just background noise. Number manually tweaked based on typical decibel levels during silence. Alternatively, do a low-pass filter to clean out the lower end completely, AND/OR provide some way for the user to calibrate it.
static const NSTimeInterval kSilenceDurationThreshold = 1.5; // If more than this duration of silence is detected, recording will be stopped.

// Keeps track of how many near-silent samples have been rendered by the audio unit.
// If enough samples (saved as a duration in durationOfContiguousSilence) are under a certain decibel threshold, we shouldn't save the audio, since it's most likely silence. If we do detect non-silence, start saving the audio again.
// See http://www.politepix.com/2010/06/18/decibel-metering-from-an-iphone-audio-unit/
- (void)checkAudioBufferForSilence:(AudioBufferList)bufferList inNumberFrames:(UInt32)inNumberFrames
{
    // Get an array of samples we can loop through
    SInt16* samples = (SInt16 *)(bufferList.mBuffers[0].mData);
    
    
    // ***** Determine peak value of this batch of audio samples ******
    // Initialize a peakValue for this batch of samples. If this peakValue remains below our silence volume threshold, we'll consider the entire batch as silence.
    Float32 peakValue = kDBOffset;
    
    // Loop through the samples, converting their amplitudes to decibels and keeping track of the peak decibel level.
    for (int i = 0; i < inNumberFrames; i++) {
        
        // Get the absolute value of each sample.
        Float32 absoluteValueOfSampleAmplitude = abs(samples[i]);
        
        // And convert it from amplitude to decibels.
        Float32 sampleVolumeInDecibels = 20.0*log10(absoluteValueOfSampleAmplitude) + kDBOffset; // Convert using log curve, and shift so that it ranges from -kDBOffset to 0.0, instead of ranging from 0.0 to +kDBOffset. By default, 0.0 is the lower limit (softest) of capturable volume, and +kDBOffset is the upper limit (loudest). Done here to emulate how it's done in AudioQueue's metering function.
        
//        NSLog(@"Amplitude: %hd, Decibels: %f", samples[i], sampleVolumeInDecibels);
        
        // If the converted decibel value is valid, check if it's louder than any previous samples in this batch.
        if (sampleVolumeInDecibels == sampleVolumeInDecibels && sampleVolumeInDecibels != INFINITY) { // If converted value in decibels is rational and not infinity
            if (sampleVolumeInDecibels > peakValue) {
                peakValue = sampleVolumeInDecibels;
            }
        }
    }
    
//    NSLog(@"Peak decibel level for this sample is: %f", peakValue);
    
    // ***** Handle results of peak audio level *****
    // If peak value didn't exceed our volume threshold...
    if (peakValue < kSilenceVolumeThresholdInDecibels) {
        NSTimeInterval sampleDuration = inNumberFrames / self.sampleRate; // (Frames or samples) divided by (samples per second) == seconds
        
        // Add the time of audio in this sample to our silence tally.
        self.durationOfContiguousSilence += sampleDuration;
        
        // If silence tally is greater than some time, we shouldn't save any more audio until non-silence is detected again.
        if (self.durationOfContiguousSilence > kSilenceDurationThreshold) {
            // If the audio graph is active, and we're currently saving audio
            if (self.recordingState != kRecordingStateStopping && self.recordingState != kRecordingStateStopped && self.shouldSaveAudio) {
                NSLog(@"Definitely probably silence. Stop recording");
                self.shouldSaveAudio = NO;
            }
        }
    }
    else { // Not silence, so let's start saving audio again.
        // Reset the silence tally if this batch WASN'T silence.
        double epsilon = 0.00001; // Epsilon for floating point comparison
        if (self.durationOfContiguousSilence - 0.0 > epsilon) { // If there was previously a chunk of silence, reset it, since we just heard some real audio.
            self.durationOfContiguousSilence = 0.0;
        }
        if (!self.shouldSaveAudio) { self.shouldSaveAudio = YES; }
    }
}
#endif


// Loop through each sample and increase the amplitude, since voice processing seems to decrease the overall gain.
- (void)increaseVolumeOfSamples:(AudioBufferList)bufferList inNumberFrames:(UInt32)inNumberFrames
{
    SInt16* samples = (SInt16 *)(bufferList.mBuffers[0].mData);
    for (int i = 0; i < inNumberFrames; i++) {
        samples[i] *= 2.0; // Simple, arbitrary increase in amplitude. TODO - May be too much if a sound is already loud.
    }
}


// Every time the shouldSaveAudio flag is switched, notify AudioController's delegate a change has happened.
- (void)setShouldSaveAudio:(BOOL)shouldSaveAudio
{
    if (_shouldSaveAudio != shouldSaveAudio) {
        if (shouldSaveAudio) {
            NSLog(@"Starting to save audio!");
            //[self.delegate didStartSavingAudio];
        }
        else {
            NSLog(@"No longer saving audio");
            //[self.delegate didStopSavingAudio];
        }
        
        _shouldSaveAudio = shouldSaveAudio;
    }
}

@end
