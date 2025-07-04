//
//  IJKPlayerView.h
//  IJKPlayer React Native Bridge
//
//  Created for low-latency livestreaming with SSL support
//

#import <UIKit/UIKit.h>
#import <React/RCTView.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// Import IJKPlayer framework
#import <IJKMediaFrameworkWithSSL/IJKMediaFrameworkWithSSL.h>

@interface IJKPlayerView : RCTView

// Player properties
@property (nonatomic, strong) IJKFFMoviePlayerController *player;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float rate;
@property (nonatomic, assign) float seek;
@property (nonatomic, assign) BOOL resizeMode;

// Low-latency configuration
@property (nonatomic, assign) NSInteger maxBufferSize;
@property (nonatomic, assign) NSInteger minBufferSize;
@property (nonatomic, assign) BOOL enableHardwareDecoding;
@property (nonatomic, assign) BOOL lowLatencyMode;

// Event callbacks
@property (nonatomic, copy) RCTBubblingEventBlock onVideoLoadStart;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoLoad;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoBuffer;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoError;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoProgress;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoSeek;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoEnd;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoFullscreenPlayerWillPresent;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoFullscreenPlayerDidPresent;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoFullscreenPlayerWillDismiss;
@property (nonatomic, copy) RCTBubblingEventBlock onVideoFullscreenPlayerDidDismiss;
@property (nonatomic, copy) RCTBubblingEventBlock onReadyForDisplay;
@property (nonatomic, copy) RCTBubblingEventBlock onPlaybackStalled;
@property (nonatomic, copy) RCTBubblingEventBlock onPlaybackResume;
@property (nonatomic, copy) RCTBubblingEventBlock onPlaybackRateChange;
@property (nonatomic, copy) RCTBubblingEventBlock onTap;

// Methods
- (void)setPaused:(BOOL)paused;
- (void)setSeek:(float)seekTime;
- (void)setRate:(float)rate;
- (void)setMuted:(BOOL)muted;
- (void)setVolume:(float)volume;
- (void)setSource:(NSString *)source;
- (void)applyModifiers;
- (void)setupLowLatencyConfiguration;
- (void)sendProgressUpdate;

// Player control methods (from IJKMediaDemo patterns)
- (BOOL)isPlaying;
- (void)play;
- (void)pause;
- (void)stop;
- (NSTimeInterval)currentPlaybackTime;
- (NSTimeInterval)duration;

@end 