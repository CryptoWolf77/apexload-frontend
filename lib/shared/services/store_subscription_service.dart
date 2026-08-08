import 'dart:async';

import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

abstract final class ApexLoadSubscriptionProducts {
  // StoreKit product identifiers. Android uses one product with two base plans.
  static const monthly = 'com.yahyazlab.apexload.premium.monthly';
  static const yearly = 'com.yahyazlab.apexload.premium.yearly';
  static const ids = <String>{monthly, yearly};

  static PremiumPlan? planFor(String productId) => switch (productId) {
    monthly => PremiumPlan.monthly,
    yearly => PremiumPlan.yearly,
    _ => null,
  };
}

abstract final class GooglePlaySubscriptionProducts {
  static const premium = 'com.yahyazlab.apexload.premium';
  static const monthlyBasePlan = 'monthly';
  static const annualBasePlan = 'annual';
  static const ids = <String>{premium};

  static PremiumPlan? planForBasePlan(String basePlanId) =>
      switch (basePlanId) {
        monthlyBasePlan => PremiumPlan.monthly,
        annualBasePlan => PremiumPlan.yearly,
        _ => null,
      };
}

abstract final class SubscriptionCatalogSupportCodes {
  static const storeUnavailable = 'AL-IAP-001';
  static const productsMissing = 'AL-IAP-002';
  static const queryFailed = 'AL-IAP-003';
}

@visibleForTesting
String? subscriptionCatalogSupportCode({
  required bool storeAvailable,
  required Set<String> returnedProductIds,
  Object? error,
}) {
  if (!storeAvailable) {
    return SubscriptionCatalogSupportCodes.storeUnavailable;
  }
  if (error != null) {
    return SubscriptionCatalogSupportCodes.queryFailed;
  }
  if (!returnedProductIds.containsAll(ApexLoadSubscriptionProducts.ids)) {
    return SubscriptionCatalogSupportCodes.productsMissing;
  }
  return null;
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.plan,
    required this.localizedPrice,
  });

  final String id;
  final PremiumPlan plan;
  final String localizedPrice;
}

class StoreEntitlement {
  const StoreEntitlement({
    this.plan,
    this.planName,
    this.expiresAt,
    this.storeRevalidationRequired = false,
    this.purchaseToComplete,
  });

  final PremiumPlan? plan;
  final String? planName;
  final DateTime? expiresAt;
  final bool storeRevalidationRequired;
  final PurchaseDetails? purchaseToComplete;
}

class GooglePlayBasePlanOffer {
  const GooglePlayBasePlanOffer({
    required this.productDetails,
    required this.basePlanId,
    required this.offerToken,
    required this.localizedPrice,
    this.offerId,
  });

  final ProductDetails productDetails;
  final String basePlanId;
  final String offerToken;
  final String localizedPrice;
  final String? offerId;
}

@visibleForTesting
Map<PremiumPlan, GooglePlayBasePlanOffer> selectGooglePlayBasePlanOffers(
  Iterable<GooglePlayBasePlanOffer> offers,
) {
  final selected = <PremiumPlan, GooglePlayBasePlanOffer>{};
  for (final offer in offers) {
    if (offer.productDetails.id != GooglePlaySubscriptionProducts.premium ||
        offer.offerId != null) {
      continue;
    }
    final plan = GooglePlaySubscriptionProducts.planForBasePlan(
      offer.basePlanId,
    );
    if (plan != null) selected.putIfAbsent(plan, () => offer);
  }
  return Map.unmodifiable(selected);
}

class StoreTransactionSnapshot {
  const StoreTransactionSnapshot({
    required this.productId,
    required this.expirationDateMilliseconds,
    required this.isVerified,
  });

  final String productId;
  final String? expirationDateMilliseconds;
  final bool isVerified;
}

