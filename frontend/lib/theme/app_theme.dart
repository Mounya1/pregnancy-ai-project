import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Raw brand ramp. These are the only hard-coded hues in the app; everything
/// else is read from [AppPalette] so the same widget renders correctly in
/// light and dark mode. Use these directly only when a colour must stay
/// vivid regardless of brightness (e.g. the hero gradient).
/// The Bloom ramp, converted from the design system's oklch tokens to sRGB.
///
/// Bloom states colour in oklch, which Flutter has no constructor for, so each
/// value below is the sRGB result of one token and the oklch triple it came
/// from is kept in the comment. Change a token by re-converting from the
/// oklch, not by nudging the hex - the ramp's even steps are a property of
/// the oklch lightness scale and hand-editing hex is what loses them.
class Brand {
  const Brand._();

  static const violet = Color(0xFF7D4EB7); // oklch(0.527 0.16 301.6) - primary
  static const violetDeep = Color(0xFF603493); // oklch(0.430 0.15 301.6)
  static const violetLift = Color(0xFFB582EE); // oklch(0.700 0.16 304.6) - dark primary
  static const coral = Color(0xFFFF6095); // oklch(0.711 0.20 3.4) - accent
  static const mint = Color(0xFF27D4A5); // oklch(0.776 0.149 168.6)
  static const amber = Color(0xFFFCB8A0); // oklch(0.840 0.086 40.5)
  static const cream = Color(0xFFFBF8FC); // oklch(0.983 0.006 316.8)
  static const ink = Color(0xFF1E1C26); // oklch(0.234 0.019 293.4)

  // Kept for the two post-birth flavours, which rotate Bloom's brand hue
  // rather than introducing a second ramp - see _FlavorColors.
  static const blossom = Color(0xFFAA3A78); // oklch(0.527 0.16 350)
  static const sky = Color(0xFF006FC0); // oklch(0.527 0.16 245)

  /// Category tints, used for icons and chips that sit on a light surface.
  ///
  /// These are Bloom's mint and a blue rotated from its brand, dropped to a
  /// lightness that stays legible as a small glyph. Bloom's own mint sits at
  /// L 0.776 for use as a fill, which is too light to read as a 17px icon.
  static const teal = Color(0xFF00906D); // oklch(0.580 0.12 168.6)
  static const indigo = Color(0xFF3C64C6); // oklch(0.527 0.16 265)
}

/// Which brand family the app is wearing.
///
/// Pregnancy keeps the violet the app has always used. After the birth it
/// follows the baby: blossom for a girl, sky for a boy. Gender is optional, so
/// violet stays the fallback rather than defaulting to one of the two.
enum BrandFlavor { violet, blossom, sky }

/// The brand-derived colours for one flavour. Everything else in the palette
/// is shared, so this is the only thing a flavour actually changes.
class _FlavorColors {
  const _FlavorColors({
    required this.brand,
    required this.strong,
    required this.soft,
    required this.surface,
    required this.accent,
    required this.scaffold,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
  });

  final Color brand;
  final Color strong;
  final Color soft;
  final Color surface;
  final Color accent;
  final Color scaffold;
  final Color surfaceAlt;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;

