import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_card.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/gradient_button.dart';
import '../../widgets/ui/illustrations.dart';
import '../../widgets/ui/reveal.dart';
import 'auth_shell.dart';

/// Everything about the account itself: who it says you are, the password,
/// and the two ways out (sign out, or erase).
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final auth = context.watch<AuthController>();
    final account = auth.account;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: const Center(child: Text('No account on this device.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          Reveal(
            child: GradientCard(
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  const Positioned.fill(child: BlobDecoration(color: Colors.white, seed: 4)),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            account.initials,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                account.email.isEmpty ? 'No email added' : account.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'On this device since '
                                '${DateFormat.yMMMM().format(account.createdAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'Account'),
          _Tile(
            icon: Icons.badge_outlined,
            tint: p.brand,
            title: 'Name and email',
            subtitle: 'How the app greets you',
            onTap: () => _editDetails(context),
          ),
          _Tile(
            icon: Icons.password_rounded,
            tint: Brand.indigo,
            title: 'Change password',
            subtitle: 'Used to unlock this app',
            onTap: () => _changePassword(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Session',
            subtitle: 'Signing out keeps everything - it just locks the app',
          ),
          _Tile(
            icon: Icons.logout_rounded,
            tint: Brand.teal,
            title: 'Sign out',
            subtitle: 'Ask for the password next time',
            onTap: () => _confirmSignOut(context),
          ),
          _Tile(
            icon: Icons.delete_forever_rounded,
            tint: p.avoid,
            title: 'Delete account and all data',
            subtitle: 'Erases everything from this device',
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _editDetails(BuildContext context) async {
    final auth = context.read<AuthController>();
    final account = auth.account!;
    final name = TextEditingController(text: account.name);
    final email = TextEditingController(text: account.email);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetForm(
        title: 'Name and email',
        submitLabel: 'Save',
        fields: (error) => [
          AuthField(
            controller: name,
            label: 'Your name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthField(
            controller: email,
            label: 'Email (optional)',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            errorText: error,
          ),
        ],
        onSubmit: () => auth.updateDetails(name: name.text, email: email.text),
      ),
    );

    name.dispose();
    email.dispose();

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account updated')));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final auth = context.read<AuthController>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SheetForm(
        title: 'Change password',
        submitLabel: 'Update password',
        fields: (error) => [
          AuthField(
            controller: current,
            label: 'Current password',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthField(
            controller: next,
            label: 'New password',
            hint: 'At least 6 characters',
            icon: Icons.lock_reset_rounded,
            obscure: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthField(
            controller: confirm,
            label: 'Confirm new password',
            icon: Icons.lock_reset_rounded,
            obscure: true,
            errorText: error,
          ),
        ],
        onSubmit: () async {
          if (next.text != confirm.text) return 'New passwords do not match';
          return auth.changePassword(
            currentPassword: current.text,
            newPassword: next.text,
          );
        },
      ),
    );

    current.dispose();
    next.dispose();
    confirm.dispose();

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password updated')));
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your profile, plans, and records stay on this device. You will need '
          'your password to get back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // Drop back to the root first: the gate replaces Home with the sign-in
    // screen, and leaving this screen pushed on top of it would show a stale
    // account page over the lock screen.
    navigator.popUntil((route) => route.isFirst);
    await auth.signOut();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This erases your account, profile, saved foods, history, nutrition '
          'log, reminders, medical reports, and baby records from this device.\n\n'
          'There is no backup and no way to undo it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.palette.avoid),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    navigator.popUntil((route) => route.isFirst);
    await auth.deleteAccountAndData();
  }
}

/// Bottom sheet wrapper for the two small account forms. Holds the error the
/// controller returns so each form doesn't have to repeat the plumbing.
class _SheetForm extends StatefulWidget {
  const _SheetForm({
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final String submitLabel;

  /// Built with the current error so the form can attach it to whichever
  /// field it belongs under.
  final List<Widget> Function(String? error) fields;

  /// Returns an error message, or null on success.
  final Future<String?> Function() onSubmit;

  @override
  State<_SheetForm> createState() => _SheetFormState();
}

class _SheetFormState extends State<_SheetForm> {
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final error = await widget.onSubmit();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: context.texts.titleMedium),
          const SizedBox(height: AppSpacing.xl),
          ...widget.fields(_error),
          const SizedBox(height: AppSpacing.xxl),
          GradientButton(
            label: widget.submitLabel,
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        radius: AppRadius.md,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: p.isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.texts.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: p.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
