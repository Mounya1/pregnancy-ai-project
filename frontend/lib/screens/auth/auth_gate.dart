import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/illustrations.dart';
import '../home_screen.dart';
import 'confirm_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Decides what the app opens on: a splash while storage is read, then either
/// the sign-up form, the unlock screen, or Home.
///
/// This is the only place that switches between them. Screens never navigate
/// to each other for auth - they change the controller and the gate reacts,
/// which is what keeps sign-out from leaving a stale Home on the stack.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    final Widget screen;
    switch (auth.status) {
      case AuthStatus.checking:
        screen = const _AuthSplash(key: ValueKey('splash'));
      case AuthStatus.needsSignUp:
        screen = const SignUpScreen(key: ValueKey('sign-up'));
      case AuthStatus.needsSignIn:
        screen = const SignInScreen(key: ValueKey('sign-in'));
      case AuthStatus.needsConfirmation:
        screen = const ConfirmScreen(key: ValueKey('confirm'));
      case AuthStatus.signedIn:
        screen = HomeScreen(
          key: const ValueKey('home'),
          userName: auth.account?.firstName ?? 'there',
        );
    }

    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.emphasized,
      child: screen,
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: p.heroGradient),
        child: const Stack(
          children: [
            Positioned.fill(child: BlobDecoration(color: Colors.white, seed: 5)),
            Center(
              child: MotherIllustration(
                color: Colors.white,
                accent: Color(0xFFEDE7FF),
                size: 150,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
