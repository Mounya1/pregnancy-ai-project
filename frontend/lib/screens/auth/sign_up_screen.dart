import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/gradient_button.dart';
import 'auth_shell.dart';

/// First run: name, optional email, password. Nothing else - the life stage,
/// due date, allergies and the rest all belong to the Profile screen, and
/// asking for them here would turn a 20-second sign-up into a questionnaire.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();

    // Validate everything at once so the form doesn't reveal problems one at
    // a time.
    final cloud = auth.isCloud;
    final nameError = AuthController.validateName(_name.text);
    final emailError = cloud
        ? AuthController.validateRequiredEmail(_email.text)
        : AuthController.validateEmail(_email.text);
    final passwordError = cloud
        ? AuthController.validateCloudPassword(_password.text)
        : AuthController.validatePassword(_password.text);
    final confirmError =
        _confirm.text == _password.text ? null : 'Passwords do not match';

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });

    if (nameError != null || emailError != null || passwordError != null || confirmError != null) {
      return;
    }

    final failure = await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );

    if (failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    }
    // On success the gate swaps this screen out for Home - no navigation here.
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final busy = context.watch<AuthController>().busy;

    return AuthShell(
      title: 'Create your account',
      subtitle: 'So your plans, reminders, and records are yours alone on this phone.',
      children: [
        AuthField(
          controller: _name,
          label: 'Your name',
          hint: 'Priya',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          errorText: _nameError,
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthField(
          controller: _email,
          label: context.watch<AuthController>().isCloud ? 'Email' : 'Email (optional)',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthField(
          controller: _password,
          label: 'Password',
          hint: context.watch<AuthController>().isCloud
              ? '8+ characters, upper and lower case, and a number'
              : 'At least 6 characters',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthField(
          controller: _confirm,
          label: 'Confirm password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          textInputAction: TextInputAction.done,
          errorText: _confirmError,
          onSubmitted: busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.xxl),
        GradientButton(
          label: busy ? 'Creating account...' : 'Create account',
          icon: Icons.arrow_forward_rounded,
          loading: busy,
          onPressed: busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: p.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.watch<AuthController>().isCloud
                      ? 'We will email you a code to confirm this address. Your '
                          'health data stays on this device - the account is only '
                          'used to sign you in.'
                      : 'There is no password reset. With no server, nobody can '
                          'verify it is you - so keep this password somewhere safe.',
                  style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
