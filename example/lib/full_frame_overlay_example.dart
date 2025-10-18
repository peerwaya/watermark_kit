import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:watermark_kit/watermark_kit.dart';

/// Examples for full-frame overlays (canvas = video size)
class FullFrameOverlayExamples {
  final WatermarkKit _watermarkKit = WatermarkKit();

  /// Example 1: Simple full-frame overlay with multiple positioned elements
  ///
  /// This is the main pattern you'll use when canvas = video size
  Future<void> example1BasicFullFrame({
    required String videoPath,
    required int videoWidth,
    required int videoHeight,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: SizedBox(
        width: videoWidth.toDouble(),
        height: videoHeight.toDouble(),
        child: Stack(
          children: [
            // Top-left logo
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified, color: Colors.blue),
              ),
            ),

            // Top-right time
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '00:45',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Bottom-center copyright
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: const Text(
                    '© 2025 My Company',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // KEY PARAMETERS for full-frame overlay:
      widgetSize: ui.Size(videoWidth.toDouble(), videoHeight.toDouble()),
      anchor: 'topLeft', // Position at origin
      margin: 0, // No margin
      widthPercent: 1.0, // Full width (100%)
      opacity: 1.0, // Fully opaque (elements control their own opacity)
    );

    await task.result;
  }

  /// Example 2: Using Align instead of Positioned
  ///
  /// More Flutter-idiomatic approach
  Future<void> example2WithAlign({
    required String videoPath,
    required int videoWidth,
    required int videoHeight,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: SizedBox(
        width: videoWidth.toDouble(),
        height: videoHeight.toDouble(),
        child: Stack(
          children: [
            // Top-left
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildBadge('LIVE', Colors.red),
              ),
            ),

            // Top-right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildBadge('HD', Colors.blue),
              ),
            ),

            // Bottom-left
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildUserInfo(),
              ),
            ),

            // Center watermark
            Align(
              alignment: Alignment.center,
              child: Opacity(opacity: 0.3, child: _buildLargeLogo()),
            ),
          ],
        ),
      ),
      widgetSize: ui.Size(videoWidth.toDouble(), videoHeight.toDouble()),
      anchor: 'topLeft',
      margin: 0,
      widthPercent: 1.0,
    );

    await task.result;
  }

  /// Example 3: Responsive layout (works for any video size)
  ///
  /// Uses LayoutBuilder to adapt to video dimensions
  Future<void> example3Responsive({
    required String videoPath,
    required int videoWidth,
    required int videoHeight,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: SizedBox(
        width: videoWidth.toDouble(),
        height: videoHeight.toDouble(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                // Scale elements based on video size
                Positioned(
                  top: height * 0.05, // 5% from top
                  right: width * 0.05, // 5% from right
                  child: _buildScaledBadge(
                    'Premium',
                    size: width * 0.08, // 8% of video width
                  ),
                ),

                // Bottom info bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: height * 0.1, // 10% of video height
                  child: _buildInfoBar(width),
                ),
              ],
            );
          },
        ),
      ),
      widgetSize: ui.Size(videoWidth.toDouble(), videoHeight.toDouble()),
      anchor: 'topLeft',
      margin: 0,
      widthPercent: 1.0,
    );

    await task.result;
  }

  /// Example 4: Instagram/TikTok style overlay
  Future<void> example4SocialMediaStyle({
    required String videoPath,
    required int videoWidth,
    required int videoHeight,
    required String username,
    required String caption,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: SizedBox(
        width: videoWidth.toDouble(),
        height: videoHeight.toDouble(),
        child: Stack(
          children: [
            // User info (bottom-left)
            Positioned(
              left: 16,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username with verified badge
                  Row(
                    children: [
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Caption
                  Container(
                    constraints: BoxConstraints(maxWidth: videoWidth * 0.7),
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons (bottom-right)
            Positioned(
              right: 16,
              bottom: 80,
              child: Column(
                children: [
                  _buildActionButton(Icons.favorite, '245K'),
                  const SizedBox(height: 20),
                  _buildActionButton(Icons.comment, '1.2K'),
                  const SizedBox(height: 20),
                  _buildActionButton(Icons.share, '892'),
                ],
              ),
            ),

            // Top-left branding
            Positioned(
              top: 20,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MyApp',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      widgetSize: ui.Size(videoWidth.toDouble(), videoHeight.toDouble()),
      anchor: 'topLeft',
      margin: 0,
      widthPercent: 1.0,
    );

    await task.result;
  }

  /// Example 5: Picture-in-Picture style
  Future<void> example5PictureInPicture({
    required String videoPath,
    required int videoWidth,
    required int videoHeight,
    required String overlayImageUrl,
  }) async {
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: SizedBox(
        width: videoWidth.toDouble(),
        height: videoHeight.toDouble(),
        child: Stack(
          children: [
            // PiP window (top-right corner)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: videoWidth * 0.25, // 25% of video width
                height: videoHeight * 0.2, // 20% of video height
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: videoWidth * 0.1,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      widgetSize: ui.Size(videoWidth.toDouble(), videoHeight.toDouble()),
      anchor: 'topLeft',
      margin: 0,
      widthPercent: 1.0,
    );

    await task.result;
  }

  /// Example 6: Getting video dimensions first
  ///
  /// Complete workflow including video dimension detection
  Future<void> example6CompleteWorkflow(String videoPath) async {
    // Step 1: Get video dimensions
    // (You'd typically use a video info package or native code)
    // For this example, assume you have these dimensions:
    const videoWidth = 1920;
    const videoHeight = 1080;

    // Step 2: Create overlay matching video size
    final task = await _watermarkKit.composeVideoWithWidget(
      inputVideoPath: videoPath,
      watermarkWidget: _buildFullFrameOverlay(videoWidth, videoHeight),
      widgetSize: const ui.Size(videoWidth, videoHeight),
      anchor: 'topLeft',
      margin: 0,
      widthPercent: 1.0,
    );

    // Step 3: Monitor progress
    task.onProgress.listen((progress) {
      print('Overlay progress: ${(progress * 100).toInt()}%');
    });

    // Step 4: Get result
    final result = await task.result;
    print('Video with overlay: ${result.outputVideoPath}');
  }

  // Helper widgets
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScaledBadge(String text, {required double size}) {
    return Container(
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.3,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 16, child: Icon(Icons.person, size: 20)),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'John Doe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@johndoe',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeLogo() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: const Icon(Icons.copyright, size: 120, color: Colors.white),
    );
  }

  Widget _buildInfoBar(double width) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Episode 5: The Journey',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          Row(
            children: [
              Icon(Icons.hd, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Icon(Icons.closed_caption, color: Colors.white, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      ],
    );
  }

  Widget _buildFullFrameOverlay(int width, int height) {
    return SizedBox(
      width: width.toDouble(),
      height: height.toDouble(),
      child: Stack(
        children: [
          // Your overlay elements here
          Positioned(top: 20, left: 20, child: _buildBadge('LIVE', Colors.red)),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _buildBadge('© 2025', Colors.black54)),
          ),
        ],
      ),
    );
  }
}

