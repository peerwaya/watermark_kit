import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'watermark_kit_platform_interface.dart';
import 'video_task.dart';
import 'widget_watermark.dart';

export 'video_task.dart';
export 'widget_watermark.dart';

class WatermarkKit {
  Future<String?> getPlatformVersion() {
    return WatermarkKitPlatform.instance.getPlatformVersion();
  }

  Future<Uint8List> composeImage({
    required Uint8List inputImage,
    required Uint8List watermarkImage,
    String anchor = 'bottomRight',
    double margin = 16.0,
    double widthPercent = 0.18,
    double opacity = 0.6,
    String format = 'jpeg',
    double quality = 0.9,
    double offsetX = 0.0,
    double offsetY = 0.0,
    String marginUnit = 'px',
    String offsetUnit = 'px',
  }) {
    return WatermarkKitPlatform.instance.composeImage(
      inputImage: inputImage,
      watermarkImage: watermarkImage,
      anchor: anchor,
      margin: margin,
      widthPercent: widthPercent,
      opacity: opacity,
      format: format,
      quality: quality,
      offsetX: offsetX,
      offsetY: offsetY,
      marginUnit: marginUnit,
      offsetUnit: offsetUnit,
    );
  }

  Future<Uint8List> composeTextImage({
    required Uint8List inputImage,
    required String text,
    String anchor = 'bottomRight',
    double margin = 16.0,
    String marginUnit = 'px',
    double offsetX = 0.0,
    double offsetY = 0.0,
    String offsetUnit = 'px',
    double widthPercent = 0.18,
    double opacity = 0.6,
    String format = 'jpeg',
    double quality = 0.9,
    String fontFamily = '.SFUI',
    double fontSizePt = 24.0,
    int fontWeight = 600,
    int colorArgb = 0xFFFFFFFF,
  }) {
    return WatermarkKitPlatform.instance.composeTextImage(
      inputImage: inputImage,
      text: text,
      anchor: anchor,
      margin: margin,
      marginUnit: marginUnit,
      offsetX: offsetX,
      offsetY: offsetY,
      offsetUnit: offsetUnit,
      widthPercent: widthPercent,
      opacity: opacity,
      format: format,
      quality: quality,
      fontFamily: fontFamily,
      fontSizePt: fontSizePt,
      fontWeight: fontWeight,
      colorArgb: colorArgb,
    );
  }

  Future<VideoTask> composeVideo({
    required String inputVideoPath,
    String? outputVideoPath,
    Uint8List? watermarkImage,
    String? text,
    String anchor = 'bottomRight',
    double margin = 16.0,
    String marginUnit = 'px',
    double offsetX = 0.0,
    double offsetY = 0.0,
    String offsetUnit = 'px',
    double widthPercent = 0.18,
    double opacity = 0.6,
    String codec = 'h264',
    int? bitrateBps,
    double? maxFps,
    int? maxLongSide,
    int? outputWidth,
    int? outputHeight,
    int? backgroundColorArgb,
  }) {
    return WatermarkKitPlatform.instance.composeVideo(
      inputVideoPath: inputVideoPath,
      outputVideoPath: outputVideoPath,
      watermarkImage: watermarkImage,
      text: text,
      anchor: anchor,
      margin: margin,
      marginUnit: marginUnit,
      offsetX: offsetX,
      offsetY: offsetY,
      offsetUnit: offsetUnit,
      widthPercent: widthPercent,
      opacity: opacity,
      codec: codec,
      bitrateBps: bitrateBps,
      maxFps: maxFps,
      maxLongSide: maxLongSide,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      backgroundColorArgb: backgroundColorArgb,
    );
  }

  // ========== Widget Watermark Methods ==========

  /// Composes an image with a Flutter widget as watermark.
  ///
  /// The widget is captured and converted to an image before being applied.
  ///
  /// Example:
  /// ```dart
  /// final result = await WatermarkKit().composeImageWithWidget(
  ///   inputImage: imageBytes,
  ///   watermarkWidget: Container(
  ///     padding: EdgeInsets.all(8),
  ///     color: Colors.black54,
  ///     child: Text('© 2025', style: TextStyle(color: Colors.white)),
  ///   ),
  ///   widgetSize: Size(200, 50),
  ///   anchor: 'bottomRight',
  /// );
  /// ```
  Future<Uint8List> composeImageWithWidget({
    required Uint8List inputImage,
    required Widget watermarkWidget,
    required ui.Size widgetSize,
    String anchor = 'bottomRight',
    double margin = 16.0,
    double widthPercent = 0.18,
    double opacity = 0.6,
    String format = 'jpeg',
    double quality = 0.9,
    double offsetX = 0.0,
    double offsetY = 0.0,
    String marginUnit = 'px',
    String offsetUnit = 'px',
    double? pixelRatio,
  }) async {
    // Capture the widget as image
    final watermarkBytes = await WidgetWatermark.capture(
      child: watermarkWidget,
      size: widgetSize,
      pixelRatio: pixelRatio,
    );

    // Use existing compose method
    return composeImage(
      inputImage: inputImage,
      watermarkImage: watermarkBytes,
      anchor: anchor,
      margin: margin,
      widthPercent: widthPercent,
      opacity: opacity,
      format: format,
      quality: quality,
      offsetX: offsetX,
      offsetY: offsetY,
      marginUnit: marginUnit,
      offsetUnit: offsetUnit,
    );
  }

