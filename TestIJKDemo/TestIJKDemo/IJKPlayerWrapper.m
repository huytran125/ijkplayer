//
//  IJKPlayerWrapper.m
//  TestIJKDemo
//
//  Bridge for IJK Player to SwiftUI
//

#import "IJKPlayerWrapper.h"
#import <IJKMediaFrameworkWithSSL/IJKMediaFrameworkWithSSL.h>

@interface IJKPlayerWrapper ()
@property (nonatomic, strong) IJKFFMoviePlayerController *player;
@property (nonatomic, strong) NSURL *contentURL;
@end

@implementation IJKPlayerWrapper

- (instancetype)initWithDelegate:(id<IJKPlayerWrapperDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        [self setupIJKFramework];
    }
    return self;
}

- (void)setupIJKFramework {
    // Enable debug logging like the working demo
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
}

- (void)setupPlayerWithURL:(NSString *)urlString {
    if (self.player) {
        [self shutdown];
    }
    
    self.contentURL = [NSURL URLWithString:urlString];
    
    // Use the EXACT same options that worked in our React Native implementation
    IJKFFOptions *options = [self createOptimizedOptions];
    
    // Create player with same pattern as working demo
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.contentURL withOptions:options];
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    // Install notifications BEFORE prepare (exact demo timing)
    [self installMovieNotificationObservers];
    
    NSLog(@"TestIJKDemo: Player created with URL: %@", urlString);
    
    // Auto-start playback (like the working demo)
    [self.player prepareToPlay];
    NSLog(@"TestIJKDemo: Auto-starting prepareToPlay for autoplay");
}

// EXACT same options that worked in React Native after all our fixes
- (IJKFFOptions *)createOptimizedOptions {
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    
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
    
    // CRITICAL settings that match demo
    [options setPlayerOptionIntValue:1      forKey:@"start-on-prepared"];
    [options setPlayerOptionIntValue:10     forKey:@"max-deviation"];
    [options setPlayerOptionIntValue:1      forKey:@"sync-type"];
    
    // Network optimizations - don't set timeout options (demo removes them)
    [options setFormatOptionIntValue:1      forKey:@"reconnect"];
    [options setFormatOptionIntValue:3      forKey:@"reconnect_streamed"];
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
    
    // User agent to match demo
    [options setFormatOptionValue:@"ijkplayer" forKey:@"user-agent"];
    
    return options;
}

- (UIView *)playerView {
    return self.player ? self.player.view : nil;
}

- (BOOL)isPlaying {
    return self.player && [self.player isPlaying];
}

- (void)play {
    if (self.player) {
        [self.player prepareToPlay];
        NSLog(@"TestIJKDemo: prepareToPlay called");
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

- (void)shutdown {
    if (self.player) {
        [self removeMovieNotificationObservers];
        [self.player shutdown];
        self.player = nil;
    }
}

#pragma mark - Notification Observers

- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:self.player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerPlaybackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:self.player];
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                   object:self.player];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.player];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                   object:self.player];
}

#pragma mark - Notification Handlers

- (void)moviePlayerLoadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = self.player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"TestIJKDemo: IJKMPMovieLoadStatePlaythroughOK: %d", (int)loadState);
        if ([self.delegate respondsToSelector:@selector(playerDidPrepare)]) {
            [self.delegate playerDidPrepare];
        }
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"TestIJKDemo: IJKMPMovieLoadStateStalled: %d", (int)loadState);
    } else {
        NSLog(@"TestIJKDemo: Load state: %d", (int)loadState);
    }
    
    if ([self.delegate respondsToSelector:@selector(playerLoadStateChanged:)]) {
        [self.delegate playerLoadStateChanged:loadState];
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification*)notification {
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    NSLog(@"TestIJKDemo: Playback finished with reason: %d", reason);
    
    if (reason == IJKMPMovieFinishReasonPlaybackError) {
        NSError *error = [NSError errorWithDomain:@"IJKPlayerError" 
                                             code:reason 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Playback failed"}];
        if ([self.delegate respondsToSelector:@selector(playerDidFail:)]) {
            [self.delegate playerDidFail:error];
        }
    }
}

- (void)moviePlayerPlaybackStateDidChange:(NSNotification*)notification {
    IJKMPMoviePlaybackState state = self.player.playbackState;
    NSLog(@"TestIJKDemo: Playback state changed to: %d", (int)state);
    
    if (state == IJKMPMoviePlaybackStatePlaying) {
        if ([self.delegate respondsToSelector:@selector(playerDidStart)]) {
            [self.delegate playerDidStart];
        }
    }
}

- (void)dealloc {
    [self shutdown];
}

@end 