import 'package:flutter/widgets.dart';

/// Describes the position and scale of the viewport over the graph plane.
class CanvasCamera extends ChangeNotifier {
  CanvasCamera({required this.minScale, required this.maxScale})
    : assert(minScale > 0),
      assert(maxScale >= minScale);

  /// [[TBD]] Replace these provisional limits with content-aware zoom limits.
  final double minScale;
  final double maxScale;

  double _scale = 1;
  Offset _translation = Offset.zero;

  /// Current zoom relative to the grid's default rendered size.
  double get scale => _scale;

  /// Screen-space displacement of the world origin from the viewport center.
  Offset get translation => _translation;

  /// Converts a screen position into Cartesian world coordinates.
  ///
  /// World coordinates use a positive Y axis pointing upwards, unlike Flutter's
  /// screen coordinate system.
  Offset worldFromScreen(Offset screenPosition, Size viewportSize) {
    final screenOrigin = viewportSize.center(Offset.zero) + _translation;
    return Offset(
      (screenPosition.dx - screenOrigin.dx) / _scale,
      (screenOrigin.dy - screenPosition.dy) / _scale,
    );
  }

  /// Converts Cartesian world coordinates into a position in the viewport.
  Offset screenFromWorld(Offset worldPosition, Size viewportSize) {
    final screenOrigin = viewportSize.center(Offset.zero) + _translation;
    return Offset(
      screenOrigin.dx + worldPosition.dx * _scale,
      screenOrigin.dy - worldPosition.dy * _scale,
    );
  }

  /// Updates the view while keeping [anchorWorld] under [focalPoint].
  void focusOn({
    required Offset anchorWorld,
    required Offset focalPoint,
    required Size viewportSize,
    required double requestedScale,
  }) {
    final nextScale = requestedScale.clamp(minScale, maxScale).toDouble();
    final nextOrigin = Offset(
      focalPoint.dx - anchorWorld.dx * nextScale,
      focalPoint.dy + anchorWorld.dy * nextScale,
    );
    final nextTranslation = nextOrigin - viewportSize.center(Offset.zero);

    if (nextScale == _scale && nextTranslation == _translation) {
      return;
    }

    _scale = nextScale;
    _translation = nextTranslation;
    notifyListeners();
  }

  /// Restores the default zoom and places world coordinate `(0, 0)` at center.
  void reset() {
    if (_scale == 1 && _translation == Offset.zero) {
      return;
    }

    _scale = 1;
    _translation = Offset.zero;
    notifyListeners();
  }
}