  static _FlavorColors light(BrandFlavor flavor) {
    switch (flavor) {
      // Bloom's own tokens. The other two flavours below are this ramp with
      // the hue rotated, so a post-birth palette keeps Bloom's lightness
      // steps and only changes which colour the app is wearing.
      case BrandFlavor.violet:
        return const _FlavorColors(
          brand: Brand.violet, // oklch(0.527 0.16 301.6)
          strong: Brand.violetDeep, // oklch(0.430 0.15 301.6)
          soft: Color(0xFF6B40A0), // oklch(0.470 0.15 301.6)
          surface: Color(0xFFF3EEF7), // oklch(0.955 0.014 310.6) - secondary
          accent: Brand.coral, // oklch(0.711 0.20 3.4)
          scaffold: Brand.cream, // oklch(0.983 0.006 316.8)
          surfaceAlt: Color(0xFFF6F3F9), // oklch(0.968 0.008 309.6) - muted
          surfaceRaised: Colors.white, // oklch(1 0 0) - card
          border: Color(0xFFE2E0E5), // oklch(0.910 0.006 301.6)
          borderStrong: Color(0xFFD0CED5), // oklch(0.855 0.010 300)
        );
      case BrandFlavor.blossom:
        return const _FlavorColors(
          brand: Brand.blossom, // oklch(0.527 0.16 350)
          strong: Color(0xFF871F5B), // oklch(0.430 0.15 350)
          soft: Color(0xFF942D66), // oklch(0.470 0.15 350)
          surface: Color(0xFFF9ECF0), // oklch(0.955 0.014 359)
          accent: Brand.teal, // mint, so the accent is not a second pink
          scaffold: Color(0xFFFDF8F9), // oklch(0.983 0.006 365)
          surfaceAlt: Color(0xFFF9F2F4), // oklch(0.968 0.008 358)
          surfaceRaised: Colors.white,
          border: Color(0xFFE5E0E2), // oklch(0.910 0.006 350)
          borderStrong: Color(0xFFD4CED0), // oklch(0.855 0.010 350)
        );
      case BrandFlavor.sky:
        return const _FlavorColors(
          brand: Brand.sky, // oklch(0.527 0.16 245)
          strong: Color(0xFF00529B), // oklch(0.430 0.15 245)
          soft: Color(0xFF005EA8), // oklch(0.470 0.15 245)
          surface: Color(0xFFEAF1FA), // oklch(0.955 0.014 254)
          accent: Brand.coral, // oklch(0.711 0.20 3.4)
          scaffold: Color(0xFFF7FAFE), // oklch(0.983 0.006 260)
          surfaceAlt: Color(0xFFF1F5FA), // oklch(0.968 0.008 253)
          surfaceRaised: Colors.white,
          border: Color(0xFFDEE2E5), // oklch(0.910 0.006 245)
          borderStrong: Color(0xFFCCD1D5), // oklch(0.855 0.010 245)
        );
    }
  }

