# Size and Transform Guide

## Understanding `size` Parameter

The `size` parameter defines the **canvas dimensions** - the rectangular area your widget is rendered into.

```dart
WidgetWatermark.capture(
  child: myWidget,
  size: Size(200, 100),  // Canvas: 200×100 pixels
)
```

## Visual Explanation

### Case 1: Widget Without Transform

```
size: Size(200, 100)

┌─────────────────────────────────┐
│ Canvas: 200×100                 │
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │  Widget fills canvas    │   │
│  │  (Container 200×100)    │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘

Result: Widget perfectly fits canvas
```

### Case 2: Rotated Widget (Correct Size)

```
Original widget: 150×40
Rotation: 30°
size: Size(180, 120)  ✓ Large enough

┌───────────────────────────────────┐
│ Canvas: 180×120                   │
│                                   │
│        ╱─────────────╲            │
│       ╱               ╲           │
│      ╱  Rotated 30°   ╲          │
│     ╱   (150×40)       ╲         │
│    ╱─────────────────── ╲        │
│                                   │
│   Widget fits comfortably         │
└───────────────────────────────────┘

Result: ✓ Widget fully visible
```

### Case 3: Rotated Widget (Size Too Small)

```
Original widget: 150×40
Rotation: 30°
size: Size(150, 40)  ✗ Too small!

┌──────────────────────┐
│ Canvas: 150×40       │
│                      │
 ─────────────╲        │  ← Clipped!
               ╲       │
  Rotated 30°  ╲      │
   (150×40)     ╲─────   ← Clipped!
                      │
└──────────────────────┘

Result: ✗ Widget is clipped at edges
```

### Case 4: Scaled Widget

```
Original widget: 50×50
Scale: 2.0×
size: Size(150, 150)  ✓ Room for scaling

┌─────────────────────────────────┐
│ Canvas: 150×150                 │
│                                 │
│       ┌───────────────┐         │
│       │               │         │
│       │  Scaled 2×    │         │
│       │  (appears     │         │
│       │   100×100)    │         │
│       │               │         │
│       └───────────────┘         │
│                                 │
└─────────────────────────────────┘

Result: ✓ Scaled widget fits with margin
```

### Case 5: Combined (Rotate + Scale)

```
Original: 60×60
Scale: 1.5× → 90×90
Rotation: 45°
size: Size(160, 160)  ✓ Accounts for both

┌─────────────────────────────────┐
│ Canvas: 160×160                 │
│                                 │
│         ◇───────────◇           │
│        ╱             ╲          │
│       ╱  Rotated 45° ╲         │
│      ╱   Scaled 1.5×  ╲        │
│     ╱    (90×90)       ╲       │
│    ◇───────────────────◇       │
│                                 │
└─────────────────────────────────┘

Result: ✓ Fully visible with transforms
```

## How It Works Under the Hood

```dart
// When you call capture:
WidgetWatermark.capture(
  child: Transform.rotate(
    angle: 0.5,
    child: Container(width: 100, height: 40),
  ),
  size: Size(200, 100),
)

// Internally:
1. Creates a RenderRepaintBoundary
2. Creates RenderConstrainedBox with BoxConstraints.tightFor(
     width: 200,  // From size parameter
     height: 100,
   )
3. Widget is laid out within 200×100 canvas
4. Transform.rotate applies rotation INSIDE the canvas
5. RenderRepaintBoundary captures the 200×100 canvas
6. Returns PNG of exactly 200×100 pixels (× pixelRatio)
```

## Calculating Required Size

### For Rotated Widgets

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

ui.Size calculateRotatedSize(
  double width,
  double height,
  double angleRadians,
) {
  final cos = math.cos(angleRadians).abs();
  final sin = math.sin(angleRadians).abs();
  
  // Bounding box after rotation
  final rotatedWidth = width * cos + height * sin;
  final rotatedHeight = width * sin + height * cos;
  
  // Add 20% margin for safety
  return ui.Size(rotatedWidth * 1.2, rotatedHeight * 1.2);
}

// Example:
final canvasSize = calculateRotatedSize(150, 40, 0.5);
// Result: ~195×127 (accommodates 150×40 rotated 0.5 rad)
```

### For Scaled Widgets

```dart
ui.Size calculateScaledSize(
  double width,
  double height,
  double scale,
) {
  // Add 20% margin
  return ui.Size(
    width * scale * 1.2,
    height * scale * 1.2,
  );
}

