import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utility class for capturing Flutter widgets as watermark images
class WidgetWatermark {
  /// Captures a widget and converts it to PNG image bytes.
  ///
  /// The widget will be laid out with the given [size] constraints.
  /// If [pixelRatio] is not provided, uses the device's pixel ratio.
  ///
  /// Example:
  /// ```dart
  /// final imageBytes = await WidgetWatermark.capture(
  ///   child: Container(
  ///     padding: EdgeInsets.all(8),
  ///     decoration: BoxDecoration(
  ///       color: Colors.black54,
  ///       borderRadius: BorderRadius.circular(8),
  ///     ),
  ///     child: Text('© 2025', style: TextStyle(color: Colors.white)),
  ///   ),
  ///   size: Size(200, 50),
  /// );
  /// ```
  static Future<Uint8List> capture({
    required Widget child,
    required ui.Size size,
    double? pixelRatio,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    final devicePixelRatio =
        pixelRatio ??
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    // Create a RepaintBoundary to capture the widget
    final repaintBoundary = RenderRepaintBoundary();

    // Create a simple render tree
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: RenderConstrainedBox(
          additionalConstraints: BoxConstraints.tightFor(
            width: size.width,
            height: size.height,
          ),
          child: repaintBoundary,
        ),
      ),
      configuration: ViewConfiguration.fromView(
        ui.PlatformDispatcher.instance.views.first,
      ),
    );

    // Create pipeline and build owners
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    // Build the widget tree
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(data: const MediaQueryData(), child: child),
      ),
    ).attachToRenderTree(buildOwner);

    // Layout and paint
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Capture the image
    final image = await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
    final byteData = await image.toByteData(format: format);

    return byteData!.buffer.asUint8List();
  }

  /// Captures a widget using a GlobalKey (for widgets already in the tree).
  ///
  /// This is useful when you want to capture a widget that's already being
  /// displayed in your app.
  ///
  /// Example:
  /// ```dart
  /// final key = GlobalKey();
  ///
  /// // In your widget tree:
  /// RepaintBoundary(
  ///   key: key,
  ///   child: YourWidget(),
  /// )
  ///
  /// // Later, to capture:
  /// final bytes = await WidgetWatermark.captureFromKey(key);
  /// ```
  static Future<Uint8List> captureFromKey(
    GlobalKey key, {
    double? pixelRatio,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('Widget not found or not wrapped in RepaintBoundary');
    }

    final image = await boundary.toImage(
      pixelRatio:
          pixelRatio ??
          ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
    );
    final byteData = await image.toByteData(format: format);

    return byteData!.buffer.asUint8List();
  }

  /// Helper method to capture a transformed/scaled widget.
  ///
  /// This wraps the widget in a Transform and captures it.
  ///
  /// Example:
  /// ```dart
  /// final bytes = await WidgetWatermark.captureTransformed(
  ///   child: Text('Rotated', style: TextStyle(fontSize: 24)),
  ///   size: Size(200, 100),
  ///   transform: Matrix4.rotationZ(0.2), // Rotate 0.2 radians
  /// );
  /// ```
  static Future<Uint8List> captureTransformed({
    required Widget child,
    required ui.Size size,
    required Matrix4 transform,
    double? pixelRatio,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    return capture(
      child: Transform(transform: transform, child: child),
      size: size,
      pixelRatio: pixelRatio,
      format: format,
    );
  }

  /// Helper to create a common text watermark widget.
  ///
  /// Returns the widget that can be passed to [capture].
  ///
  /// Example:
  /// ```dart
  /// final widget = WidgetWatermark.textWatermark(
  ///   text: '© 2025 My Company',
  ///   style: TextStyle(fontSize: 20, color: Colors.white),
  ///   backgroundColor: Colors.black54,
  /// );
  /// final bytes = await WidgetWatermark.capture(
  ///   child: widget,
  ///   size: Size(300, 60),
  /// );
  /// ```
  static Widget textWatermark({
    required String text,
    TextStyle? style,
    Color? backgroundColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        boxShadow: shadows,
      ),
      child: Text(
        text,
        style:
            style ??
            const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  /// Helper to create a logo + text watermark widget.
  static Widget logoTextWatermark({
    required Widget logo,
    required String text,
    TextStyle? textStyle,
    Color? backgroundColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double spacing = 8.0,
    Axis direction = Axis.horizontal,
  }) {
    final children = [
      logo,
      SizedBox(
        width: direction == Axis.horizontal ? spacing : 0,
        height: direction == Axis.vertical ? spacing : 0,
      ),
      Text(
        text,
        style:
            textStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
      ),
    ];

    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: direction == Axis.horizontal
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  /// Helper to create a custom badge watermark.
  static Widget badgeWatermark({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 0,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );
  }
}
