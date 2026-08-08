import 'dart:async';

import 'package:apexload/core/constants/app_config.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/services/store_subscription_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('iOS StoreKit product identifiers remain unchanged', () {
    expect(
      ApexLoadSubscriptionProducts.monthly,
      'com.yahyazlab.apexload.premium.monthly',
    );
    expect(
      ApexLoadSubscriptionProducts.yearly,
      'com.yahyazlab.apexload.premium.yearly',
    );
  });

  test('Google Play uses the single configured subscription product', () {
    expect(
      GooglePlaySubscriptionProducts.premium,
      'com.yahyazlab.apexload.premium',
    );
  });

  test('Android monthly base plan maps from basePlanId monthly', () {
    expect(
      GooglePlaySubscriptionProducts.planForBasePlan('monthly'),
      PremiumPlan.monthly,
    );
  });

  test('Android yearly UI plan maps from basePlanId annual', () {
    expect(
      GooglePlaySubscriptionProducts.planForBasePlan('annual'),
      PremiumPlan.yearly,
    );
  });

  test('inactive Android basePlanId yearly is ignored', () {
    expect(GooglePlaySubscriptionProducts.planForBasePlan('yearly'), isNull);
    final selected = selectGooglePlayBasePlanOffers([
      _offerSnapshot(basePlanId: 'yearly', offerToken: 'inactive-token'),
    ]);
    expect(selected, isEmpty);
  });

  test('discount offer cannot replace the regular base plan token', () {
    final selected = selectGooglePlayBasePlanOffers([
      _offerSnapshot(
        basePlanId: 'monthly',
        offerToken: 'discount-token',
        offerId: 'intro',
      ),
      _offerSnapshot(basePlanId: 'monthly', offerToken: 'monthly-token'),
    ]);

    expect(selected[PremiumPlan.monthly]?.offerToken, 'monthly-token');
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

    test('reports missing products for an incomplete iOS catalog', () {
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

    test('returns no support code for the complete iOS catalog', () {
      expect(
        subscriptionCatalogSupportCode(
          storeAvailable: true,
          returnedProductIds: ApexLoadSubscriptionProducts.ids,
        ),
        isNull,
      );
    });
  });

  test('Google Play catalog exposes localized recurring prices', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );

    final catalog = await store.loadCatalog();

    expect(catalog.products[PremiumPlan.monthly]?.localizedPrice, r'$1.29');
    expect(catalog.products[PremiumPlan.yearly]?.localizedPrice, r'$10.49');
    expect(catalog.storeProducts, hasLength(2));
    expect(catalog.supportCode, isNull);
  });

  test('monthly purchase uses the monthly base plan offer token', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.monthly]!,
    );

    expect(result, StorePurchaseLaunchResult.launched);
    expect(gateway.lastPurchaseParam?.offerToken, 'monthly-token');
    expect(gateway.lastPurchaseParam?.changeSubscriptionParam, isNull);
  });

  test('annual purchase uses the annual base plan offer token', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.yearly]!,
    );

    expect(result, StorePurchaseLaunchResult.launched);
    expect(gateway.lastPurchaseParam?.offerToken, 'annual-token');
    expect(gateway.lastPurchaseParam?.changeSubscriptionParam, isNull);
  });

  test('monthly to annual charges the full annual price immediately', () async {
    final active = _googlePlayPurchase(token: 'old-token');
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
      pastPurchases: [active],
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.yearly]!,
      currentPlan: PremiumPlan.monthly,
    );

    final replacement = gateway.lastPurchaseParam?.changeSubscriptionParam;
    expect(result, StorePurchaseLaunchResult.launched);
    expect(gateway.lastPurchaseParam?.offerToken, 'annual-token');
    expect(replacement?.oldPurchaseDetails, same(active));
    expect(replacement?.replacementMode, ReplacementMode.chargeFullPrice);
  });

  test('annual to monthly changes without proration', () async {
    final active = _googlePlayPurchase(token: 'old-token');
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
      pastPurchases: [active],
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.monthly]!,
      currentPlan: PremiumPlan.yearly,
    );

    final replacement = gateway.lastPurchaseParam?.changeSubscriptionParam;
    expect(result, StorePurchaseLaunchResult.launched);
    expect(gateway.lastPurchaseParam?.offerToken, 'monthly-token');
    expect(replacement?.oldPurchaseDetails, same(active));
    expect(replacement?.replacementMode, ReplacementMode.withoutProration);
  });

  test('same monthly plan does not launch a Play purchase', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
      pastPurchases: [_googlePlayPurchase()],
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.monthly]!,
      currentPlan: PremiumPlan.monthly,
    );

    expect(result, StorePurchaseLaunchResult.unchanged);
    expect(gateway.purchaseLaunchCount, 0);
    expect(gateway.lastPurchaseParam, isNull);
  });

  test('same annual plan does not launch a Play purchase', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
      pastPurchases: [_googlePlayPurchase()],
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.yearly]!,
      currentPlan: PremiumPlan.yearly,
    );

    expect(result, StorePurchaseLaunchResult.unchanged);
    expect(gateway.purchaseLaunchCount, 0);
    expect(gateway.lastPurchaseParam, isNull);
  });

  test('active purchase with unknown current plan does not launch', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
      pastPurchases: [_googlePlayPurchase()],
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );
    final catalog = await store.loadCatalog();

    final result = await store.purchase(
      catalog.storeProducts[PremiumPlan.yearly]!,
    );

    expect(result, StorePurchaseLaunchResult.currentPlanUnknown);
    expect(gateway.purchaseLaunchCount, 0);
    expect(gateway.lastPurchaseParam, isNull);
  });

  test('Google Play plan changes never use time proration', () {
    expect(
      googlePlayReplacementMode(
        from: PremiumPlan.monthly,
        to: PremiumPlan.yearly,
      ),
      isNot(ReplacementMode.withTimeProration),
    );
    expect(
      googlePlayReplacementMode(
        from: PremiumPlan.yearly,
        to: PremiumPlan.monthly,
      ),
      isNot(ReplacementMode.withTimeProration),
    );
  });

  test(
    'Google Play active purchase restores a revalidated entitlement',
    () async {
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
        pastPurchases: [_googlePlayPurchase()],
      );
      addTearDown(gateway.dispose);
      final store = GooglePlaySubscriptionStore(
        gateway: gateway,
        isSupportedOverride: true,
      );

      final entitlement = await store.currentEntitlement();

      expect(entitlement, isNotNull);
      expect(entitlement?.storeRevalidationRequired, isTrue);
      expect(entitlement?.expiresAt, isNull);
      expect(entitlement?.planName, 'Google Play');
    },
  );

  test('Google Play missing active purchase returns no entitlement', () async {
    final gateway = _FakeGooglePlayBillingGateway(
      productDetails: _googlePlayProducts(),
    );
    addTearDown(gateway.dispose);
    final store = GooglePlaySubscriptionStore(
      gateway: gateway,
      isSupportedOverride: true,
    );

    expect(await store.currentEntitlement(), isNull);
  });

  test(
    'Google Play purchase completion delegates acknowledgement once',
    () async {
      final purchase = _googlePlayPurchase(acknowledged: false);
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
      );
      addTearDown(gateway.dispose);
      final store = GooglePlaySubscriptionStore(
        gateway: gateway,
        isSupportedOverride: true,
      );

      expect(purchase.pendingCompletePurchase, isTrue);
      await store.complete(purchase);

      expect(gateway.completedPurchases, [purchase]);
    },
  );

  test(
    'purchase update activates and acknowledges Google Play Premium',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
      );
      addTearDown(gateway.dispose);
      final store = GooglePlaySubscriptionStore(
        gateway: gateway,
        isSupportedOverride: true,
      );
      final container = ProviderContainer(
        overrides: [subscriptionStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      container.read(subscriptionStoreControllerProvider);
      await pumpEventQueue(times: 20);

      final purchase = _googlePlayPurchase(acknowledged: false);
      gateway.pastPurchases = [purchase];
      gateway.emit([purchase]);
      await pumpEventQueue(times: 20);

      final subscription = container.read(subscriptionControllerProvider);
      expect(subscription.isStoreManagedPremium, isTrue);
      expect(subscription.storeRevalidationRequired, isTrue);
      expect(gateway.completedPurchases, [purchase]);
    },
  );

  test(
    'reviewer entitlement survives empty Google Play reconciliation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
      );
      addTearDown(gateway.dispose);
      final store = GooglePlaySubscriptionStore(
        gateway: gateway,
        isSupportedOverride: true,
      );
      final container = ProviderContainer(
        overrides: [subscriptionStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container
          .read(subscriptionControllerProvider.notifier)
          .activateReviewerEntitlement();

      container.read(subscriptionStoreControllerProvider);
      await pumpEventQueue(times: 20);

      final subscription = container.read(subscriptionControllerProvider);
      expect(subscription.isPremium, isTrue);
      expect(subscription.premiumActivatedMock, isTrue);
      expect(subscription.planName, 'Google Play Reviewer');
    },
  );

  test(
    'store-managed Premium clears after empty Play reconciliation',
    () async {
      SharedPreferences.setMockInitialValues({
        'subscription_is_premium': true,
        'subscription_plan_name': 'Monthly',
        'subscription_downloads_used_today': 0,
        'subscription_last_reset_date': DateTime.now().toIso8601String(),
        'subscription_premium_mock': false,
        'subscription_store_revalidation_required': true,
      });
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
      );
      addTearDown(gateway.dispose);
      final container = ProviderContainer(
        overrides: [
          subscriptionStoreProvider.overrideWithValue(
            GooglePlaySubscriptionStore(
              gateway: gateway,
              isSupportedOverride: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(subscriptionStoreControllerProvider);
      await pumpEventQueue(times: 20);

      expect(container.read(subscriptionControllerProvider).isPremium, isFalse);
    },
  );

  test(
    'startup reconciliation acknowledges an unfinished Play purchase',
    () async {
      SharedPreferences.setMockInitialValues({});
      final purchase = _googlePlayPurchase(acknowledged: false);
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
        pastPurchases: [purchase],
      );
      addTearDown(gateway.dispose);
      final container = ProviderContainer(
        overrides: [
          subscriptionStoreProvider.overrideWithValue(
            GooglePlaySubscriptionStore(
              gateway: gateway,
              isSupportedOverride: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(subscriptionStoreControllerProvider);
      await pumpEventQueue(times: 20);

      expect(container.read(subscriptionControllerProvider).isPremium, isTrue);
      expect(gateway.completedPurchases, [purchase]);
    },
  );

  test(
    'startup restore preserves a cached Google Play base plan name',
    () async {
      SharedPreferences.setMockInitialValues({
        'subscription_is_premium': true,
        'subscription_plan_name': 'Yearly',
        'subscription_downloads_used_today': 0,
        'subscription_last_reset_date': DateTime.now().toIso8601String(),
        'subscription_premium_mock': false,
        'subscription_store_revalidation_required': true,
      });
      final gateway = _FakeGooglePlayBillingGateway(
        productDetails: _googlePlayProducts(),
        pastPurchases: [_googlePlayPurchase()],
      );
      addTearDown(gateway.dispose);
      final container = ProviderContainer(
        overrides: [
          subscriptionStoreProvider.overrideWithValue(
            GooglePlaySubscriptionStore(
              gateway: gateway,
              isSupportedOverride: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(subscriptionStoreControllerProvider);
      await pumpEventQueue(times: 20);

      expect(container.read(subscriptionControllerProvider).planName, 'Yearly');
      expect(
        container.read(subscriptionStoreControllerProvider).activePlan,
        PremiumPlan.yearly,
      );
    },
  );

  test('fresh install starts Free', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(subscriptionControllerProvider.notifier)
        .checkDownloadAllowance();

    expect(container.read(subscriptionControllerProvider).isPremium, isFalse);
  });

  test('APEXLOAD_TESTER_PREMIUM is false by default', () {
    expect(AppConfig.testerPremiumEnabled, isFalse);
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

  test(
    'returns no StoreKit entitlement when every subscription is expired',
    () {
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
    },
  );
}

GooglePlayBasePlanOffer _offerSnapshot({
  required String basePlanId,
  required String offerToken,
  String? offerId,
}) {
  return GooglePlayBasePlanOffer(
    productDetails: ProductDetails(
      id: GooglePlaySubscriptionProducts.premium,
      title: 'ApexLoad Premium',
      description: 'Premium',
      price: r'$1.29',
      rawPrice: 1.29,
      currencyCode: 'USD',
    ),
    basePlanId: basePlanId,
    offerToken: offerToken,
    localizedPrice: r'$1.29',
    offerId: offerId,
  );
}

List<GooglePlayProductDetails> _googlePlayProducts() {
  const offers = [
    SubscriptionOfferDetailsWrapper(
      basePlanId: 'monthly',
      offerTags: [],
      offerIdToken: 'monthly-token',
      pricingPhases: [
        PricingPhaseWrapper(
          billingCycleCount: 0,
          billingPeriod: 'P1M',
          formattedPrice: r'$1.29',
          priceAmountMicros: 1290000,
          priceCurrencyCode: 'USD',
          recurrenceMode: RecurrenceMode.infiniteRecurring,
        ),
      ],
    ),
    SubscriptionOfferDetailsWrapper(
      basePlanId: 'annual',
      offerTags: [],
      offerIdToken: 'annual-token',
      pricingPhases: [
        PricingPhaseWrapper(
          billingCycleCount: 0,
          billingPeriod: 'P1Y',
          formattedPrice: r'$10.49',
          priceAmountMicros: 10490000,
          priceCurrencyCode: 'USD',
          recurrenceMode: RecurrenceMode.infiniteRecurring,
        ),
      ],
    ),
    SubscriptionOfferDetailsWrapper(
      basePlanId: 'yearly',
      offerTags: [],
      offerIdToken: 'inactive-yearly-token',
      pricingPhases: [
        PricingPhaseWrapper(
          billingCycleCount: 0,
          billingPeriod: 'P1Y',
          formattedPrice: r'$9.49',
          priceAmountMicros: 9490000,
          priceCurrencyCode: 'USD',
          recurrenceMode: RecurrenceMode.infiniteRecurring,
        ),
      ],
    ),
  ];
  return GooglePlayProductDetails.fromProductDetails(
    const ProductDetailsWrapper(
      description: 'ApexLoad Premium subscription',
      name: 'ApexLoad Premium',
      productId: 'com.yahyazlab.apexload.premium',
      productType: ProductType.subs,
      subscriptionOfferDetails: offers,
      title: 'ApexLoad Premium',
    ),
  );
}

GooglePlayPurchaseDetails _googlePlayPurchase({
  String token = 'purchase-token',
  bool acknowledged = true,
}) {
  return GooglePlayPurchaseDetails.fromPurchase(
    PurchaseWrapper(
      orderId: 'order-id',
      packageName: 'com.yahyazlab.apexload',
      purchaseTime: DateTime.now().millisecondsSinceEpoch,
      purchaseToken: token,
      signature: 'signature',
      products: const [GooglePlaySubscriptionProducts.premium],
      isAutoRenewing: true,
      originalJson: '{}',
      isAcknowledged: acknowledged,
      purchaseState: PurchaseStateWrapper.purchased,
    ),
  ).single;
}

class _FakeGooglePlayBillingGateway implements GooglePlayBillingGateway {
  _FakeGooglePlayBillingGateway({
    required this.productDetails,
    List<GooglePlayPurchaseDetails> pastPurchases = const [],
  }) : pastPurchases = List.of(pastPurchases);

  final List<ProductDetails> productDetails;
  List<GooglePlayPurchaseDetails> pastPurchases;
  final completedPurchases = <PurchaseDetails>[];
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();
  GooglePlayPurchaseParam? lastPurchaseParam;
  int purchaseLaunchCount = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _updates.stream;

  void emit(List<PurchaseDetails> purchases) => _updates.add(purchases);

  Future<void> dispose() => _updates.close();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: productDetails,
    notFoundIDs: const [],
  );

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases() async =>
      QueryPurchaseDetailsResponse(pastPurchases: pastPurchases);

  @override
  Future<bool> buyNonConsumable(GooglePlayPurchaseParam purchaseParam) async {
    purchaseLaunchCount++;
    lastPurchaseParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
  }
}