  static _FlavorColors dark(BrandFlavor flavor) {
    switch (flavor) {
      // Bloom's .dark block. Its dark ground is oklch(0.234 0.019 293.4) -
      // the same value its light mode uses for text, which is what keeps the
      // two modes reading as one system rather than two palettes.
      case BrandFlavor.violet:
        return const _FlavorColors(
          brand: Brand.violetLift, // oklch(0.700 0.16 304.6)
          strong: Color(0xFF955DCD), // oklch(0.590 0.17 304.6)
          soft: Color(0xFFD1B6F4), // oklch(0.820 0.09 304.6)
          surface: Color(0xFF41384F), // oklch(0.360 0.04 301.6) - brand-soft
          accent: Brand.coral, // unchanged across modes in Bloom
          scaffold: Brand.ink, // oklch(0.234 0.019 293.4)
          surfaceAlt: Color(0xFF2C2A35), // oklch(0.290 0.020 293.6) - card
          surfaceRaised: Color(0xFF393546), // oklch(0.340 0.030 295.6) - muted
          border: Color(0xFF494554), // oklch(0.400 0.025 295.6)
          borderStrong: Color(0xFF595567), // oklch(0.460 0.030 295)
        );
      case BrandFlavor.blossom:
        return const _FlavorColors(
          brand: Color(0xFFE76FA7), // oklch(0.700 0.16 353)
          strong: Color(0xFFC54986), // oklch(0.590 0.17 353)
          soft: Color(0xFFF3ACC9), // oklch(0.820 0.09 353)
          surface: Color(0xFF4D3440), // oklch(0.360 0.04 350)
          accent: Color(0xFF5EDFB5), // mint, oklch(0.820 0.13 168.6)
          scaffold: Color(0xFF241A20), // oklch(0.234 0.019 342)
          surfaceAlt: Color(0xFF33282E), // oklch(0.290 0.020 342)
          surfaceRaised: Color(0xFF43323C), // oklch(0.340 0.030 344)
          border: Color(0xFF52424B), // oklch(0.400 0.025 344)
          borderStrong: Color(0xFF62525B), // oklch(0.460 0.030 344)
        );
      case BrandFlavor.sky:
        return const _FlavorColors(
          brand: Color(0xFF3BA4FC), // oklch(0.700 0.16 248)
          strong: Color(0xFF0081DC), // oklch(0.590 0.17 248)
          soft: Color(0xFF95CAFC), // oklch(0.820 0.09 248)
          surface: Color(0xFF2B3F51), // oklch(0.360 0.04 245)
          accent: Brand.coral,
          scaffold: Color(0xFF151F26), // oklch(0.234 0.019 237)
          surfaceAlt: Color(0xFF222D34), // oklch(0.290 0.020 237)
          surfaceRaised: Color(0xFF293A46), // oklch(0.340 0.030 239)
          border: Color(0xFF3C4A54), // oklch(0.400 0.025 239)
          borderStrong: Color(0xFF4C5A64), // oklch(0.460 0.030 239)
        );
    }
  }
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
  static const xxxl = 40.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Shared motion vocabulary. Keeping durations in one place is what makes the
/// staggered reveals, press feedback, and page transitions feel like one
/// system rather than a pile of one-off animations.
class AppMotion {
  const AppMotion._();

  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const reveal = Duration(milliseconds: 520);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Semantic colour tokens, resolved per brightness. Read via
/// `context.palette` rather than referencing [Brand] in screen code.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.brand,
    required this.brandStrong,
    required this.brandSoft,
    required this.brandSurface,
    required this.onBrand,
    required this.accent,
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.safe,
    required this.safeSurface,
    required this.limit,
    required this.limitSurface,
    required this.avoid,
    required this.avoidSurface,
    required this.neutral,
    required this.neutralSurface,
    required this.shadow,
  });

  final bool isDark;

  final Color brand;
  final Color brandStrong;

  /// Tinted brand text/icon colour that stays legible on [brandSurface].
  final Color brandSoft;

  /// Low-emphasis brand-tinted fill for chips, icon badges, empty states.
  final Color brandSurface;
  final Color onBrand;
  final Color accent;

  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color safe;
  final Color safeSurface;
  final Color limit;
  final Color limitSurface;
  final Color avoid;
  final Color avoidSurface;
  final Color neutral;
  final Color neutralSurface;

  final Color shadow;

  /// The signature header gradient (home hero, chat header, primary buttons).
  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brandStrong, brand, accent],
        stops: const [0.0, 0.55, 1.0],
      );

  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [brandStrong, brand],
      );

  /// Subtle top-light sheen layered over cards to give them a sense of depth.
  LinearGradient get sheenGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.05 : 0.9),
          Colors.white.withValues(alpha: 0.0),
        ],
      );

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.45 : 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  List<BoxShadow> get raisedShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: isDark ? 0.55 : 0.10),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ];

  /// Coloured glow used under the hero card and primary CTAs.
  List<BoxShadow> brandShadow({double opacity = 0.34}) => [
        BoxShadow(
          color: brand.withValues(alpha: isDark ? opacity * 0.6 : opacity),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];

  /// Light palette for a brand flavour. Only the brand family and the tints
  /// derived from it change; text, status and surface neutrals stay fixed so
  /// switching flavour never alters legibility or the meaning of a colour.
  static AppPalette lightFor(BrandFlavor flavor) {
    final f = _FlavorColors.light(flavor);
    return AppPalette(
      isDark: false,
      brand: f.brand,
      brandStrong: f.strong,
      brandSoft: f.soft,
      brandSurface: f.surface,
      onBrand: const Color(0xFFFCFBFD), // oklch(0.990 0.002 320) - primary-fg
      accent: f.accent,
      scaffold: f.scaffold,
      surface: Colors.white,
      surfaceAlt: f.surfaceAlt,
      surfaceRaised: Colors.white,
      border: f.border,
      borderStrong: f.borderStrong,
      textPrimary: Brand.ink, // oklch(0.234 0.019 293.4) - foreground
      textSecondary: const Color(0xFF64616F), // oklch(0.500 0.022 295) - muted-fg
      // L 0.54, not the 0.640 that sat halfway between Bloom's foreground and
      // its muted-foreground. This is the colour of 11px labels and field
      // hints, and at 0.640 it read 3.2:1 on the cream ground - short of AA
      // for text that size. Bloom does not define a third text tier, so the
      // contrast floor decides it rather than a token.
      textMuted: const Color(0xFF6F6D77), // oklch(0.540 0.016 295)
      // The three verdicts are Bloom's mint, amber and destructive, each
      // dropped in lightness until it passes contrast as body text on its own
      // tint. Bloom states them at fill lightness - mint at L 0.776, amber at
      // L 0.840 - which is unreadable as the text of a verdict chip.
      safe: const Color(0xFF007251), // oklch(0.480 0.12 168.6)
      safeSurface: const Color(0xFFE7FBF3), // oklch(0.971 0.024 170.2) - mint-soft
      limit: const Color(0xFF9C5313), // oklch(0.520 0.12 55)
      limitSurface: const Color(0xFFFFF5ED), // oklch(0.975 0.015 58.2) - amber-soft
      avoid: const Color(0xFFC21725), // oklch(0.520 0.20 25)
      avoidSurface: const Color(0xFFFFEDEC), // oklch(0.960 0.020 20)
      neutral: const Color(0xFF64616F), // oklch(0.500 0.022 295)
      neutralSurface: const Color(0xFFF1EFF5), // oklch(0.955 0.008 300)
      shadow: const Color(0xFF2F2A40), // oklch(0.300 0.040 295)
    );
  }

  static AppPalette darkFor(BrandFlavor flavor) {
    final f = _FlavorColors.dark(flavor);
    return AppPalette(
      isDark: true,
      brand: f.brand,
      brandStrong: f.strong,
      brandSoft: f.soft,
      brandSurface: f.surface,
      onBrand: Brand.ink, // Bloom's dark primary-foreground is its own ground
      accent: f.accent,
      scaffold: f.scaffold,
      surface: f.surfaceAlt,
      surfaceAlt: f.surfaceRaised,
      surfaceRaised: f.surfaceRaised,
      border: f.border,
      borderStrong: f.borderStrong,
      textPrimary: Brand.cream, // oklch(0.983 0.006 316.8) - modes swap these
      textSecondary: const Color(0xFFA5A2B0), // oklch(0.720 0.020 295)
      textMuted: const Color(0xFF8A8793), // oklch(0.630 0.018 295) - see light

      // Same three hues as light mode, lifted rather than dropped: on a dark
      // ground the tint is the deep colour and the text is the bright one.
      safe: const Color(0xFF5EDFB5), // oklch(0.820 0.13 168.6)
      safeSurface: const Color(0xFF204638), // oklch(0.360 0.05 168) - mint-soft
      limit: const Color(0xFFFFC298), // oklch(0.860 0.09 55)
      limitSurface: const Color(0xFF633D2C), // oklch(0.400 0.06 45) - amber-soft
      avoid: const Color(0xFFFF9E9B), // oklch(0.800 0.12 22) - AA on its tint
      avoidSurface: const Color(0xFF683738), // oklch(0.400 0.07 20)
      neutral: const Color(0xFFA5A2B0), // oklch(0.720 0.020 295)
      neutralSurface: const Color(0xFF393546), // oklch(0.340 0.030 295)
      shadow: const Color(0xFF000000),
    );
  }

  /// The default flavour, used before a profile has loaded.
  static AppPalette get light => lightFor(BrandFlavor.violet);

  static AppPalette get dark => darkFor(BrandFlavor.violet);

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? brand,
    Color? brandStrong,
    Color? brandSoft,
    Color? brandSurface,
    Color? onBrand,
    Color? accent,
    Color? scaffold,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceRaised,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? safe,
    Color? safeSurface,
    Color? limit,
    Color? limitSurface,
    Color? avoid,
    Color? avoidSurface,
    Color? neutral,
    Color? neutralSurface,
    Color? shadow,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      brand: brand ?? this.brand,
      brandStrong: brandStrong ?? this.brandStrong,
      brandSoft: brandSoft ?? this.brandSoft,
      brandSurface: brandSurface ?? this.brandSurface,
      onBrand: onBrand ?? this.onBrand,
      accent: accent ?? this.accent,
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      safe: safe ?? this.safe,
      safeSurface: safeSurface ?? this.safeSurface,
      limit: limit ?? this.limit,
      limitSurface: limitSurface ?? this.limitSurface,
      avoid: avoid ?? this.avoid,
      avoidSurface: avoidSurface ?? this.avoidSurface,
      neutral: neutral ?? this.neutral,
      neutralSurface: neutralSurface ?? this.neutralSurface,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      brand: c(brand, other.brand),
      brandStrong: c(brandStrong, other.brandStrong),
      brandSoft: c(brandSoft, other.brandSoft),
      brandSurface: c(brandSurface, other.brandSurface),
      onBrand: c(onBrand, other.onBrand),
      accent: c(accent, other.accent),
      scaffold: c(scaffold, other.scaffold),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      safe: c(safe, other.safe),
      safeSurface: c(safeSurface, other.safeSurface),
      limit: c(limit, other.limit),
      limitSurface: c(limitSurface, other.limitSurface),
      avoid: c(avoid, other.avoid),
      avoidSurface: c(avoidSurface, other.avoidSurface),
      neutral: c(neutral, other.neutral),
      neutralSurface: c(neutralSurface, other.neutralSurface),
      shadow: c(shadow, other.shadow),
    );
  }
}

