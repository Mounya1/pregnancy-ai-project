import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/ui/illustrations.dart';

/// Shared frame for sign-up and sign-in: a gradient crown with the figure
/// illustration, then the form on the scaffold below it.
///
/// Both screens use the same frame so signing out and back in doesn't feel
/// like landing in a different app.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBabyFigure = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Sign-in shows the baby alongside the mother once an account exists -
  /// a small nod that this device already has a story on it.
  final bool showBabyFigure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      // resizeToAvoidBottomInset default plus a scroll view keeps the password
      // field visible when the keyboard opens on a short phone.
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Crown(title: title, subtitle: subtitle, showBabyFigure: showBabyFigure),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phonelink_lock_rounded, size: 14, color: p.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Your account and data stay on this phone. Nothing is uploaded.',
                        style: TextStyle(fontSize: 11.5, color: p.textMuted, height: 1.4),
                      ),
                    ),
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

class _Crown extends StatelessWidget {
  const _Crown({required this.title, required this.subtitle, required this.showBabyFigure});

  final String title;
  final String subtitle;
  final bool showBabyFigure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        gradient: p.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        boxShadow: p.brandShadow(opacity: 0.28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: BlobDecoration(color: Colors.white, seed: 3)),
          Positioned(
            right: -4,
            bottom: -8,
            child: Opacity(
              opacity: 0.34,
              // Signing up is one figure; coming back to a device that
              // already knows you is the pair.
              child: showBabyFigure
                  ? const HoldingBabyIllustration(
                      color: Colors.white,
                      accent: Color(0xFFEDE7FF),
                      size: 132,
                    )
                  : const MotherIllustration(
                      color: Colors.white,
                      accent: Color(0xFFEDE7FF),
                      size: 128,
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              MediaQuery.of(context).padding.top + AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    'Pregnancy & Baby Nutrition',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: 240,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Text field shared by both auth forms: consistent label, inline error, and
/// an optional reveal toggle for passwords.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: p.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.controller,
          obscureText: _hidden,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 18, color: p.textMuted),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 18,
                      color: p.textMuted,
                    ),
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
