import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Raw brand ramp. These are the only hard-coded hues in the app; everything
/// else is read from [AppPalette] so the same widget renders correctly in
/// light and dark mode. Use these directly only when a colour must stay
/// vivid regardless of brightness (e.g. the hero gradient).
class Brand {
  const Brand._();

  static const violet = Color(0xFF7B6FE0);
  static const violetDeep = Color(0xFF534AB7);
  static const violetLift = Color(0xFFA79BFF);
  static const indigo = Color(0xFF5C63D8);
  static const blossom = Color(0xFFF08FB4);
  static const teal = Color(0xFF35B0A7);
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
      case BrandFlavor.violet:
        return const _FlavorColors(
          brand: Brand.violet,
          strong: Brand.violetDeep,
          soft: Color(0xFF5A50C0),
          surface: Color(0xFFEFEDFE),
          accent: Brand.blossom,
          scaffold: Color(0xFFF7F6FD),
          surfaceAlt: Color(0xFFF1EFFB),
          surfaceRaised: Colors.white,
          border: Color(0xFFE7E3F5),
          borderStrong: Color(0xFFD3CDEB),
        );
      case BrandFlavor.blossom:
        return const _FlavorColors(
          brand: Color(0xFFE86A93),
          strong: Color(0xFFBE3F6C),
          soft: Color(0xFFB93E68),
          surface: Color(0xFFFDECF1),
          accent: Color(0xFFF5A26B),
          scaffold: Color(0xFFFEF7F8),
          surfaceAlt: Color(0xFFFBEDF1),
          surfaceRaised: Colors.white,
          border: Color(0xFFF6DDE4),
          borderStrong: Color(0xFFEDC2CF),
        );
      case BrandFlavor.sky:
        return const _FlavorColors(
          brand: Color(0xFF3D8FD6),
          strong: Color(0xFF255F9B),
          soft: Color(0xFF23628F),
          surface: Color(0xFFE6F1FB),
          accent: Color(0xFF34B3AC),
          scaffold: Color(0xFFF5FAFE),
          surfaceAlt: Color(0xFFEBF3FA),
          surfaceRaised: Colors.white,
          border: Color(0xFFD9E7F3),
          borderStrong: Color(0xFFBBD3E8),
        );
    }
  }

  static _FlavorColors dark(BrandFlavor flavor) {
    switch (flavor) {
      case BrandFlavor.violet:
        return const _FlavorColors(
          brand: Brand.violetLift,
          strong: Brand.violet,
          soft: Color(0xFFC7BEFF),
          surface: Color(0xFF272341),
          accent: Color(0xFFE887AE),
          scaffold: Color(0xFF0E0D16),
          surfaceAlt: Color(0xFF181724),
          surfaceRaised: Color(0xFF201E30),
          border: Color(0xFF2E2B41),
          borderStrong: Color(0xFF3D3956),
        );
      case BrandFlavor.blossom:
        return const _FlavorColors(
          brand: Color(0xFFF593B2),
          strong: Color(0xFFE86A93),
          soft: Color(0xFFFCC3D5),
          surface: Color(0xFF3A2430),
          accent: Color(0xFFF7B98A),
          scaffold: Color(0xFF161013),
          surfaceAlt: Color(0xFF231A1E),
          surfaceRaised: Color(0xFF2C2126),
          border: Color(0xFF3D2C34),
          borderStrong: Color(0xFF523A45),
        );
      case BrandFlavor.sky:
        return const _FlavorColors(
          brand: Color(0xFF74B6EC),
          strong: Color(0xFF3D8FD6),
          soft: Color(0xFFB3D8F5),
          surface: Color(0xFF1E3049),
          accent: Color(0xFF5ECFC8),
          scaffold: Color(0xFF0B1119),
          surfaceAlt: Color(0xFF141C26),
          surfaceRaised: Color(0xFF1B2531),
          border: Color(0xFF25313F),
          borderStrong: Color(0xFF334455),
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
      onBrand: Colors.white,
      accent: f.accent,
      scaffold: f.scaffold,
      surface: Colors.white,
      surfaceAlt: f.surfaceAlt,
      surfaceRaised: Colors.white,
      border: f.border,
      borderStrong: f.borderStrong,
      textPrimary: const Color(0xFF171526),
      textSecondary: const Color(0xFF5C5872),
      textMuted: const Color(0xFF8E8AA3),
      safe: const Color(0xFF2F6B22),
      safeSurface: const Color(0xFFE8F3E0),
      limit: const Color(0xFF8A5208),
      limitSurface: const Color(0xFFFBEEDA),
      avoid: const Color(0xFF8C2020),
      avoidSurface: const Color(0xFFFBE9E9),
      neutral: const Color(0xFF5C5872),
      neutralSurface: const Color(0xFFEDEBF4),
      shadow: const Color(0xFF2A2545),
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
      onBrand: const Color(0xFF14121F),
      accent: f.accent,
      scaffold: f.scaffold,
      surface: f.surfaceAlt,
      surfaceAlt: f.surfaceRaised,
      surfaceRaised: f.surfaceRaised,
      border: f.border,
      borderStrong: f.borderStrong,
      textPrimary: const Color(0xFFF3F2F8),
      textSecondary: const Color(0xFFAEAAC2),
      textMuted: const Color(0xFF807C97),
      safe: const Color(0xFF93D98C),
      safeSurface: const Color(0xFF1C2C1B),
      limit: const Color(0xFFECB768),
      limitSurface: const Color(0xFF322614),
      avoid: const Color(0xFFF08C8C),
      avoidSurface: const Color(0xFF33191B),
      neutral: const Color(0xFFAEAAC2),
      neutralSurface: const Color(0xFF262338),
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

    final textTheme = base.textTheme
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary)
        .copyWith(
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: p.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: p.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: p.textPrimary,
          ),
          bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: p.textPrimary),
          bodyMedium: TextStyle(fontSize: 13.5, height: 1.5, color: p.textPrimary),
          bodySmall: TextStyle(fontSize: 12, height: 1.45, color: p.textSecondary),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.textSecondary),
          labelSmall: TextStyle(fontSize: 11, color: p.textMuted),
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
