# Widget Watermark Feature Guide

## Overview

The Widget Watermark feature allows you to use **any Flutter widget** as a watermark on videos and images. This means you can create rich, customizable watermarks with:

- ✅ Custom layouts (Container, Row, Column, Stack, etc.)
- ✅ Transforms and rotations
- ✅ Gradients and shadows
- ✅ Icons and images
- ✅ Complex compositions
- ✅ Live widget capture from your UI

## How It Works

```
Flutter Widget → Capture as Image → Apply as Watermark
```

1. **Create Widget**: Build your watermark using Flutter widgets
2. **Capture**: Widget is rendered off-screen and captured as PNG
3. **Apply**: The captured image is used as a watermark via the existing native pipeline

## Basic Usage

### Simple Text Watermark

```dart
import 'package:watermark_kit/watermark_kit.dart';

final watermarkKit = WatermarkKit();

// Apply widget watermark to video
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: '/path/to/video.mp4',
  watermarkWidget: Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '© 2025 My Company',
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  ),
  widgetSize: Size(200, 40),
  anchor: 'bottomRight',
  margin: 20.0,
);

// Monitor progress
task.onProgress.listen((progress) {
  print('Progress: ${(progress * 100).toInt()}%');
});

final result = await task.result;
print('Done: ${result.outputVideoPath}');
```

### Logo + Text Watermark

```dart
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue, Colors.purple],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified, color: Colors.white),
        SizedBox(width: 8),
        Text('Verified', style: TextStyle(color: Colors.white)),
      ],
    ),
  ),
  widgetSize: Size(150, 50),
  anchor: 'topRight',
);
```

## Advanced Features

### 1. Transformed Widgets

Apply rotation, scale, or other transforms:

```dart
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: Transform.rotate(
    angle: -0.2, // Rotate 0.2 radians
    child: Container(
      padding: EdgeInsets.all(10),
      color: Colors.red,
      child: Text('DRAFT', style: TextStyle(fontSize: 24)),
    ),
  ),
  widgetSize: Size(150, 60),
  anchor: 'center',
);
```

### 2. Complex Compositions

Build sophisticated watermarks:

```dart
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.deepPurple, Colors.purple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: 32),
        SizedBox(height: 8),
        Text(
          'Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Member',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
  widgetSize: Size(120, 140),
  anchor: 'topLeft',
  margin: 20,
);
```

### 3. Live Widget Capture

Capture a widget that's already rendered in your UI:

```dart
class MyScreen extends StatelessWidget {
  final watermarkKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your video player
        VideoPlayer(...),
        
        // Live watermark widget
        Positioned(
          bottom: 20,
          right: 20,
          child: RepaintBoundary(
            key: watermarkKey,
            child: MyCustomWatermarkWidget(),
          ),
        ),
      ],
    );
  }

  Future<void> exportVideo(String videoPath) async {
    final task = await watermarkKit.composeVideoWithWidgetKey(
      inputVideoPath: videoPath,
      watermarkKey: watermarkKey,
      anchor: 'bottomRight',
      margin: 20,
    );
    
    await task.result;
  }
}
```

## Helper Methods

The library provides convenient helpers for common watermark styles:

### Text Watermark Helper

```dart
final widget = WidgetWatermark.textWatermark(
  text: '© 2025 All Rights Reserved',
  style: TextStyle(fontSize: 16, color: Colors.white),
  backgroundColor: Colors.black54,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  borderRadius: BorderRadius.circular(12),
);

final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: widget,
  widgetSize: Size(300, 50),
);
```

### Badge Watermark Helper

```dart
final widget = WidgetWatermark.badgeWatermark(
  child: Row(
    children: [
      Icon(Icons.verified, color: Colors.blue),
      SizedBox(width: 8),
      Text('Verified', style: TextStyle(color: Colors.white)),
    ],
  ),
  gradient: LinearGradient(colors: [Colors.blue, Colors.cyan]),
  borderRadius: BorderRadius.circular(20),
);
```

### Logo + Text Helper

```dart
final widget = WidgetWatermark.logoTextWatermark(
  logo: Image.asset('assets/logo.png', width: 32, height: 32),
  text: 'My Brand',
  textStyle: TextStyle(fontSize: 18, color: Colors.white),
  backgroundColor: Colors.black54,
  spacing: 12,
  direction: Axis.horizontal,
);
```

## Image Watermarking

Works with images too:

