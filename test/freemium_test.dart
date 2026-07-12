import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('free users get 5 downloads per day and ads after every 2', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(subscriptionControllerProvider.notifier);
    final initialAllowance = await controller.checkDownloadAllowance();
    expect(initialAllowance.allowed, isTrue);
    expect(
      container.read(subscriptionControllerProvider).remainingDownloadsToday,
      5,
    );

    expect(await controller.recordSuccessfulDownload(), isFalse);
    expect(await controller.recordSuccessfulDownload(), isTrue);
    expect(await controller.recordSuccessfulDownload(), isFalse);
    expect(await controller.recordSuccessfulDownload(), isTrue);
    expect(await controller.recordSuccessfulDownload(), isFalse);

    final blocked = await controller.checkDownloadAllowance();
    expect(blocked.allowed, isFalse);
    expect(blocked.reason, DownloadBlockReason.dailyLimitReached);
    expect(
      container.read(subscriptionControllerProvider).remainingDownloadsToday,
      0,
    );
  });

  test(
    'free daily counter resets when stored date is from yesterday',
    () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'subscription_is_premium': false,
        'subscription_plan_name': 'Free',
        'subscription_downloads_used_today': 5,
        'subscription_last_reset_date': yesterday.toIso8601String(),
        'subscription_premium_mock': false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        subscriptionControllerProvider.notifier,
      );
      final allowance = await controller.checkDownloadAllowance();

      expect(allowance.allowed, isTrue);
      expect(
        container.read(subscriptionControllerProvider).downloadsUsedToday,
        0,
      );
      expect(
        container.read(subscriptionControllerProvider).remainingDownloadsToday,
        5,
      );
    },
  );

  test('premium users bypass limits and never trigger mock ads', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.activatePremium(PremiumPlan.yearly);

    final allowance = await controller.checkDownloadAllowance();
    expect(allowance.allowed, isTrue);
    expect(container.read(subscriptionControllerProvider).isPremium, isTrue);
    expect(container.read(subscriptionControllerProvider).planName, 'Yearly');

    for (var i = 0; i < 6; i++) {
      expect(await controller.recordSuccessfulDownload(), isFalse);
    }
  });

  test('auto-save to gallery preference is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    final controller = container.read(
      autoSaveToGalleryControllerProvider.notifier,
    );

    await controller.setEnabled(false);
    expect(container.read(autoSaveToGalleryControllerProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('auto_save_to_gallery'), isFalse);
    container.dispose();

    final restored = ProviderContainer();
    addTearDown(restored.dispose);
    restored.read(autoSaveToGalleryControllerProvider);
    await pumpEventQueue();
    expect(restored.read(autoSaveToGalleryControllerProvider), isFalse);
  });
}
