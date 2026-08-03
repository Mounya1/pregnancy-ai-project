import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Colours for chart marks, kept separate from the UI palette because chart
/// marks have stricter requirements than interface chrome.
///
/// These exact values were checked with the dataviz palette validator
/// (lightness band, chroma floor, colour-vision-deficiency separation,
/// normal-vision separation, and contrast against the chart surface) and pass
/// on all pairs in both modes. The dark values are chosen for the dark band
/// (OKLCH L 0.48-0.67), not derived by lightening the light ones.
///
/// Nutrients are deliberately NOT given a colour each. A five-hue categorical
/// set could not pass colour-vision separation on all pairs - green/teal and
/// rose/teal collide - and the hue carried no information anyway, since every
/// row is already labelled. Magnitude gets one hue; reaching the target
/// switches to the reserved "good" status colour, always with an icon.
class ChartColors {
  const ChartColors._();

  /// Default mark colour for magnitude (bars, lines, areas).
  static Color mark(BuildContext context) =>
      context.palette.isDark ? const Color(0xFF8F84E4) : const Color(0xFF7B6FE0);

  /// Reserved status colour: target met / improving. Never used as a series hue.
  static Color good(BuildContext context) =>
      context.palette.isDark ? const Color(0xFF4E9E4A) : const Color(0xFF2F6B22);

  /// Recessive fill for the portion of a track that is not yet filled.
  static Color track(BuildContext context) => context.palette.surfaceAlt;

  /// Grid and reference lines - must stay quieter than any data mark.
  static Color grid(BuildContext context) =>
      context.palette.border.withValues(alpha: context.palette.isDark ? 0.9 : 1.0);
}
