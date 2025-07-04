//
//  IJKPlayerView.m
//  IJKPlayer React Native Bridge
//
//  Created for low-latency livestreaming with SSL support
//

#import "IJKPlayerView.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>

@interface IJKPlayerView ()
@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, strong) NSTimer *progressTimer;
@property (nonatomic, assign) BOOL playerReady;
@property (nonatomic, strong) IJKFFOptions *playerOptions;
@end

@implementation IJKPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        // Initialize default values with low-latency settings
        _paused = NO;
        _muted = NO;
        _volume = 1.0;
        _rate = 1.0;
        _resizeMode = NO;
        _playerReady = NO;
        
        // Low-latency defaults from IJKMediaDemo
        _maxBufferSize = 800;    // 800ms max buffer
        _minBufferSize = 100;    // 100ms min buffer
        _enableHardwareDecoding = YES;
        _lowLatencyMode = YES;
        
        self.backgroundColor = [UIColor blackColor];
        
        // Setup player options immediately
        [self setupPlayerOptions];
    }
    return self;
}

- (void)dealloc
{
    [self removePlayerNotifications];
    [self.progressTimer invalidate];
    [self.player shutdown];
}

- (void)setupPlayerOptions
{
    // Set up IJKPlayer logging and version checks (from IJKMediaDemo)
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:NO]; // Don't show alert in React Native
    
    // Create player options with comprehensive low-latency configuration
    self.playerOptions = [IJKFFOptions optionsByDefault];
    
    // ALWAYS apply low-latency configuration for RTMPS streaming
    [self setupLowLatencyConfiguration:self.playerOptions];
    
    // Hardware decoding settings are now configured in setupLowLatencyConfiguration
    // This ensures consistency with IJKMediaDemo's optionsWithLowLatency method
}

- (void)setupPlayer
{
    if (!_source || _source.length == 0) {
        return;
    }
    
    // Clean up existing player
    if (self.player) {
        [self removePlayerNotifications];
        [self.player shutdown];
        [self.player.view removeFromSuperview];
        self.player = nil;
    }
    
    // Create new player with URL (match demo's URL handling)
    NSURL *url = [NSURL URLWithString:_source];
    
    // Validate URL creation like the demo does
    if (!url) {
        RCTLogError(@"IJKPlayer: Invalid URL string: %@", _source);
        if (self.onVideoError) {
            self.onVideoError(@{@"error": @{@"code": @"INVALID_URL", @"description": @"Invalid URL string"}});
        }
        return;
    }
    
    RCTLogInfo(@"IJKPlayer: Creating player with URL: %@ (scheme: %@)", url.absoluteString, url.scheme);
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:self.playerOptions];
    
    if (!self.player) {
        RCTLogError(@"IJKPlayer: Failed to create player with URL: %@", _source);
        return;
    }
    
    // Configure player view (following IJKMediaDemo pattern)
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = self.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = !_paused;
    
    // Critical: Set autoresizesSubviews (from IJKMediaDemo)
    self.autoresizesSubviews = YES;
    
    [self addSubview:self.player.view];
    [self addPlayerNotifications];
    
    // Delay prepareToPlay slightly to match demo timing  
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.player) {
            [self.player prepareToPlay];
            RCTLogInfo(@"IJKPlayer: prepareToPlay called");
        }
    });
    
    RCTLogInfo(@"IJKPlayer: Player created with URL: %@", _source);
}

