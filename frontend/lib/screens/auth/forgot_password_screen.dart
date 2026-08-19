import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/gradient_button.dart';
import 'auth_shell.dart';

/// Password reset in two steps on one screen: ask for the code, then set the
/// new password with it.
///
/// One screen rather than two because the email address has to stay put
/// between the steps, and re-typing it is exactly the mistake that sends the
/// code to an address you cannot read.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();

  bool _codeSent = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final failure = await context.read<AuthController>().forgotPassword(_email.text);
    if (!mounted) return;
    setState(() {
      _error = failure;
      if (failure == null) _codeSent = true;
    });
  }

  Future<void> _reset() async {
    final failure = await context.read<AuthController>().confirmForgotPassword(
          email: _email.text,
          code: _code.text,
          newPassword: _password.text,
        );
    if (!mounted) return;
    setState(() {
      _error = failure;
      if (failure == null) _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthController>();

    if (_done) {
      return AuthShell(
        title: 'Password changed',
        subtitle: 'You can sign in with your new password now.',
        children: [
          GradientButton(
            label: 'Back to sign in',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }

    return AuthShell(
      title: 'Reset your password',
      subtitle: _codeSent
          ? 'Enter the code we emailed you, and pick a new password.'
          : 'Tell us your email address and we will send a reset code.',
      children: [
        AuthField(
          controller: _email,
          label: 'Email',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofocus: widget.initialEmail.isEmpty,
          errorText: _codeSent ? null : _error,
        ),

        if (!_codeSent) ...[
          const SizedBox(height: AppSpacing.xxl),
          GradientButton(
            label: auth.busy ? 'Sending...' : 'Send reset code',
            icon: Icons.send_rounded,
            loading: auth.busy,
            onPressed: auth.busy ? null : _sendCode,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'If an account exists for that address, a code will arrive within '
            'a minute or two.',
            style: TextStyle(fontSize: 11, height: 1.4, color: p.textMuted),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.lg),
          AuthField(
            controller: _code,
            label: 'Reset code',
            hint: '123456',
            icon: Icons.mark_email_read_outlined,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthField(
            controller: _password,
            label: 'New password',
            hint: '8+ characters, upper and lower case, and a number',
            icon: Icons.lock_reset_rounded,
            obscure: true,
            textInputAction: TextInputAction.done,
            errorText: _error,
            onSubmitted: auth.busy ? null : _reset,
          ),
          const SizedBox(height: AppSpacing.xxl),
          GradientButton(
            label: auth.busy ? 'Saving...' : 'Set new password',
            icon: Icons.check_rounded,
            loading: auth.busy,
            onPressed: auth.busy ? null : _reset,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: auth.busy ? null : _sendCode,
            style: TextButton.styleFrom(foregroundColor: p.textSecondary),
            child: const Text('Send another code', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ],
    );
  }
}
