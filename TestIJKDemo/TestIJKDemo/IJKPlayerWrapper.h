//
//  IJKPlayerWrapper.h
//  TestIJKDemo
//
//  Bridge for IJK Player to SwiftUI
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IJKPlayerWrapperDelegate <NSObject>
- (void)playerDidPrepare;
- (void)playerDidStart;
- (void)playerDidFail:(NSError *)error;
- (void)playerLoadStateChanged:(NSInteger)loadState;
@end

@interface IJKPlayerWrapper : NSObject

@property (nonatomic, weak) id<IJKPlayerWrapperDelegate> delegate;
@property (nonatomic, readonly) UIView *playerView;
@property (nonatomic, readonly) BOOL isPlaying;

- (instancetype)initWithDelegate:(id<IJKPlayerWrapperDelegate>)delegate;
- (void)setupPlayerWithURL:(NSString *)urlString;
- (void)play;
- (void)pause;
- (void)stop;
- (void)shutdown;

@end

NS_ASSUME_NONNULL_END 