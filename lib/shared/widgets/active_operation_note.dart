import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveOperationNote extends ConsumerWidget {
  const ActiveOperationNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(activeOperationWakelockServiceProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: service.isWakelockActive,
      builder: (context, active, child) {
        if (!active) return const SizedBox.shrink();
        final l = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryEnd.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryEnd.withValues(alpha: 0.26),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.screen_lock_portrait_rounded,
                  color: AppColors.primaryEnd,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.t('activeOperationWakelockNote'),
                    style: TextStyle(
                      color: AppTone.textSecondary(context),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
