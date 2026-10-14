// lib/features/warranty/presentation/warranty_screen.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/shared/widgets/placeholder_screen.dart';

class WarrantyScreen extends StatelessWidget {
  const WarrantyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warranties')),
      body: const PlaceholderScreen(
        title: 'Warranty Tracker',
        subtitle:
            'Product warranties linked to your receipts will be tracked here.',
        icon: Icons.verified_outlined,
      ),
    );
  }
}
