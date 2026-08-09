import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/doctor_note.dart';
import '../services/care_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/segmented_tabs.dart';

/// What your doctor actually said, for you and for the baby, kept apart.
///
/// Everything else in this app is general guidance. This is the one screen
/// that holds advice about *your* pregnancy and *your* baby, which is why the
/// rest of the app defers to it rather than the other way round.
class DoctorNotesScreen extends StatefulWidget {
  const DoctorNotesScreen({super.key});

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> {
  NoteSubject _subject = NoteSubject.mother;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final care = context.watch<CareController>();
    final notes = care.notesFor(_subject);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SegmentedTabs(
            labels: const ['About me', 'About baby'],
            index: _subject == NoteSubject.mother ? 0 : 1,
            onChanged: (i) => setState(
              () => _subject = i == 0 ? NoteSubject.mother : NoteSubject.baby,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          110,
        ),
        children: [
          AppCard(
            color: p.surfaceAlt,
            borderColor: Colors.transparent,
            shadow: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded, size: 15, color: p.textMuted),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Written down here, kept on this phone, never uploaded. '
                    'Take it to your next appointment.',
                    style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (notes.isEmpty)
            EmptyState(
              icon: Icons.edit_note_rounded,
              title: _subject == NoteSubject.mother
                  ? 'No notes about you yet'
                  : 'No notes about your baby yet',
              message: 'After an appointment, write down what you were told and '
                  'anything you were asked to do. You will not remember it as '
                  'well as you think.',
            )
          else
            for (var i = 0; i < notes.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _NoteTile(
                    note: notes[i],
                    onTap: () => _edit(context, existing: notes[i]),
                  ),
                ),
              ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GradientButton(
          label: _subject == NoteSubject.mother ? 'Add a note about me' : 'Add a note about baby',
          icon: Icons.add_rounded,
          onPressed: () => _edit(context),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, {DoctorNote? existing}) async {
    final care = context.read<CareController>();
    final result = await showModalBottomSheet<_NoteResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteSheet(existing: existing, subject: _subject),
    );
    if (result == null) return;

    if (result.delete) {
      await care.removeNote(existing!);
    } else {
      await care.saveNote(result.note!);
    }
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onTap});

  final DoctorNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(noteSubjectIcon(note.subject), size: 16, color: p.brand),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall,
                ),
              ),
              Text(
                DateFormat('d MMM yyyy').format(note.visitedAt),
                style: TextStyle(fontSize: 10.5, color: p.textMuted),
              ),
            ],
          ),
          if (note.clinician.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note.clinician,
              style: TextStyle(fontSize: 11, color: p.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            note.body,
            style: TextStyle(fontSize: 12, height: 1.5, color: p.textSecondary),
          ),
          if (note.nextAppointment != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: note.hasUpcoming ? p.brandSurface : p.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 13,
                    color: note.hasUpcoming ? p.brand : p.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${note.hasUpcoming ? 'Next' : 'Was'}: '
                    '${DateFormat('EEE d MMM').format(note.nextAppointment!)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: note.hasUpcoming ? p.brand : p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteResult {
  const _NoteResult.save(this.note) : delete = false;
  const _NoteResult.delete()
      : note = null,
        delete = true;

  final DoctorNote? note;
  final bool delete;
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({this.existing, required this.subject});

  final DoctorNote? existing;
  final NoteSubject subject;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  late final _clinician =
      TextEditingController(text: widget.existing?.clinician ?? '');
  late DateTime _visitedAt = widget.existing?.visitedAt ?? DateTime.now();
  late DateTime? _next = widget.existing?.nextAppointment;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _clinician.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNext}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext ? (_next ?? now) : _visitedAt,
      // A visit is in the past, an appointment is in the future. Constraining
      // each stops the two being entered the wrong way round.
      firstDate: isNext ? now : DateTime(now.year - 3),
      lastDate: isNext ? DateTime(now.year + 3) : now,
    );
    if (picked == null) return;
    setState(() {
      if (isNext) {
        _next = picked;
      } else {
        _visitedAt = picked;
      }
    });
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'What was the appointment about?');
      return;
    }
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'Write down what you were told');
      return;
    }

    Navigator.pop(
      context,
      _NoteResult.save(DoctorNote(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        subject: widget.existing?.subject ?? widget.subject,
        title: _title.text.trim(),
        body: _body.text.trim(),
        visitedAt: _visitedAt,
        clinician: _clinician.text.trim(),
        nextAppointment: _next,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subject = widget.existing?.subject ?? widget.subject;

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
            Row(
              children: [
                Icon(noteSubjectIcon(subject), size: 18, color: p.brand),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.existing == null
                      ? 'New note about ${noteSubjectLabel(subject).toLowerCase()}'
                      : 'Edit note',
                  style: context.texts.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _title,
              autofocus: widget.existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What was it about?',
                hintText: '20 week scan, 6 week check, feeding review',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _body,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What were you told?',
                hintText: 'Measurements, results, anything you were asked to do, '
                    'and anything you want to ask next time.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _clinician,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Who did you see? (optional)',
                hintText: 'Dr Rao, midwife Sarah',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DateRow(
              label: 'Date of visit',
              value: DateFormat('d MMM yyyy').format(_visitedAt),
              onTap: () => _pickDate(isNext: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DateRow(
              label: 'Next appointment',
              value: _next == null ? 'Not set' : DateFormat('d MMM yyyy').format(_next!),
              onTap: () => _pickDate(isNext: true),
              onClear: _next == null ? null : () => setState(() => _next = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: TextStyle(fontSize: 12, color: p.avoid)),
            ],
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: widget.existing == null ? 'Save note' : 'Save changes',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(context, const _NoteResult.delete()),
                style: TextButton.styleFrom(foregroundColor: p.avoid),
                child: const Text('Delete this note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        ),
        if (onClear != null)
          IconButton(
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 16, color: p.textMuted),
          ),
        Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: p.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: p.brand.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.brand,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
