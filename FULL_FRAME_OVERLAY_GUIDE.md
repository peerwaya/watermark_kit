# Full-Frame Overlay Guide

## When Canvas = Video Size

When you want the canvas to match the video dimensions (full-frame overlay), you're creating a transparent layer that covers the entire video where you can position multiple elements.

## The Function & Parameters

```dart
final task = await WatermarkKit().composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: yourWidget,
  widgetSize: ui.Size(videoWidth, videoHeight),  // ← Match video size
  anchor: 'topLeft',      // ← Position at origin
  margin: 0,              // ← No offset
  widthPercent: 1.0,      // ← Full width (100%)
  opacity: 1.0,           // ← Let elements control opacity
);
```

### Key Parameters Explained

| Parameter | Value for Full-Frame | Why |
|-----------|---------------------|-----|
| `widgetSize` | `Size(videoWidth, videoHeight)` | Canvas = video dimensions |
| `anchor` | `'topLeft'` | Align to top-left corner (0,0) |
| `margin` | `0` | No margin/offset |
| `widthPercent` | `1.0` | Scale to 100% of video width |
| `opacity` | `1.0` | Individual elements control opacity |

## Basic Pattern

```dart
// 1. Get video dimensions (1920×1080 example)
const videoWidth = 1920;
const videoHeight = 1080;

// 2. Create full-frame widget
final overlayWidget = SizedBox(
  width: videoWidth.toDouble(),
  height: videoHeight.toDouble(),
  child: Stack(
    children: [
      // Position elements anywhere
      Positioned(top: 20, left: 20, child: TopLeftElement()),
      Positioned(bottom: 20, right: 20, child: BottomRightElement()),
      Align(alignment: Alignment.center, child: CenterElement()),
    ],
  ),
);

// 3. Apply to video
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: overlayWidget,
  widgetSize: ui.Size(videoWidth, videoHeight),
  anchor: 'topLeft',
  margin: 0,
  widthPercent: 1.0,
);
```

## Positioning Elements

### Using Positioned

```dart
Stack(
  children: [
    Positioned(
      top: 20,        // 20px from top
      left: 20,       // 20px from left
      child: MyWidget(),
    ),
    Positioned(
      bottom: 40,     // 40px from bottom
      right: 30,      // 30px from right
      child: MyWidget(),
    ),
  ],
)
```

### Using Align

```dart
Stack(
  children: [
    Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: MyWidget(),
      ),
    ),
    Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: MyWidget(),
      ),
    ),
  ],
)
```

### Responsive Positioning

```dart
Stack(
  children: [
    Positioned(
      top: videoHeight * 0.05,     // 5% from top
      right: videoWidth * 0.05,    // 5% from right
      child: MyWidget(
        size: videoWidth * 0.1,    // 10% of video width
      ),
    ),
  ],
)
```

## Common Use Cases

### 1. Multiple Watermarks

```dart
SizedBox(
  width: videoWidth.toDouble(),
  height: videoHeight.toDouble(),
  child: Stack(
    children: [
      // Logo top-left
      Positioned(top: 20, left: 20, child: Logo()),
      // Time top-right
      Positioned(top: 20, right: 20, child: TimeDisplay()),
      // Copyright bottom-center
      Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: Center(child: Copyright()),
      ),
    ],
  ),
)
```

### 2. Social Media Style Overlay

```dart
SizedBox(
  width: videoWidth.toDouble(),
  height: videoHeight.toDouble(),
  child: Stack(
    children: [
      // User info (bottom-left)
      Positioned(
        left: 16,
        bottom: 80,
        child: UserInfo(),
      ),
      // Action buttons (bottom-right)
      Positioned(
        right: 16,
        bottom: 80,
        child: ActionButtons(),
      ),
      // Branding (top-left)
      Positioned(
        top: 20,
        left: 16,
        child: AppBranding(),
      ),
    ],
  ),
)
```

### 3. Lower Third Banner

```dart
SizedBox(
  width: videoWidth.toDouble(),
  height: videoHeight.toDouble(),
  child: Stack(
    children: [
      // Bottom banner
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: videoHeight * 0.15,  // 15% of video height
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Row(
            children: [
              // Your content
            ],
          ),
        ),
      ),
    ],
  ),
)
```

