// lib/app/router/app_shell.dart
//
// The main scaffold that wraps all bottom-navigation destinations.
// It uses a StatefulShellRoute from go_router so that each branch keeps
// its own navigation stack.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps the five main destinations with a persistent NavigationBar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Bottom-nav destinations (index matches StatefulShellRoute branch order).
  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Receipts',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _NavDestination(
      label: 'Warranties',
      icon: Icons.verified_outlined,
      selectedIcon: Icons.verified,
    ),
    _NavDestination(
      label: 'Add',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
    ),
    _NavDestination(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
    _NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == 2) {
      // Centre "Add" button navigates to the add-receipt flow as a new route
      // rather than switching tabs, keeping the previous tab active.
      context.push('/add');
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        destinations: _destinations.map((dest) {
          final bool isAdd = dest.label == 'Add';
          if (isAdd) {
            // Make the centre Add button visually prominent.
            return NavigationDestination(
              icon: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(dest.icon, color: colorScheme.onPrimary, size: 26),
              ),
              selectedIcon: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  dest.selectedIcon,
                  color: colorScheme.onPrimary,
                  size: 26,
                ),
              ),
              label: dest.label,
            );
          }
          return NavigationDestination(
            icon: Icon(dest.icon),
            selectedIcon: Icon(dest.selectedIcon),
            label: dest.label,
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper — keeps destination data alongside icons.
// ---------------------------------------------------------------------------

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
