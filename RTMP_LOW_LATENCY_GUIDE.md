# RTMP Low-Latency Streaming Configuration Guide

This guide explains how to configure ijkplayer-ios for minimal delay when streaming RTMP content.

## Problem
By default, ijkplayer uses conservative buffering settings optimized for stable playback over unreliable networks. This causes significant delay (typically 3-10 seconds) which is unacceptable for live streaming applications.

## Solution
The key is to reduce buffering at multiple levels while accounting for stream bitrate:

### 1. Buffer Watermarks (Bitrate-Aware)
For **2.2 Mbps streams** (275 KB/s):
- **first-high-water-mark-ms**: 100ms (27.5 KB buffer)
- **next-high-water-mark-ms**: 300ms (82.5 KB buffer)  
- **last-high-water-mark-ms**: 800ms (220 KB buffer)

For **lower bitrate streams** (< 1 Mbps):
- **first-high-water-mark-ms**: 50ms
- **next-high-water-mark-ms**: 200ms
- **last-high-water-mark-ms**: 500ms

### 2. Frame Buffering (GOP-Aware)
- **min-frames**: Set to GOP size (e.g., 30 frames for 29-frame GOP)
- **max-buffer-size**: 2MB for 2.2 Mbps streams, 1MB for lower bitrates
- **video-pictq-size**: 2 frames for smooth 30fps playback

### 3. RTMP-Specific Options
- **rtmp_live**: Enable RTMP live mode
- **rtmp_buffer**: Disable RTMP internal buffering
- **rtmp_buffer_size**: 8KB for high bitrate (2+ Mbps), 1KB for lower

### 4. Performance Optimizations
- **max-fps**: Match source FPS exactly (30 for most streams)
- **skip_loop_filter**: Skip loop filter for faster decoding
- **videotoolbox-async**: Enable async hardware decoding for high bitrates

## Implementation

The optimized configuration for **2.2 Mbps @ 30fps RTMPS streams**:

```objective-c
+ (IJKFFOptions *)optionsWithLowLatency
{
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    
    // Player options - reduce buffering for low latency
    [options setPlayerOptionIntValue:1      forKey:@"packet-buffering"];
    [options setPlayerOptionIntValue:1      forKey:@"framedrop"];
    [options setPlayerOptionIntValue:0      forKey:@"sync-av-start"];
    
    // Optimized buffer watermarks for 2.2 Mbps stream (275 KB/s)
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
    
    // Performance optimizations for 30 FPS stream
    [options setCodecOptionIntValue:1       forKey:@"skip_loop_filter"];
    [options setPlayerOptionIntValue:2      forKey:@"video-pictq-size"];
    [options setPlayerOptionIntValue:30     forKey:@"max-fps"];
    
    // Network optimizations for 2.2 Mbps RTMPS
    [options setFormatOptionIntValue:1      forKey:@"reconnect"];
    [options setFormatOptionIntValue:3      forKey:@"reconnect_streamed"];
    [options setFormatOptionIntValue:15*1000*1000 forKey:@"timeout"];
    [options setFormatOptionIntValue:1      forKey:@"tcp_nodelay"];
    [options setFormatOptionValue:@"1048576" forKey:@"recv_buffer_size"];
    
    // Hardware acceleration for high bitrate streams
    [options setPlayerOptionIntValue:1      forKey:@"videotoolbox"];
    [options setPlayerOptionIntValue:1      forKey:@"videotoolbox-async"];
    [options setPlayerOptionIntValue:0      forKey:@"videotoolbox-wait-async"];
    
    return options;
}
```

## Expected Results

With these **bitrate-optimized** settings for 2.2 Mbps streams:
- **Latency**: 200-800ms (down from 3-10 seconds)
- **Startup time**: Faster initial playback
- **FPS stability**: Smooth 30fps playback
- **Network resilience**: Better handling of 2.2 Mbps throughput

## Bitrate-Specific Tuning

### For High Bitrate Streams (2+ Mbps)
```objective-c
[options setPlayerOptionIntValue:100    forKey:@"first-high-water-mark-ms"];
[options setPlayerOptionIntValue:300    forKey:@"next-high-water-mark-ms"];
[options setPlayerOptionIntValue:800    forKey:@"last-high-water-mark-ms"];
[options setPlayerOptionIntValue:30     forKey:@"min-frames"]; // 1 GOP
[options setPlayerOptionIntValue:2*1024*1024 forKey:@"max-buffer-size"];
[options setFormatOptionIntValue:8192   forKey:@"rtmp_buffer_size"];
```

### For Ultra-Low Latency (< 500ms) with Lower Bitrates
```objective-c
[options setPlayerOptionIntValue:25     forKey:@"first-high-water-mark-ms"];
[options setPlayerOptionIntValue:100    forKey:@"next-high-water-mark-ms"];
[options setPlayerOptionIntValue:250    forKey:@"last-high-water-mark-ms"];
[options setPlayerOptionIntValue:15     forKey:@"min-frames"];
```

## Stream Configuration Guidelines

### Optimal Server Settings for Low Latency:
- **GOP structure**: 1-2 seconds (30-60 frames @ 30fps)
- **Keyframe interval**: Every 1 second for best seeking
- **Bitrate consistency**: Stable CBR encoding
- **Audio bitrate**: 128-192 kbps recommended

### Network Requirements for 2.2 Mbps Streams:
- **Bandwidth**: At least 3.3 Mbps available (1.5x stream bitrate)
- **Latency**: < 50ms RTT to streaming server
- **Stability**: < 0.5% packet loss
- **Buffer**: 1MB+ receive buffer for high bitrate

## Troubleshooting

### Frequent Buffering on High Bitrate Streams
- Increase `max-buffer-size` to 3-4MB
- Increase watermark values by 100-200ms
- Check network bandwidth capacity

### Audio/Video Sync Issues
- Enable `sync-av-start`: `[options setPlayerOptionIntValue:1 forKey:@"sync-av-start"];`
- Increase `video-pictq-size` to 3-4 frames

### Poor Performance on High Bitrate
- Ensure hardware acceleration: `videotoolbox` and `videotoolbox-async`
- Increase receive buffer: `recv_buffer_size` to 2MB
- Monitor CPU usage and thermal throttling

### Network Instability
- Increase `timeout` to 20-30 seconds
- Enable more aggressive reconnection
- Consider adaptive bitrate streaming

## Server-Side Optimizations

For best results with 2.2 Mbps streams:
- Use CBR (Constant Bitrate) encoding
- Set GOP to exactly 1 second (30 frames @ 30fps)
- Minimize server-side buffering
- Use TCP_NODELAY on server socket
- Configure proper RTMP chunk sizes (4096-8192 bytes) 