```dart
final result = await watermarkKit.composeImageWithWidget(
  inputImage: imageBytes,
  watermarkWidget: Container(
    padding: EdgeInsets.all(10),
    color: Colors.red,
    child: Text('SAMPLE', style: TextStyle(fontSize: 24)),
  ),
  widgetSize: Size(150, 50),
  anchor: 'center',
  opacity: 0.7,
);

// Use result (Uint8List)
```

## Advanced Options

### Pixel Ratio Control

For high-quality watermarks, adjust the pixel ratio:

```dart
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: myWidget,
  widgetSize: Size(200, 50),
  pixelRatio: 3.0, // Higher quality (default uses device pixel ratio)
);
```

### Positioning

Use all standard positioning options:

```dart
final task = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  watermarkWidget: myWidget,
  widgetSize: Size(200, 50),
  anchor: 'topLeft',      // topLeft, topRight, bottomLeft, bottomRight, center
  margin: 20,             // Distance from edge
  marginUnit: 'px',       // 'px' or 'percent'
  offsetX: 10,            // Additional X offset
  offsetY: -5,            // Additional Y offset
  offsetUnit: 'px',       // 'px' or 'percent'
  opacity: 0.8,           // Watermark opacity (0.0 - 1.0)
  widthPercent: 0.2,      // Scale relative to video width
);
```

## Multiple Watermarks

Apply multiple watermarks by processing sequentially:

```dart
// First watermark
final temp = '${videoPath}_temp.mp4';
final task1 = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: videoPath,
  outputVideoPath: temp,
  watermarkWidget: logoWidget,
  widgetSize: Size(100, 100),
  anchor: 'topLeft',
);
await task1.result;

// Second watermark
final task2 = await watermarkKit.composeVideoWithWidget(
  inputVideoPath: temp,
  watermarkWidget: textWidget,
  widgetSize: Size(250, 50),
  anchor: 'bottomRight',
);
await task2.result;
```

## Best Practices

### 1. Widget Size

Choose appropriate sizes for your watermark:

```dart
// Small badge
widgetSize: Size(50, 50)

// Text watermark
widgetSize: Size(200, 40)

// Complex watermark
widgetSize: Size(300, 100)
```

### 2. Use RepaintBoundary

For better performance when capturing:

```dart
RepaintBoundary(
  child: YourWatermarkWidget(),
)
```

### 3. Transparency

Use semi-transparent backgrounds for better blending:

```dart
decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.6), // 60% opacity
)
```

### 4. Shadows for Contrast

Add shadows to ensure readability:

```dart
decoration: BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
)
```

## Performance Considerations

- **Widget Complexity**: Simple widgets capture faster than complex ones
- **Size**: Larger widget sizes take more time to capture
- **Pixel Ratio**: Higher pixel ratios produce better quality but take longer
- **Caching**: Consider capturing your watermark once and reusing the bytes

Example caching:

```dart
class WatermarkCache {
  Uint8List? _cachedWatermark;

  Future<Uint8List> getWatermark() async {
    _cachedWatermark ??= await WidgetWatermark.capture(
      child: myWatermarkWidget,
      size: Size(200, 50),
    );
    return _cachedWatermark!;
  }
}
```

## Troubleshooting

### Widget not rendering correctly?

- Ensure widget has fixed size or uses `MainAxisSize.min`
- Wrap in `Directionality` if text direction matters
- Check for null media queries (handled automatically by the library)

### Poor quality watermark?

- Increase `pixelRatio` parameter
- Use larger `widgetSize`
- Ensure source images/icons are high resolution

### Widget not found error (GlobalKey)?

- Ensure widget is wrapped in `RepaintBoundary`
- Wait for widget to be rendered before capturing
- Check that key is attached to the correct widget

## Examples

See `example/lib/widget_watermark_examples.dart` for 10+ complete examples including:

1. Simple text watermarks
2. Logo + text combinations
3. Custom badges
4. Rotated/transformed widgets
5. Complex multi-element watermarks
6. Live widget capture
7. Multiple watermarks
8. And more!

## API Reference

### `WidgetWatermark.capture`
Captures a widget and converts it to image bytes.

### `WidgetWatermark.captureFromKey`
Captures a widget using its GlobalKey (for already-rendered widgets).

### `WatermarkKit.composeVideoWithWidget`
Applies a Flutter widget as watermark to a video.

### `WatermarkKit.composeImageWithWidget`
Applies a Flutter widget as watermark to an image.

### `WatermarkKit.composeVideoWithWidgetKey`
Applies a captured widget (via GlobalKey) as watermark to a video.