### 4. Picture-in-Picture

```dart
SizedBox(
  width: videoWidth.toDouble(),
  height: videoHeight.toDouble(),
  child: Stack(
    children: [
      Positioned(
        top: 20,
        right: 20,
        width: videoWidth * 0.25,   // 25% of video width
        height: videoHeight * 0.2,  // 20% of video height
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: YourPiPContent(),
        ),
      ),
    ],
  ),
)
```

## Getting Video Dimensions

You'll need to get the video dimensions first. Here are common approaches:

### Option 1: Use video_player package

```dart
import 'package:video_player/video_player.dart';

Future<void> processVideo(String videoPath) async {
  final controller = VideoPlayerController.file(File(videoPath));
  await controller.initialize();
  
  final videoWidth = controller.value.size.width.toInt();
  final videoHeight = controller.value.size.height.toInt();
  
  // Now use these dimensions
  final task = await watermarkKit.composeVideoWithWidget(
    inputVideoPath: videoPath,
    watermarkWidget: createOverlay(videoWidth, videoHeight),
    widgetSize: ui.Size(videoWidth, videoHeight),
    anchor: 'topLeft',
    margin: 0,
    widthPercent: 1.0,
  );
  
  controller.dispose();
}
```

### Option 2: Use ffmpeg or native code

```dart
// Platform channel to get video info from native side
final videoInfo = await platform.invokeMethod('getVideoInfo', videoPath);
final videoWidth = videoInfo['width'];
final videoHeight = videoInfo['height'];
```

### Option 3: Standard resolutions

```dart
// If you know the video format
const standardSizes = {
  '4K': ui.Size(3840, 2160),
  '1080p': ui.Size(1920, 1080),
  '720p': ui.Size(1280, 720),
  'vertical': ui.Size(1080, 1920),  // Instagram/TikTok
};
```

## Complete Example

```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:watermark_kit/watermark_kit.dart';

class VideoOverlayService {
  final WatermarkKit _watermarkKit = WatermarkKit();

  Future<void> addFullFrameOverlay({
    required String videoPath,
    required int videoWidth,
    required int videoHeight,
    required String username,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: _buildOverlay(
        videoWidth,
        videoHeight,
        username,
      ),
      widgetSize: ui.Size(
        videoWidth.toDouble(),
        videoHeight.toDouble(),
      ),
      anchor: 'topLeft',
      margin: 0,
      widthPercent: 1.0,
      opacity: 1.0,
    );

    // Monitor progress
    task.onProgress.listen((progress) {
      print('Progress: ${(progress * 100).toInt()}%');
    });

    // Wait for completion
    final result = await task.result;
    print('Done: ${result.outputVideoPath}');
  }

  Widget _buildOverlay(int width, int height, String username) {
    return SizedBox(
      width: width.toDouble(),
      height: height.toDouble(),
      child: Stack(
        children: [
          // Top-left: Logo
          Positioned(
            top: 20,
            left: 20,
            child: _buildLogo(),
          ),
          
          // Top-right: Live indicator
          Positioned(
            top: 20,
            right: 20,
            child: _buildLiveBadge(),
          ),
          
          // Bottom-left: User info
          Positioned(
            bottom: 80,
            left: 20,
            child: _buildUserInfo(username),
          ),
          
          // Bottom-center: Copyright
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _buildCopyright()),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.play_circle, color: Colors.blue, size: 32),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String username) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 20,
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 8),
          Text(
            '@$username',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyright() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '© 2025 All Rights Reserved',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
```

## Key Takeaways

1. **Match video dimensions**: `widgetSize = Size(videoWidth, videoHeight)`
2. **Position at origin**: `anchor: 'topLeft', margin: 0`
3. **Full width**: `widthPercent: 1.0`
4. **Use Stack + Positioned**: For absolute positioning
5. **Use Align**: For relative positioning
6. **Responsive sizing**: Use percentages of video dimensions

See `example/lib/full_frame_overlay_example.dart` for complete working examples!


