import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medical_report.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/empty_state.dart';
import '../widgets/ui/gradient_button.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/shimmer.dart';

/// Upload a lab report or doctor's summary, extract the diet-relevant parts,
/// and push the conditions it finds into the profile so meal plans and chat
/// answers start accounting for them.
class MedicalReportScreen extends StatefulWidget {
  const MedicalReportScreen({super.key});

  @override
  State<MedicalReportScreen> createState() => _MedicalReportScreenState();
}

class _MedicalReportScreenState extends State<MedicalReportScreen> {
  final _api = ApiClient();
  final _storage = LocalStorageService();
  final _picker = ImagePicker();

  List<MedicalReport> _reports = [];
  bool _loading = true;
  bool _analyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await _storage.loadMedicalReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _loading = false;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    await _analyze(await picked.readAsBytes(), picked.name);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      // Needed on web and desktop, where paths aren't readable directly.
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    await _analyze(file!.bytes!, file.name);
  }

  Future<void> _analyze(Uint8List bytes, String filename) async {
    final profile = context.read<ProfileController>().profile;
    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final report = await _api.analyzeMedicalReport(
        fileBytes: bytes,
        profile: profile,
        filename: filename,
      );
      await _storage.saveMedicalReport(report);
      await _applyConditions(report);
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = describeApiError(e, baseUrl: _api.baseUrl));
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  /// Merges the report's conditions into the profile without dropping any the
  /// user added by hand or picked up from an earlier report.
  Future<void> _applyConditions(MedicalReport report) async {
    if (report.conditions.isEmpty || !mounted) return;
    final controller = context.read<ProfileController>();
    await controller.update((profile) {
      final merged = {...profile.healthConditions, ...report.conditions}.toList();
      return profile.copyWith(healthConditions: merged);
    });
  }

  Future<void> _chooseSource() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a report', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xl),
              _SourceTile(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Upload a PDF',
                subtitle: 'Lab results emailed by your clinic',
                onTap: () => Navigator.pop(sheetContext, 'pdf'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SourceTile(
                icon: Icons.photo_camera_rounded,
                title: 'Take a photo',
                subtitle: 'Point at a printed report',
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                subtitle: 'A picture you already have',
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'pdf':
        await _pickPdf();
      case 'camera':
        await _pickPhoto(ImageSource.camera);
      case 'gallery':
        await _pickPhoto(ImageSource.gallery);
    }
  }

  Future<void> _delete(MedicalReport report) async {
    await _storage.removeMedicalReport(report.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final conditions = context.watch<ProfileController>().profile.healthConditions;

    return Scaffold(
      appBar: AppBar(title: const Text('Medical reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          110,
        ),
        children: [
          AppCard(
            color: p.brandSurface,
            borderColor: p.brand.withValues(alpha: 0.18),
            shadow: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.health_and_safety_rounded, size: 18, color: p.brandSoft),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Upload blood work or a doctor\'s summary. Anything diet-relevant it finds is added to your profile, and meal plans adapt to it.',
                    style: TextStyle(fontSize: 12, height: 1.45, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (conditions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(
              title: 'Active in your diet',
              subtitle: 'Meal plans and answers account for these',
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: conditions
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: p.limitSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: p.limit.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.limit,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) ...[
            ErrorPanel(message: _error!, onRetry: _chooseSource),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (_analyzing) ...[
            const _AnalyzingSkeleton(),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (_loading)
            const SkeletonCardList(count: 2, height: 120)
          else if (_reports.isEmpty && !_analyzing)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: EmptyState(
                icon: Icons.description_rounded,
                title: 'No reports yet',
                message: 'Upload your first report and your diet will adjust to what it shows.',
              ),
            )
          else
            for (var i = 0; i < _reports.length; i++)
              Reveal.stagger(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _ReportCard(
                    report: _reports[i],
                    onDelete: () => _delete(_reports[i]),
                  ),
                ),
              ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GradientButton(
          label: _reports.isEmpty ? 'Upload report' : 'Upload another',
          icon: Icons.upload_file_rounded,
          loading: _analyzing,
          onPressed: _chooseSource,
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      shadow: false,
      radius: AppRadius.md,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: p.brandSoft),
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
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onDelete});

  final MedicalReport report;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: context.texts.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(report.uploadedAt),
                      style: TextStyle(fontSize: 11, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(Icons.close_rounded, size: 17, color: p.textMuted),
                ),
              ),
            ],
          ),
          if (report.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(report.summary, style: context.texts.bodyMedium),
          ],
          if (report.findings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...report.findings.map((f) => _FindingRow(finding: f)),
          ],
          if (report.keyNutrients.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Pills(
              label: 'Prioritise',
              items: report.keyNutrients,
              color: p.brandSoft,
              background: p.brandSurface,
            ),
          ],
          if (report.foodsToEmphasize.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Pills(
              label: 'Eat more',
              items: report.foodsToEmphasize,
              color: p.safe,
              background: p.safeSurface,
            ),
          ],
          if (report.foodsToLimit.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _Pills(
              label: 'Limit',
              items: report.foodsToLimit,
              color: p.avoid,
              background: p.avoidSurface,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            report.disclaimer,
            style: TextStyle(fontSize: 10, height: 1.4, color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

  final ReportFinding finding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (color, background) = switch (finding.status) {
      FindingStatus.low => (p.limit, p.limitSurface),
      FindingStatus.high => (p.avoid, p.avoidSurface),
      FindingStatus.normal => (p.safe, p.safeSurface),
      FindingStatus.unknown => (p.neutral, p.neutralSurface),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              findingStatusLabel(finding.status),
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: finding.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (finding.value.isNotEmpty)
                        TextSpan(
                          text: '  ${finding.value}',
                          style: TextStyle(color: p.textSecondary),
                        ),
                    ],
                  ),
                  style: TextStyle(fontSize: 12.5, color: p.textPrimary),
                ),
                if (finding.note.isNotEmpty)
                  Text(
                    finding.note,
                    style: TextStyle(fontSize: 11, height: 1.4, color: p.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills({
    required this.label,
    required this.items,
    required this.color,
    required this.background,
  });

  final String label;
  final List<String> items;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 66,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: context.palette.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs + 2,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _AnalyzingSkeleton extends StatelessWidget {
  const _AnalyzingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading your report...',
            style: context.texts.titleSmall?.copyWith(color: context.palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 140, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
