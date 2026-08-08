import 'package:flutter/material.dart';
import '../widgets/ui/segmented_tabs.dart';
import 'fitness_screen.dart';
import 'meal_planner_screen.dart';
import 'shopping_screen.dart';

/// "Plan" section: everything the app generates for the week ahead.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'Plan',
      labels: ['Meals', 'Fitness', 'Shop'],
      children: [
        MealPlannerScreen(embedded: true),
        FitnessScreen(embedded: true),
        ShoppingScreen(embedded: true),
      ],
    );
  }
}
