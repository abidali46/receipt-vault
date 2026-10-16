// lib/main.dart
//
// Entry point for Receipt Vault.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ReceiptVaultApp()));
}

/// Root widget for the Receipt Vault application.
class ReceiptVaultApp extends StatelessWidget {
  const ReceiptVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Receipt Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
