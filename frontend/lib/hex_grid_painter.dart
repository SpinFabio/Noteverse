import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'canvas_camera.dart';
import 'hex_grid_geometry.dart';

/// Paints only the flat-top hexagons intersecting the current viewport.
class HexGridPainter extends CustomPainter {
  HexGridPainter({
    required this.camera,
    required this.geometry,
    required this.backgroundColor,
    required this.gridColor,
  }) : _backgroundPaint = Paint()..color = backgroundColor,
       _gridPaint = Paint()
         ..color = gridColor
         ..strokeWidth = 1,
       _originPaint = Paint()..color = Colors.red,
       super(repaint: camera);

  final CanvasCamera camera;
  final HexGridGeometry geometry;
  final Color backgroundColor;
  final Color gridColor;
  final Paint _backgroundPaint;
  final Paint _gridPaint;
  final Paint _originPaint;

  Float32List _lineBuffer = Float32List(0);

  static const _visibleMargin = 2;
  static const _originRadius = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final scale = camera.scale;
    final originX = size.width / 2 + camera.translation.dx;
    final originY = size.height / 2 + camera.translation.dy;
    final worldLeft = -originX / scale;
    final worldRight = (size.width - originX) / scale;
    final worldTop = originY / scale;
    final worldBottom = (originY - size.height) / scale;

    final minQ = geometry.qAtX(worldLeft).floor() - _visibleMargin;
    final maxQ = geometry.qAtX(worldRight).ceil() + _visibleMargin;
    final minR = geometry.rAt(worldRight, worldBottom).floor() - _visibleMargin;
    final maxR = geometry.rAt(worldLeft, worldTop).ceil() + _visibleMargin;

    final screenRadius = geometry.radius * camera.scale;
    final screenHalfHeight = geometry.height * camera.scale / 2;
    final candidateCount = (maxQ - minQ + 1) * (maxR - minR + 1);
    _ensureLineCapacity(candidateCount * 12);
    var lineIndex = 0;

    for (var q = minQ; q <= maxQ; q++) {
      final centerX = originX + geometry.centerXOf(q) * scale;
      if (centerX < -screenRadius || centerX > size.width + screenRadius) {
        continue;
      }

      for (var r = minR; r <= maxR; r++) {
        final centerY = originY - geometry.centerYOf(q, r) * scale;
        if (centerY < -screenHalfHeight ||
            centerY > size.height + screenHalfHeight) {
          continue;
        }

        final right = centerX + screenRadius;
        final halfRight = centerX + screenRadius / 2;
        final halfLeft = centerX - screenRadius / 2;
        final left = centerX - screenRadius;
        final lower = centerY + screenHalfHeight;

        // Three consecutive sides are sufficient: adjacent cells own the
        // opposite sides, so every shared grid edge is submitted exactly once.
        _lineBuffer[lineIndex++] = right;
        _lineBuffer[lineIndex++] = centerY;
        _lineBuffer[lineIndex++] = halfRight;
        _lineBuffer[lineIndex++] = lower;

        _lineBuffer[lineIndex++] = halfRight;
        _lineBuffer[lineIndex++] = lower;
        _lineBuffer[lineIndex++] = halfLeft;
        _lineBuffer[lineIndex++] = lower;

        _lineBuffer[lineIndex++] = halfLeft;
        _lineBuffer[lineIndex++] = lower;
        _lineBuffer[lineIndex++] = left;
        _lineBuffer[lineIndex++] = centerY;
      }
    }

    if (lineIndex > 0) {
      canvas.drawRawPoints(
        PointMode.lines,
        Float32List.sublistView(_lineBuffer, 0, lineIndex),
        _gridPaint,
      );
    }

    canvas.drawCircle(
      Offset(originX, originY),
      _originRadius * camera.scale,
      _originPaint,
    );
  }

  void _ensureLineCapacity(int requiredLength) {
    if (_lineBuffer.length >= requiredLength) {
      return;
    }

    var capacity = math.max(1024, _lineBuffer.length);
    while (capacity < requiredLength) {
      capacity *= 2;
    }
    _lineBuffer = Float32List(capacity);
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) =>
      oldDelegate.camera != camera ||
      oldDelegate.geometry.radius != geometry.radius ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.gridColor != gridColor;
}
