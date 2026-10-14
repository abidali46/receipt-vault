// lib/features/settings/presentation/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/shared/widgets/placeholder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const PlaceholderScreen(
        title: 'Settings',
        subtitle: 'App preferences and account options will appear here.',
        icon: Icons.settings_outlined,
      ),
    );
  }
}
