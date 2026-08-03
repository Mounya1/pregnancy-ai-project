import 'package:flutter/material.dart';
import 'ui/empty_state.dart';

/// Shown for features that are designed but not yet built. Keeps every tap in
/// the app leading somewhere instead of silently doing nothing.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, title: title, message: description),
    );
  }
}
