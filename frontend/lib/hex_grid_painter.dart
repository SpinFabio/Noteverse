import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'canvas_camera.dart';
import 'graph/models/graph_data.dart';
import 'graph/models/graph_node.dart';
import 'graph/interaction/graph_hover_controller.dart';
import 'hex_grid_geometry.dart';
import 'hex_grid_lines.dart';
import 'theme/noteverse_typography.dart';
import 'theme/noteverse_graph_style.dart';

/// Paints only the flat-top hexagons intersecting the current viewport.
class HexGridPainter extends CustomPainter {
  HexGridPainter({
    required this.camera,
    required this.hover,
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
    required this.nodeHoverColor,
    required this.shadowColor,
    required this.selectedNodeId,
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
       super(repaint: Listenable.merge([camera, hover]));

  final CanvasCamera camera;
  final GraphHoverController hover;
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
  final Color nodeHoverColor;
  final Color shadowColor;
  final String? selectedNodeId;
  final Paint _backgroundPaint;
  final Paint _gridPaint;
  final Paint _originPaint;
  final Paint _nodeSurfacePaint;
  final Paint _nodeOutlinePaint;
  final Paint _edgePaint;
  final Paint _arrowPaint;

  static const _originRadius = 3.0;
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
    final maximumNodeRadius =
        NoteverseGraphStyle.mainNodeRadius *
        NoteverseGraphStyle.maximumNodeScale *
        scale;
    final nodeCenters = <String, Offset>{
      for (final node in graph.nodes)
        node.id: _screenCenter(node, originX, originY, scale),
    };

    _edgePaint.strokeWidth = (_edgeWidth * scale).clamp(0.5, 2.5);
    for (final edge in graph.edges) {
      final source = nodeCenters[edge.sourceNodeId]!;
      final target = nodeCenters[edge.targetNodeId]!;
      if (!_segmentIntersectsViewport(
        source,
        target,
        size,
        maximumNodeRadius,
      )) {
        continue;
      }
      _paintDirectedEdge(
        canvas,
        source,
        target,
        _radiusOf(edge.sourceNodeId) * scale,
        _radiusOf(edge.targetNodeId) * scale,
        scale,
      );
    }

    _nodeOutlinePaint.strokeWidth = (_nodeOutlineWidth * scale).clamp(0.75, 3);
    for (final node in graph.nodes) {
      final center = nodeCenters[node.id]!;
      final nodeRadius = _radiusOf(node.id) * scale;
      if (!_circleIntersectsViewport(center, nodeRadius, size)) {
        continue;
      }
      final amount = hover.amountFor(node.id);
      if (amount > 0) {
        final baseCenter =
            center + Offset(0, NoteverseGraphStyle.hoverLift * amount);
        canvas.drawOval(
          Rect.fromCenter(
            center: baseCenter,
            width: nodeRadius * 2,
            height: nodeRadius * 1.1,
          ),
          Paint()
            ..color = shadowColor.withValues(alpha: 0.45 * amount)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      _nodeSurfacePaint.color = node.id == selectedNodeId
          ? nodeHoverColor
          : Color.lerp(nodeSurfaceColor, nodeHoverColor, amount)!;
      canvas.drawCircle(center, nodeRadius, _nodeSurfacePaint);
      canvas.drawCircle(center, nodeRadius, _nodeOutlinePaint);
      if (scale >= _minimumLabelScale) {
        _paintNodeLabel(canvas, node, center, nodeRadius, scale);
      }
    }
  }

  double _radiusOf(String nodeId) => NoteverseGraphStyle.nodeRadiusFor(
    graph.neighborCountsByNodeId[nodeId]!,
    baseRadius: NoteverseGraphStyle.mainNodeRadius,
  );

  Offset _screenCenter(
    GraphNode node,
    double originX,
    double originY,
    double scale,
  ) {
    final worldCenter = geometry.centerOf(node.cell);
    return Offset(
      originX + worldCenter.dx * scale,
      originY -
          worldCenter.dy * scale -
          NoteverseGraphStyle.hoverLift * hover.amountFor(node.id),
    );
  }

  void _paintDirectedEdge(
    Canvas canvas,
    Offset source,
    Offset target,
    double sourceRadius,
    double targetRadius,
    double scale,
  ) {
    final delta = target - source;
    final distance = delta.distance;
    if (distance <= sourceRadius + targetRadius) {
      return;
    }

    final direction = delta / distance;
    final start = source + direction * sourceRadius;
    final tip = target - direction * targetRadius;
    final arrowLength = math.min(
      _arrowLength * scale,
      (distance - sourceRadius - targetRadius) / 2,
    );
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
      oldDelegate.hover != hover ||
      oldDelegate.geometry.radius != geometry.radius ||
      oldDelegate.graph != graph ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.gridLineWidth != gridLineWidth ||
      oldDelegate.originColor != originColor ||
      oldDelegate.nodeSurfaceColor != nodeSurfaceColor ||
      oldDelegate.nodeOutlineColor != nodeOutlineColor ||
      oldDelegate.nodeLabelColor != nodeLabelColor ||
      oldDelegate.edgeColor != edgeColor ||
      oldDelegate.nodeHoverColor != nodeHoverColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.selectedNodeId != selectedNodeId;
}
