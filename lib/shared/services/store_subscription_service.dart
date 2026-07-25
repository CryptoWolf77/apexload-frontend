import 'dart:async';

import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

abstract final class ApexLoadSubscriptionProducts {
  static const monthly = 'com.yahyazlab.apexload.premium.monthly';
  static const yearly = 'com.yahyazlab.apexload.premium.yearly';
  static const ids = <String>{monthly, yearly};

  static PremiumPlan? planFor(String productId) => switch (productId) {
    monthly => PremiumPlan.monthly,
    yearly => PremiumPlan.yearly,
    _ => null,
  };
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
  const StoreEntitlement({required this.plan, required this.expiresAt});

  final PremiumPlan plan;
  final DateTime expiresAt;
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
    if (active == null || expiresAt.isAfter(active.expiresAt)) {
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
    this.error,
  });

  final bool storeAvailable;
  final Map<PremiumPlan, StoreProduct> products;
  final Map<PremiumPlan, ProductDetails> storeProducts;
  final String? error;
}

abstract interface class SubscriptionStore {
  bool get isSupported;
  Stream<List<PurchaseDetails>> get purchaseUpdates;

  Future<SubscriptionCatalog> loadCatalog();
  Future<StoreEntitlement?> currentEntitlement();
  Future<bool> purchase(ProductDetails product);
  Future<void> restore();
  Future<void> complete(PurchaseDetails purchase);
}

class AppleSubscriptionStore implements SubscriptionStore {
  AppleSubscriptionStore({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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
      );
    }
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      return const SubscriptionCatalog(
        storeAvailable: false,
        products: {},
        storeProducts: {},
      );
    }

    final response = await _inAppPurchase.queryProductDetails(
      ApexLoadSubscriptionProducts.ids,
    );
    var catalogProducts = response.productDetails;
    var missingProductIds = response.notFoundIDs;
    var catalogError = response.error?.message;

    // StoreKit 2 occasionally returns an empty response on a real device
    // without a platform error. Querying the same catalog through StoreKit 1
    // is a safe compatibility fallback and does not change the purchase IDs.
    if (catalogProducts.isEmpty) {
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
        if (legacyProducts.isNotEmpty) {
          catalogProducts = legacyProducts;
          missingProductIds = legacyResponse.invalidProductIdentifiers;
          catalogError = null;
        }
      } catch (error) {
        debugPrint('ApexLoad StoreKit 1 fallback failed: $error');
      }
    }
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

    return SubscriptionCatalog(
      storeAvailable: true,
      products: Map.unmodifiable(products),
      storeProducts: Map.unmodifiable(productDetails),
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
    this.error,
  });

  const SubscriptionStoreState.loading()
    : phase = StorePurchasePhase.loading,
      storeAvailable = false,
      products = const {},
      error = null;

  final StorePurchasePhase phase;
  final bool storeAvailable;
  final Map<PremiumPlan, StoreProduct> products;
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
    String? error,
    bool clearError = false,
  }) {
    return SubscriptionStoreState(
      phase: phase ?? this.phase,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      products: products ?? this.products,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final subscriptionStoreProvider = Provider<SubscriptionStore>(
  (ref) => AppleSubscriptionStore(),
);

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
        debugPrint('ApexLoad StoreKit purchase stream failed: $error');
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
      state = SubscriptionStoreState(
        phase: catalog.storeAvailable
            ? StorePurchasePhase.ready
            : StorePurchasePhase.unavailable,
        storeAvailable: catalog.storeAvailable,
        products: catalog.products,
        error: catalog.error,
      );
      if (!catalog.storeAvailable) return;

      final entitlement = await service.currentEntitlement();
      if (!ref.mounted) return;
      if (entitlement == null) {
        await ref
            .read(subscriptionControllerProvider.notifier)
            .clearStoreEntitlement();
      } else {
        await _activate(entitlement);
      }
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad StoreKit initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(phase: StorePurchasePhase.error, error: '$error');
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
          error: 'The App Store purchase sheet could not be opened.',
        );
      }
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad StoreKit purchase failed: $error');
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
      debugPrint('ApexLoad StoreKit restore failed: $error');
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
              ApexLoadSubscriptionProducts.planFor(purchase.productID) != null,
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
          entitlement = _fallbackEntitlement(deliverable.last);
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
        debugPrint('ApexLoad StoreKit delivery failed: $error');
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
        state = state.copyWith(phase: StorePurchasePhase.restoreNotFound);
      } else {
        await _activate(entitlement);
        if (!ref.mounted) return;
        state = state.copyWith(
          phase: StorePurchasePhase.restored,
          clearError: true,
        );
      }
    } on Object catch (error, stackTrace) {
      debugPrint('ApexLoad StoreKit entitlement restore failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!ref.mounted) return;
      state = state.copyWith(phase: StorePurchasePhase.error, error: '$error');
    }
  }

  Future<void> _activate(StoreEntitlement entitlement) {
    return ref
        .read(subscriptionControllerProvider.notifier)
        .activateStoreEntitlement(
          plan: entitlement.plan,
          expiresAt: entitlement.expiresAt,
        );
  }

  StoreEntitlement? _fallbackEntitlement(PurchaseDetails purchase) {
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
