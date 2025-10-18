import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:watermark_kit/watermark_kit.dart';

/// Examples of using Flutter widgets as watermarks
class WidgetWatermarkExamples {
  final WatermarkKit _watermarkKit = WatermarkKit();

  /// Example 1: Simple text watermark with background
  Future<void> example1SimpleText({required String videoPath}) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '© 2025 My Company',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      widgetSize: const Size(250, 40),
      anchor: 'bottomRight',
      margin: 20,
    );

    // Listen to progress
    task.onProgress.listen((progress) {
      print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
    });

    final result = await task.result;
    print('Video saved: ${result.outputVideoPath}');
  }

  /// Example 2: Logo + Text watermark
  Future<void> example2LogoWithText({
    required String videoPath,
    required Widget logo,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.purple.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            const SizedBox(width: 8),
            const Text(
              'Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      widgetSize: const Size(180, 60),
      anchor: 'topRight',
      margin: 16,
    );

    await task.result;
  }

  /// Example 3: Custom badge with icon
  Future<void> example3CustomBadge({required String videoPath}) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.verified, color: Colors.white, size: 32),
      ),
      widgetSize: const Size(52, 52),
      anchor: 'topLeft',
      margin: 20,
      widthPercent: 0.1, // Smaller watermark
    );

    await task.result;
  }

  /// Example 4: Animated-style watermark (capture current state)
  Future<void> example4AnimatedStyle({required String videoPath}) async {
    // Create a widget with transform/rotation
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: Transform.rotate(
        angle: -0.1, // Slight rotation
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Text(
            'LIMITED EDITION',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      widgetSize: const Size(200, 50),
      anchor: 'topRight',
      margin: 30,
      offsetX: -10,
      offsetY: 10,
    );

    await task.result;
  }

  /// Example 5: Complex multi-element watermark
  Future<void> example5ComplexWatermark({required String videoPath}) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.copyright, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '2025',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'MyCompany LLC',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      widgetSize: const Size(200, 80),
      anchor: 'bottomRight',
      margin: 20,
    );

    await task.result;
  }

  /// Example 6: Using a GlobalKey to capture live widget
  Future<void> example6LiveWidget({
    required String videoPath,
    required GlobalKey watermarkKey,
  }) async {
    // In your UI, you have:
    // RepaintBoundary(
    //   key: watermarkKey,
    //   child: MyLiveWatermarkWidget(),
    // )

    final task = await _watermarkKit.composeVideoWithWidgetKey(
      inputVideoPath: videoPath,
      watermarkKey: watermarkKey,
      anchor: 'bottomLeft',
      margin: 20,
    );

    await task.result;
  }

  /// Example 7: Using helper methods
  Future<void> example7Helpers({required String videoPath}) async {
    // Use built-in text watermark helper
    final widget = WidgetWatermark.textWatermark(
      text: '© 2025 All Rights Reserved',
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(12),
    );

    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: widget,
      widgetSize: const Size(300, 50),
      anchor: 'bottomRight',
    );

    await task.result;
  }

  /// Example 8: Badge watermark helper
  Future<void> example8BadgeHelper({required String videoPath}) async {
    final widget = WidgetWatermark.badgeWatermark(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.star, color: Colors.amber, size: 24),
          SizedBox(width: 8),
          Text(
            'Featured',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      gradient: LinearGradient(colors: [Colors.deepPurple, Colors.purple]),
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );

    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: widget,
      widgetSize: const Size(160, 50),
      anchor: 'topLeft',
      margin: 20,
    );

    await task.result;
  }

  /// Example 9: Image watermarking with widget
  Future<void> example9ImageWatermark({required Uint8List imageBytes}) async {
    final result = await _watermarkKit.composeImageWithWidget(
      inputImage: imageBytes,
      watermarkWidget: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'SAMPLE',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      widgetSize: const Size(150, 60),
      anchor: 'center',
      opacity: 0.7,
    );

    // Use the watermarked image bytes
    print('Watermarked image: ${result.length} bytes');
  }

  /// Example 10: Multiple watermarks (apply sequentially)
  Future<void> example10MultipleWatermarks({required String videoPath}) async {
    // First watermark - logo in top-left
    final tempPath = '${videoPath}_temp.mp4';

    final task1 = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      outputVideoPath: tempPath,
      watermarkWidget: WidgetWatermark.badgeWatermark(
        child: const Icon(Icons.wb_sunny, color: Colors.amber, size: 32),
        backgroundColor: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      widgetSize: const Size(48, 48),
      anchor: 'topLeft',
      margin: 20,
    );

    await task1.result;

    // Second watermark - text in bottom-right
    final task2 = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: tempPath,
      watermarkWidget: WidgetWatermark.textWatermark(
        text: '© 2025 My Brand',
        backgroundColor: Colors.black54,
      ),
      widgetSize: const Size(200, 40),
      anchor: 'bottomRight',
      margin: 20,
    );

    await task2.result;

    // Clean up temp file if needed
  }
}

/// Example widget that can be used as a live watermark
class LiveWatermarkWidget extends StatelessWidget {
  const LiveWatermarkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.8), Colors.cyan.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Verified Creator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@username',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
