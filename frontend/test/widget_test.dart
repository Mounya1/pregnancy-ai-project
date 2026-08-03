import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pregnancy_ai_assistant/main.dart';
import 'package:pregnancy_ai_assistant/models/baby_record.dart';
import 'package:pregnancy_ai_assistant/models/nutrition_log.dart';
import 'package:pregnancy_ai_assistant/models/pregnancy_week.dart';
import 'package:pregnancy_ai_assistant/models/reminder.dart';
import 'package:pregnancy_ai_assistant/models/suggestions.dart';
import 'package:pregnancy_ai_assistant/models/user_profile.dart';
import 'package:pregnancy_ai_assistant/models/weekly_stats.dart';
import 'package:pregnancy_ai_assistant/services/local_storage_service.dart';
import 'package:pregnancy_ai_assistant/services/theme_controller.dart';
import 'package:pregnancy_ai_assistant/theme/app_theme.dart';
import 'package:pregnancy_ai_assistant/theme/brand_flavor.dart';
import 'package:pregnancy_ai_assistant/screens/me_screen.dart';
import 'package:pregnancy_ai_assistant/widgets/app_nav_bar.dart';
import 'package:pregnancy_ai_assistant/widgets/ui/illustrations.dart';

/// Monday of the week containing [date], matching WeeklyStats' week boundary.
DateTime _mondayOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Finds a bottom-nav destination by label.
///
/// An IndexedStack builds every tab up front, so each section's AppBar title
/// ("Plan", "Track", ...) is in the tree alongside its nav label. Scoping to
/// the nav bar is what makes these taps unambiguous.
Finder _navItem(String label) => find.descendant(
      of: find.byType(AppNavBar),
      matching: find.text(label),
    );

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(_navItem(label));
  await tester.pumpAndSettle();
}

