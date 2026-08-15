import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// A photograph used as a section header, with a scrim so the caption stays
/// readable whatever the image is.
///
/// The scrim is not decoration - white text over an arbitrary photo fails
/// contrast somewhere in almost every image, and a dark gradient under the
/// text is the only thing that makes it reliable.
class PhotoBanner extends StatelessWidget {
  const PhotoBanner({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    this.height = 132,
    this.onTap,
    this.alignment = Alignment.center,
  });

  /// Asset path, e.g. 'assets/images/nutrition.jpg'.
  final String image;

  final String title;
  final String? subtitle;
  final double height;
  final VoidCallback? onTap;

  /// Which part of the photo to keep when it is cropped to the banner.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                image,
                fit: BoxFit.cover,
                alignment: alignment,
                // A missing or corrupt asset falls back to the brand gradient
                // rather than Flutter's grey error box, so a bad build still
                // looks like the app.
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(gradient: p.heroGradient),
                ),
              ),
              // Bottom-weighted scrim: dark where the text sits, clear at the
              // top so the photo is still the thing you see.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xE6000000),
                      Color(0x66000000),
                      Color(0x1A000000),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xF2FFFFFF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
