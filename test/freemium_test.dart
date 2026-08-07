import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('free users get 5 downloads per day without placeholder ads', () async {
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
    expect(await controller.recordSuccessfulDownload(), isFalse);
    expect(await controller.recordSuccessfulDownload(), isFalse);
    expect(await controller.recordSuccessfulDownload(), isFalse);
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

  test('store premium users bypass limits and never trigger ads', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.activateStoreEntitlement(
      plan: PremiumPlan.yearly,
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );

    final allowance = await controller.checkDownloadAllowance();
    expect(allowance.allowed, isTrue);
    expect(container.read(subscriptionControllerProvider).isPremium, isTrue);
    expect(container.read(subscriptionControllerProvider).planName, 'Yearly');
    expect(
      container.read(subscriptionControllerProvider).isStoreManagedPremium,
      isTrue,
    );

    for (var i = 0; i < 6; i++) {
      expect(await controller.recordSuccessfulDownload(), isFalse);
    }
  });

  test(
    'reviewer entitlement persists and survives an empty store result',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      final controller = container.read(
        subscriptionControllerProvider.notifier,
      );
      await controller.activateReviewerEntitlement();

      var subscription = container.read(subscriptionControllerProvider);
      expect(subscription.isPremium, isTrue);
      expect(subscription.planName, 'Google Play Reviewer');
      expect(subscription.premiumActivatedMock, isTrue);
      expect(subscription.isStoreManagedPremium, isFalse);
      expect(subscription.expiresAt?.year, 2099);

      await controller.clearStoreEntitlement();
      subscription = container.read(subscriptionControllerProvider);
      expect(subscription.isPremium, isTrue);
      expect(subscription.planName, 'Google Play Reviewer');

      container.dispose();
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      await restored
          .read(subscriptionControllerProvider.notifier)
          .checkDownloadAllowance();

      subscription = restored.read(subscriptionControllerProvider);
      expect(subscription.isPremium, isTrue);
      expect(subscription.planName, 'Google Play Reviewer');
      expect(subscription.premiumActivatedMock, isTrue);
      expect(subscription.expiresAt?.year, 2099);
    },
  );

  test('reviewer activation does not replace a store entitlement', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(subscriptionControllerProvider.notifier);
    final storeExpiry = DateTime.now().add(const Duration(days: 365));

    await controller.activateStoreEntitlement(
      plan: PremiumPlan.yearly,
      expiresAt: storeExpiry,
    );
    await controller.activateReviewerEntitlement();

    final subscription = container.read(subscriptionControllerProvider);
    expect(subscription.isPremium, isTrue);
    expect(subscription.planName, 'Yearly');
    expect(subscription.premiumActivatedMock, isFalse);
    expect(subscription.isStoreManagedPremium, isTrue);
    expect(subscription.expiresAt, storeExpiry);
  });

  test('expired store entitlement returns the user to the free plan', () async {
    SharedPreferences.setMockInitialValues({
      'subscription_is_premium': true,
      'subscription_plan_name': 'Monthly',
      'subscription_downloads_used_today': 2,
      'subscription_last_reset_date': DateTime.now().toIso8601String(),
      'subscription_premium_mock': false,
      'subscription_expires_at': DateTime.now()
          .subtract(const Duration(minutes: 1))
          .toIso8601String(),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(subscriptionControllerProvider.notifier)
        .checkDownloadAllowance();

    final subscription = container.read(subscriptionControllerProvider);
    expect(subscription.isPremium, isFalse);
    expect(subscription.downloadsUsedToday, 2);
  });

  test(
    'legacy lifetime state remains premium without a lifetime plan',
    () async {
      SharedPreferences.setMockInitialValues({
        'subscription_is_premium': true,
        'subscription_plan_name': 'Lifetime',
        'subscription_downloads_used_today': 0,
        'subscription_last_reset_date': DateTime.now().toIso8601String(),
        'subscription_premium_mock': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final allowance = await container
          .read(subscriptionControllerProvider.notifier)
          .checkDownloadAllowance();

      expect(allowance.allowed, isTrue);
      expect(container.read(subscriptionControllerProvider).isPremium, isTrue);
      expect(PremiumPlan.values, [PremiumPlan.monthly, PremiumPlan.yearly]);
    },
  );

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

  test('legacy auto-save preference is migrated to enabled once', () async {
    SharedPreferences.setMockInitialValues({'auto_save_to_gallery': false});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(autoSaveToGalleryControllerProvider);
    await pumpEventQueue();

    expect(container.read(autoSaveToGalleryControllerProvider), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('auto_save_to_gallery'), isTrue);
    expect(prefs.getBool('auto_save_to_gallery_default_enabled_v2'), isTrue);
  });
}
