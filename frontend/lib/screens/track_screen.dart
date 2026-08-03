import 'package:flutter/material.dart';
import '../widgets/ui/segmented_tabs.dart';
import 'history_screen.dart';
import 'nutrition_tracker_screen.dart';
import 'trends_screen.dart';

/// "Track" section: what you logged today, how the week is going, and every
/// past question or scan.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'Track',
      labels: ['Today', 'Trends', 'History'],
      children: [
        NutritionTrackerScreen(embedded: true),
        TrendsScreen(embedded: true),
        HistoryScreen(embedded: true),
      ],
    );
  }
}
