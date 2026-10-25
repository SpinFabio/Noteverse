import 'package:flutter/rendering.dart';

import 'hex_grid_geometry.dart';

/// Draws continuous grid lines with a screen-space width shared by all views.
abstract final class HexGridLines {
  /// Draws visible cells, submitting each shared edge exactly once.
  static void paint({
    required Canvas canvas,
    required Size viewportSize,
    required HexGridGeometry geometry,
    required Offset screenOrigin,
    required double scale,
    required Paint linePaint,
  }) {
    final worldLeft = -screenOrigin.dx / scale;
    final worldRight = (viewportSize.width - screenOrigin.dx) / scale;
    final worldTop = screenOrigin.dy / scale;
    final worldBottom = (screenOrigin.dy - viewportSize.height) / scale;
    final minQ = geometry.qAtX(worldLeft).floor() - 2;
    final maxQ = geometry.qAtX(worldRight).ceil() + 2;
    final minR = geometry.rAt(worldRight, worldBottom).floor() - 2;
    final maxR = geometry.rAt(worldLeft, worldTop).ceil() + 2;
    final radius = geometry.radius * scale;
    final halfHeight = geometry.height * scale / 2;
    final path = Path();

    for (var q = minQ; q <= maxQ; q++) {
      final centerX = screenOrigin.dx + geometry.centerXOf(q) * scale;
      if (centerX < -radius || centerX > viewportSize.width + radius) {
        continue;
      }
      for (var r = minR; r <= maxR; r++) {
        final centerY = screenOrigin.dy - geometry.centerYOf(q, r) * scale;
        if (centerY < -halfHeight ||
            centerY > viewportSize.height + halfHeight) {
          continue;
        }
        // The other three sides belong to neighboring cells. Avoid drawing
        // shared edges twice, which would darken translucent grid lines.
        path
          ..moveTo(centerX + radius, centerY)
          ..lineTo(centerX + radius / 2, centerY + halfHeight)
          ..lineTo(centerX - radius / 2, centerY + halfHeight)
          ..lineTo(centerX - radius, centerY);
      }
    }
    canvas.drawPath(path, linePaint);
  }
}
