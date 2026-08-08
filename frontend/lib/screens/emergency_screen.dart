import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/emergency_contact.dart';
import '../services/emergency_controller.dart';
import '../services/profile_controller.dart';
import '../services/shopping_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';

/// Numbers to call, and the signs that mean call now.
///
/// Everything on this screen is built for one state of mind: frightened, one
/// hand free, not reading carefully. Big targets, urgent things first, no
/// cleverness.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final emergency = context.watch<EmergencyController>();
    final profile = context.watch<ProfileController>().profile;
    final region = context.watch<ShoppingController>().region;
    final contacts = emergency.contacts;

    final signs = profile.babyBirthDate != null
        ? kBabyWarningSigns
        : kPregnancyWarningSigns;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        actions: [
          if (contacts.isNotEmpty)
            IconButton(
              tooltip: 'Add contact',
              onPressed: () => _edit(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          110,
        ),
        children: [
          // The national number, always here, never something to set up. It is
          // the one number that must work on a phone you have just picked up.
          Reveal(
            child: _EmergencyDialCard(
              number: emergencyNumberFor(region.code),
              regionName: region.name,
              onCall: () => _dial(context, emergencyNumberFor(region.code)),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SectionHeader(
            title: 'Your contacts',
            subtitle: contacts.isEmpty ? null : 'Tap to dial',
          ),
          if (!emergency.isLoaded)
            const Center(child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ))
          else if (contacts.isEmpty)
            const EmptyState(
              icon: Icons.contact_phone_rounded,
              title: 'No contacts yet',
              message:
                  'Add your hospital or maternity unit, your midwife or doctor, '
                  'and the person you would want beside you.',
            )
          else
            for (var i = 0; i < contacts.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ContactTile(
                    contact: contacts[i],
                    onCall: () => _dial(context, contacts[i].phone),
                    onEdit: () => _edit(context, existing: contacts[i]),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.xxl),
          SectionHeader(
            title: profile.babyBirthDate != null
                ? 'Call straight away if your baby has'
                : 'Call straight away if you have',
            subtitle: 'Do not wait for a scheduled appointment',
          ),
          AppCard(
            color: p.avoidSurface,
            borderColor: p.avoid.withValues(alpha: 0.25),
            shadow: false,
            child: Column(
              children: [
                for (var i = 0; i < signs.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    Divider(height: 1, color: p.avoid.withValues(alpha: 0.15)),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _SignRow(sign: signs[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'This list is not exhaustive. If something feels wrong, that is '
            'reason enough to call - nobody will mind.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textMuted),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GradientButton(
          label: 'Add a contact',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => _edit(context),
        ),
      ),
    );
  }

  Future<void> _dial(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<EmergencyController>().dial(phone);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open the dialler for $phone')),
      );
    }
  }

  Future<void> _edit(BuildContext context, {EmergencyContact? existing}) async {
    final controller = context.read<EmergencyController>();
    final result = await showModalBottomSheet<_ContactSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactSheet(existing: existing),
    );
    if (result == null) return;

    if (result.delete) {
      await controller.remove(existing!);
    } else {
      await controller.save(result.contact!);
    }
  }
}

/// The national emergency number. Styled as the one unmissable thing on the
/// screen, and kept above the fold on every phone size.
class _EmergencyDialCard extends StatelessWidget {
  const _EmergencyDialCard({
    required this.number,
    required this.regionName,
    required this.onCall,
  });

  final String number;
  final String regionName;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onCall,
      color: p.avoidSurface,
      borderColor: p.avoid.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: p.avoid,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.call_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call $number',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.avoid,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Emergency services in $regionName',
                  style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onCall,
    required this.onEdit,
  });

  final EmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onCall,
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.brand.withValues(alpha: p.isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(contactKindIcon(contact.kind), size: 20, color: p.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  contact.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
                if (contact.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    contact.notes,
                    maxLines: 2,
                    style: TextStyle(fontSize: 11, height: 1.35, color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.more_horiz_rounded, size: 19, color: p.textMuted),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.safe.withValues(alpha: p.isDark ? 0.24 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.call_rounded, size: 19, color: p.safe),
          ),
        ],
      ),
    );
  }
}

class _SignRow extends StatelessWidget {
  const _SignRow({required this.sign});

  final WarningSign sign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.priority_high_rounded, size: 15, color: p.avoid),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sign.sign,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sign.why,
                style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sheet result: either a contact to save, or a request to delete.
class _ContactSheetResult {
  const _ContactSheetResult.save(this.contact) : delete = false;
  const _ContactSheetResult.delete()
      : contact = null,
        delete = true;

  final EmergencyContact? contact;
  final bool delete;
}

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({this.existing});

  final EmergencyContact? existing;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  late ContactKind _kind = widget.existing?.kind ?? ContactKind.hospital;
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _relationship =
      TextEditingController(text: widget.existing?.relationship ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');

  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give this contact a name');
      return;
    }
    // A contact with no number is a note, not a contact - and finding that
    // out mid-emergency is exactly the wrong time.
    if (_phone.text.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) {
      setState(() => _error = 'Enter a phone number');
      return;
    }

    Navigator.pop(
      context,
      _ContactSheetResult.save(EmergencyContact(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        kind: _kind,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        relationship: _relationship.text.trim(),
        notes: _notes.text.trim(),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add a contact' : 'Edit contact',
              style: context.texts.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final kind in ContactKind.values)
                  Pressable(
                    onTap: () => setState(() => _kind = kind),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _kind == kind ? p.brandSurface : p.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: _kind == kind ? p.brand : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            contactKindIcon(kind),
                            size: 15,
                            color: _kind == kind ? p.brand : p.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contactKindLabel(kind),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kind == kind ? p.brand : p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: _kind == ContactKind.hospital
                    ? 'City Maternity Unit'
                    : 'Who is this?',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'Include the area or country code',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _relationship,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
                hintText: 'Husband, my mum, Ward 4',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Ask for the labour ward. Parking is on Level 2.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(fontSize: 12, color: p.avoid)),
            ],
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: widget.existing == null ? 'Add contact' : 'Save changes',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, const _ContactSheetResult.delete()),
                style: TextButton.styleFrom(foregroundColor: p.avoid),
                child: const Text('Remove this contact'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