// Example:
final canvasSize = calculateScaledSize(50, 50, 2.0);
// Result: 120×120 (accommodates 50×50 scaled 2×)
```

### For Combined Transforms

```dart
ui.Size calculateTransformedSize(
  double width,
  double height,
  double scale,
  double angleRadians,
) {
  // Apply scale first
  final scaledWidth = width * scale;
  final scaledHeight = height * scale;
  
  // Then calculate rotation
  return calculateRotatedSize(
    scaledWidth,
    scaledHeight,
    angleRadians,
  );
}
```

## Practical Examples

### Example 1: Simple Watermark (No Transform)

```dart
final bytes = await WidgetWatermark.capture(
  child: Container(
    padding: EdgeInsets.all(8),
    color: Colors.black54,
    child: Text('© 2025'),
  ),
  size: Size(150, 40),  // Widget size ≈ canvas size
);
```

### Example 2: Tilted Badge

```dart
final bytes = await WidgetWatermark.capture(
  child: Transform.rotate(
    angle: -0.15,  // Slight tilt
    child: Container(
      padding: EdgeInsets.all(10),
      color: Colors.red,
      child: Text('NEW'),
    ),
  ),
  size: Size(100, 60),  // Extra room for tilt
);
```

### Example 3: Large Badge (Scaled)

```dart
final bytes = await WidgetWatermark.capture(
  child: Transform.scale(
    scale: 2.0,
    child: Icon(Icons.verified, size: 30),
  ),
  size: Size(100, 100),  // 30 × 2.0 = 60, canvas = 100
);
```

### Example 4: Complex Watermark

```dart
// Calculate size for 120×50 rotated 25°
final canvasSize = calculateRotatedSize(120, 50, 0.436);

final bytes = await WidgetWatermark.capture(
  child: Transform.rotate(
    angle: 0.436,  // 25 degrees
    child: Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.star),
          Text('Premium'),
        ],
      ),
    ),
  ),
  size: canvasSize,  // Auto-calculated size
);
```

## Common Mistakes

### ❌ Mistake 1: Size Too Small for Rotation

```dart
// Widget is 150×40, rotated 45°
// Diagonal = sqrt(150² + 40²) ≈ 155
WidgetWatermark.capture(
  child: Transform.rotate(
    angle: math.pi / 4,
    child: Container(width: 150, height: 40),
  ),
  size: Size(150, 40),  // ❌ Too small! Will be clipped
)
```

**Fix:** Use larger canvas
```dart
size: Size(180, 120),  // ✓ Fits rotated widget
```

### ❌ Mistake 2: Forgetting Scale Factor

```dart
// Widget scaled 3×
WidgetWatermark.capture(
  child: Transform.scale(
    scale: 3.0,
    child: Container(width: 50, height: 50),
  ),
  size: Size(50, 50),  // ❌ Too small! 50×3=150 needed
)
```

**Fix:**
```dart
size: Size(180, 180),  // ✓ 50×3×1.2 = 180
```

### ❌ Mistake 3: Not Accounting for Padding/Shadows

```dart
WidgetWatermark.capture(
  child: Container(
    padding: EdgeInsets.all(20),  // Adds 40px to each dimension
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(blurRadius: 10),  // Adds ~10px around
      ],
    ),
    child: Text('Watermark'),
  ),
  size: Size(100, 30),  // ❌ Doesn't account for padding/shadow
)
```

**Fix:**
```dart
size: Size(160, 90),  // ✓ Accounts for padding + shadow
```

## Best Practices

1. **Start Generous**: Better too large than too small
   ```dart
   size: Size(200, 100),  // Generous canvas
   ```

2. **Calculate When Rotating**: Use math for precision
   ```dart
   final size = calculateRotatedSize(width, height, angle);
   ```

3. **Add Margin**: 20-30% extra space prevents clipping
   ```dart
   size: Size(width * 1.3, height * 1.3),
   ```

4. **Test Edge Cases**: Try 45°, 90°, 180° rotations

5. **Consider Shadows/Borders**: Add extra space for decorations

## Performance Notes

- **Larger canvas = More pixels to render**: But usually negligible (< 50ms)
- **pixelRatio multiplier**: `size × pixelRatio = actual pixel dimensions`
- **Memory usage**: A 500×500 canvas at 3× pixelRatio = 7.5MP image

## Summary

| Aspect | What to Know |
|--------|-------------|
| **size** | Output canvas dimensions (width × height) |
| **Transforms** | Applied INSIDE the canvas |
| **Rotation** | Needs diagonal room: `sqrt(w² + h²)` |
| **Scale** | Needs `original × scale` room |
| **Clipping** | Happens if widget exceeds canvas bounds |
| **Best Practice** | Add 20-30% margin for transforms |

See `example/lib/transform_size_example.dart` for complete working examples!


