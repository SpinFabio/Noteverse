import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'canvas_camera.dart';
import 'graph/models/graph_data.dart';
import 'graph/models/graph_node.dart';
import 'hex_grid_geometry.dart';
import 'hex_grid_lines.dart';
import 'theme/noteverse_typography.dart';

/// Paints only the flat-top hexagons intersecting the current viewport.
class HexGridPainter extends CustomPainter {
  HexGridPainter({
    required this.camera,
    required this.geometry,
    required this.graph,
    required this.backgroundColor,
    required this.gridColor,
    required this.gridLineWidth,
    required this.originColor,
    required this.nodeSurfaceColor,
    required this.nodeOutlineColor,
    required this.nodeLabelColor,
    required this.edgeColor,
  }) : _backgroundPaint = Paint()..color = backgroundColor,
       _gridPaint = Paint()
         ..color = gridColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = gridLineWidth,
       _originPaint = Paint()..color = originColor,
       _nodeSurfacePaint = Paint()..color = nodeSurfaceColor,
       _nodeOutlinePaint = Paint()
         ..color = nodeOutlineColor
         ..style = PaintingStyle.stroke,
       _edgePaint = Paint()
         ..color = edgeColor
         ..strokeCap = StrokeCap.round,
       _arrowPaint = Paint()..color = edgeColor,
       super(repaint: camera);

  final CanvasCamera camera;
  final HexGridGeometry geometry;
  final GraphData graph;
  final Color backgroundColor;
  final Color gridColor;
  final double gridLineWidth;
  final Color originColor;
  final Color nodeSurfaceColor;
  final Color nodeOutlineColor;
  final Color nodeLabelColor;
  final Color edgeColor;
  final Paint _backgroundPaint;
  final Paint _gridPaint;
  final Paint _originPaint;
  final Paint _nodeSurfacePaint;
  final Paint _nodeOutlinePaint;
  final Paint _edgePaint;
  final Paint _arrowPaint;

  static const _originRadius = 3.0;
  static const _nodeRadius = 11.0;
  static const _nodeOutlineWidth = 1.25;
  static const _edgeWidth = 1.25;
  static const _arrowLength = 7.0;
  static const _arrowHalfWidth = 3.5;
  static const _minimumLabelScale = 0.65;
  static const _labelFontSize = 10.0;
  static const _labelGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final scale = camera.scale;
    final originX = size.width / 2 + camera.translation.dx;
    final originY = size.height / 2 + camera.translation.dy;
    HexGridLines.paint(
      canvas: canvas,
      viewportSize: size,
      geometry: geometry,
      screenOrigin: Offset(originX, originY),
      scale: scale,
      linePaint: _gridPaint,
    );

    _paintGraph(canvas, size, originX, originY, scale);

    canvas.drawCircle(
      Offset(originX, originY),
      _originRadius * camera.scale,
      _originPaint,
    );
  }

  void _paintGraph(
    Canvas canvas,
    Size size,
    double originX,
    double originY,
    double scale,
  ) {
    final nodeRadius = _nodeRadius * scale;
    final nodeCenters = <String, Offset>{
      for (final node in graph.nodes)
        node.id: _screenCenter(node, originX, originY, scale),
    };

    _edgePaint.strokeWidth = (_edgeWidth * scale).clamp(0.5, 2.5);
    for (final edge in graph.edges) {
      final source = nodeCenters[edge.sourceNodeId]!;
      final target = nodeCenters[edge.targetNodeId]!;
      if (!_segmentIntersectsViewport(source, target, size, nodeRadius)) {
        continue;
      }
      _paintDirectedEdge(canvas, source, target, nodeRadius, scale);
    }

    _nodeOutlinePaint.strokeWidth = (_nodeOutlineWidth * scale).clamp(0.75, 3);
    for (final node in graph.nodes) {
      final center = nodeCenters[node.id]!;
      if (!_circleIntersectsViewport(center, nodeRadius, size)) {
        continue;
      }
      canvas.drawCircle(center, nodeRadius, _nodeSurfacePaint);
      canvas.drawCircle(center, nodeRadius, _nodeOutlinePaint);
      if (scale >= _minimumLabelScale) {
        _paintNodeLabel(canvas, node, center, nodeRadius, scale);
      }
    }
  }

  Offset _screenCenter(
    GraphNode node,
    double originX,
    double originY,
    double scale,
  ) {
    final worldCenter = geometry.centerOf(node.cell);
    return Offset(
      originX + worldCenter.dx * scale,
      originY - worldCenter.dy * scale,
    );
  }

  void _paintDirectedEdge(
    Canvas canvas,
    Offset source,
    Offset target,
    double nodeRadius,
    double scale,
  ) {
    final delta = target - source;
    final distance = delta.distance;
    if (distance <= nodeRadius * 2) {
      return;
    }

    final direction = delta / distance;
    final start = source + direction * nodeRadius;
    final tip = target - direction * nodeRadius;
    final arrowLength = _arrowLength * scale;
    final arrowHalfWidth = _arrowHalfWidth * scale;
    final arrowBase = tip - direction * arrowLength;
    final perpendicular = Offset(-direction.dy, direction.dx);

    canvas.drawLine(start, arrowBase, _edgePaint);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          arrowBase.dx + perpendicular.dx * arrowHalfWidth,
          arrowBase.dy + perpendicular.dy * arrowHalfWidth,
        )
        ..lineTo(
          arrowBase.dx - perpendicular.dx * arrowHalfWidth,
          arrowBase.dy - perpendicular.dy * arrowHalfWidth,
        )
        ..close(),
      _arrowPaint,
    );
  }

  void _paintNodeLabel(
    Canvas canvas,
    GraphNode node,
    Offset center,
    double nodeRadius,
    double scale,
  ) {
    final maxWidth = geometry.radius * 1.4 * scale;
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.title,
        style: TextStyle(
          fontFamily: NoteverseTypography.fontFamily,
          fontWeight: FontWeight.w700,
          color: nodeLabelColor,
          fontSize: (_labelFontSize * scale).clamp(8, 16),
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + nodeRadius + _labelGap * scale,
      ),
    );
  }

  bool _circleIntersectsViewport(Offset center, double radius, Size size) {
    return center.dx + radius >= 0 &&
        center.dx - radius <= size.width &&
        center.dy + radius >= 0 &&
        center.dy - radius <= size.height;
  }

  bool _segmentIntersectsViewport(
    Offset start,
    Offset end,
    Size size,
    double margin,
  ) {
    return math.max(start.dx, end.dx) >= -margin &&
        math.min(start.dx, end.dx) <= size.width + margin &&
        math.max(start.dy, end.dy) >= -margin &&
        math.min(start.dy, end.dy) <= size.height + margin;
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) =>
      oldDelegate.camera != camera ||
      oldDelegate.geometry.radius != geometry.radius ||
      oldDelegate.graph != graph ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.gridLineWidth != gridLineWidth ||
      oldDelegate.originColor != originColor ||
      oldDelegate.nodeSurfaceColor != nodeSurfaceColor ||
      oldDelegate.nodeOutlineColor != nodeOutlineColor ||
      oldDelegate.nodeLabelColor != nodeLabelColor ||
      oldDelegate.edgeColor != edgeColor;
}
