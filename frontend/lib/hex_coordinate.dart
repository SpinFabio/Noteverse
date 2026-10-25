/// Integer axial coordinates for one cell in the infinite hexagonal grid.
///
/// The equivalent third cube coordinate is derived so the invariant
/// `q + r + s == 0` is always preserved.
class HexCoordinate {
  const HexCoordinate(this.q, this.r);

  /// Creates a coordinate from its JSON representation.
  factory HexCoordinate.fromJson(Map<String, Object?> json) {
    final q = json['q'];
    final r = json['r'];

    if (q is! int || r is! int) {
      throw const FormatException('Hex coordinates q and r must be integers.');
    }

    return HexCoordinate(q, r);
  }

  /// Diagonal flat-top grid axis.
  final int q;

  /// Vertical flat-top grid axis.
  final int r;

  /// Derived third coordinate used by symmetric hex-grid algorithms.
  int get s => -q - r;

  /// Converts this coordinate to its JSON representation.
  Map<String, int> toJson() => {'q': q, 'r': r};

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HexCoordinate && other.q == q && other.r == r;
  }

  @override
  int get hashCode => Object.hash(q, r);
}
