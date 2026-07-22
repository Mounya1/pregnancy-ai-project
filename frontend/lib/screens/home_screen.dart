import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/interaction_mode_selector.dart';
import '../widgets/quick_action_grid.dart';
import 'chat_screen.dart';
import 'food_analysis_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.profile, required this.userName});

  final UserProfile profile;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(profile: profile, userName: userName),
              const SizedBox(height: 20),
              const _AssistantCard(),
              const SizedBox(height: 20),
              _SearchBar(onTap: () => _openChat(context)),
              const SizedBox(height: 20),
              const Text(
                'How would you like to ask?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              InteractionModeSelector(
                onType: () => _openChat(context),
                onVoice: () => _openChat(context, startWithVoice: true),
                onScan: () => _openScan(context),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quick actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(fontSize: 12))),
                ],
              ),
              const SizedBox(height: 10),
              QuickActionGrid(
                actions: [
                  QuickAction(
                    label: 'Meal planner',
                    icon: Icons.restaurant_menu,
                    onTap: () {},
                  ),
                  QuickAction(
                    label: 'Nutrition tracker',
                    icon: Icons.bar_chart,
                    onTap: () {},
                  ),
                  QuickAction(
                    label: 'Scan label',
                    icon: Icons.qr_code_scanner,
                    onTap: () => _openScan(context),
                  ),
                  QuickAction(
                    label: 'Saved foods',
                    icon: Icons.favorite_border,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, {bool startWithVoice = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(profile: profile, startWithVoice: startWithVoice),
      ),
    );
  }

  void _openScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodAnalysisScreen(profile: profile)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.userName});

  final UserProfile profile;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $userName 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              profile.statusLabel,
              style: const TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
            const CircleAvatar(radius: 20, backgroundColor: AppColors.purpleLight, child: Icon(Icons.person, color: AppColors.purple)),
          ],
        ),
      ],
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(18)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your AI nutrition assistant',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Ask anything about food, ingredients, and nutrition - for you and your baby.',
            style: TextStyle(color: AppColors.purpleLight, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textMuted, size: 18),
            SizedBox(width: 8),
            Text('Ask a question or search food...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
