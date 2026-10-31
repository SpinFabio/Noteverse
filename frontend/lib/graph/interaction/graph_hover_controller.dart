import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Animates transient node hover without rebuilding the canvas widget per frame.
class GraphHoverController extends ChangeNotifier {
  GraphHoverController({required TickerProvider vsync}) {
    _animation = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 100),
    )..addListener(notifyListeners);
  }

  late final AnimationController _animation;
  Map<String, double> _startingAmounts = {};
  String? _hoveredNodeId;

  String? get hoveredNodeId => _hoveredNodeId;

  /// Current amount of lift, accent color, and shadow for a node.
  double amountFor(String nodeId) {
    final start = _startingAmounts[nodeId] ?? 0;
    final end = nodeId == _hoveredNodeId ? 1.0 : 0.0;
    final progress = Curves.easeInOut.transform(_animation.value);
    return start + (end - start) * progress;
  }

  /// Transitions from current visual values, including when hovers change quickly.
  void setHoveredNode(String? nodeId, {required bool animate}) {
    if (_hoveredNodeId == nodeId) {
      return;
    }
    final previousIds = {..._startingAmounts.keys, ?_hoveredNodeId};
    final nextAmounts = <String, double>{};
    for (final id in previousIds) {
      final amount = amountFor(id);
      if (amount > 0) {
        nextAmounts[id] = amount;
      }
    }
    _animation.stop();
    _startingAmounts = nextAmounts;
    _hoveredNodeId = nodeId;
    if (animate) {
      _animation.forward(from: 0);
    } else {
      _animation.value = 1;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}
