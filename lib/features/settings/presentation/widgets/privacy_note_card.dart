// lib/features/settings/presentation/widgets/privacy_note_card.dart

import 'package:flutter/material.dart';
import 'package:receipt_vault/app/theme/app_theme.dart';

/// Card explaining the offline-first architecture and local data persistence guarantee.
class PrivacyNoteCard extends StatelessWidget {
  const PrivacyNoteCard({super.key});

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withAlpha(isDark ? 40 : 25),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '100% Offline & Local Privacy',
                      key: const Key('settings_privacy_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stored strictly on your device',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Receipt Vault operates entirely offline. All receipt data, purchase details, warranty dates, and captured receipt images are stored exclusively in your device\'s local storage. Your information is never uploaded to any remote server or cloud provider.',
            key: const Key('settings_privacy_description'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondaryTextColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _PrivacyPoint(
            text: 'Local SQLite database on device',
            primaryTextColor: primaryTextColor,
          ),
          const SizedBox(height: 8),
          _PrivacyPoint(
            text: 'Photos saved in app-owned persistent storage',
            primaryTextColor: primaryTextColor,
          ),
          const SizedBox(height: 8),
          _PrivacyPoint(
            text: 'Zero tracking, cloud analytics, or external accounts',
            primaryTextColor: primaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({required this.text, required this.primaryTextColor});

  final String text;
  final Color primaryTextColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: AppColors.success,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: primaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
