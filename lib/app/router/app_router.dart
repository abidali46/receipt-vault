// lib/app/router/app_router.dart
//
// Centralised go_router configuration.
// Uses a StatefulShellRoute for the bottom-navigation shell so that each
// tab keeps its own navigation stack independently.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/app/router/app_shell.dart';
import 'package:receipt_vault/core/storage/app_database.dart';
import 'package:receipt_vault/features/alerts/presentation/alerts_screen.dart';
import 'package:receipt_vault/features/home/presentation/add_receipt_screen.dart';
import 'package:receipt_vault/features/receipts/presentation/receipt_detail_screen.dart';
import 'package:receipt_vault/features/receipts/presentation/receipts_screen.dart';
import 'package:receipt_vault/features/settings/presentation/settings_screen.dart';
import 'package:receipt_vault/features/warranty/presentation/warranty_screen.dart';

/// Named route paths — use these constants instead of raw strings.
abstract final class AppRoutes {
  static const String receipts = '/receipts';
  static const String warranties = '/warranties';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String add = '/add';
  static const String receiptDetail = '/receipts/:id';
  static const String editReceipt = '/receipts/:id/edit';

  /// Helper to build path for receipt details screen.
  static String receiptDetailPath(int id) => '/receipts/$id';

  /// Helper to build path for receipt editing screen.
  static String editReceiptPath(int id) => '/receipts/$id/edit';
}

/// Root navigator key for pushing full-screen modal/detail routes above the bottom shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// The root [GoRouter] instance for the app.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.receipts,
  debugLogDiagnostics: false,
  routes: [
    // ── Shell (bottom navigation) ──────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            return AppShell(navigationShell: navigationShell);
          },
      branches: [
        // Branch 0 – Receipts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.receipts,
              builder: (context, state) => const ReceiptsScreen(),
            ),
          ],
        ),

        // Branch 1 – Warranties
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.warranties,
              builder: (context, state) => const WarrantyScreen(),
            ),
          ],
        ),

        // Branch 2 – Add (tab index placeholder; actual navigation is a push)
        // We still need a branch at index 2 so the shell's selectedIndex aligns.
        // The shell intercepts taps on index 2 and pushes /add instead.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/add-placeholder',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),

        // Branch 3 – Alerts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.alerts,
              builder: (context, state) => const AlertsScreen(),
            ),
          ],
        ),

        // Branch 4 – Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Add Receipt (modal / full-screen push outside the shell) ──────────
    GoRoute(
      path: AppRoutes.add,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AddReceiptScreen(),
    ),

    // ── Receipt Details (full-screen push outside the shell) ─────────────
    GoRoute(
      path: AppRoutes.receiptDetail,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '');
        final staticReceipt = state.extra is Receipt
            ? state.extra as Receipt
            : null;
        return ReceiptDetailScreen(receiptId: id, receipt: staticReceipt);
      },
    ),

    // ── Edit Receipt (full-screen push outside the shell) ────────────────
    GoRoute(
      path: AppRoutes.editReceipt,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final idStr = state.pathParameters['id'];
        final id = int.tryParse(idStr ?? '');
        final receipt = state.extra is Receipt ? state.extra as Receipt : null;
        return AddReceiptScreen(receiptToEdit: receipt, receiptId: id);
      },
    ),
  ],
);
