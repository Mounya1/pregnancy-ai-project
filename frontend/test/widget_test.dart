import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pregnancy_ai_assistant/main.dart';
import 'package:pregnancy_ai_assistant/models/baby_month.dart';
import 'package:pregnancy_ai_assistant/models/baby_record.dart';
import 'package:pregnancy_ai_assistant/models/care_plan.dart';
import 'package:pregnancy_ai_assistant/models/doctor_note.dart';
import 'package:pregnancy_ai_assistant/models/emergency_contact.dart';
import 'package:pregnancy_ai_assistant/models/milestone.dart';
import 'package:pregnancy_ai_assistant/models/nutrition_log.dart';
import 'package:pregnancy_ai_assistant/models/pregnancy_week.dart';
import 'package:pregnancy_ai_assistant/models/reminder.dart';
import 'package:pregnancy_ai_assistant/models/shopping.dart';
import 'package:pregnancy_ai_assistant/models/shopping_region.dart';
import 'package:pregnancy_ai_assistant/models/suggestions.dart';
import 'package:pregnancy_ai_assistant/models/user_profile.dart';
import 'package:pregnancy_ai_assistant/models/weekly_stats.dart';
import 'package:pregnancy_ai_assistant/models/account.dart';
import 'package:pregnancy_ai_assistant/services/auth_controller.dart';
import 'package:pregnancy_ai_assistant/services/care_controller.dart';
import 'package:pregnancy_ai_assistant/services/cognito_client.dart';
import 'package:pregnancy_ai_assistant/services/emergency_controller.dart';
import 'package:pregnancy_ai_assistant/services/local_storage_service.dart';
import 'package:pregnancy_ai_assistant/services/milestone_controller.dart';
import 'package:pregnancy_ai_assistant/services/nutrition_controller.dart';
import 'package:pregnancy_ai_assistant/services/password_hash.dart';
import 'package:pregnancy_ai_assistant/services/shopping_controller.dart';
import 'package:pregnancy_ai_assistant/services/theme_controller.dart';
import 'package:pregnancy_ai_assistant/theme/app_theme.dart';
import 'package:pregnancy_ai_assistant/theme/brand_flavor.dart';
import 'package:pregnancy_ai_assistant/screens/me_screen.dart';
import 'package:pregnancy_ai_assistant/widgets/app_nav_bar.dart';
import 'package:pregnancy_ai_assistant/widgets/suggestion_field.dart';
import 'package:pregnancy_ai_assistant/widgets/ui/illustrations.dart';
import 'package:pregnancy_ai_assistant/widgets/ui/segmented_tabs.dart';

const _testPassword = 'sunflower7';

/// One account reused by every test that needs to be past the sign-in screen.
///
/// Built once at file scope because hashing is deliberately slow - paying
/// PBKDF2's cost in each of a dozen setUps would add seconds to the suite for
/// no extra coverage.
final Account _testAccount = () {
  final salt = PasswordHash.newSalt();
  return Account(
    id: 'test-account',
    // Two words on purpose: Home greets you by first name while the Me tab
    // shows the full one, so 'Priya' stays unambiguous in the widget tree.
    name: 'Priya Sharma',
    email: 'priya@example.com',
    salt: salt,
    iterations: PasswordHash.defaultIterations,
    passwordHash: PasswordHash.hash(_testPassword, salt),
    createdAt: DateTime(2026, 1, 20),
  );
}();

/// Storage as it looks for someone who already signed in on this device.
Map<String, Object> _signedInPrefs() => {
      'flutter.account': jsonEncode(_testAccount.toJson()),
      'flutter.session_active': true,
    };

/// Same account, but locked - the state after signing out or a fresh launch
/// with the session flag cleared.
Map<String, Object> _lockedPrefs() => {
      'flutter.account': jsonEncode(_testAccount.toJson()),
      'flutter.session_active': false,
    };

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

/// Fills the sign-up form. The fields are in tree order: name, email,
/// password, confirm.
Future<void> _fillSignUp(
  WidgetTester tester, {
  required String name,
  required String password,
  String? confirm,
  String email = '',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirm ?? password);
  await tester.pump();
}

