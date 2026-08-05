import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/store_subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App Store product identifiers match App Store Connect', () {
    expect(
      ApexLoadSubscriptionProducts.monthly,
      'com.yahyazlab.apexload.premium.monthly',
    );
    expect(
      ApexLoadSubscriptionProducts.yearly,
      'com.yahyazlab.apexload.premium.yearly',
    );
  });

  group('subscription catalog support codes', () {
    test('reports unavailable when StoreKit cannot be reached', () {
      expect(
        subscriptionCatalogSupportCode(
          storeAvailable: false,
          returnedProductIds: const {},
        ),
        SubscriptionCatalogSupportCodes.storeUnavailable,
      );
    });

    test('reports missing products for an incomplete catalog', () {
      expect(
        subscriptionCatalogSupportCode(
          storeAvailable: true,
          returnedProductIds: const {ApexLoadSubscriptionProducts.monthly},
        ),
        SubscriptionCatalogSupportCodes.productsMissing,
      );
    });

    test('reports query failure when StoreKit returns an error', () {
      expect(
        subscriptionCatalogSupportCode(
          storeAvailable: true,
          returnedProductIds: const {},
          error: StateError('StoreKit failed'),
        ),
        SubscriptionCatalogSupportCodes.queryFailed,
      );
    });

    test('returns no support code for the complete catalog', () {
      expect(
        subscriptionCatalogSupportCode(
          storeAvailable: true,
          returnedProductIds: ApexLoadSubscriptionProducts.ids,
        ),
        isNull,
      );
    });
  });

  test('selects the latest active verified StoreKit entitlement', () {
    final now = DateTime(2026, 7, 24);
    final active = selectActiveSubscriptionEntitlement([
      StoreTransactionSnapshot(
        productId: ApexLoadSubscriptionProducts.monthly,
        expirationDateMilliseconds: now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch
            .toString(),
        isVerified: true,
      ),
      StoreTransactionSnapshot(
        productId: ApexLoadSubscriptionProducts.yearly,
        expirationDateMilliseconds: now
            .add(const Duration(days: 200))
            .millisecondsSinceEpoch
            .toString(),
        isVerified: true,
      ),
      StoreTransactionSnapshot(
        productId: ApexLoadSubscriptionProducts.monthly,
        expirationDateMilliseconds: now
            .add(const Duration(days: 400))
            .millisecondsSinceEpoch
            .toString(),
        isVerified: false,
      ),
    ], now: now);

    expect(active?.plan, PremiumPlan.yearly);
    expect(active?.expiresAt, now.add(const Duration(days: 200)));
  });

  test('returns no entitlement when every subscription is expired', () {
    final now = DateTime(2026, 7, 24);
    final active = selectActiveSubscriptionEntitlement([
      StoreTransactionSnapshot(
        productId: ApexLoadSubscriptionProducts.monthly,
        expirationDateMilliseconds: now
            .subtract(const Duration(seconds: 1))
            .millisecondsSinceEpoch
            .toString(),
        isVerified: true,
      ),
    ], now: now);

    expect(active, isNull);
  });
}