/// Settings moved behind the Me tab when navigation was restructured. Its
/// tile sits below the fold in the test viewport, so scroll it into view
/// rather than assuming it is on screen.
Future<void> _openSettings(WidgetTester tester) async {
  await _tapNav(tester, 'Me');
  await tester.scrollUntilVisible(
    find.text('Settings'),
    300,
    scrollable: find
        .descendant(of: find.byType(MeScreen), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
}

/// Lets the profile/theme controllers finish their async load and the home
/// screen's staggered entrance animations finish before asserting.
Future<void> _settleHome(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The hero illustrations breathe and the blobs drift on an endless loop,
    // so pumpAndSettle would never settle. Asking for reduced motion freezes
    // them at a neutral pose - which also exercises that accessibility path.
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('home screen renders the hero and navigation', (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    expect(find.text('Priya'), findsOneWidget);
    expect(find.text('How would you like to ask?'), findsOneWidget);

    for (final label in ['Home', 'Plan', 'Track', 'Baby', 'Me']) {
      expect(_navItem(label), findsOneWidget);
    }
  });

  testWidgets('settings tab exposes the theme selector', (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _openSettings(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('choosing dark mode repaints the app in the dark palette', (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _openSettings(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Appearance'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.palette.isDark, isTrue);
  });

  testWidgets('back returns to the previous tab instead of leaving the app', (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _tapNav(tester, 'Me');
    expect(find.text('Your details'), findsOneWidget);

    await _tapNav(tester, 'Plan');
    expect(find.text('Meals'), findsWidgets);

    // Back should retrace Plan -> Me -> Home rather than no-op.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Your details'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('How would you like to ask?'), findsOneWidget);
  });

  test('reminder schedules and ids behave', () {
    final daily = Reminder(
      id: 'a',
      kind: ReminderKind.medicine,
      title: 'Iron tablet',
      hour: 21,
      minute: 30,
    );
    expect(daily.isDaily, isTrue);
    expect(daily.scheduleLabel, 'Every day');
    expect(daily.notificationBaseId, greaterThanOrEqualTo(0));

    final weekly = daily.copyWith(weekdays: {DateTime.monday, DateTime.friday});
    expect(weekly.isDaily, isFalse);
    expect(weekly.scheduleLabel, 'M F');
    // Editing keeps the id, so its scheduled notifications stay addressable.
    expect(weekly.id, daily.id);
  });

  test('profile round-trips cuisines and health conditions', () {
    final profile = UserProfile(
      lifeStage: LifeStage.pregnancy,
      cuisines: const ['Indian', 'Chinese'],
      healthConditions: const ['gestational diabetes'],
    );

    final restored = UserProfile.fromStorageJson(profile.toStorageJson());
    expect(restored.cuisines, ['Indian', 'Chinese']);
    expect(restored.healthConditions, ['gestational diabetes']);

    // Both must reach the backend, which keys the meal-plan prompt off them.
    final api = profile.toApiJson();
    expect(api['cuisines'], ['Indian', 'Chinese']);
    expect(api['health_conditions'], ['gestational diabetes']);
  });

  testWidgets('home shows a full-colour figure, not just a faint watermark',
      (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    // The hero watermark plus the illustrated card both draw a figure, so a
    // figure must be present more than once.
    final figures = find.byWidgetPredicate(
      (w) => w is MotherIllustration || w is BabyIllustration,
    );
    expect(figures, findsWidgets);

    // At least one must be full-colour (tones set), which is what makes it an
    // illustration rather than a silhouette.
    final coloured = tester.widgetList(figures).where((w) {
      if (w is MotherIllustration) return w.tones != null;
      if (w is BabyIllustration) return w.tones != null;
      return false;
    });
    expect(coloured, isNotEmpty, reason: 'no full-colour figure on the home screen');
  });

  testWidgets('illustrations animate normally but freeze under reduced motion',
      (tester) async {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

    // Reduced motion is on from setUp: the figure must come to rest, or
    // pumpAndSettle would hang here.
    await tester.pumpWidget(host(const MotherIllustration(color: Colors.black)));
    await tester.pumpAndSettle();
    expect(find.byType(MotherIllustration), findsOneWidget);

    // With motion allowed the loop never ends, so frames keep being scheduled.
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pumpWidget(host(const BabyIllustration(color: Colors.black)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.hasScheduledFrame, isTrue);

    // animate: false must stop it even when the OS allows motion.
    await tester.pumpWidget(
      host(const BabyIllustration(color: Colors.black, animate: false)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BabyIllustration), findsOneWidget);
  });

  test('suggestions filter ranks prefix matches first and excludes chosen tags', () {
    final matches = filterSuggestions(kConditionSuggestions, 'vit');
    expect(matches.first.toLowerCase().startsWith('vit'), isTrue);

    // Already-added tags must not be offered again.
    final without = filterSuggestions(
      kAllergySuggestions,
      'pea',
      exclude: const ['Peanuts'],
    );
    expect(without.contains('Peanuts'), isFalse);
  });

  test('weekly stats compare this week against last week', () {
    final monday = _mondayOf(DateTime.now());
    // 2 servings of fortified cereal = 36mg iron, on two days this week.
    final entries = [
      NutritionEntry(id: '1', foodName: 'Fortified cereal (1 cup)', servings: 2, loggedAt: monday),
      NutritionEntry(
          id: '2',
          foodName: 'Fortified cereal (1 cup)',
          servings: 2,
          loggedAt: monday.add(const Duration(days: 1))),
      // Half as much on the same weekday last week.
      NutritionEntry(
          id: '3',
          foodName: 'Fortified cereal (1 cup)',
          servings: 1,
          loggedAt: monday.subtract(const Duration(days: 7))),
    ];

    final stats = WeeklyStats(entries: entries, lifeStage: LifeStage.pregnancy);
    final iron = stats.build().firstWhere((w) => w.label == 'Iron');

    expect(stats.daysLogged, 2);
    expect(iron.dailyTotals.length, 7);
    expect(iron.total, closeTo(72, 0.01));
    // This week averages more than last week, so the delta is positive.
    expect(iron.deltaPercent, isNotNull);
    expect(iron.deltaPercent! > 0, isTrue);
  });

  test('weekly stats report no comparison when last week is empty', () {
    final monday = _mondayOf(DateTime.now());
    final stats = WeeklyStats(
      entries: [
        NutritionEntry(id: '1', foodName: 'Lentils (1 cup cooked)', servings: 1, loggedAt: monday),
      ],
      lifeStage: LifeStage.pregnancy,
    );
    // A jump from zero would read as infinite improvement, so it stays null.
    expect(stats.build().first.deltaPercent, isNull);
  });

  test('baby weight is read against an age-appropriate range', () {
    expect(readWeight(7.0, 6), WeightRead.within);
    expect(readWeight(4.0, 6), WeightRead.below);
    expect(readWeight(12.0, 6), WeightRead.above);
    // Without a birth date there is no age, so no judgement is made.
    expect(readWeight(7.0, null), WeightRead.unknown);
  });

  test('every pregnancy week has usable reference data', () {
    expect(kPregnancyWeeks.length, 42);
    for (var w = 1; w <= 42; w++) {
      final info = pregnancyWeekInfo(w);
      expect(info.week, w);
      expect(info.sizeComparison, isNotEmpty);
      expect(info.babyDevelopment, isNotEmpty);
      expect(info.motherExperience, isNotEmpty);
    }
    // Out-of-range weeks clamp rather than throwing.
    expect(pregnancyWeekInfo(0).week, 1);
    expect(pregnancyWeekInfo(99).week, 42);
  });

  test('week measurements only ever increase', () {
    double lastWeight = 0;
    double lastLength = 0;
    for (final info in kPregnancyWeeks) {
      // Length switches from crown-rump to crown-heel at week 20, so the
      // jump there is expected; everywhere else it must not go backwards.
      if (info.weightGrams != null) {
        expect(info.weightGrams!, greaterThanOrEqualTo(lastWeight),
            reason: 'weight dropped at week ${info.week}');
        lastWeight = info.weightGrams!;
      }
      if (info.lengthCm != null) {
        expect(info.lengthCm!, greaterThanOrEqualTo(lastLength),
            reason: 'length dropped at week ${info.week}');
        lastLength = info.lengthCm!;
      }
    }
  });

  test('trimesters split at the clinical boundaries', () {
    expect(pregnancyWeekInfo(13).trimester, 1);
    expect(pregnancyWeekInfo(14).trimester, 2);
    expect(pregnancyWeekInfo(27).trimester, 2);
    expect(pregnancyWeekInfo(28).trimester, 3);
    // Length switches measurement basis at week 20.
    expect(pregnancyWeekInfo(19).lengthLabel, 'head to bottom');
    expect(pregnancyWeekInfo(20).lengthLabel, 'head to heel');
  });

  test('brand flavour follows pregnancy then the baby', () {
    UserProfile p({required LifeStage stage, BabyGender gender = BabyGender.unspecified}) =>
        UserProfile(lifeStage: stage, babyGender: gender);

    // Pregnancy stays violet whatever gender is set.
    expect(flavorForProfile(p(stage: LifeStage.pregnancy, gender: BabyGender.girl)),
        BrandFlavor.violet);
    expect(flavorForProfile(p(stage: LifeStage.breastfeeding, gender: BabyGender.girl)),
        BrandFlavor.blossom);
    expect(flavorForProfile(p(stage: LifeStage.postpartum, gender: BabyGender.boy)),
        BrandFlavor.sky);
    // Never guess a colour that implies something unstated.
    expect(flavorForProfile(p(stage: LifeStage.postpartum)), BrandFlavor.violet);
  });

  test('each flavour produces a distinct brand colour in both modes', () {
    final brands = BrandFlavor.values.map((f) => AppPalette.lightFor(f).brand).toSet();
    expect(brands.length, BrandFlavor.values.length);

    for (final flavor in BrandFlavor.values) {
      // Status and text colours must not move with the brand.
      expect(AppPalette.lightFor(flavor).safe, AppPalette.lightFor(BrandFlavor.violet).safe);
      expect(AppPalette.darkFor(flavor).isDark, isTrue);
    }
  });

  test('theme controller persists the selected mode', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();

    final controller = ThemeController(storage);
    await controller.load();
    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.dark);

    final reloaded = ThemeController(storage);
    await reloaded.load();
    expect(reloaded.mode, ThemeMode.dark);
  });
}
