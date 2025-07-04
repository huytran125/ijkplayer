//
//  IJKPlayerManager.m
//  IJKPlayer React Native Bridge Manager
//
//  Created for low-latency livestreaming with SSL support
//

#import "IJKPlayerManager.h"
#import "IJKPlayerView.h"
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

@implementation IJKPlayerManager

RCT_EXPORT_MODULE(IJKPlayer)

- (UIView *)view
{
    return [[IJKPlayerView alloc] init];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

#pragma mark - Props

RCT_EXPORT_VIEW_PROPERTY(source, NSString)
RCT_EXPORT_VIEW_PROPERTY(paused, BOOL)
RCT_EXPORT_VIEW_PROPERTY(muted, BOOL)
RCT_EXPORT_VIEW_PROPERTY(volume, float)
RCT_EXPORT_VIEW_PROPERTY(rate, float)
RCT_EXPORT_VIEW_PROPERTY(seek, float)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, BOOL)

// Low-latency configuration props
RCT_EXPORT_VIEW_PROPERTY(maxBufferSize, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(minBufferSize, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(enableHardwareDecoding, BOOL)
RCT_EXPORT_VIEW_PROPERTY(lowLatencyMode, BOOL)

#pragma mark - Events

RCT_EXPORT_VIEW_PROPERTY(onVideoLoadStart, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoLoad, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoBuffer, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoError, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoProgress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoSeek, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoEnd, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoFullscreenPlayerWillPresent, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoFullscreenPlayerDidPresent, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoFullscreenPlayerWillDismiss, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoFullscreenPlayerDidDismiss, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onReadyForDisplay, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlaybackStalled, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlaybackResume, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlaybackRateChange, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTap, RCTBubblingEventBlock)

#pragma mark - Methods

RCT_EXPORT_METHOD(seek:(nonnull NSNumber *)reactTag
                  toTime:(float)toTime)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            [view setSeek:toTime];
        }
    }];
}

RCT_EXPORT_METHOD(pause:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            [view setPaused:YES];
        }
    }];
}

RCT_EXPORT_METHOD(play:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            [view setPaused:NO];
        }
    }];
}

RCT_EXPORT_METHOD(setVolume:(nonnull NSNumber *)reactTag
                  volume:(float)volume)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            [view setVolume:volume];
        }
    }];
}

RCT_EXPORT_METHOD(stop:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            [view stop];
        }
    }];
}

RCT_EXPORT_METHOD(getCurrentTime:(nonnull NSNumber *)reactTag
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            NSTimeInterval currentTime = [view currentPlaybackTime];
            resolve(@(currentTime));
        } else {
            reject(@"E_VIEW_NOT_FOUND", @"IJKPlayerView not found", nil);
        }
    }];
}

RCT_EXPORT_METHOD(getDuration:(nonnull NSNumber *)reactTag
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        IJKPlayerView *view = (IJKPlayerView *)viewRegistry[reactTag];
        if ([view isKindOfClass:[IJKPlayerView class]]) {
            NSTimeInterval duration = [view duration];
            resolve(@(duration));
        } else {
            reject(@"E_VIEW_NOT_FOUND", @"IJKPlayerView not found", nil);
        }
    }];
}

@end 