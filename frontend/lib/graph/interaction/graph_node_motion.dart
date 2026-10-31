import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Continuous world positions during dragging and the final grid transition.
///
/// Notifies the canvas directly, without rebuilding the page on each frame.
class GraphNodeMotion extends ChangeNotifier {
  GraphNodeMotion({required TickerProvider vsync}) {
    _animation = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 100),
    )..addListener(_tick);
  }

  late final AnimationController _animation;
  Map<String, Offset> _positions = const {};
  Map<String, Offset> _from = const {};
  Map<String, Offset> _targets = const {};

  /// Render-only overrides; the graph's stored coordinates remain on the grid.
  Map<String, Offset> get positions => _positions;

  /// Follows the pointer immediately, with no interpolation or input lag.
  void follow(Map<String, Offset> positions) {
    _animation.stop();
    _positions = Map.unmodifiable(positions);
    notifyListeners();
  }

  /// Settles onto the committed cells, or back onto the original cells.
  void settle(Map<String, Offset> targets, {required bool animate}) {
    if (!animate || _positions.isEmpty) {
      finish();
      return;
    }
    _from = _positions;
    _targets = Map.unmodifiable(targets);
    _animation.forward(from: 0);
  }

  /// Removes overrides so the canvas uses the graph's committed coordinates.
  void finish() {
    _animation.stop();
    _positions = const {};
    _from = const {};
    _targets = const {};
    notifyListeners();
  }

  void _tick() {
    if (_animation.value == 1) {
      finish();
      return;
    }
    final amount = Curves.easeOut.transform(_animation.value);
    _positions = Map.unmodifiable({
      for (final entry in _targets.entries)
        entry.key: Offset.lerp(_from[entry.key], entry.value, amount)!,
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}