@visibleForTesting
StoreEntitlement? selectActiveSubscriptionEntitlement(
  Iterable<StoreTransactionSnapshot> transactions, {
  required DateTime now,
}) {
  StoreEntitlement? active;
  for (final transaction in transactions) {
    final plan = ApexLoadSubscriptionProducts.planFor(transaction.productId);
    final milliseconds = int.tryParse(
      transaction.expirationDateMilliseconds ?? '',
    );
    if (!transaction.isVerified || plan == null || milliseconds == null) {
      continue;
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    if (!expiresAt.isAfter(now)) continue;
    if (active == null || expiresAt.isAfter(active.expiresAt!)) {
      active = StoreEntitlement(plan: plan, expiresAt: expiresAt);
    }
  }
  return active;
}

class SubscriptionCatalog {
  const SubscriptionCatalog({
    required this.storeAvailable,
    required this.products,
    required this.storeProducts,
    this.missingProductIds = const {},
    this.supportCode,
    this.error,
  });

  final bool storeAvailable;
  final Map<PremiumPlan, StoreProduct> products;
  final Map<PremiumPlan, ProductDetails> storeProducts;
  final Set<String> missingProductIds;
  final String? supportCode;
  final String? error;
}

abstract interface class SubscriptionStore {
  bool get isSupported;
  int get expectedPlanCount;
  bool get supportsPlanChanges;
  Stream<List<PurchaseDetails>> get purchaseUpdates;

  bool supportsProductId(String productId);
  Future<SubscriptionCatalog> loadCatalog();
  Future<StoreEntitlement?> currentEntitlement();
  Future<bool> purchase(ProductDetails product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
  StoreEntitlement? fallbackEntitlement(PurchaseDetails purchase);
}

class AppleSubscriptionStore implements SubscriptionStore {
  AppleSubscriptionStore({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  int get expectedPlanCount => ApexLoadSubscriptionProducts.ids.length;

  @override
  bool get supportsPlanChanges => false;

  @override
  bool supportsProductId(String productId) =>
      ApexLoadSubscriptionProducts.planFor(productId) != null;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => isSupported
      ? _inAppPurchase.purchaseStream
      : const Stream<List<PurchaseDetails>>.empty();

  @override
  Future<SubscriptionCatalog> loadCatalog() async {
    if (!isSupported) {
      return const SubscriptionCatalog(
        storeAvailable: false,
        products: {},
        storeProducts: {},
        supportCode: SubscriptionCatalogSupportCodes.storeUnavailable,
      );
    }
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const SubscriptionCatalog(
        storeAvailable: false,
        products: {},
        storeProducts: {},
        supportCode: SubscriptionCatalogSupportCodes.storeUnavailable,
      );
    }

    final productsById = <String, ProductDetails>{};
    var missingProductIds = Set<String>.from(ApexLoadSubscriptionProducts.ids);
    String? catalogError;

    // StoreKit's sandbox catalog can be briefly empty immediately after the
    // app starts. Make a bounded retry before declaring the catalog missing.
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _inAppPurchase.queryProductDetails(
          ApexLoadSubscriptionProducts.ids,
        );
        for (final product in response.productDetails) {
          productsById[product.id] = product;
        }
        missingProductIds = ApexLoadSubscriptionProducts.ids.difference(
          productsById.keys.toSet(),
        );
        catalogError = response.error?.message;
        debugPrint(
          'ApexLoad StoreKit 2 catalog attempt $attempt: '
          'products=${productsById.keys.join(',')} '
          'missing=${missingProductIds.join(',')} '
          'notFound=${response.notFoundIDs.join(',')} '
          'error=$catalogError',
        );
        if (missingProductIds.isEmpty) break;
      } on Object catch (error, stackTrace) {
        catalogError = '$error';
        debugPrint(
          'ApexLoad StoreKit 2 catalog attempt $attempt failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }
    }

    // StoreKit 2 occasionally returns an empty response on a real device
    // without a platform error. Querying the same catalog through StoreKit 1
    // is a safe compatibility fallback and does not change the purchase IDs.
    if (missingProductIds.isNotEmpty) {
      try {
        final legacyResponse = await SKRequestMaker().startProductRequest(
          ApexLoadSubscriptionProducts.ids.toList(growable: false),
        );
        final legacyProducts = legacyResponse.products
            .map(AppStoreProductDetails.fromSKProduct)
            .toList(growable: false);
        debugPrint(
          'ApexLoad StoreKit 1 fallback: '
          'products=${legacyProducts.map((product) => product.id).join(',')} '
          'missing=${legacyResponse.invalidProductIdentifiers.join(',')}',
        );
        for (final product in legacyProducts) {
          productsById[product.id] = product;
        }
        missingProductIds = ApexLoadSubscriptionProducts.ids.difference(
          productsById.keys.toSet(),
        );
        if (missingProductIds.isEmpty) {
          catalogError = null;
        }
      } on Object catch (error, stackTrace) {
        catalogError ??= '$error';
        debugPrint('ApexLoad StoreKit 1 fallback failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    final catalogProducts = productsById.values.toList(growable: false);
    debugPrint(
      'ApexLoad StoreKit catalog: '
      'products=${catalogProducts.map((product) => product.id).join(',')} '
      'missing=${missingProductIds.join(',')} '
      'error=$catalogError',
    );
    final productDetails = <PremiumPlan, ProductDetails>{};
    final products = <PremiumPlan, StoreProduct>{};
    for (final product in catalogProducts) {
      final plan = ApexLoadSubscriptionProducts.planFor(product.id);
      if (plan == null) continue;
      productDetails[plan] = product;
      products[plan] = StoreProduct(
        id: product.id,
        plan: plan,
        localizedPrice: product.price,
      );
    }
    final supportCode = subscriptionCatalogSupportCode(
      storeAvailable: true,
      returnedProductIds: productsById.keys.toSet(),
      error: catalogError,
    );

    return SubscriptionCatalog(
      storeAvailable: true,
      products: Map.unmodifiable(products),
      storeProducts: Map.unmodifiable(productDetails),
      missingProductIds: Set.unmodifiable(missingProductIds),
      supportCode: supportCode,
      error:
          catalogError ??
          (missingProductIds.isEmpty
              ? null
              : 'Products not found: ${missingProductIds.join(', ')}'),
    );
  }

  @override
  Future<StoreEntitlement?> currentEntitlement() async {
    if (!isSupported) return null;
    final transactions = await SK2Transaction.transactions();
    return selectActiveSubscriptionEntitlement(
      transactions.map(
        (transaction) => StoreTransactionSnapshot(
          productId: transaction.productId,
          expirationDateMilliseconds: transaction.expirationDate,
          isVerified: transaction.error == null,
        ),
      ),
      now: DateTime.now(),
    );
  }

  @override
  Future<bool> purchase(ProductDetails product) {
    return _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> restore() => _inAppPurchase.restorePurchases();

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _inAppPurchase.completePurchase(purchase);

  @override
  StoreEntitlement? fallbackEntitlement(PurchaseDetails purchase) {
    final plan = ApexLoadSubscriptionProducts.planFor(purchase.productID);
    if (plan == null) return null;
    final now = DateTime.now();
    return StoreEntitlement(
      plan: plan,
      expiresAt: plan == PremiumPlan.monthly
          ? now.add(const Duration(days: 35))
          : now.add(const Duration(days: 370)),
    );
  }
}

abstract interface class GooglePlayBillingGateway {
  Stream<List<PurchaseDetails>> get purchaseUpdates;

  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<QueryPurchaseDetailsResponse> queryPastPurchases();
  Future<bool> buyNonConsumable(GooglePlayPurchaseParam purchaseParam);
  Future<void> completePurchase(PurchaseDetails purchase);
}

class PluginGooglePlayBillingGateway implements GooglePlayBillingGateway {
  PluginGooglePlayBillingGateway({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  InAppPurchaseAndroidPlatformAddition get _androidAddition => _inAppPurchase
      .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates =>
      _inAppPurchase.purchaseStream;

  @override
  Future<bool> isAvailable() => _inAppPurchase.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _inAppPurchase.queryProductDetails(identifiers);

  @override
  Future<QueryPurchaseDetailsResponse> queryPastPurchases() =>
      _androidAddition.queryPastPurchases();

  @override
  Future<bool> buyNonConsumable(GooglePlayPurchaseParam purchaseParam) =>
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _inAppPurchase.completePurchase(purchase);
}

class GooglePlaySubscriptionStore implements SubscriptionStore {
  GooglePlaySubscriptionStore({
    GooglePlayBillingGateway? gateway,
    bool? isSupportedOverride,
  }) : _gateway = gateway ?? PluginGooglePlayBillingGateway(),
       _isSupportedOverride = isSupportedOverride;

  final GooglePlayBillingGateway _gateway;
  final bool? _isSupportedOverride;
  Map<PremiumPlan, GooglePlayBasePlanOffer> _offers = const {};
  PremiumPlan? _pendingPlan;

  @override
  bool get isSupported =>
      _isSupportedOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  @override
  int get expectedPlanCount => 2;

  @override
  bool get supportsPlanChanges => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => isSupported
      ? _gateway.purchaseUpdates
      : const Stream<List<PurchaseDetails>>.empty();

  @override
  bool supportsProductId(String productId) =>
      productId == GooglePlaySubscriptionProducts.premium;

  @override
  Future<SubscriptionCatalog> loadCatalog() async {
    if (!isSupported || !await _gateway.isAvailable()) {
      return const SubscriptionCatalog(
        storeAvailable: false,
        products: {},
        storeProducts: {},
        supportCode: SubscriptionCatalogSupportCodes.storeUnavailable,
      );
    }

    final response = await _gateway.queryProductDetails(
      GooglePlaySubscriptionProducts.ids,
    );
    final offers = <GooglePlayBasePlanOffer>[];
    for (final product in response.productDetails) {
      if (product is! GooglePlayProductDetails ||
          product.id != GooglePlaySubscriptionProducts.premium) {
        continue;
      }
      final index = product.subscriptionIndex;
      final subscriptionOffers =
          product.productDetails.subscriptionOfferDetails;
      if (index == null ||
          subscriptionOffers == null ||
          index >= subscriptionOffers.length) {
        continue;
      }
      final details = subscriptionOffers[index];
      final recurringPhase = details.pricingPhases.firstWhere(
        (phase) => phase.recurrenceMode == RecurrenceMode.infiniteRecurring,
        orElse: () => details.pricingPhases.last,
      );
      offers.add(
        GooglePlayBasePlanOffer(
          productDetails: product,
          basePlanId: details.basePlanId,
          offerId: details.offerId,
          offerToken: details.offerIdToken,
          localizedPrice: recurringPhase.formattedPrice,
        ),
      );
    }
    _offers = selectGooglePlayBasePlanOffers(offers);

    final products = <PremiumPlan, StoreProduct>{};
    final storeProducts = <PremiumPlan, ProductDetails>{};
    for (final entry in _offers.entries) {
      storeProducts[entry.key] = entry.value.productDetails;
      products[entry.key] = StoreProduct(
        id: entry.value.productDetails.id,
        plan: entry.key,
        localizedPrice: entry.value.localizedPrice,
      );
    }
    final missingPlans = PremiumPlan.values
        .where((plan) => !_offers.containsKey(plan))
        .map(
          (plan) =>
              '${GooglePlaySubscriptionProducts.premium}:${plan == PremiumPlan.monthly ? GooglePlaySubscriptionProducts.monthlyBasePlan : GooglePlaySubscriptionProducts.annualBasePlan}',
        )
        .toSet();
    final error = response.error?.message;
    final supportCode = error != null
        ? SubscriptionCatalogSupportCodes.queryFailed
        : missingPlans.isNotEmpty
        ? SubscriptionCatalogSupportCodes.productsMissing
        : null;
    return SubscriptionCatalog(
      storeAvailable: true,
      products: Map.unmodifiable(products),
      storeProducts: Map.unmodifiable(storeProducts),
      missingProductIds: Set.unmodifiable(missingPlans),
      supportCode: supportCode,
      error:
          error ??
          (missingPlans.isEmpty
              ? null
              : 'Google Play base plans not found: ${missingPlans.join(', ')}'),
    );
  }

  Future<GooglePlayPurchaseDetails?> _activePurchase() async {
    final response = await _gateway.queryPastPurchases();
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    for (final purchase in response.pastPurchases.reversed) {
      if (supportsProductId(purchase.productID) &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        return purchase;
      }
    }
    return null;
  }

  @override
  Future<StoreEntitlement?> currentEntitlement() async {
    final purchase = await _activePurchase();
    if (purchase == null) return null;
    return StoreEntitlement(
      plan: _pendingPlan,
      planName: _pendingPlan?.label ?? 'Google Play',
      storeRevalidationRequired: true,
      purchaseToComplete: purchase.pendingCompletePurchase ? purchase : null,
    );
  }

  @override
  Future<bool> purchase(ProductDetails product) async {
    final selected = _offers.entries
        .where((entry) => identical(entry.value.productDetails, product))
        .firstOrNull;
    if (selected == null || product is! GooglePlayProductDetails) {
      throw StateError('The selected Google Play base plan is unavailable.');
    }
    final previousPlan = _pendingPlan;
    _pendingPlan = selected.key;
    final activePurchase = await _activePurchase();
    final launched = await _gateway.buyNonConsumable(
      GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: selected.value.offerToken,
        changeSubscriptionParam: activePurchase == null
            ? null
            : ChangeSubscriptionParam(
                oldPurchaseDetails: activePurchase,
                replacementMode: ReplacementMode.withTimeProration,
              ),
      ),
    );
    if (!launched) _pendingPlan = previousPlan;
    return launched;
  }

  @override
  Future<void> restore() async {
    // SubscriptionStoreController immediately reconciles with
    // queryPastPurchases(), which is the active-purchase source on Android.
  }

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _gateway.completePurchase(purchase);

  @override
  StoreEntitlement? fallbackEntitlement(PurchaseDetails purchase) => null;
}

class UnavailableSubscriptionStore implements SubscriptionStore {
  const UnavailableSubscriptionStore();

  @override
  bool get isSupported => false;

  @override
  int get expectedPlanCount => 0;

  @override
  bool get supportsPlanChanges => false;

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates =>
      const Stream<List<PurchaseDetails>>.empty();

  @override
  bool supportsProductId(String productId) => false;

  @override
  Future<SubscriptionCatalog> loadCatalog() async => const SubscriptionCatalog(
    storeAvailable: false,
    products: {},
    storeProducts: {},
    supportCode: SubscriptionCatalogSupportCodes.storeUnavailable,
  );

  @override
  Future<StoreEntitlement?> currentEntitlement() async => null;

  @override
  Future<bool> purchase(ProductDetails product) async => false;

  @override
  Future<void> restore() async {}

  @override
  Future<void> complete(PurchaseDetails purchase) async {}

  @override
  StoreEntitlement? fallbackEntitlement(PurchaseDetails purchase) => null;
}

enum StorePurchasePhase {
  loading,
  ready,
  purchasing,
  pending,
  restoring,
  purchased,
  restored,
  restoreNotFound,
  canceled,
  error,
  unavailable,
}

class SubscriptionStoreState {
  const SubscriptionStoreState({
    required this.phase,
    required this.storeAvailable,
    this.products = const {},
    this.supportsPlanChanges = false,
    this.activePlan,
    this.supportCode,
    this.error,
  });

  const SubscriptionStoreState.loading()
    : phase = StorePurchasePhase.loading,
      storeAvailable = false,
      products = const {},
      supportsPlanChanges = false,
      activePlan = null,
      supportCode = null,
      error = null;

  final StorePurchasePhase phase;
  final bool storeAvailable;
  final Map<PremiumPlan, StoreProduct> products;
  final bool supportsPlanChanges;
  final PremiumPlan? activePlan;
  final String? supportCode;
  final String? error;

  bool get isBusy =>
      phase == StorePurchasePhase.loading ||
      phase == StorePurchasePhase.purchasing ||
      phase == StorePurchasePhase.pending ||
      phase == StorePurchasePhase.restoring;

  String? priceFor(PremiumPlan plan) => products[plan]?.localizedPrice;

  SubscriptionStoreState copyWith({
    StorePurchasePhase? phase,
    bool? storeAvailable,
    Map<PremiumPlan, StoreProduct>? products,
    bool? supportsPlanChanges,
    PremiumPlan? activePlan,
    String? supportCode,
    String? error,
    bool clearError = false,
    bool clearSupportCode = false,
    bool clearActivePlan = false,
  }) {
    return SubscriptionStoreState(
      phase: phase ?? this.phase,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      products: products ?? this.products,
      supportsPlanChanges: supportsPlanChanges ?? this.supportsPlanChanges,
      activePlan: clearActivePlan ? null : activePlan ?? this.activePlan,
      supportCode: clearSupportCode ? null : supportCode ?? this.supportCode,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final subscriptionStoreProvider = Provider<SubscriptionStore>((ref) {
  if (kIsWeb) return const UnavailableSubscriptionStore();
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => GooglePlaySubscriptionStore(),
    TargetPlatform.iOS => AppleSubscriptionStore(),
    _ => const UnavailableSubscriptionStore(),
  };
});

final subscriptionStoreControllerProvider =
    NotifierProvider<SubscriptionStoreController, SubscriptionStoreState>(
      SubscriptionStoreController.new,
    );

class SubscriptionStoreController extends Notifier<SubscriptionStoreState> {
  SubscriptionStore? _service;
  SubscriptionCatalog? _catalog;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  SubscriptionStoreState build() {
    final service = ref.watch(subscriptionStoreProvider);
    _service = service;
    _purchaseSubscription = service.purchaseUpdates.listen(
      (updates) => unawaited(_handlePurchaseUpdates(updates)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('ApexLoad subscription purchase stream failed: $error');
        state = state.copyWith(
          phase: StorePurchasePhase.error,
          error: '$error',
        );
      },
    );
    ref.onDispose(() => unawaited(_purchaseSubscription?.cancel()));
    unawaited(Future<void>.microtask(_initialize));
    return const SubscriptionStoreState.loading();
  }

  Future<void> _initialize() async {
    final service = _service;
    if (service == null || !service.isSupported) {
      state = const SubscriptionStoreState(
        phase: StorePurchasePhase.unavailable,
        storeAvailable: false,
      );
      return;
    }

    try {
      final catalog = await service.loadCatalog();
      if (!ref.mounted) return;
      _catalog = catalog;
      final catalogComplete =
          catalog.storeProducts.length == service.expectedPlanCount;
      state = SubscriptionStoreState(
        phase: catalog.storeAvailable && catalogComplete
            ? StorePurchasePhase.ready
            : StorePurchasePhase.unavailable,
        storeAvailable: catalog.storeAvailable,
        products: catalog.products,
        supportsPlanChanges: service.supportsPlanChanges,
        supportCode: catalog.supportCode,
        error: catalog.error,
      );
      if (!catalog.storeAvailable) return;

      final entitlement = await service.currentEntitlement();
      if (!ref.mounted) return;
      if (entitlement == null) {
        await ref
            .read(subscriptionControllerProvider.notifier)
            .clearStoreEntitlement();
        if (ref.mounted) {
          state = state.copyWith(clearActivePlan: true);
        }
      } else {
        await _activate(entitlement);
        await _completePendingEntitlement(entitlement);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad subscription initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: StorePurchasePhase.error,
        supportCode: SubscriptionCatalogSupportCodes.queryFailed,
        error: '$error',
      );
    }
  }

  Future<void> purchase(PremiumPlan plan) async {
    if (state.isBusy) return;
    final product = _catalog?.storeProducts[plan];
    final service = _service;
    if (service == null || product == null) {
      state = state.copyWith(
        phase: StorePurchasePhase.error,
        error: 'The selected subscription is not available.',
      );
      return;
    }
    state = state.copyWith(
      phase: StorePurchasePhase.purchasing,
      clearError: true,
    );
    try {
      final launched = await service.purchase(product);
      if (!launched && ref.mounted) {
        state = state.copyWith(
          phase: StorePurchasePhase.error,
          error: 'The store purchase sheet could not be opened.',
        );
      }
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad subscription purchase failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(phase: StorePurchasePhase.error, error: '$error');
    }
  }

  Future<void> refreshCatalog() async {
    if (state.isBusy) return;
    state = state.copyWith(phase: StorePurchasePhase.loading, clearError: true);
    await _initialize();
  }

  Future<void> restore() async {
    if (state.isBusy || !state.storeAvailable) return;
    final service = _service;
    if (service == null) return;
    state = state.copyWith(
      phase: StorePurchasePhase.restoring,
      clearError: true,
    );
    try {
      await service.restore();
      unawaited(_finishRestoreIfNeeded());
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad subscription restore failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(phase: StorePurchasePhase.error, error: '$error');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> updates) async {
    if (!ref.mounted) return;
    if (updates.isEmpty) {
      if (state.phase == StorePurchasePhase.restoring) {
        await _finishRestore();
      }
      return;
    }

    final supported = updates
        .where(
          (purchase) =>
              _service?.supportsProductId(purchase.productID) ?? false,
        )
        .toList();
    if (supported.isEmpty) return;

    final deliverable = supported
        .where(
          (purchase) =>
              purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored,
        )
        .toList();
    if (deliverable.isNotEmpty) {
      try {
        var entitlement = await _service?.currentEntitlement();
        final restored = deliverable.every(
          (purchase) => purchase.status == PurchaseStatus.restored,
        );
        if (entitlement == null && !restored) {
          entitlement = _service?.fallbackEntitlement(deliverable.last);
        }
        if (entitlement == null) {
          if (state.phase == StorePurchasePhase.restoring) {
            await _finishRestore();
          } else {
            state = state.copyWith(
              phase: StorePurchasePhase.error,
              error: 'The subscription could not be verified.',
            );
          }
          return;
        }

        await _activate(entitlement);
        for (final purchase in deliverable) {
          if (purchase.pendingCompletePurchase) {
            await _service?.complete(purchase);
          }
        }
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: restored || state.phase == StorePurchasePhase.restoring
              ? StorePurchasePhase.restored
              : StorePurchasePhase.purchased,
          clearError: true,
        );
        return;
      } on Object catch (error, stackTrace) {
        debugPrint('ApexLoad subscription delivery failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: StorePurchasePhase.error,
          error: '$error',
        );
        return;
      }
    }

    if (supported.any(
      (purchase) => purchase.status == PurchaseStatus.pending,
    )) {
      state = state.copyWith(phase: StorePurchasePhase.pending);
      return;
    }
    if (supported.any(
      (purchase) => purchase.status == PurchaseStatus.canceled,
    )) {
      state = state.copyWith(phase: StorePurchasePhase.canceled);
      return;
    }
    final failed = supported
        .where((purchase) => purchase.status == PurchaseStatus.error)
        .firstOrNull;
    if (failed != null) {
      state = state.copyWith(
        phase: StorePurchasePhase.error,
        error: failed.error?.message,
      );
    }
  }

  Future<void> _finishRestoreIfNeeded() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!ref.mounted || state.phase != StorePurchasePhase.restoring) return;
    await _finishRestore();
  }

  Future<void> _finishRestore() async {
    try {
      final entitlement = await _service?.currentEntitlement();
      if (!ref.mounted) return;
      if (entitlement == null) {
        await ref
            .read(subscriptionControllerProvider.notifier)
            .clearStoreEntitlement();
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: StorePurchasePhase.restoreNotFound,
          clearActivePlan: true,
        );
      } else {
        await _activate(entitlement);
        await _completePendingEntitlement(entitlement);
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: StorePurchasePhase.restored,
          clearError: true,
        );
      }
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad subscription entitlement restore failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(phase: StorePurchasePhase.error, error: '$error');
    }
  }

  Future<void> _activate(StoreEntitlement entitlement) async {
    await ref
        .read(subscriptionControllerProvider.notifier)
        .activateStoreEntitlement(
          plan: entitlement.plan,
          planName: entitlement.planName,
          expiresAt: entitlement.expiresAt,
          storeRevalidationRequired: entitlement.storeRevalidationRequired,
        );
    if (ref.mounted) {
      final subscription = ref.read(subscriptionControllerProvider);
      final activePlan =
          entitlement.plan ??
          PremiumPlan.values
              .where((plan) => plan.label == subscription.planName)
              .firstOrNull;
      state = state.copyWith(activePlan: activePlan);
    }
  }

  Future<void> _completePendingEntitlement(StoreEntitlement entitlement) async {
    final purchase = entitlement.purchaseToComplete;
    if (purchase != null && purchase.pendingCompletePurchase) {
      await _service?.complete(purchase);
    }
  }
}
