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
}
