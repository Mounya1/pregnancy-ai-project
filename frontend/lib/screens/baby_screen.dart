import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/baby_record.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/charts.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/illustrations.dart';
import '../widgets/ui/reveal.dart';
import 'chat_screen.dart';

/// Baby hub: growth tracking plus a always-available companion for the
/// questions that come up at 3am.
class BabyScreen extends StatefulWidget {
  const BabyScreen({super.key});

  @override
  State<BabyScreen> createState() => _BabyScreenState();
}

class _BabyScreenState extends State<BabyScreen> {
  final _storage = LocalStorageService();
  List<BabyRecord> _records = [];
  bool _loading = true;

  static const _companionPrompts = [
    'When can my baby start solids?',
    'Is my baby feeding enough?',
    'Which foods are choking hazards?',
    'How do I introduce allergens safely?',
    'What should I do about reflux?',
    'How much water can my baby have?',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _storage.loadBabyRecords();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _addRecord() async {
    final result = await showModalBottomSheet<BabyRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddRecordSheet(),
    );
    if (result != null) {
      await _storage.saveBabyRecord(result);
      await _load();
    }
  }

  Future<void> _remove(BabyRecord record) async {
    await _storage.removeBabyRecord(record.id);
    await _load();
  }

  void _ask(UserProfile profile, String question) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(profile: profile, initialQuestion: question)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final ageMonths = profile.babyAgeMonths;
    final latest = _records.isEmpty ? null : _records.last;

    return Scaffold(
      appBar: AppBar(title: const Text('Baby')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          110,
        ),
        children: [
          Reveal(
            child: _CompanionCard(
              ageMonths: ageMonths,
              onAsk: () => _ask(profile, ''),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Ask anything, any time',
            subtitle: 'Grounded in AAP and CDC infant-feeding guidance',
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _companionPrompts
                .map((q) => Pressable(
                      onTap: () => _ask(profile, q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: p.brandSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: p.brand.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          q,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.brandSoft,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SectionHeader(
            title: 'Growth',
            subtitle: latest == null
                ? 'Log a weight to start tracking'
                : 'Last logged ${DateFormat('MMM d').format(latest.recordedAt)}',
          ),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()))
          else if (_records.isEmpty)
            const EmptyState(
              icon: Icons.monitor_weight_rounded,
              title: 'No measurements yet',
              message: 'Log your baby\'s weight after each check-up and the trend will build here.',
            )
          else ...[
            Reveal(child: _GrowthCard(records: _records, ageMonths: ageMonths)),
            const SizedBox(height: AppSpacing.lg),
            for (var i = _records.length - 1; i >= 0; i--)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RecordTile(
                  record: _records[i],
                  previous: i > 0 ? _records[i - 1] : null,
                  onRemove: () => _remove(_records[i]),
                ),
              ),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GradientButton(
          label: 'Log weight',
          icon: Icons.add_rounded,
          onPressed: _addRecord,
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.ageMonths, required this.onAsk});

  final int? ageMonths;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onAsk,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(child: BlobDecoration(color: Colors.white, seed: 3)),
          const Positioned(
            right: -4,
            bottom: -12,
            child: Opacity(
              opacity: 0.38,
              child: BabyIllustration(
                color: Colors.white,
                accent: Color(0xFFF3E9FF),
                size: 118,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _content(context),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '24/7 baby companion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ageMonths == null
                      ? 'Feeding, sleep, and safety questions answered any time'
                      : 'Answers tuned to a $ageMonths-month-old',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        const Icon(Icons.chevron_right_rounded, color: Colors.white),
      ],
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.records, required this.ageMonths});

  final List<BabyRecord> records;
  final int? ageMonths;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final latest = records.last;
    final read = readWeight(latest.weightKg, ageMonths);
    final range = ageMonths == null ? null : weightRangeForMonths(ageMonths!);

    final (fg, bg, icon) = switch (read) {
      WeightRead.within => (p.safe, p.safeSurface, Icons.check_circle_rounded),
      WeightRead.below || WeightRead.above => (p.limit, p.limitSurface, Icons.info_rounded),
      WeightRead.unknown => (p.neutral, p.neutralSurface, Icons.help_rounded),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${latest.weightKg.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (range != null)
                    Text(
                      'Typical at $ageMonths months: ${range.$1}-${range.$2} kg',
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: fg.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      weightReadLabel(read),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TrendLineChart(
            values: records.map((r) => r.weightKg).toList(),
            labels: records.map((r) => DateFormat('d MMM').format(r.recordedAt)).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ranges blend WHO growth standards for boys and girls and are advisory only - your paediatrician tracks the percentile that actually matters.',
            style: TextStyle(fontSize: 10, height: 1.4, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.previous, required this.onRemove});

  final BabyRecord record;
  final BabyRecord? previous;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final prev = previous;
    final gain = prev == null ? null : record.weightKg - prev.weightKg;

    return AppCard(
      radius: AppRadius.md,
      shadow: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.monitor_weight_rounded, size: 15, color: p.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.weightKg.toStringAsFixed(2)} kg'
                  '${record.lengthCm != null ? '  ·  ${record.lengthCm!.toStringAsFixed(1)} cm' : ''}',
                  style: context.texts.bodyMedium,
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(record.recordedAt),
                  style: TextStyle(fontSize: 11, color: p.textMuted),
                ),
              ],
            ),
          ),
          if (gain != null)
            Text(
              '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(2)} kg',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: gain >= 0 ? p.safe : p.limit,
              ),
            ),
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 16, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AddRecordSheet extends StatefulWidget {
  const _AddRecordSheet();

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 40) {
      setState(() => _error = 'Enter a weight in kilograms, e.g. 6.4');
      return;
    }
    final length = double.tryParse(_lengthController.text.trim().replaceAll(',', '.'));

    Navigator.pop(
      context,
      BabyRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        weightKg: weight,
        lengthCm: length,
        recordedAt: _date,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log a measurement', style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _weightController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: context.texts.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 6.4',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _lengthController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: context.texts.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'Length (cm) - optional',
              hintText: 'e.g. 64',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            radius: AppRadius.md,
            shadow: false,
            color: p.surfaceAlt,
            borderColor: Colors.transparent,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 1200)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: p.brandSoft),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Date', style: context.texts.titleSmall)),
                Text(
                  DateFormat('MMM d, yyyy').format(_date),
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.brandSoft),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(fontSize: 12, color: p.avoid)),
          ],
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            label: 'Save measurement',
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
