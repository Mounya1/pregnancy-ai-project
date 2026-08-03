import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../services/reminder_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _edit(BuildContext context, {Reminder? existing}) async {
    final controller = context.read<ReminderController>();
    final result = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReminderSheet(existing: existing),
    );
    if (result == null) return;

    await controller.save(result);
    // Nothing will actually fire until the OS grants permission, so ask the
    // first time the user commits to a reminder rather than on app launch.
    if (NotificationService.instance.supportsScheduling) {
      await NotificationService.instance.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final controller = context.watch<ReminderController>();
    final reminders = controller.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          if (reminders.isNotEmpty)
            IconButton(
              tooltip: 'Add reminder',
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add_rounded),
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
          if (!NotificationService.instance.supportsScheduling)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: AppCard(
                color: p.limitSurface,
                borderColor: p.limit.withValues(alpha: 0.25),
                shadow: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, size: 17, color: p.limit),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'On the web these are an in-app schedule only. Install the Android build to get alarms that go off when the app is closed.',
                        style: TextStyle(fontSize: 12, height: 1.45, color: p.limit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: Icons.alarm_rounded,
                title: 'No reminders yet',
                message: 'Set reminders for your meals, your baby\'s feeds, medicines, supplements, water, and bedtime.',
              ),
            )
          else
            for (var i = 0; i < reminders.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ReminderTile(
                    reminder: reminders[i],
                    onToggle: (on) => controller.toggle(reminders[i], on),
                    onTap: () => _edit(context, existing: reminders[i]),
                    onDelete: () => controller.remove(reminders[i]),
                  ),
                ),
              ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GradientButton(
          label: 'New reminder',
          icon: Icons.add_alarm_rounded,
          onPressed: () => _edit(context),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Reminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = _tintFor(context, reminder.kind);

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(
          color: p.avoidSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(Icons.delete_outline_rounded, color: p.avoid),
      ),
      child: AppCard(
        onTap: onTap,
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Opacity(
          opacity: reminder.enabled ? 1 : 0.55,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: p.isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(reminderKindIcon(reminder.kind), size: 19, color: tint),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reminder.formattedTime(context),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: p.isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            reminderKindLabel(reminder.kind),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium,
                    ),
                    Text(
                      reminder.scheduleLabel,
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(value: reminder.enabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }

  static Color _tintFor(BuildContext context, ReminderKind kind) {
    final p = context.palette;
    switch (kind) {
      case ReminderKind.motherMeal:
        return p.brand;
      case ReminderKind.babyFeed:
        return p.accent;
      case ReminderKind.medicine:
      case ReminderKind.supplement:
        return Brand.teal;
      case ReminderKind.water:
        return Brand.indigo;
      case ReminderKind.bedtime:
        return Brand.violetDeep;
    }
  }
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({this.existing});

  final Reminder? existing;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late ReminderKind _kind;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  /// True while the title still matches the kind's default, so switching kind
  /// can keep updating it instead of stranding a stale title.
  late bool _titleIsDefault;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _kind = existing?.kind ?? ReminderKind.motherMeal;
    _time = existing?.time ?? const TimeOfDay(hour: 8, minute: 0);
    _weekdays = {...?existing?.weekdays};
    _titleController = TextEditingController(
      text: existing?.title ?? reminderKindDefaultTitle(_kind),
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _titleIsDefault = existing == null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectKind(ReminderKind kind) {
    setState(() {
      _kind = kind;
      if (_titleIsDefault) _titleController.text = reminderKindDefaultTitle(kind);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    Navigator.pop(
      context,
      Reminder(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        kind: _kind,
        title: title.isEmpty ? reminderKindDefaultTitle(_kind) : title,
        hour: _time.hour,
        minute: _time.minute,
        notes: _notesController.text.trim(),
        weekdays: _weekdays,
        enabled: widget.existing?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'New reminder' : 'Edit reminder',
              style: context.texts.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('What for?', style: context.texts.titleSmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ReminderKind.values.map((kind) {
                final selected = kind == _kind;
                return Pressable(
                  onTap: () => _selectKind(kind),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? p.brandSurface : p.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: selected ? p.brand : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reminderKindIcon(kind),
                          size: 15,
                          color: selected ? p.brandSoft : p.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm - 2),
                        Text(
                          reminderKindLabel(kind),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? p.brandSoft : p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              onTap: _pickTime,
              radius: AppRadius.md,
              shadow: false,
              color: p.surfaceAlt,
              borderColor: Colors.transparent,
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 19, color: p.brandSoft),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('Time', style: context.texts.titleSmall)),
                  Text(
                    MaterialLocalizations.of(context).formatTimeOfDay(_time),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: p.brandSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: Text('Repeat', style: context.texts.titleSmall)),
                Text(
                  _weekdays.isEmpty ? 'Every day' : '${_weekdays.length} days',
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(7, (i) {
                final weekday = i + 1; // DateTime.monday == 1
                final selected = _weekdays.contains(weekday);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : AppSpacing.sm),
                    child: Pressable(
                      onTap: () => setState(() {
                        selected ? _weekdays.remove(weekday) : _weekdays.add(weekday);
                      }),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: selected ? p.brand : p.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          kWeekdayLabels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? p.onBrand : p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Leave all days off to repeat every day.',
              style: TextStyle(fontSize: 11, color: p.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _titleController,
              style: context.texts.bodyMedium,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => _titleIsDefault = false,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              style: context.texts.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Iron tablet after food',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: widget.existing == null ? 'Create reminder' : 'Save changes',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
