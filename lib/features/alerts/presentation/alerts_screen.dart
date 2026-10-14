// lib/features/alerts/presentation/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/shared/widgets/placeholder_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: const PlaceholderScreen(
        title: 'Warranty Alerts',
        subtitle:
            'You will be notified here when warranties are about to expire.',
        icon: Icons.notifications_outlined,
      ),
    );
  }
}
