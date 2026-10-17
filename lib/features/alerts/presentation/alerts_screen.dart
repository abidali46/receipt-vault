// lib/features/alerts/presentation/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_vault/app/router/app_router.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';
import 'package:receipt_vault/features/alerts/domain/entities/warranty_alert.dart';
import 'package:receipt_vault/features/alerts/presentation/providers/alerts_providers.dart';
import 'package:receipt_vault/features/alerts/presentation/widgets/alert_card.dart';
import 'package:receipt_vault/features/alerts/presentation/widgets/alert_filter_row.dart';
import 'package:receipt_vault/features/alerts/presentation/widgets/alerts_empty_state.dart';
import 'package:receipt_vault/features/receipts/domain/repositories/receipts_repository.dart';

/// Screen displaying active warranty alerts (expiring soon and recently expired)
/// with urgency sorting, filter chips, and navigation to receipt details.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({
    super.key,
    this.initialAlerts,
    this.repository,
    this.now,
  });

  /// Optional static alerts fixture for hermetic widget testing.
  final List<WarrantyAlert>? initialAlerts;

  /// Optional repository override for hermetic widget testing.
  final ReceiptsRepository? repository;

  /// Optional clock override for deterministic testing.
  final DateTime? now;

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertFilter _selectedFilter = AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final Widget bodyContent;
    if (widget.initialAlerts != null) {
      bodyContent = _buildContent(
        context,
        widget.initialAlerts!,
        theme,
        isDark,
        primaryTextColor,
        secondaryTextColor,
      );
    } else if (widget.repository != null) {
      bodyContent = StreamBuilder<List<WarrantyAlert>>(
        stream: widget.repository!.watchReceipts().map(
          (receipts) => generateWarrantyAlerts(receipts, now: widget.now),
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorBody(
              context,
              snapshot.error.toString(),
              theme,
              isDark,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(
            context,
            snapshot.data!,
            theme,
            isDark,
            primaryTextColor,
            secondaryTextColor,
          );
        },
      );
    } else {
      final alertsAsync = ref.watch(alertsStreamProvider);
      bodyContent = alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _buildErrorBody(context, error.toString(), theme, isDark),
        data: (alerts) => _buildContent(
          context,
          alerts,
          theme,
          isDark,
          primaryTextColor,
          secondaryTextColor,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text('Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SafeArea(child: bodyContent),
    );
  }

  Widget _buildErrorBody(
    BuildContext context,
    String error,
    ThemeData theme,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WarrantyAlert> allAlerts,
    ThemeData theme,
    bool isDark,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final expiringAlerts = allAlerts.where((a) => a.isExpiringSoon).toList();
    final expiredAlerts = allAlerts.where((a) => a.isExpired).toList();

    final counts = {
      AlertFilter.all: allAlerts.length,
      AlertFilter.expiringSoon: expiringAlerts.length,
      AlertFilter.expired: expiredAlerts.length,
    };

    final List<WarrantyAlert> filteredAlerts;
    switch (_selectedFilter) {
      case AlertFilter.all:
        filteredAlerts = allAlerts;
        break;
      case AlertFilter.expiringSoon:
        filteredAlerts = expiringAlerts;
        break;
      case AlertFilter.expired:
        filteredAlerts = expiredAlerts;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        // Filter Chips Row
        AlertFilterRow(
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          counts: counts,
        ),

        const SizedBox(height: 12),

        // Status Summary Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${expiringAlerts.length} Expiring Soon',
                key: const Key('alerts_summary_expiring_count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: expiringAlerts.isNotEmpty
                      ? AppColors.warning
                      : secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (expiredAlerts.isNotEmpty)
                Text(
                  '${expiredAlerts.length} Expired',
                  key: const Key('alerts_summary_expired_count'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // List or Empty State
        Expanded(
          child: filteredAlerts.isEmpty
              ? AlertsEmptyState(
                  filter: _selectedFilter,
                  onResetFilter: () {
                    setState(() {
                      _selectedFilter = AlertFilter.all;
                    });
                  },
                  onViewWarranties: () {
                    context.go(AppRoutes.warranties);
                  },
                  onAddReceipt: () {
                    context.push(AppRoutes.add);
                  },
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: _buildAlertsList(
                      context,
                      filteredAlerts,
                      theme,
                      primaryTextColor,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAlertsList(
    BuildContext context,
    List<WarrantyAlert> alerts,
    ThemeData theme,
    Color primaryTextColor,
  ) {
    // If viewing All and both categories exist, show section headers matching mockups
    final showSectionHeaders = _selectedFilter == AlertFilter.all;
    final expiringItems = alerts.where((a) => a.isExpiringSoon).toList();
    final expiredItems = alerts.where((a) => a.isExpired).toList();

    return ListView(
      key: const Key('alerts_items_list'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (showSectionHeaders && expiringItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              'Expiring Soon',
              key: const Key('alerts_section_expiring_header'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
          ...expiringItems.map(
            (alert) => AlertCard(
              key: Key('alert_card_${alert.receipt.id}'),
              alert: alert,
              onTap: () {
                context.push(AppRoutes.receiptDetailPath(alert.receipt.id));
              },
            ),
          ),
        ],
        if (showSectionHeaders && expiredItems.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              bottom: 8,
              top: expiringItems.isNotEmpty ? 16 : 4,
            ),
            child: Text(
              'Expired',
              key: const Key('alerts_section_expired_header'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ),
          ...expiredItems.map(
            (alert) => AlertCard(
              key: Key('alert_card_${alert.receipt.id}'),
              alert: alert,
              onTap: () {
                context.push(AppRoutes.receiptDetailPath(alert.receipt.id));
              },
            ),
          ),
        ],
        if (!showSectionHeaders)
          ...alerts.map(
            (alert) => AlertCard(
              key: Key('alert_card_${alert.receipt.id}'),
              alert: alert,
              onTap: () {
                context.push(AppRoutes.receiptDetailPath(alert.receipt.id));
              },
            ),
          ),
      ],
    );
  }
}
