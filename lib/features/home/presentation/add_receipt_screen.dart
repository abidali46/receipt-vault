// lib/features/home/presentation/add_receipt_screen.dart
//
// Placeholder for the Add Receipt flow. Shown when the user taps the
// prominent centre Add button in the navigation bar.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/shared/widgets/placeholder_screen.dart';

class AddReceiptScreen extends StatelessWidget {
  const AddReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Receipt'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: const PlaceholderScreen(
        title: 'Capture a Receipt',
        subtitle:
            'Camera capture, gallery import, and manual entry will be available here.',
        icon: Icons.add_a_photo_outlined,
      ),
    );
  }
}
