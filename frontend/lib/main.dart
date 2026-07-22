import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PregnancyAiApp());
}

class PregnancyAiApp extends StatelessWidget {
  const PregnancyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo profile - replace with the real profile loaded from
    // auth/local storage once that's wired up.
    final demoProfile = UserProfile(
      lifeStage: LifeStage.breastfeeding,
      babyAgeMonths: 7,
    );

    return MaterialApp(
      title: 'Pregnancy & Baby Nutrition AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: HomeScreen(profile: demoProfile, userName: 'Priya'),
    );
  }
}
