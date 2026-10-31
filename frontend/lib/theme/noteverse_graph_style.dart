/// Shared dimensions for graph rendering in the main canvas and layout modal.
abstract final class NoteverseGraphStyle {
  /// Screen-space width in logical pixels, independent of camera zoom.
  static const gridLineWidth = 0.25;

  /// Base radii before the connection-dependent scale and camera zoom.
  static const mainNodeRadius = 11.0;
  static const layoutNodeRadius = 9.0;

  static const maximumNodeScale = 1.5;

  /// Uniform invisible hit target, 20% larger than the maximum rendered node.
  ///
  /// Expressed in canvas units so it scales with zoom. Hit targets and selection
  /// indicators follow the node's animated center, including hover elevation.
  static double nodeHitRadius({required double baseRadius}) =>
      baseRadius * maximumNodeScale * 1.2;

  /// Small upward screen-space displacement for hovered nodes.
  static const hoverLift = 6.0;

  /// Scales 0–1 neighbors to 50% and 20 or more to 150% of [baseRadius],
  /// with equal increments between 1 and 20 neighbors.
  static double nodeRadiusFor(int neighborCount, {required double baseRadius}) {
    final multiplier = 0.5 + (neighborCount.clamp(1, 20) - 1) / 19;
    return baseRadius * multiplier;
  }
}