  /// Composes a video with a Flutter widget as watermark.
  ///
  /// The widget is captured and converted to an image before being applied.
  ///
  /// Example:
  /// ```dart
  /// final task = await WatermarkKit().composeVideoWithWidget(
  ///   inputVideoPath: '/path/to/video.mp4',
  ///   watermarkWidget: Row(
  ///     children: [
  ///       Icon(Icons.verified, color: Colors.blue),
  ///       SizedBox(width: 8),
  ///       Text('Verified', style: TextStyle(color: Colors.white)),
  ///     ],
  ///   ),
  ///   widgetSize: Size(150, 40),
  ///   anchor: 'topRight',
  /// );
  /// ```
  Future<VideoTask> composeVideoWithWidget({
    required String inputVideoPath,
    required Widget watermarkWidget,
    required ui.Size widgetSize,
    String? outputVideoPath,
    String anchor = 'bottomRight',
    double margin = 16.0,
    String marginUnit = 'px',
    double offsetX = 0.0,
    double offsetY = 0.0,
    String offsetUnit = 'px',
    double widthPercent = 0.18,
    double opacity = 0.6,
    String codec = 'h264',
    int? bitrateBps,
    double? maxFps,
    int? maxLongSide,
    int? outputWidth,
    int? outputHeight,
    int? backgroundColorArgb,
    double? pixelRatio,
  }) async {
    // Capture the widget as image
    final watermarkBytes = await WidgetWatermark.capture(
      child: watermarkWidget,
      size: widgetSize,
      pixelRatio: pixelRatio,
    );

    // Use existing compose method
    return composeVideo(
      inputVideoPath: inputVideoPath,
      outputVideoPath: outputVideoPath,
      watermarkImage: watermarkBytes,
      anchor: anchor,
      margin: margin,
      marginUnit: marginUnit,
      offsetX: offsetX,
      offsetY: offsetY,
      offsetUnit: offsetUnit,
      widthPercent: widthPercent,
      opacity: opacity,
      codec: codec,
      bitrateBps: bitrateBps,
      maxFps: maxFps,
      maxLongSide: maxLongSide,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      backgroundColorArgb: backgroundColorArgb,
    );
  }

  /// Composes a video with a widget from a GlobalKey (for already-rendered widgets).
  ///
  /// Useful when you want to capture a widget that's already displayed in your UI.
  ///
  /// Example:
  /// ```dart
  /// final key = GlobalKey();
  ///
  /// // In your UI:
  /// RepaintBoundary(
  ///   key: key,
  ///   child: MyWatermarkWidget(),
  /// )
  ///
  /// // Later:
  /// final task = await WatermarkKit().composeVideoWithWidgetKey(
  ///   inputVideoPath: '/path/to/video.mp4',
  ///   watermarkKey: key,
  /// );
  /// ```
  Future<VideoTask> composeVideoWithWidgetKey({
    required String inputVideoPath,
    required GlobalKey watermarkKey,
    String? outputVideoPath,
    String anchor = 'bottomRight',
    double margin = 16.0,
    String marginUnit = 'px',
    double offsetX = 0.0,
    double offsetY = 0.0,
    String offsetUnit = 'px',
    double widthPercent = 0.18,
    double opacity = 0.6,
    String codec = 'h264',
    int? bitrateBps,
    double? maxFps,
    int? maxLongSide,
    int? outputWidth,
    int? outputHeight,
    int? backgroundColorArgb,
    double? pixelRatio,
  }) async {
    // Capture from the key
    final watermarkBytes = await WidgetWatermark.captureFromKey(
      watermarkKey,
      pixelRatio: pixelRatio,
    );

    return composeVideo(
      inputVideoPath: inputVideoPath,
      outputVideoPath: outputVideoPath,
      watermarkImage: watermarkBytes,
      anchor: anchor,
      margin: margin,
      marginUnit: marginUnit,
      offsetX: offsetX,
      offsetY: offsetY,
      offsetUnit: offsetUnit,
      widthPercent: widthPercent,
      opacity: opacity,
      codec: codec,
      bitrateBps: bitrateBps,
      maxFps: maxFps,
      maxLongSide: maxLongSide,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      backgroundColorArgb: backgroundColorArgb,
    );
  }
}
