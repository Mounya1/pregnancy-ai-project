import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/gradient_button.dart';
import 'auth_shell.dart';

/// Enter the six-digit code Cognito emailed, to finish creating the account.
///
/// A separate screen rather than a dialog because it survives an app restart:
/// the pending email is stored, so closing the app mid sign-up comes back
/// here instead of stranding a half-created account with no way to finish it.
class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  final _code = TextEditingController();
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final failure = await context.read<AuthController>().confirmSignUp(_code.text);
    if (!mounted) return;
    setState(() {
      _error = failure;
      _notice = null;
    });
  }

  Future<void> _resend() async {
    final failure = await context.read<AuthController>().resendCode();
    if (!mounted) return;
    setState(() {
      _error = failure;
      _notice = failure == null ? 'A new code is on its way.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthController>();
    final email = auth.pendingEmail ?? 'your email';

    return AuthShell(
      title: 'Check your email',
      subtitle: 'We sent a six-digit code to $email. Enter it to finish setting '
          'up your account.',
      children: [
        AuthField(
          controller: _code,
          label: 'Confirmation code',
          hint: '123456',
          icon: Icons.mark_email_read_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofocus: true,
          errorText: _error,
          onSubmitted: auth.busy ? null : _submit,
        ),
        if (_notice != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _notice!,
            style: TextStyle(fontSize: 11.5, color: p.safe),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        GradientButton(
          label: auth.busy ? 'Confirming...' : 'Confirm account',
          icon: Icons.check_rounded,
          loading: auth.busy,
          onPressed: auth.busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: auth.busy ? null : _resend,
          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
          child: const Text('Send a new code', style: TextStyle(fontSize: 12.5)),
        ),
        Text(
          'Codes expire after 24 hours. Check your spam folder before asking '
          'for another - the new one replaces the old.',
          style: TextStyle(fontSize: 11, height: 1.4, color: p.textMuted),
        ),
      ],
    );
  }
}
