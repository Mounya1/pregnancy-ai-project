import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// "How would you like to ask?" row: Type / Voice / Scan Food, matching
/// the home screen mockup.
class InteractionModeSelector extends StatelessWidget {
  const InteractionModeSelector({
    super.key,
    required this.onType,
    required this.onVoice,
    required this.onScan,
  });

  final VoidCallback onType;
  final VoidCallback onVoice;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.chat_bubble_outline,
            title: 'Type',
            subtitle: 'Ask with text',
            onTap: onType,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeCard(
            icon: Icons.mic_none,
            title: 'Voice',
            subtitle: 'Speak your question',
            onTap: onVoice,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeCard(
            icon: Icons.camera_alt_outlined,
            title: 'Scan food',
            subtitle: 'Take a photo',
            onTap: onScan,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.purple, size: 18),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
