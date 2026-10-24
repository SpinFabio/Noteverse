/// Integer axial coordinates for one cell in the infinite hexagonal grid.
///
/// The equivalent third cube coordinate is derived so the invariant
/// `q + r + s == 0` is always preserved.
class HexCoordinate {
  const HexCoordinate(this.q, this.r);

  /// Diagonal flat-top grid axis.
  final int q;

  /// Vertical flat-top grid axis.
  final int r;

  /// Derived third coordinate used by symmetric hex-grid algorithms.
  int get s => -q - r;
}
