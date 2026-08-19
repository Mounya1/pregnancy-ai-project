import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/gradient_button.dart';
import 'auth_shell.dart';
import 'forgot_password_screen.dart';

/// The unlock screen. An account already exists on this device, so the only
/// question is the password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _password = TextEditingController();
  final _email = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Set here rather than as a `late final` with a context lookup: a lazy
    // initialiser can first run inside dispose(), and reading an inherited
    // widget from a deactivated element throws.
    _email.text = context.read<AuthController>().account?.email ?? '';
  }

  @override
  void dispose() {
    _password.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final failure = await auth.signIn(_password.text, email: _email.text);
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
        // Cloud accounts are keyed on email, and the same login works on any
        // device - so the address has to be editable, not assumed from
        // whatever this phone happens to remember.
        if (auth.isCloud) ...[
          AuthField(
            controller: _email,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
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
          onPressed: auth.busy
              ? null
              : () {
                  if (auth.isCloud) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(initialEmail: _email.text),
                      ),
                    );
                  } else {
                    _forgotPassword();
                  }
                },
          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
          child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}
