import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/gradient_button.dart';
import 'auth_shell.dart';

/// The unlock screen. An account already exists on this device, so the only
/// question is the password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final failure = await auth.signIn(_password.text);
    if (!mounted) return;
    setState(() => _error = failure);
    if (failure == null) _password.clear();
  }

  /// No server means no reset link. The only real option is wiping the device
  /// copy and starting again, so say that plainly instead of offering a
  /// "recovery" that cannot exist.
  Future<void> _forgotPassword() async {
    final auth = context.read<AuthController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot your password?'),
        content: const Text(
          'This account only exists on this phone, so there is no reset email '
          'and no way to verify who you are.\n\n'
          'The only way back in is to start over, which erases your profile, '
          'saved foods, reminders, medical reports, and baby records from this '
          'device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.palette.avoid),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase and start over'),
          ),
        ],
      ),
    );

    if (confirmed == true) await auth.deleteAccountAndData();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthController>();
    final name = auth.account?.firstName ?? 'there';

    return AuthShell(
      title: 'Welcome back, $name',
      subtitle: 'Enter your password to unlock your plans and records.',
      showBabyFigure: true,
      children: [
        AuthField(
          controller: _password,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          autofocus: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _error,
          onSubmitted: auth.busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.xxl),
        GradientButton(
          label: auth.busy ? 'Unlocking...' : 'Sign in',
          icon: Icons.lock_open_rounded,
          loading: auth.busy,
          onPressed: auth.busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: auth.busy ? null : _forgotPassword,
          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
          child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}
