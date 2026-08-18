import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_entry.dart';
import '../models/nutrition_log.dart';
import '../models/pregnancy_week.dart';
import '../models/reminder.dart';
import '../models/user_profile.dart';
import '../services/local_storage_service.dart';
import '../services/profile_controller.dart';
import '../services/reminder_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/week_ring.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/illustrations.dart';
import '../widgets/ui/progress_ring.dart';
import '../widgets/ui/reveal.dart';
import '../widgets/ui/verdict_chip.dart';
import 'baby_screen.dart';
import 'chat_screen.dart';
import 'me_screen.dart';
import 'nutrition_tracker_screen.dart';
import 'plan_screen.dart';
import 'reminders_screen.dart';
import 'track_screen.dart';
import 'emergency_screen.dart';
import 'week_detail_screen.dart';

/// Root shell holding the bottom nav. Home/Plan/Track/Baby/Me are
/// tabs swapped in place (IndexedStack) rather than pushed routes, so the
/// bottom nav behaves like a normal tabbed app instead of stacking screens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userName});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Tabs visited, oldest first, current last.
  ///
  /// An IndexedStack creates no route history, so without this a back press
  /// (browser back, or Android's system back) had nothing to pop and either
  /// did nothing or closed the app. Tracking visits here lets back retrace
  /// the tabs the user actually moved through before it leaves the app.
  final List<int> _visited = [0];

  int get _tabIndex => _visited.last;

  void _select(int index) {
    if (index == _tabIndex) return;
    setState(() {
      _visited.remove(index);
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      // The avatar in the hero jumps to the Me tab, which lives in this shell
      // rather than as a pushed route - hence the callback.
      _HomeTab(userName: widget.userName, onOpenTab: _select),
      const PlanScreen(),
      const TrackScreen(),
      const BabyScreen(),
      const MeScreen(),
    ];

    return PopScope(
      // Only let the pop escape the app once we're back to a single tab.
      canPop: _visited.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _visited.removeLast());
      },
      child: Scaffold(
        body: IndexedStack(index: _tabIndex, children: tabs),
        bottomNavigationBar: AppNavBar(
          currentIndex: _tabIndex,
          onSelected: _select,
          items: const [
            NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
            NavItem(
              icon: Icons.restaurant_menu_outlined,
              activeIcon: Icons.restaurant_menu_rounded,
              label: 'Plan',
            ),
            NavItem(
              icon: Icons.insights_outlined,
              activeIcon: Icons.insights_rounded,
              label: 'Track',
            ),
            NavItem(
              icon: Icons.child_care_outlined,
              activeIcon: Icons.child_care_rounded,
              label: 'Baby',
            ),
            NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.userName, required this.onOpenTab});

  final String userName;

  /// Switches the shell's bottom-nav tab, for hero controls that point at a
  /// tab rather than a pushed screen.
  final ValueChanged<int> onOpenTab;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _storage = LocalStorageService();
  List<HistoryEntry> _recent = [];
  List<NutritionEntry> _todayNutrition = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _storage.loadHistory();
    final nutrition = await _storage.loadNutritionEntries();
    if (!mounted) return;
    setState(() {
      _recent = history.take(3).toList();
      _todayNutrition = nutrition.where((e) => e.isSameDay(DateTime.now())).toList();
    });
  }

  /// Every push from home can change what the dashboard shows (a new chat
  /// logs history, a logged food moves the nutrition rings), so refresh on
  /// the way back rather than leaving stale numbers on screen.
  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  void _openChat(UserProfile profile, {bool startWithVoice = false}) =>
      _push(ChatScreen(profile: profile, startWithVoice: startWithVoice));

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = context.watch<ProfileController>().profile;
    final nextReminder = context.watch<ReminderController>().nextUpToday;

    return RefreshIndicator(
      onRefresh: _load,
      color: p.brand,
      backgroundColor: p.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _HeroHeader(
            userName: widget.userName,
            profile: profile,
            onSearchTap: () => _openChat(profile),
            onAvatarTap: () => widget.onOpenTab(4),
            onNotificationsTap: () => _push(const RemindersScreen()),
            onEmergencyTap: () => _push(const EmergencyScreen()),
            reminderCount: context.watch<ReminderController>().activeCount,
            onWeekTap: () => _push(
              WeekDetailScreen(initialWeek: profile.pregnancyWeek ?? 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // One way in, not three. Typing, speaking and scanning all
                // live inside the chat composer now, so offering them as
                // separate front doors just made the same room harder to find.
                Reveal.stagger(
                  index: 0,
                  child: const _SectionTitle('Ask about any food'),
                ),
                const SizedBox(height: AppSpacing.md),
                Reveal.stagger(
                  index: 1,
                  child: _AskCard(onTap: () => _openChat(profile)),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Reveal.stagger(
                  index: 2,
                  child: _PhotoShortcuts(onOpenPlan: () => widget.onOpenTab(1)),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Reveal.stagger(index: 3, child: _StageArtCard(profile: profile)),
                const SizedBox(height: AppSpacing.xxl),
                Reveal.stagger(index: 3, child: _InsightCard(profile: profile)),
                const SizedBox(height: AppSpacing.xxl),
                if (nextReminder != null) ...[
                  Reveal.stagger(
                    index: 3,
                    child: _NextReminderCard(
                      reminder: nextReminder,
                      onTap: () => _push(const RemindersScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                Reveal.stagger(
                  index: 4,
                  child: _NutritionSnapshot(
                    entries: _todayNutrition,
                    profile: profile,
                    onTap: () => _push(const NutritionTrackerScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (_recent.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const Reveal(child: _SectionTitle('Recent checks')),
                  const SizedBox(height: AppSpacing.md),
                  ..._recent.map((e) => Reveal(child: _RecentTile(entry: e))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: context.texts.titleMedium);
}

/// Gradient banner running under the status bar: greeting, avatar, a progress
/// dial for the current life stage, and the search entry into chat.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.userName,
    required this.profile,
    required this.onSearchTap,
    required this.onAvatarTap,
    required this.onNotificationsTap,
    required this.onEmergencyTap,
    required this.reminderCount,
    required this.onWeekTap,
  });

  final String userName;
  final UserProfile profile;
  final VoidCallback onSearchTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;

  /// Emergency numbers, reachable from the first screen. Anything buried
  /// three taps down is not an emergency feature.
  final VoidCallback onEmergencyTap;

  /// Drives the badge on the bell - active reminders are the only thing in
  /// this app that legitimately notifies you.
  final int reminderCount;

  final VoidCallback onWeekTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        gradient: p.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        boxShadow: p.brandShadow(opacity: 0.28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative layer: soft blobs plus a stage-appropriate figure,
          // both kept faint and behind the content so nothing competes with
          // the text on top.
          const Positioned.fill(child: BlobDecoration(color: Colors.white, seed: 7)),
          Positioned(
            right: -6,
            bottom: -6,
            child: Opacity(
              // Strong enough to actually see against the gradient, still
              // clearly behind the text.
              opacity: 0.34,
              child: !profileHasBaby(profile)
                  ? const MotherIllustration(
                      color: Colors.white,
                      accent: Color(0xFFEDE7FF),
                      size: 150,
                    )
                  // Once the baby is here the header shows the pair, not the
                  // baby alone - the app is for both of them.
                  : const HoldingBabyIllustration(
                      color: Colors.white,
                      accent: Color(0xFFEDE7FF),
                      size: 148,
                    ),
            ),
          ),
          _buildContent(context, p),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppPalette p) {
    const onBrand = Colors.white;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        MediaQuery.of(context).padding.top + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        fontSize: 12,
                        color: onBrand.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: onBrand,
                      ),
                    ),
                  ],
                ),
              ),
              _HeroIconButton(
                icon: Icons.emergency_rounded,
                onTap: onEmergencyTap,
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeroIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: onNotificationsTap,
                badgeCount: reminderCount,
              ),
              const SizedBox(width: AppSpacing.sm),
              Pressable(
                onTap: onAvatarTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: onBrand.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: onBrand.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.person_rounded, color: onBrand, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // During pregnancy the week dial is the headline; otherwise the
          // stage panel still carries the baby's age.
          if (profile.lifeStage == LifeStage.pregnancy && profile.pregnancyWeek != null)
            _PregnancyDial(profile: profile, onTap: onWeekTap)
          else
            _StageProgressPanel(profile: profile),
          const SizedBox(height: AppSpacing.xl),
          Pressable(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              decoration: BoxDecoration(
                color: onBrand.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: onBrand.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: onBrand.withValues(alpha: 0.85), size: 19),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Is it safe to eat...?',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: onBrand.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Icon(Icons.auto_awesome_rounded, color: onBrand.withValues(alpha: 0.85), size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 18) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.palette.brandStrong,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The pregnancy headline: the week dial, the trimester, and the size
/// comparison for the current week, tapping through to the full week detail.
class _PregnancyDial extends StatelessWidget {
  const _PregnancyDial({required this.profile, required this.onTap});

  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final week = profile.pregnancyWeek!;
    final info = pregnancyWeekInfo(week);
    final due = profile.dueDate;

    // Day within the week, so the dial can read "(24+3)" like a clinical note.
    int? dayInWeek;
    if (due != null) {
      final remaining = daysToGo(due);
      final daysDone = 280 - remaining;
      if (daysDone >= 0) dayInWeek = daysDone % 7;
    }

    return Pressable(
      onTap: onTap,
      child: Column(
        children: [
          WeekRing(
            week: week,
            progress: pregnancyProgress(week),
            daysToGo: due == null ? 0 : daysToGo(due),
            dayInWeek: dayInWeek,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm - 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(info.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${info.trimesterLabel}  ·  size of ${info.sizeComparison}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent panel inside the hero showing how far along the user is:
/// a week dial during pregnancy, a month count while breastfeeding, or a
/// plain prompt to finish setting up the profile.
class _StageProgressPanel extends StatelessWidget {
  const _StageProgressPanel({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;
    final (headline, detail, ringValue, ringLabel, ringCaption) = _content();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: onBrand.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: onBrand.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: ringValue,
            size: 66,
            strokeWidth: 7,
            trackColor: onBrand.withValues(alpha: 0.22),
            colors: [onBrand, onBrand.withValues(alpha: 0.75)],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ringLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onBrand,
                    height: 1,
                  ),
                ),
                Text(
                  ringCaption,
                  style: TextStyle(
                    fontSize: 9,
                    color: onBrand.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: onBrand,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: onBrand.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String, double, String, String) _content() {
    switch (profile.lifeStage) {
      case LifeStage.pregnancy:
        final week = profile.pregnancyWeek;
        if (week == null) {
          return ('Pregnancy', 'Add your due date in Profile to track your weeks.', 0.0, '--', 'WEEK');
        }
        final daysLeft = profile.dueDate!.difference(DateTime.now()).inDays;
        return (
          trimesterLabel(week),
          daysLeft > 0 ? '$daysLeft days until your due date' : 'Your due date has arrived',
          week / 40,
          '$week',
          'WEEK',
        );
      case LifeStage.breastfeeding:
        final months = profile.babyAgeMonths;
        if (months == null) {
          return ('Breastfeeding', "Add your baby's birth date in Profile.", 0.0, '--', 'MOS');
        }
        return (
          'Breastfeeding',
          'Your baby is $months month${months == 1 ? '' : 's'} old',
          // Chart the first two years, the window where feeding guidance
          // changes most.
          (months / 24).clamp(0.0, 1.0).toDouble(),
          '$months',
          'MOS',
        );
      case LifeStage.postpartum:
        final months = profile.babyAgeMonths;
        return (
          'Postpartum',
          months != null ? '$months months since birth' : 'Recovery and nutrition support',
          months != null ? (months / 12).clamp(0.0, 1.0).toDouble() : 0.0,
          months != null ? '$months' : '--',
          'MOS',
        );
      case LifeStage.general:
        return (
          'General nutrition',
          'Set your life stage in Profile for tailored advice.',
          0.0,
          '--',
          'STAGE',
        );
    }
  }
}

String trimesterLabel(int week) {
  if (week <= 13) return 'First trimester';
  if (week <= 27) return 'Second trimester';
  return 'Third trimester';
}

/// A rotating, stage-aware nutrition tip. Keyed to the day of the year so it
/// stays stable through a session but changes daily.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.profile});

  final UserProfile profile;

  static const _pregnancyTips = [
    ('Folate first', 'Leafy greens, lentils, and fortified cereal help cover the 600mcg daily target.'),
    ('Iron absorption', 'Pair iron-rich meals with vitamin C - lentils with peppers, spinach with orange.'),
    ('Watch the mercury', 'Salmon and sardines are great; skip swordfish, king mackerel, and shark.'),
    ('Stay hydrated', 'Aim for 8-10 cups of fluid a day; it supports amniotic fluid and digestion.'),
    ('Calcium counts', 'Yogurt, tofu, and fortified milk protect your bone stores while baby builds theirs.'),
  ];

  static const _nursingTips = [
    ('Eat for supply', 'Nursing needs roughly 300-500 extra calories a day - keep snacks within reach.'),
    ('Hydrate often', 'Have a glass of water each time you feed; supply follows fluid intake.'),
    ('Protein matters', 'Eggs, beans, and Greek yogurt help recovery and steady energy.'),
    ('Vitamin D', 'Most breastfed babies need a D supplement - check with your pediatrician.'),
  ];

  static const _generalTips = [
    ('Balanced plates', 'Half vegetables, a quarter protein, a quarter whole grains is a simple guide.'),
    ('Ask anything', 'Not sure about a food? Scan the label or ask - answers cite trusted sources.'),
    ('Log as you go', 'Tracking a few foods a day is enough to spot gaps in iron or calcium.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tips = switch (profile.lifeStage) {
      LifeStage.pregnancy => _pregnancyTips,
      LifeStage.breastfeeding => _nursingTips,
      LifeStage.postpartum || LifeStage.general => _generalTips,
    };
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final (title, body) = tips[dayOfYear % tips.length];

    return AppCard(
      color: p.brandSurface,
      borderColor: p.brand.withValues(alpha: 0.18),
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.brand.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.tips_and_updates_rounded, size: 19, color: p.brandSoft),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIP OF THE DAY',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: p.brandSoft,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(title, style: context.texts.titleSmall),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(fontSize: 12, height: 1.45, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-colour illustrated panel: the figure is the point here, not a
/// watermark, so it gets real size, real tones, and a light backdrop that lets
/// those tones read properly.
/// Whether there is actually a baby to draw.
///
/// Not simply "not pregnant": a general-nutrition user has no baby, and
/// showing them a mother holding one is both wrong and a little cruel.
bool profileHasBaby(UserProfile profile) =>
    profile.babyBirthDate != null ||
    profile.lifeStage == LifeStage.breastfeeding ||
    profile.lifeStage == LifeStage.postpartum;

class _StageArtCard extends StatelessWidget {
  const _StageArtCard({required this.profile});

  final UserProfile profile;

  bool get _showBaby => profileHasBaby(profile);

  /// General nutrition is its own stage, not "pregnancy without a due date".
  /// Telling someone who chose General that this is "Your pregnancy" is both
  /// wrong and, for anyone who is trying to conceive or has lost a pregnancy,
  /// a genuinely unkind thing for an app to say.
  bool get _isGeneral => profile.lifeStage == LifeStage.general;

  String get _title {
    if (_isGeneral) return 'Eating well';
    if (!_showBaby) {
      final week = profile.pregnancyWeek;
      return week == null ? 'Your pregnancy' : trimesterLabel(week);
    }
    final months = profile.babyAgeMonths;
    return months == null ? 'You and your baby' : 'Your baby at $months months';
  }

  String get _body {
    if (_isGeneral) {
      return 'Everyday nutrition guidance, grounded in the same trusted sources.';
    }
    if (!_showBaby) {
      final week = profile.pregnancyWeek;
      if (week == null) return 'Add your due date to see how your week is going.';
      return 'Week $week of 40. Every meal you log is building something.';
    }
    return 'Feeding, growth, and sleep questions answered any time of day.';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tones = FigureTones.defaults(
      _showBaby ? p.accent : p.brand,
      dark: p.isDark,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          // A soft tinted ground so the warm skin and hair tones have
          // something to sit against instead of a flat white card.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.brandSurface, p.surface],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: BlobDecoration(color: p.brand, seed: _showBaby ? 5 : 11),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title, style: context.texts.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _body,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _showBaby
                        ? HoldingBabyIllustration(
                            color: p.accent,
                            tones: tones,
                            size: 124,
                          )
                        : MotherIllustration(
                            color: p.brand,
                            tones: tones,
                            size: 124,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The next reminder still due today, so the dashboard answers "what's next"
/// without opening the reminders screen.
class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({required this.reminder, required this.onTap});

  final Reminder reminder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.brandSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(reminderKindIcon(reminder.kind), size: 20, color: p.brandSoft),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleSmall,
                ),
              ],
            ),
          ),
          Text(
            reminder.formattedTime(context),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.brandSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dials summarising today's logged nutrition against the targets for
/// the user's life stage, linking through to the full tracker.
class _NutritionSnapshot extends StatelessWidget {
  const _NutritionSnapshot({
    required this.entries,
    required this.profile,
    required this.onTap,
  });

  final List<NutritionEntry> entries;
  final UserProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final targets = targetsForLifeStage(profile.lifeStage);
    final total = entries.fold(const NutrientProfile(), (sum, e) => sum + e.nutrients);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text("Today's nutrition", style: context.texts.titleMedium)),
              Text(
                entries.isEmpty ? 'Nothing logged' : '${entries.length} logged',
                style: TextStyle(fontSize: 11.5, color: p.textMuted),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _Dial(
                  label: 'Iron',
                  value: total.ironMg,
                  target: targets.ironMg,
                  unit: 'mg',
                  tint: p.brand,
                ),
              ),
              Expanded(
                child: _Dial(
                  label: 'Calcium',
                  value: total.calciumMg,
                  target: targets.calciumMg,
                  unit: 'mg',
                  tint: Brand.teal,
                ),
              ),
              Expanded(
                child: _Dial(
                  label: 'Protein',
                  value: total.proteinG,
                  target: targets.proteinG,
                  unit: 'g',
                  tint: p.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.tint,
  });

  final String label;
  final double value;
  final double target;
  final String unit;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = target > 0 ? value / target : 0.0;

    return Column(
      children: [
        ProgressRing(
          value: ratio,
          size: 62,
          strokeWidth: 6,
          colors: [tint, tint.withValues(alpha: 0.6)],
          child: Text(
            '${(ratio * 100).clamp(0, 999).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: context.texts.titleSmall),
        Text(
          '${value.toStringAsFixed(0)}/${target.toStringAsFixed(0)} $unit',
          style: TextStyle(fontSize: 10.5, color: p.textMuted),
        ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.entry});

  final HistoryEntry entry;

  IconData get _icon => switch (entry.source) {
        HistorySource.voice => Icons.graphic_eq_rounded,
        HistorySource.scan => Icons.center_focus_strong_rounded,
        HistorySource.chat => Icons.chat_bubble_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        radius: AppRadius.md,
        shadow: false,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_icon, size: 16, color: p.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                entry.query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            VerdictChip(verdict: entry.motherResult.verdict, compact: true),
          ],
        ),
      ),
    );
  }
}

/// Three photo tiles into the Plan section.
///
/// These are shortcuts, not decoration - every tile goes somewhere, which is
/// the only reason a photo earns space on a screen this busy.
class _PhotoShortcuts extends StatelessWidget {
  const _PhotoShortcuts({required this.onOpenPlan});

  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    const tiles = [
      ('assets/images/nutrition.jpg', 'Meals', Icons.restaurant_rounded),
      ('assets/images/fitness.jpg', 'Fitness', Icons.self_improvement_rounded),
      ('assets/images/baby_shopping.jpg', 'Shop', Icons.shopping_basket_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your week'),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 104,
          child: Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PhotoTile(
                    image: tiles[i].$1,
                    label: tiles[i].$2,
                    icon: tiles[i].$3,
                    onTap: onOpenPlan,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.image,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String image;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(gradient: p.heroGradient),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xE6000000), Color(0x40000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 15, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The single entry into the assistant.
///
/// Type, speak, and scan are all in the chat composer, so this card advertises
/// them rather than splitting them into three destinations that each land in
/// the same place.
class _AskCard extends StatelessWidget {
  const _AskCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/mother_eating.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.15),
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(gradient: p.heroGradient),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xF2000000), Color(0x33000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Is this safe for me?',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // The three inputs, named where they are discoverable but
                    // not where they fragment the journey.
                    Row(
                      children: [
                        for (final mode in const [
                          (Icons.keyboard_rounded, 'Type'),
                          (Icons.mic_none_rounded, 'Speak'),
                          (Icons.photo_camera_outlined, 'Scan'),
                        ]) ...[
                          Container(
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(mode.$1, size: 13, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  mode.$2,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
