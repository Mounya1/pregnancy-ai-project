import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Pill segmented control used as the header of a section screen.
///
/// Built rather than using Material's TabBar so the selected state matches
/// the filter pills used elsewhere in the app - one visual language for
/// "pick one of these" no matter where it appears.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (i == index) return;
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.emphasized,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: i == index ? p.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: i == index ? p.softShadow : null,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.base,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                      color: i == index ? p.brandSoft : p.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    child: Text(labels[i], textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A top-level section: a title, a segmented control, and the child screens
/// kept alive in an IndexedStack so switching tabs never reloads or loses
/// scroll position.
class SectionScaffold extends StatefulWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.labels,
    required this.children,
  });

  final String title;
  final List<String> labels;
  final List<Widget> children;

  @override
  State<SectionScaffold> createState() => _SectionScaffoldState();
}

class _SectionScaffoldState extends State<SectionScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SegmentedTabs(
            labels: widget.labels,
            index: _index,
            onChanged: (i) => setState(() => _index = i),
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: widget.children),
    );
  }
}