/// Taps a button on the auth forms. The test viewport is shorter than a real
/// phone, so the submit button sits below the fold - scroll to it first.
Future<void> _tapAuthButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
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
    // Default to signed in: the auth gate now stands in front of Home, and
    // every test below it is about what happens once you are through.
    SharedPreferences.setMockInitialValues(_signedInPrefs());
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
    expect(find.text('Ask about any food'), findsOneWidget);

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
    expect(find.text('Ask about any food'), findsOneWidget);
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

  testWidgets('a general profile is never told it is pregnant', (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    // The default test profile is General - no due date, no baby.
    expect(find.text('Eating well'), findsOneWidget);
    expect(find.text('General nutrition'), findsOneWidget);

    // Nothing on Home may claim a pregnancy that was never entered.
    expect(find.text('Your pregnancy'), findsNothing);
    expect(find.text('First trimester'), findsNothing);
    expect(find.textContaining('until your due date'), findsNothing);
    expect(find.textContaining('Week '), findsNothing);
  });

  testWidgets('home shows a full-colour figure, not just a faint watermark',
      (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    // The hero watermark plus the illustrated card both draw a figure, so a
    // figure must be present more than once.
    final figures = find.byWidgetPredicate(
      (w) =>
          w is MotherIllustration ||
          w is BabyIllustration ||
          w is HoldingBabyIllustration,
    );
    expect(figures, findsWidgets);

    // At least one must be full-colour (tones set), which is what makes it an
    // illustration rather than a silhouette.
    final coloured = tester.widgetList(figures).where((w) {
      if (w is MotherIllustration) return w.tones != null;
      if (w is BabyIllustration) return w.tones != null;
      if (w is HoldingBabyIllustration) return w.tones != null;
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

  testWidgets('allergy suggestions are tappable without typing first', (tester) async {
    final added = <String>[];

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SuggestionField(
          tags: const [],
          pool: kAllergySuggestions,
          hint: 'Search or type an allergy',
          tint: const Color(0xFF8C2020),
          onAdd: added.add,
          onRemove: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The whole complaint: options must be visible before any typing.
    expect(find.text('COMMON'), findsOneWidget);
    expect(find.text('Peanuts'), findsOneWidget);

    // And tapping one must add it, with no typing involved.
    await tester.tap(find.text('Peanuts'));
    await tester.pumpAndSettle();
    expect(added, ['Peanuts']);

    // "See all" opens the full list.
    expect(find.text('See all'), findsOneWidget);
  });

  testWidgets('all three profile fields offer tappable options up front',
      (tester) async {
    // Allergies, dietary preferences and health conditions share one widget,
    // so this guards against any of them regressing to a bare text box.
    final cases = <String, (List<String>, String)>{
      'allergies': (kAllergySuggestions, 'Peanuts'),
      'dietary': (kDietarySuggestions, 'Vegetarian'),
      'conditions': (kConditionSuggestions, 'Gestational diabetes'),
    };

    for (final entry in cases.entries) {
      final (pool, expectedChip) = entry.value;
      final added = <String>[];

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SuggestionField(
            tags: const [],
            pool: pool,
            hint: 'Search or type',
            tint: const Color(0xFF7B6FE0),
            onAdd: added.add,
            onRemove: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('COMMON'), findsOneWidget,
          reason: '${entry.key}: options should show before typing');
      expect(find.text('See all'), findsOneWidget,
          reason: '${entry.key}: full list should be reachable');
      expect(find.text(expectedChip), findsOneWidget,
          reason: '${entry.key}: expected $expectedChip among the first options');

      await tester.tap(find.text(expectedChip));
      await tester.pumpAndSettle();
      expect(added, [expectedChip], reason: '${entry.key}: tap should add it');
    }
  });

  testWidgets('See all opens a searchable multi-select list', (tester) async {
    final added = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SuggestionField(
          tags: const [],
          pool: kDietarySuggestions,
          hint: 'Search or type a preference',
          tint: const Color(0xFF7B6FE0),
          onAdd: added.add,
          onRemove: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    // The chips behind the sheet still hold the same labels, so scope every
    // lookup to the sheet itself.
    Finder inSheet(String label) => find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(label),
        );

    // Options beyond the first few are reachable only through this sheet.
    expect(inSheet('Low FODMAP'), findsOneWidget);

    // Several can be ticked before committing.
    await tester.tap(inSheet('Vegan'));
    await tester.tap(inSheet('Low FODMAP'));
    await tester.pumpAndSettle();
    expect(find.text('Add 2 selected'), findsOneWidget);

    await tester.tap(find.text('Add 2 selected'));
    await tester.pumpAndSettle();
    expect(added, containsAll(['Vegan', 'Low FODMAP']));
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

  // ---- Care plan: to-do, supplements, doctor notes ----

  test('the to-do list follows the stage, and every task explains itself', () {
    List<CareSection> at(UserProfile profile) => careTasksFor(profile);

    UserProfile pregnantAt(int week) => UserProfile(
          lifeStage: LifeStage.pregnancy,
          dueDate: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day + (40 - week) * 7,
          ),
        );

    // Current trimester leads.
    expect(at(pregnantAt(8)).first.title, 'First trimester');
    expect(at(pregnantAt(20)).first.title, 'Second trimester');
    expect(at(pregnantAt(34)).first.title, 'Third trimester');
    // Late pregnancy gets the newborn list too - too late to read it after.
    expect(at(pregnantAt(34)).any((s) => s.title == 'What your baby needs'), isTrue);

    // Newborn leads once the baby is here.
    final newborn = at(UserProfile(
      lifeStage: LifeStage.breastfeeding,
      babyBirthDate: DateTime.now().subtract(const Duration(days: 20)),
    ));
    expect(newborn.first.title, 'What your baby needs');

    // General nutrition has no antenatal to-do list at all.
    expect(at(UserProfile()), isEmpty);

    // Every task, in every list, is unique and says what and why.
    final all = [
      ...at(pregnantAt(8)),
      ...at(pregnantAt(20)),
      ...at(pregnantAt(34)),
      ...newborn,
    ].expand((s) => s.tasks).toList();
    final ids = all.map((t) => t.id).toSet();
    for (final task in all) {
      expect(task.title, isNotEmpty);
      expect(task.detail, isNotEmpty, reason: '${task.id} has no explanation');
    }
    expect(ids.length, greaterThan(20));
  });

  test('supplements cover omega-3 and flag what needs a doctor', () {
    final pregnancy = supplementsFor(UserProfile(
      lifeStage: LifeStage.pregnancy,
      dueDate: DateTime.now().add(const Duration(days: 100)),
    ));

    final byId = {for (final s in pregnancy) s.id: s};
    expect(byId.keys, contains('s_folic'));
    expect(byId.keys, contains('s_omega'));
    expect(byId.keys, contains('s_vitd'));

    final omega = byId['s_omega']!;
    expect(omega.name, contains('Omega-3'));
    expect(omega.foodSources.toLowerCase(), contains('salmon'));
    // The one genuinely dangerous mistake with omega-3 in pregnancy.
    expect(omega.warning.toLowerCase(), contains('cod liver oil'));

    // Iron is dose-by-bloods, not something to start on your own.
    expect(byId['s_iron']!.confirmWithDoctor, isTrue);
    // Folic acid is not - everyone takes it, and hedging it would be harmful.
    expect(byId['s_folic']!.confirmWithDoctor, isFalse);

    // Babies get their own list, headed by vitamin D drops.
    final baby = supplementsFor(UserProfile(
      lifeStage: LifeStage.breastfeeding,
      babyBirthDate: DateTime.now().subtract(const Duration(days: 10)),
    ));
    expect(baby.first.id, 'bs_vitd');
    expect(baby.first.dose, contains('400 IU'));

    // General nutrition gets no pregnancy supplement advice.
    expect(supplementsFor(UserProfile()), isEmpty);

    // And the avoid list exists, because it is the part that prevents harm.
    expect(kSupplementsToAvoid.join(' ').toLowerCase(), contains('retinol'));
  });

  test('doctor notes stay separated by subject and survive storage', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();
    final care = CareController(storage);
    await care.load();

    expect(care.hasBabyNotes, isFalse);
    expect(care.hasMotherNotes, isFalse);

    await care.saveNote(DoctorNote(
      id: 'n1',
      subject: NoteSubject.mother,
      title: '20 week scan',
      body: 'All measurements normal. Anterior placenta.',
      visitedAt: DateTime(2026, 3, 2),
      clinician: 'Dr Rao',
      nextAppointment: DateTime.now().add(const Duration(days: 28)),
    ));
    await care.saveNote(DoctorNote(
      id: 'n2',
      subject: NoteSubject.baby,
      title: '6 week check',
      body: 'Hips and heart fine. Continue vitamin D drops.',
      visitedAt: DateTime(2026, 7, 15),
    ));

    expect(care.hasMotherNotes, isTrue);
    expect(care.hasBabyNotes, isTrue);
    expect(care.notesFor(NoteSubject.baby).single.title, '6 week check');
    expect(care.notesFor(NoteSubject.mother).single.clinician, 'Dr Rao');

    // Newest first - the last thing you were told is what you are looking for.
    expect(care.notes.first.id, 'n2');

    // The upcoming appointment is found across both subjects.
    expect(care.nextAppointment?.id, 'n1');

    final reloaded = CareController(storage);
    await reloaded.load();
    expect(reloaded.notes.length, 2);
    expect(reloaded.notesFor(NoteSubject.baby).single.body, contains('vitamin D'));

    await reloaded.removeNote(reloaded.notesFor(NoteSubject.baby).single);
    expect(reloaded.hasBabyNotes, isFalse);
  });

  test('a past appointment is not reported as upcoming', () {
    final past = DoctorNote(
      id: 'x',
      subject: NoteSubject.mother,
      title: 'Booking',
      body: 'Bloods taken.',
      visitedAt: DateTime(2026, 1, 5),
      nextAppointment: DateTime(2026, 1, 20),
    );
    expect(past.hasUpcoming, isFalse);

    final future = past.copyWith(
      nextAppointment: DateTime.now().add(const Duration(days: 3)),
    );
    expect(future.hasUpcoming, isTrue);

    // Round trip keeps both dates and the subject.
    final restored = DoctorNote.fromJson(future.toJson());
    expect(restored.subject, NoteSubject.mother);
    expect(restored.visitedAt, DateTime(2026, 1, 5));
    expect(restored.hasUpcoming, isTrue);
  });

  test('care task ticks persist', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();
    final care = CareController(storage);
    await care.load();

    expect(care.isDone('t1_folic'), isFalse);
    await care.toggleTask('t1_folic');
    expect(care.isDone('t1_folic'), isTrue);

    final reloaded = CareController(storage);
    await reloaded.load();
    expect(reloaded.isDone('t1_folic'), isTrue);

    await reloaded.toggleTask('t1_folic');
    expect(reloaded.isDone('t1_folic'), isFalse);
  });

  testWidgets('the baby tab points at a doctor, not at an AI companion',
      (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _tapNav(tester, 'Baby');

    // What the tab offers now: your paediatrician, and what they told you.
    expect(find.text('Ask your paediatrician'), findsOneWidget);
    expect(find.text('Nothing from your doctor yet'), findsOneWidget);
    expect(find.text('Add doctor notes'), findsOneWidget);

    // Growth sits below the photo banner now, so scroll rather than assume.
    await tester.scrollUntilVisible(find.text('Growth'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Growth'), findsOneWidget);

    // And what it must never offer again: a chat that answers questions about
    // a specific baby without anyone having examined that baby.
    expect(find.text('24/7 baby companion'), findsNothing);
    expect(find.text('Ask anything, any time'), findsNothing);
    expect(find.text('When can my baby start solids?'), findsNothing);
    expect(find.text('Is my baby feeding enough?'), findsNothing);
  });

  // ---- Emergency contacts ----

  test('emergency contacts sort by urgency, not by when they were added',
      () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();
    final controller = EmergencyController(storage);
    await controller.load();

    expect(controller.isEmpty, isTrue);

    // Added in the order a real person would think of them.
    await controller.save(const EmergencyContact(
      id: '1',
      kind: ContactKind.person,
      name: 'Arjun',
      phone: '+91 98765 43210',
      relationship: 'Husband',
    ));
    await controller.save(const EmergencyContact(
      id: '2',
      kind: ContactKind.doctor,
      name: 'Dr Rao',
      phone: '044 2345 6789',
    ));
    await controller.save(const EmergencyContact(
      id: '3',
      kind: ContactKind.hospital,
      name: 'City Maternity',
      phone: '044 1111 2222',
      notes: 'Ask for the labour ward',
    ));

    // Read back in the order you would need them at 3am.
    expect(
      controller.contacts.map((c) => c.name).toList(),
      ['City Maternity', 'Dr Rao', 'Arjun'],
    );

    // Editing keeps the id, so it replaces rather than duplicating.
    await controller.save(
      controller.contacts.first.copyWith(phone: '044 3333 4444'),
    );
    expect(controller.contacts.length, 3);
    expect(controller.contacts.first.phone, '044 3333 4444');

    final reloaded = EmergencyController(storage);
    await reloaded.load();
    expect(reloaded.contacts.length, 3);
    expect(reloaded.contacts.first.notes, 'Ask for the labour ward');

    await reloaded.remove(reloaded.contacts.first);
    expect(reloaded.contacts.length, 2);
  });

  test('the national emergency number follows the region', () {
    expect(emergencyNumberFor('IN'), '112');
    expect(emergencyNumberFor('US'), '911');
    expect(emergencyNumberFor('GB'), '999');
    expect(emergencyNumberFor('AU'), '000');
    // Unknown region falls back to 112, which works across the EU and on any
    // GSM phone - a safer default than guessing.
    expect(emergencyNumberFor('XX'), '112');
  });

  test('warning signs are stage-specific and every one says why', () {
    expect(kPregnancyWarningSigns, isNotEmpty);
    expect(kBabyWarningSigns, isNotEmpty);

    for (final sign in [...kPregnancyWarningSigns, ...kBabyWarningSigns]) {
      expect(sign.sign, isNotEmpty);
      expect(sign.why, isNotEmpty, reason: '"${sign.sign}" has no explanation');
    }

    // The two lists must not be the same advice with different headings.
    final pregnancy = kPregnancyWarningSigns.map((s) => s.sign).toSet();
    final baby = kBabyWarningSigns.map((s) => s.sign).toSet();
    expect(pregnancy.intersection(baby), isEmpty);

    // The two that matter most for this app's users.
    expect(
      pregnancy.any((s) => s.toLowerCase().contains('moving less')),
      isTrue,
      reason: 'reduced fetal movement must be on the pregnancy list',
    );
    expect(
      baby.any((s) => s.toLowerCase().contains('fever')),
      isTrue,
      reason: 'newborn fever must be on the baby list',
    );
  });

  testWidgets('emergency is one tap from home and shows a callable number',
      (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    // Straight off the hero, not buried in a settings menu.
    await tester.tap(find.byIcon(Icons.emergency_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Emergency'), findsWidgets);
    expect(find.textContaining('Call '), findsWidgets);
    expect(find.text('No contacts yet'), findsOneWidget);
    // Pregnancy list by default, since the test profile has no baby.
    expect(find.text('Baby moving less than usual'), findsOneWidget);
  });

  // ---- Food log: typed and scanned foods ----

  test('a typed food carries its own nutrients, a built-in one looks them up', () {
    // Built-in: no numbers stored, resolved through the table.
    final picked = NutritionEntry(
      id: '1',
      foodName: 'Lentils (1 cup cooked)',
      servings: 2,
    );
    expect(picked.perServing, isNull);
    expect(picked.hasNutrients, isTrue);
    expect(picked.nutrients.ironMg, closeTo(13.2, 0.01));
    expect(picked.isEstimated, isFalse);

    // Typed: nothing in the table to fall back on, so the numbers have to
    // live on the entry or they are lost.
    final typed = NutritionEntry(
      id: '2',
      foodName: 'rajma chawal',
      servings: 2,
      perServing: const NutrientProfile(ironMg: 3.2, proteinG: 12),
      servingDescription: '1 bowl (300g)',
      source: NutritionSource.typed,
    );
    expect(typed.hasNutrients, isTrue);
    expect(typed.nutrients.ironMg, closeTo(6.4, 0.01));
    expect(typed.isEstimated, isTrue);

    // A food with neither is still a valid record of what was eaten, but it
    // must not pretend to contribute nothing silently.
    final unknown = NutritionEntry(id: '3', foodName: 'grandma soup', servings: 1);
    expect(unknown.hasNutrients, isFalse);
    expect(unknown.nutrients.isEmpty, isTrue);
  });

  test('typed and scanned entries survive a round trip through storage', () {
    final entry = NutritionEntry(
      id: '9',
      foodName: 'idli sambar',
      servings: 3,
      perServing: const NutrientProfile(
        ironMg: 1.4,
        calciumMg: 60,
        folateMcg: 30,
        proteinG: 6.2,
        vitaminDMcg: 0,
      ),
      servingDescription: '2 idlis with sambar (220g)',
      source: NutritionSource.scanned,
      loggedAt: DateTime(2026, 8, 6, 13, 30),
    );

    final restored = NutritionEntry.fromJson(entry.toJson());

    expect(restored.foodName, 'idli sambar');
    expect(restored.source, NutritionSource.scanned);
    expect(restored.servingDescription, '2 idlis with sambar (220g)');
    expect(restored.perServing!.calciumMg, 60);
    expect(restored.nutrients.proteinG, closeTo(18.6, 0.01));

    // Entries written before typing and scanning existed have neither field,
    // and must still resolve through the built-in table rather than crash.
    final legacy = NutritionEntry.fromJson({
      'id': '10',
      'food_name': 'Tofu (1/2 cup)',
      'servings': 1,
      'logged_at': DateTime(2026, 1, 1).toIso8601String(),
    });
    expect(legacy.source, NutritionSource.picked);
    expect(legacy.perServing, isNull);
    expect(legacy.nutrients.calciumMg, 253);
  });

  test('a nutrient estimate parses the API shape, including a refusal', () {
    final estimate = NutrientEstimate.fromJson(const {
      'food_name': 'poha',
      'serving_description': '1 cup (150g)',
      'iron_mg': 2.7,
      'calcium_mg': 12.0,
      'folate_mcg': 8.0,
      'protein_g': 4.1,
      'vitamin_d_mcg': 0.0,
      'is_estimate': true,
      'note': 'Assumes iron-fortified flattened rice.',
      'recognised': true,
    });

    expect(estimate.foodName, 'poha');
    expect(estimate.perServing.ironMg, 2.7);
    expect(estimate.servingDescription, '1 cup (150g)');
    expect(estimate.isEstimate, isTrue);

    // Not a food: zeros plus an explanation, not a silent row of nothing.
    final refusal = NutrientEstimate.fromJson(const {
      'food_name': 'asdfgh',
      'recognised': false,
      'note': 'That does not appear to be a food.',
    });
    expect(refusal.recognised, isFalse);
    expect(refusal.perServing.isEmpty, isTrue);
  });

  test('the log controller totals only the requested day', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final controller = NutritionController(LocalStorageService());
    await controller.load();

    await controller.add(NutritionEntry(
      id: 'a',
      foodName: 'Spinach (1 cup cooked)',
      servings: 1,
    ));
    await controller.add(NutritionEntry(
      id: 'b',
      foodName: 'poha',
      servings: 2,
      perServing: const NutrientProfile(ironMg: 2.5),
      source: NutritionSource.typed,
    ));
    // Yesterday's food must not inflate today's rings.
    await controller.add(NutritionEntry(
      id: 'c',
      foodName: 'Fortified cereal (1 cup)',
      servings: 1,
      loggedAt: DateTime.now().subtract(const Duration(days: 1)),
    ));

    expect(controller.today.length, 2);
    expect(controller.todayTotal.ironMg, closeTo(6.4 + 5.0, 0.01));

    await controller.remove(controller.today.first);
    expect(controller.today.length, 1);

    // And it is actually persisted, not just held in memory.
    final reloaded = NutritionController(LocalStorageService());
    await reloaded.load();
    expect(reloaded.today.length, 1);
    expect(reloaded.entries.length, 2);
  });

  // ---- Location-aware shopping ----

  testWidgets('the Shop tab lists things to buy and where to buy them',
      (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _tapNav(tester, 'Plan');
    await tester.tap(find.descendant(
      of: find.byType(SegmentedTabs),
      matching: find.text('Shop'),
    ));
    await tester.pumpAndSettle();

    // The location-aware half: a region, and searches phrased for it.
    expect(find.text('FIND NEAR ME'), findsOneWidget);
    expect(find.text('Baby store'), findsOneWidget);

    // Counter first, while it is still on screen - the list is lazy, so
    // anything scrolled past stops being built.
    expect(find.text('3 to look at'), findsOneWidget);

    // Then scroll past the photo banner to reach the basket and tick one.
    await tester.scrollUntilVisible(find.text('Food basket near you'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Food basket near you'), findsOneWidget);

    await tester.tap(find.textContaining('Iron:').first);
    await tester.pumpAndSettle();

    // Back up to read the counter again.
    await tester.scrollUntilVisible(find.text('1 of 3 ticked off'), -300);
    await tester.pumpAndSettle();
    expect(find.text('1 of 3 ticked off'), findsOneWidget);
  });

  test('region is guessed from the device locale, never from GPS', () {
    expect(regionForCountry('IN').name, 'India');
    expect(regionForCountry('BD').name, 'India');
    expect(regionForCountry('gb').pharmacyTerm, 'chemist');
    expect(regionForCountry('US').pharmacyTerm, 'pharmacy');
    expect(regionForCountry('MY').name, 'Southeast Asia');

    // Anywhere unmapped, and a device that reports no country at all, must
    // still land somewhere usable rather than on an empty list.
    expect(regionForCountry('BR').name, 'International');
    expect(regionForCountry(null).name, 'International');
    expect(regionForCountry('').ironFoods, isNotEmpty);
  });

  test('the food basket changes with the region, the advice does not', () {
    final profile = UserProfile(
      lifeStage: LifeStage.pregnancy,
      dueDate: DateTime.now().add(const Duration(days: 120)),
    );

    final india = shoppingFor(profile, regionByCode('IN'));
    final uk = shoppingFor(profile, regionByCode('GB'));

    String basket(List<ShoppingSection> sections) => sections
        .firstWhere((s) => s.title == 'Food basket near you')
        .items
        .map((i) => i.name)
        .join(' ');

    expect(basket(india), contains('ragi'));
    expect(basket(uk), contains('fortified breakfast cereal'));
    expect(basket(india), isNot(contains('fortified breakfast cereal')));

    // Everything else is the same list - nutrition does not change by border.
    List<String> nonFood(List<ShoppingSection> s) => s
        .where((section) => section.title != 'Food basket near you')
        .expand((section) => section.items)
        .map((i) => i.id)
        .toList();
    expect(nonFood(india), nonFood(uk));
  });

  test('the list follows the stage, and the hospital bag arrives in time', () {
    ShoppingItem? find(List<ShoppingSection> sections, String id) {
      for (final section in sections) {
        for (final item in section.items) {
          if (item.id == id) return item;
        }
      }
      return null;
    }

    List<ShoppingSection> atWeek(int week) => shoppingFor(
          UserProfile(
            lifeStage: LifeStage.pregnancy,
            dueDate: DateTime.now().add(Duration(days: (40 - week) * 7)),
          ),
          regionByCode('XX'),
        );

    expect(find(atWeek(8), 'p_prenatal'), isNotNull);
    expect(find(atWeek(20), 'p_prenatal'), isNull, reason: 'first-trimester only');
    expect(find(atWeek(20), 'p_maternity_clothes'), isNotNull);
    expect(find(atWeek(34), 'p_nursing_bra'), isNotNull);

    // Packed by 36 weeks means it has to appear well before 36.
    expect(find(atWeek(28), 'h_car_seat'), isNull);
    expect(find(atWeek(30), 'h_car_seat'), isNotNull);
    expect(find(atWeek(38), 'h_car_seat'), isNotNull);

    // Once the baby is here it is a baby list, whatever the old due date says.
    final withBaby = shoppingFor(
      UserProfile(
        lifeStage: LifeStage.breastfeeding,
        dueDate: DateTime.now().subtract(const Duration(days: 200)),
        babyBirthDate: DateTime.now().subtract(const Duration(days: 220)),
      ),
      regionByCode('XX'),
    );
    expect(find(withBaby, 'p_prenatal'), isNull);
    // ~7 months old, so weaning kit rather than newborn restocking.
    expect(find(withBaby, 'b_open_cup'), isNotNull);
  });

  test('a general profile still gets the food basket and nothing pregnancy-specific', () {
    final sections = shoppingFor(UserProfile(), regionByCode('IN'));

    expect(sections.length, 1);
    expect(sections.single.title, 'Food basket near you');
  });

  test('ticked items persist and survive a region change', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();

    final controller = ShoppingController(storage, deviceCountryCode: 'IN');
    await controller.load();

    // Guessed, not chosen - the UI wording depends on telling these apart.
    expect(controller.region.code, 'IN');
    expect(controller.regionWasChosen, isFalse);

    await controller.toggle('p_prenatal');
    expect(controller.isChecked('p_prenatal'), isTrue);

    await controller.setRegion(regionByCode('GB'));
    expect(controller.regionWasChosen, isTrue);
    // Changing where you shop must not wipe what you already bought.
    expect(controller.isChecked('p_prenatal'), isTrue);

    final reloaded = ShoppingController(storage, deviceCountryCode: 'US');
    await reloaded.load();
    // The stored choice wins over the device locale.
    expect(reloaded.region.code, 'GB');
    expect(reloaded.isChecked('p_prenatal'), isTrue);

    await reloaded.clearChecked();
    expect(reloaded.isChecked('p_prenatal'), isFalse);
  });

  test('every shopping item has a stable unique id and a reason', () {
    final profiles = [
      UserProfile(),
      UserProfile(
        lifeStage: LifeStage.pregnancy,
        dueDate: DateTime.now().add(const Duration(days: 250)),
      ),
      UserProfile(
        lifeStage: LifeStage.pregnancy,
        dueDate: DateTime.now().add(const Duration(days: 40)),
      ),
      UserProfile(
        lifeStage: LifeStage.breastfeeding,
        babyBirthDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserProfile(
        lifeStage: LifeStage.breastfeeding,
        babyBirthDate: DateTime.now().subtract(const Duration(days: 500)),
      ),
    ];

    for (final profile in profiles) {
      for (final region in kShoppingRegions) {
        final items = shoppingFor(profile, region).expand((s) => s.items).toList();
        final ids = items.map((i) => i.id).toList();

        expect(ids.toSet().length, ids.length,
            reason: 'duplicate id would tick two rows at once');
        for (final item in items) {
          expect(item.why, isNotEmpty, reason: '${item.id} has no reason given');
          expect(item.name, isNotEmpty);
        }
      }
    }
  });

  // ---- Weekly milestone updates ----

  test('pregnancy week boundaries match the week the rest of the app shows', () {
    final due = DateTime(2026, 12, 1);

    // Week 40 starts on the due date, and each week back is exactly 7 days.
    expect(pregnancyWeekStart(due, 40), DateTime(2026, 12, 1));
    expect(pregnancyWeekStart(due, 39), DateTime(2026, 11, 24));
    expect(pregnancyWeekStart(due, 20), DateTime(2026, 7, 14));

    // The real check: on the day a milestone fires, UserProfile must already
    // agree it is that week. If these drift, the app announces a week it is
    // not showing. Anchored to today, since pregnancyWeek reads the clock.
    final today = DateTime.now();
    for (final week in [12, 20, 28, 36, 40]) {
      // Calendar arithmetic, for the same reason the app uses it: adding
      // 196 * 24h from an August evening lands on the previous date once the
      // clocks go back.
      final dueForToday = DateTime(today.year, today.month, today.day + (40 - week) * 7);
      final profile = UserProfile(lifeStage: LifeStage.pregnancy, dueDate: dueForToday);

      expect(profile.pregnancyWeek, week);
      expect(
        pregnancyWeekStart(dueForToday, week),
        DateTime(today.year, today.month, today.day),
        reason: 'week $week should begin today for this due date',
      );
    }
  });

  test('baby month boundaries survive short months', () {
    // Born on the 31st: February has no 31st, so it lands on the 28th rather
    // than rolling into March.
    final born = DateTime(2026, 1, 31);
    expect(babyMonthStart(born, 1), DateTime(2026, 2, 28));
    expect(babyMonthStart(born, 2), DateTime(2026, 3, 31));
    expect(babyMonthStart(born, 12), DateTime(2027, 1, 31));
  });

  test('milestones are scheduled forward only, in order, with real content', () {
    final now = DateTime(2026, 8, 6, 12);
    final profile = UserProfile(
      lifeStage: LifeStage.pregnancy,
      // Roughly 22 weeks along.
      dueDate: now.add(const Duration(days: 18 * 7)),
    );

    final milestones = upcomingMilestones(profile, from: now, hour: 9);

    expect(milestones, isNotEmpty);
    expect(milestones.first.when.isAfter(now), isTrue);
    expect(milestones.first.when.hour, 9);

    for (var i = 1; i < milestones.length; i++) {
      expect(milestones[i].when.isAfter(milestones[i - 1].when), isTrue,
          reason: 'milestones must be in date order');
      expect(milestones[i].index, milestones[i - 1].index + 1);
    }

    // Every one carries this week's own text - a repeating alarm could not.
    final bodies = milestones.map((m) => m.body).toSet();
    expect(bodies.length, milestones.length);
    expect(milestones.first.title, contains('Week'));
    expect(milestones.last.index, 42);

    // Ids never collide with the reminder range.
    for (final m in milestones) {
      expect(m.notificationId, greaterThanOrEqualTo(Milestone.idBase));
      expect(m.notificationId, lessThanOrEqualTo(Milestone.idMax));
    }
  });

  test('the baby takes over from the due date once born', () {
    final now = DateTime(2026, 8, 6, 12);
    final profile = UserProfile(
      lifeStage: LifeStage.breastfeeding,
      // A stale due date left on the profile must not resurrect week updates.
      dueDate: DateTime(2026, 6, 1),
      babyBirthDate: DateTime(2026, 6, 3),
    );

    final milestones = upcomingMilestones(profile, from: now);

    expect(milestones, isNotEmpty);
    expect(
      milestones.every((m) => m.kind == MilestoneKind.babyMonth),
      isTrue,
    );
    // Two months old on 3 August, so the next one due is month 3.
    expect(milestones.first.index, 3);
    expect(milestones.first.body, contains('Feeding:'));
  });

  test('a profile with no dates schedules nothing at all', () {
    final now = DateTime(2026, 8, 6);

    expect(upcomingMilestones(UserProfile(), from: now), isEmpty);
    expect(
      upcomingMilestones(UserProfile(lifeStage: LifeStage.pregnancy), from: now),
      isEmpty,
    );
    // General nutrition with a due date left over is not a pregnancy.
    expect(
      upcomingMilestones(
        UserProfile(lifeStage: LifeStage.general, dueDate: DateTime(2027, 1, 1)),
        from: now,
      ),
      isEmpty,
    );
  });

  test('milestone updates stay off until asked for, and persist once on', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();
    final profile = UserProfile(
      lifeStage: LifeStage.pregnancy,
      dueDate: DateTime.now().add(const Duration(days: 100)),
    );
    await storage.saveProfile(profile);

    final controller = MilestoneController(storage);
    await controller.load();

    // Off by default: an app that starts notifying uninvited gets muted.
    expect(controller.settings.enabled, isFalse);
    expect(controller.scheduled, isEmpty);

    await controller.setTime(7, 30, profile);
    await controller.setEnabled(true, profile);

    expect(controller.settings.enabled, isTrue);
    expect(controller.scheduled, isNotEmpty);
    expect(controller.next!.when.hour, 7);
    expect(controller.next!.when.minute, 30);

    final reloaded = MilestoneController(storage);
    await reloaded.load();
    expect(reloaded.settings.enabled, isTrue);
    expect(reloaded.settings.hour, 7);
    expect(reloaded.next, isNotNull);
  });

  test('every baby month has usable reference data', () {
    expect(kBabyMonths.length, 25);

    for (var i = 0; i < kBabyMonths.length; i++) {
      final month = kBabyMonths[i];
      expect(month.month, i, reason: 'months must be contiguous from 0');
      expect(month.development, isNotEmpty);
      expect(month.feeding, isNotEmpty);
      expect(month.parentExperience, isNotEmpty);
      expect(month.emoji, isNotEmpty);
    }

    // Solids start at 6 months - the single fact this dataset must not get
    // wrong, since every feeding answer keys off it.
    expect(babyMonthInfo(5).onSolids, isFalse);
    expect(babyMonthInfo(6).onSolids, isTrue);
    expect(babyMonthInfo(6).feeding.toLowerCase(), contains('iron'));
    // Out of range still returns something rather than throwing.
    expect(babyMonthInfo(99).month, 24);
  });

  // ---- Cloud accounts (AWS Cognito) ----

  test('cloud mode is off unless the build was given a pool', () {
    // A fresh clone and local development must work with no AWS at all.
    expect(CognitoClient.isConfigured, isFalse);
    expect(AuthController(LocalStorageService()).isCloud, isFalse);
  });

  test('cloud password rules match what Cognito will enforce', () {
    // Checked on the client so the person is told while they are typing,
    // rather than after a round trip that returns a generic refusal.
    expect(AuthController.validateCloudPassword('short1A'), isNotNull);
    expect(AuthController.validateCloudPassword('alllowercase1'), contains('uppercase'));
    expect(AuthController.validateCloudPassword('ALLUPPERCASE1'), contains('lowercase'));
    expect(AuthController.validateCloudPassword('NoDigitsHere'), contains('number'));
    expect(AuthController.validateCloudPassword('Sunflower7'), isNull);

    // Email is optional on a device account and required in the cloud.
    expect(AuthController.validateEmail(''), isNull);
    expect(AuthController.validateRequiredEmail(''), isNotNull);
    expect(AuthController.validateRequiredEmail('not-an-email'), isNotNull);
    expect(AuthController.validateRequiredEmail('a@b.co'), isNull);
  });

  test('cognito errors become messages a person can act on', () {
    CognitoException parse(String type, [String message = '']) =>
        CognitoException.fromResponse({'__type': type, 'message': message});

    // A namespaced type still resolves.
    expect(parse('#UserNotConfirmedException').needsConfirmation, isTrue);
    expect(parse('UsernameExistsException').userExists, isTrue);

    // Wrong password and unknown email must read identically - saying which
    // is which tells a stranger whose email has an account here.
    expect(
      parse('NotAuthorizedException').message,
      parse('UserNotFoundException').message,
    );

    expect(parse('CodeMismatchException').message.toLowerCase(), contains('code'));
    expect(parse('ExpiredCodeException').message.toLowerCase(), contains('expired'));
    expect(parse('LimitExceededException').message.toLowerCase(), contains('too many'));

    // An unmapped type falls back to whatever Cognito said rather than a
    // blank message.
    expect(parse('SomeNewException', 'Details here').message, 'Details here');
  });

  test('cognito tokens round-trip and expire a minute early', () {
    final tokens = CognitoTokens.fromAuthResult({
      'AccessToken': 'a',
      'IdToken': 'i',
      'RefreshToken': 'r',
      'ExpiresIn': 3600,
    });
    expect(tokens.isExpired, isFalse);

    final restored = CognitoTokens.fromJson(tokens.toJson());
    expect(restored.accessToken, 'a');
    expect(restored.refreshToken, 'r');

    // A refresh response carries no refresh token; the old one stays valid.
    final refreshed = CognitoTokens.fromAuthResult(
      {'AccessToken': 'a2', 'IdToken': 'i2', 'ExpiresIn': 3600},
      fallbackRefreshToken: 'r',
    );
    expect(refreshed.refreshToken, 'r');

    // Anything inside the last minute counts as expired, so a token never
    // leaves on a request that outlives it.
    final almost = CognitoTokens(
      accessToken: 'a',
      idToken: 'i',
      refreshToken: 'r',
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
    );
    expect(almost.isExpired, isTrue);
  });

  // ---- Device-only account ----

  testWidgets('a device with no account opens on sign-up, not on Home', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    expect(find.text('Create your account'), findsOneWidget);
    // Home must not be reachable behind it.
    expect(find.byType(AppNavBar), findsNothing);
    expect(find.text('Ask about any food'), findsNothing);
  });

  testWidgets('creating an account signs you straight into Home', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _fillSignUp(tester, name: 'Asha Verma', password: 'lemontree1');
    await _tapAuthButton(tester, 'Create account');

    // Greeted by first name, and the whole app is available - no second
    // "now sign in" step with the password just chosen.
    expect(find.text('Asha'), findsOneWidget);
    expect(find.byType(AppNavBar), findsOneWidget);

    // And it survives a restart, because the account was persisted.
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);
    expect(find.text('Asha'), findsOneWidget);
  });

  testWidgets('sign-up refuses a short password and a mismatched confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _fillSignUp(tester, name: 'Asha Verma', password: 'abc', confirm: 'abc');
    await _tapAuthButton(tester, 'Create account');

    expect(find.text('Use at least 6 characters'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);

    await _fillSignUp(tester, name: 'Asha Verma', password: 'lemontree1', confirm: 'lemontre');
    await _tapAuthButton(tester, 'Create account');

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);
  });

  testWidgets('a locked device asks for the password before showing anything',
      (tester) async {
    SharedPreferences.setMockInitialValues(_lockedPrefs());

    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    expect(find.text('Welcome back, Priya'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);

    // Wrong password says so and keeps the door shut.
    await tester.enterText(find.byType(TextField), 'not-the-password');
    await _tapAuthButton(tester, 'Sign in');

    expect(find.text('That password does not match'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);

    // The right one opens it.
    await tester.enterText(find.byType(TextField), _testPassword);
    await _tapAuthButton(tester, 'Sign in');

    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
  });

  testWidgets('sign out is reachable from Me without opening Account',
      (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _tapNav(tester, 'Me');
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      300,
      scrollable: find
          .descendant(of: find.byType(MeScreen), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    // Confirms first - a stray tap must not lock someone out mid-task.
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Sign out'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Priya'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);
  });

  testWidgets('signing out locks the app but keeps the account', (tester) async {
    await tester.pumpWidget(const PregnancyAiApp());
    await _settleHome(tester);

    await _tapNav(tester, 'Me');
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('priya@example.com'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    // Confirm in the dialog - the tile and the dialog button share a label.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Sign out'),
    ));
    await tester.pumpAndSettle();

    // Back to the lock screen, still knowing who you are.
    expect(find.text('Welcome back, Priya'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);
    // Not the sign-up form: the account is intact.
    expect(find.text('Create your account'), findsNothing);
  });

  test('password hashing never stores the password and rejects wrong ones', () {
    const password = 'sunflower7';
    final salt = PasswordHash.newSalt();
    final hash = PasswordHash.hash(password, salt);

    expect(hash, isNot(contains(password)));
    expect(PasswordHash.verify(password, salt, hash), isTrue);
    expect(PasswordHash.verify('sunflower8', salt, hash), isFalse);

    // A different salt for the same password gives a different hash, so two
    // people picking the same password don't look identical in storage.
    expect(PasswordHash.hash(password, PasswordHash.newSalt()), isNot(hash));
  });

  test('clearing local data leaves the account signed in', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();

    final auth = AuthController(storage);
    await auth.load();
    expect(auth.status, AuthStatus.signedIn);

    await storage.saveProfile(UserProfile(lifeStage: LifeStage.pregnancy));
    await auth.clearDataKeepingAccount();

    // The data is gone...
    expect(await storage.loadProfile(), isNull);
    // ...but a relaunch still finds the account and the open session.
    final reloaded = AuthController(storage);
    await reloaded.load();
    expect(reloaded.status, AuthStatus.signedIn);
    expect(reloaded.account?.name, 'Priya Sharma');
  });

  test('deleting the account erases everything it owned', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final storage = LocalStorageService();

    final auth = AuthController(storage);
    await auth.load();
    await storage.saveProfile(UserProfile(lifeStage: LifeStage.pregnancy));

    await auth.deleteAccountAndData();

    expect(auth.status, AuthStatus.needsSignUp);
    expect(await storage.loadProfile(), isNull);
    expect(await storage.loadAccount(), isNull);
  });

  test('changing the password invalidates the old one', () async {
    SharedPreferences.setMockInitialValues(_signedInPrefs());
    final auth = AuthController(LocalStorageService());
    await auth.load();

    expect(
      await auth.changePassword(currentPassword: 'wrong', newPassword: 'newpassword1'),
      'Your current password does not match',
    );

    expect(
      await auth.changePassword(currentPassword: _testPassword, newPassword: 'newpassword1'),
      isNull,
    );

    await auth.signOut();
    expect(await auth.signIn(_testPassword), 'That password does not match');
    expect(await auth.signIn('newpassword1'), isNull);
    expect(auth.status, AuthStatus.signedIn);
  });

  test('account validation covers the optional email', () {
    expect(AuthController.validateName(' '), isNotNull);
    expect(AuthController.validateName('Asha'), isNull);

    // Blank is fine - the field is optional. Malformed is not.
    expect(AuthController.validateEmail(''), isNull);
    expect(AuthController.validateEmail('asha@example.com'), isNull);
    expect(AuthController.validateEmail('asha@example'), isNotNull);
    expect(AuthController.validateEmail('asha.example.com'), isNotNull);
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