extension PaletteExtension on BuildContext {
  /// Semantic colours for the current brightness.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  TextTheme get texts => Theme.of(this).textTheme;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light([BrandFlavor flavor = BrandFlavor.violet]) =>
      _build(AppPalette.lightFor(flavor), Brightness.light, flavor);

  static ThemeData dark([BrandFlavor flavor = BrandFlavor.violet]) =>
      _build(AppPalette.darkFor(flavor), Brightness.dark, flavor);

  static ThemeData _build(AppPalette p, Brightness brightness, BrandFlavor flavor) {
    final base = ThemeData(brightness: brightness);

    // Bloom pairs a display serif with a body sans and applies the serif to
    // headings only. Flutter has no h1-h4, so the split lands on the largest
    // title and above: headlines and titleLarge are headings, while
    // titleMedium and below are UI labels and belong to the body face.
    //
    // Fraunces carries the whole change in character. Dropping it and keeping
    // only the colours would leave this looking like the old theme recoloured.
    final display = GoogleFonts.fraunces();
    final body = GoogleFonts.dmSans();

    final textTheme = base.textTheme
        .apply(
          bodyColor: p.textPrimary,
          displayColor: p.textPrimary,
          fontFamily: body.fontFamily,
        )
        .copyWith(
          displayLarge: display.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: p.textPrimary,
          ),
          headlineMedium: display.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: p.textPrimary,
          ),
          headlineSmall: display.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: p.textPrimary,
          ),
          titleLarge: display.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: p.textPrimary,
          ),
          titleMedium: body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
          titleSmall: body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
          bodyLarge: body.copyWith(fontSize: 15, height: 1.5, color: p.textPrimary),
          bodyMedium: body.copyWith(fontSize: 13.5, height: 1.5, color: p.textPrimary),
          bodySmall: body.copyWith(fontSize: 12, height: 1.45, color: p.textSecondary),
          labelLarge: body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium:
              body.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
          labelSmall: body.copyWith(fontSize: 11, color: p.textMuted),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.scaffold,
      canvasColor: p.surface,
      splashFactory: InkSparkle.splashFactory,
      extensions: [p],
      colorScheme: ColorScheme.fromSeed(
        // Seed from the active flavour so Material's own generated roles
        // (ripples, text selection, date picker) follow the brand too.
        seedColor: _FlavorColors.light(flavor).brand,
        brightness: brightness,
      ).copyWith(
        primary: p.brand,
        onPrimary: p.onBrand,
        secondary: p.accent,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.avoid,
        surfaceContainerHighest: p.surfaceAlt,
        outline: p.border,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textSecondary, size: 20),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.brandSoft,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brandSoft,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: p.onBrand,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.brandSurface,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(fontSize: 12, color: p.brandSoft, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        hintStyle: TextStyle(fontSize: 13.5, color: p.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.brand, width: 1.6),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.surfaceRaised : p.textPrimary,
        contentTextStyle: TextStyle(fontSize: 13, color: p.isDark ? p.textPrimary : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.surfaceAlt,
        circularTrackColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      sliderTheme: SliderThemeData(activeTrackColor: p.brand, thumbColor: p.brand),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.brand : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.brandSurface : p.surfaceAlt,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