- (void)setupLowLatencyConfiguration:(IJKFFOptions *)options
{
    // EXACT configuration from IJKMediaDemo's optionsWithLowLatency method
    
    // Player options - reduce buffering for low latency
    [options setPlayerOptionIntValue:1      forKey:@"packet-buffering"];
    [options setPlayerOptionIntValue:1      forKey:@"framedrop"];
    [options setPlayerOptionIntValue:1      forKey:@"sync-av-start"];
    
    // Optimized buffer watermarks
    [options setPlayerOptionIntValue:100    forKey:@"first-high-water-mark-ms"];
    [options setPlayerOptionIntValue:300    forKey:@"next-high-water-mark-ms"];
    [options setPlayerOptionIntValue:800    forKey:@"last-high-water-mark-ms"];
    
    // Buffer size optimized for 2.2 Mbps stream
    [options setPlayerOptionIntValue:30     forKey:@"min-frames"];
    [options setPlayerOptionIntValue:2*1024*1024 forKey:@"max-buffer-size"];
    
    // RTMP specific options for live streaming
    [options setFormatOptionIntValue:1      forKey:@"rtmp_live"];
    [options setFormatOptionIntValue:0      forKey:@"rtmp_buffer"];
    [options setFormatOptionIntValue:8192   forKey:@"rtmp_buffer_size"];
    
    // Performance optimizations
    [options setCodecOptionIntValue:1       forKey:@"skip_loop_filter"];
    [options setPlayerOptionIntValue:3      forKey:@"video-pictq-size"];
    [options setPlayerOptionIntValue:30     forKey:@"max-fps"];
    
    // CRITICAL FIX: Match demo's configuration exactly
    [options setPlayerOptionIntValue:1      forKey:@"start-on-prepared"]; // Changed from 0 to 1
    [options setPlayerOptionIntValue:10     forKey:@"max-deviation"];
    [options setPlayerOptionIntValue:1      forKey:@"sync-type"];
    
    // Network optimizations - REMOVE timeout options like the demo does
    [options setFormatOptionIntValue:1      forKey:@"reconnect"];
    [options setFormatOptionIntValue:3      forKey:@"reconnect_streamed"];
    // CRITICAL: Don't set timeout options at all (demo removes them entirely)
    // [options setFormatOptionIntValue:...   forKey:@"timeout"]; // REMOVED - let IJKPlayer remove it
    // [options setFormatOptionIntValue:...   forKey:@"listen_timeout"]; // REMOVED
    [options setFormatOptionIntValue:1      forKey:@"tcp_nodelay"];
    [options setFormatOptionValue:@"1048576" forKey:@"recv_buffer_size"];
    
    // Hardware decode optimizations
    [options setPlayerOptionIntValue:0      forKey:@"enable-accurate-seek"];
    [options setPlayerOptionIntValue:1      forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:1      forKey:@"videotoolbox-async"];
    [options setPlayerOptionIntValue:0      forKey:@"videotoolbox-wait-async"];
    
    // Audio optimizations
    [options setPlayerOptionIntValue:512*1024 forKey:@"audio-buffer-size"];
    [options setPlayerOptionIntValue:0      forKey:@"audio-disable-mixing"];
    
    // CRITICAL: Set user-agent to match demo
    [options setFormatOptionValue:@"ijkplayer" forKey:@"user-agent"];
    
    RCTLogInfo(@"IJKPlayer: Demo-matching low-latency configuration applied - options configured");
}

- (void)addPlayerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:self.player];
}

- (void)removePlayerNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                   object:self.player];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.player];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                   object:self.player];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                   object:self.player];
}

#pragma mark - Setters

- (void)setSource:(NSString *)source
{
    if (![source isEqualToString:_source]) {
        _source = source;
        
        if (source && source.length > 0) {
            if (self.onVideoLoadStart) {
                self.onVideoLoadStart(@{@"src": @{@"uri": source}});
            }
            
            RCTLogInfo(@"IJKPlayer: Source set: %@", source);
            
            // Don't setup player immediately - wait for view to be ready
            if (self.superview) {
                [self setupPlayer];
            }
            // If no superview yet, setupPlayer will be called in didMoveToSuperview
        }
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    // Setup player when view is added to hierarchy, but delay to match demo timing
    if (self.superview && _source && _source.length > 0 && !self.player) {
        RCTLogInfo(@"IJKPlayer: View added to superview, delaying player setup");
        
        // Delay player creation to allow OpenGL view to fully initialize
        // This matches the demo's timing where Main Thread Checker warnings happen first
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.superview && !self.player) {
                RCTLogInfo(@"IJKPlayer: OpenGL view ready, setting up player");
                [self setupPlayer];
            }
        });
    }
}

- (void)setPaused:(BOOL)paused
{
    if (_paused != paused) {
        _paused = paused;
        [self applyModifiers];
    }
}

- (void)setMuted:(BOOL)muted
{
    if (_muted != muted) {
        _muted = muted;
        [self applyModifiers];
    }
}

- (void)setVolume:(float)volume
{
    if (_volume != volume) {
        _volume = volume;
        [self applyModifiers];
    }
}

- (void)setRate:(float)rate
{
    if (_rate != rate) {
        _rate = rate;
        [self applyModifiers];
    }
}

