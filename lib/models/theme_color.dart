import 'dart:ui' show Color;

/// App theme colours the user can pick; each seeds the whole Material palette.
enum ThemeColor {
  blue('Blue', Color(0xFF00D2FF)),
  green('Green', Color(0xFF1FA463)),
  teal('Teal', Color(0xFF00897B)),
  purple('Purple', Color(0xFF7E57C2)),
  orange('Orange', Color(0xFFF57C00)),
  pink('Pink', Color(0xFFD81B60)),
  paniMesh('Pani Mesh', Color(0xFF8B5CF6));

  final String label;
  final Color seed;
  const ThemeColor(this.label, this.seed);
}
