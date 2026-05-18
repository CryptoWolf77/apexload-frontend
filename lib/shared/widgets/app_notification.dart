import 'dart:math' as math;

import 'package:apexload/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

enum AppNotificationType { success, error, warning, info }

class AppNotification {
  const AppNotification._();

  static void success(
    BuildContext context, {
    String? title,
    required String message,
  }) => show(
    context,
    title: title,
    message: message,
    type: AppNotificationType.success,
  );

  static void error(
    BuildContext context, {
    String? title,
    required String message,
  }) => show(
    context,
    title: title,
    message: message,
    type: AppNotificationType.error,
  );

  static void warning(
    BuildContext context, {
    String? title,
    required String message,
  }) => show(
    context,
    title: title,
    message: message,
    type: AppNotificationType.warning,
  );

  static void info(
    BuildContext context, {
    String? title,
    required String message,
  }) => show(
    context,
    title: title,
    message: message,
    type: AppNotificationType.info,
  );

  static void show(
    BuildContext context, {
    String? title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
  }) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.92, 520.0);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        width: width,
        duration: const Duration(milliseconds: 2800),
        padding: EdgeInsets.zero,
        dismissDirection: DismissDirection.down,
        content: SafeArea(
          minimum: const EdgeInsets.only(bottom: 12),
          child: _NotificationCard(title: title, message: message, type: type),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.message,
    required this.type,
  });

  final String? title;
  final String message;
  final AppNotificationType type;

  @override
  Widget build(BuildContext context) {
    final isLight = AppTone.isLight(context);
    final accent = _accent;
    final background = isLight
        ? AppColors.lightSurface
        : const Color(0xFF1B2340);
    final primaryText = isLight ? AppColors.lightTextPrimary : Colors.white;
    final secondaryText = isLight
        ? AppColors.lightTextSecondary
        : AppColors.textSecondary;

    return DecoratedBox(
      key: const Key('app_notification_card'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? AppColors.lightBorder
              : accent.withValues(alpha: 0.36),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isLight ? 0.14 : 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          textDirection: Directionality.of(context),
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isLight ? 0.12 : 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message,
                    maxLines: title == null ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: title == null ? primaryText : secondaryText,
                      fontWeight: title == null
                          ? FontWeight.w800
                          : FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _accent {
    return switch (type) {
      AppNotificationType.success => AppColors.success,
      AppNotificationType.error => AppColors.error,
      AppNotificationType.warning => AppColors.premiumGold,
      AppNotificationType.info => AppColors.primaryEnd,
    };
  }

  IconData get _icon {
    return switch (type) {
      AppNotificationType.success => Icons.check_circle_rounded,
      AppNotificationType.error => Icons.error_rounded,
      AppNotificationType.warning => Icons.warning_rounded,
      AppNotificationType.info => Icons.info_rounded,
    };
  }
}
