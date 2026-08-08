import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_controller.dart';
import 'services/emergency_controller.dart';
import 'services/local_storage_service.dart';
import 'services/milestone_controller.dart';
import 'services/notification_service.dart';
import 'services/nutrition_controller.dart';
import 'services/profile_controller.dart';
import 'services/reminder_controller.dart';
import 'services/shopping_controller.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'theme/brand_flavor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sets up timezones and the notification channel before any reminder is
  // scheduled. No-ops on web, where alarms can't be scheduled at all.
  await NotificationService.instance.init();
  runApp(const PregnancyAiApp());
}

class PregnancyAiApp extends StatelessWidget {
  const PregnancyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(storage)..load()),
        ChangeNotifierProvider(create: (_) => ProfileController(storage)..load()),
        ChangeNotifierProvider(create: (_) => ThemeController(storage)..load()),
        ChangeNotifierProvider(create: (_) => ReminderController(storage)..load()),
        ChangeNotifierProvider(create: (_) => ShoppingController(storage)..load()),
        ChangeNotifierProvider(create: (_) => NutritionController(storage)..load()),
        ChangeNotifierProvider(create: (_) => EmergencyController(storage)..load()),
        // Weekly updates are derived from the due date / birth date, so the
        // schedule has to be rebuilt whenever the profile changes - not only
        // when the toggle is touched.
        ChangeNotifierProxyProvider<ProfileController, MilestoneController>(
          create: (_) => MilestoneController(storage)..load(),
          update: (_, profileController, milestones) {
            final controller = milestones ?? MilestoneController(storage);
            // Deferred: update() runs during build, and syncFor notifies.
            scheduleMicrotask(() => controller.syncFor(profileController.profile));
            return controller;
          },
        ),
      ],
      // The brand colour depends on the profile (violet while pregnant, then
      // the baby's colour), so the theme has to rebuild when either the theme
      // mode or the profile changes.
      child: Consumer2<ThemeController, ProfileController>(
        builder: (context, theme, profileController, _) {
          final flavor = flavorForProfile(profileController.profile);
          return MaterialApp(
            title: 'Pregnancy & Baby Nutrition AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(flavor),
            darkTheme: AppTheme.dark(flavor),
            themeMode: theme.mode,
            // Animates every palette token when the brand or brightness
            // changes, so switching to the baby's colour sweeps through the
            // app instead of snapping.
            themeAnimationDuration: AppMotion.slow,
            themeAnimationCurve: AppMotion.emphasized,
            // The gate picks between the splash, sign-up, sign-in, and Home.
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