- (void)setSeek:(float)seekTime
{
    if (self.player && _playerReady) {
        self.player.currentPlaybackTime = seekTime;
        
        if (self.onVideoSeek) {
            self.onVideoSeek(@{
                @"currentTime": @(self.player.currentPlaybackTime),
                @"seekTime": @(seekTime)
            });
        }
    }
}

- (void)applyModifiers
{
    if (!self.player) return;
    
    if (_paused) {
        [self.player pause];
    } else {
        [self.player play];
    }
    
    // Apply volume (muted overrides volume)
    float targetVolume = _muted ? 0.0 : _volume;
    self.player.playbackVolume = targetVolume;
    
    // Apply playback rate
    self.player.playbackRate = _rate;
}

#pragma mark - Progress Timer

- (void)startProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                          target:self
                                                        selector:@selector(sendProgressUpdate)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)stopProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

- (void)sendProgressUpdate
{
    if (!self.player || !_playerReady) return;
    
    if (self.onVideoProgress) {
        self.onVideoProgress(@{
            @"currentTime": @(self.player.currentPlaybackTime),
            @"playableDuration": @(self.player.playableDuration),
            @"duration": @(self.player.duration)
        });
    }
}

#pragma mark - Player Notifications

- (void)moviePlayerPreparedToPlayDidChange:(NSNotification *)notification
{
    if (self.player.isPreparedToPlay) {
        _playerReady = YES;
        
        if (self.onVideoLoad) {
            self.onVideoLoad(@{
                @"duration": @(self.player.duration),
                @"naturalSize": @{
                    @"width": @(self.player.naturalSize.width),
                    @"height": @(self.player.naturalSize.height)
                }
            });
        }
        
        if (self.onReadyForDisplay) {
            self.onReadyForDisplay(@{});
        }
        
        [self applyModifiers];
        [self startProgressTimer];
        
        RCTLogInfo(@"IJKPlayer: Ready to play - Duration: %.2fs", self.player.duration);
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    NSNumber *reason = notification.userInfo[IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    if (self.onVideoEnd) {
        self.onVideoEnd(@{@"reason": reason ?: @0});
    }
    
    [self stopProgressTimer];
    
    RCTLogInfo(@"IJKPlayer: Playback finished with reason: %@", reason);
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    IJKMPMoviePlaybackState playbackState = self.player.playbackState;
    
    switch (playbackState) {
        case IJKMPMoviePlaybackStatePlaying:
            if (self.onPlaybackResume) {
                self.onPlaybackResume(@{});
            }
            [self startProgressTimer];
            break;
            
        case IJKMPMoviePlaybackStatePaused:
        case IJKMPMoviePlaybackStateStopped:
            [self stopProgressTimer];
            break;
            
        default:
            break;
    }
    
    if (self.onPlaybackRateChange) {
        self.onPlaybackRateChange(@{@"playbackRate": @(self.player.playbackRate)});
    }
}

- (void)moviePlayerLoadStateDidChange:(NSNotification *)notification
{
    IJKMPMovieLoadState loadState = self.player.loadState;
    
    if (loadState & IJKMPMovieLoadStateStalled) {
        if (self.onPlaybackStalled) {
            self.onPlaybackStalled(@{});
        }
        if (self.onVideoBuffer) {
            self.onVideoBuffer(@{@"isBuffering": @YES});
        }
    } else if (loadState & IJKMPMovieLoadStatePlayable) {
        if (self.onVideoBuffer) {
            self.onVideoBuffer(@{@"isBuffering": @NO});
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.player.view) {
        self.player.view.frame = self.bounds;
    }
}

#pragma mark - Additional Methods (from IJKMediaDemo patterns)

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.onTap) {
        self.onTap(@{});
    }
}

- (BOOL)isPlaying {
    return self.player ? [self.player isPlaying] : NO;
}

- (void)play {
    if (self.player) {
        [self.player play];
    }
}

- (void)pause {
    if (self.player) {
        [self.player pause];
    }
}

- (void)stop {
    if (self.player) {
        [self.player stop];
    }
}

- (NSTimeInterval)currentPlaybackTime {
    return self.player ? self.player.currentPlaybackTime : 0.0;
}

- (NSTimeInterval)duration {
    return self.player ? self.player.duration : 0.0;
}

@end 