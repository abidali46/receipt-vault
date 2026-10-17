// test/features/settings/settings_screen_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/core/storage/app_settings_service.dart';
import 'package:receipt_vault/features/settings/presentation/providers/settings_providers.dart';
import 'package:receipt_vault/features/settings/presentation/settings_screen.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/about_app_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/data_export_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/privacy_note_card.dart';
import 'package:receipt_vault/features/settings/presentation/widgets/theme_selection_card.dart';

Widget _buildTestApp({
  AppSettingsService? settingsService,
  ThemeMode initialThemeMode = ThemeMode.system,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final service =
      settingsService ?? InMemoryAppSettingsService(initialThemeMode);

  return ProviderScope(
    overrides: [
      settingsServiceProvider.overrideWithValue(service),
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  group('AppSettingsService Unit Tests', () {
    test(
      'InMemoryAppSettingsService defaults to system and persists theme',
      () async {
        final service = InMemoryAppSettingsService();
        expect(await service.getThemeMode(), ThemeMode.system);

        await service.setThemeMode(ThemeMode.dark);
        expect(await service.getThemeMode(), ThemeMode.dark);

        await service.setThemeMode(ThemeMode.light);
        expect(await service.getThemeMode(), ThemeMode.light);
      },
    );

    test(
      'LocalFileAppSettingsService persists and reads theme from file',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('settings_test_');
        addTearDown(() => tempDir.delete(recursive: true));

        final service = LocalFileAppSettingsService(
          getDirectory: () async => tempDir,
        );

        // Non-existent file defaults to system
        expect(await service.getThemeMode(), ThemeMode.system);

        // Set dark
        await service.setThemeMode(ThemeMode.dark);
        expect(await service.getThemeMode(), ThemeMode.dark);

        // New instance pointing to same directory reads saved file
        final service2 = LocalFileAppSettingsService(
          getDirectory: () async => tempDir,
        );
        expect(await service2.getThemeMode(), ThemeMode.dark);

        // Update to light
        await service2.setThemeMode(ThemeMode.light);
        expect(await service.getThemeMode(), ThemeMode.light);
      },
    );

    test(
      'LocalFileAppSettingsService handles corrupt file gracefully',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'settings_corrupt_test_',
        );
        addTearDown(() => tempDir.delete(recursive: true));

        final file = File('${tempDir.path}/app_settings.json');
        await file.writeAsString('{ invalid_json: ');

        final service = LocalFileAppSettingsService(
          getDirectory: () async => tempDir,
        );

        expect(await service.getThemeMode(), ThemeMode.system);
      },
    );
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all four settings sections', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('Data & Privacy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      expect(find.byType(ThemeSelectionCard), findsOneWidget);
      expect(find.byType(DataExportCard), findsOneWidget);
      expect(find.byType(PrivacyNoteCard), findsOneWidget);
      expect(find.byType(AboutAppCard), findsOneWidget);
    });

    testWidgets('renders theme options and updates selection on tap', (
      tester,
    ) async {
      final service = InMemoryAppSettingsService(ThemeMode.system);

      await tester.pumpWidget(_buildTestApp(settingsService: service));
      await tester.pumpAndSettle();

      // Three theme options visible
      expect(find.byKey(const Key('settings_theme_system')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_light')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_dark')), findsOneWidget);

      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Tap Light Mode
      await tester.tap(find.byKey(const Key('settings_theme_light')));
      await tester.pumpAndSettle();

      expect(await service.getThemeMode(), ThemeMode.light);

      // Tap Dark Mode
      await tester.tap(find.byKey(const Key('settings_theme_dark')));
      await tester.pumpAndSettle();

      expect(await service.getThemeMode(), ThemeMode.dark);

      // Tap System Default
      await tester.tap(find.byKey(const Key('settings_theme_system')));
      await tester.pumpAndSettle();

      expect(await service.getThemeMode(), ThemeMode.system);
    });

    testWidgets('renders data & privacy section with offline storage info', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_privacy_title')), findsOneWidget);
      expect(find.text('100% Offline & Local Privacy'), findsOneWidget);
      expect(
        find.textContaining('operates entirely offline', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Local SQLite database on device'), findsOneWidget);
      expect(
        find.text('Photos saved in app-owned persistent storage'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders about section with app name, version, and description',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('settings_about_app_name')),
          findsOneWidget,
        );
        expect(find.text('Receipt Vault'), findsOneWidget);
        expect(
          find.byKey(const Key('settings_about_version_badge')),
          findsOneWidget,
        );
        expect(find.text('v1.0.0'), findsOneWidget);
        expect(
          find.byKey(const Key('settings_about_description')),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'offline-first receipt keeper',
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders cleanly in dark mode without errors or defects', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(ThemeSelectionCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
