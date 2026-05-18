import 'dart:async';

import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/clipboard_helper_service.dart';
import 'package:apexload/shared/services/mock_download_service.dart';
import 'package:apexload/shared/services/mock_library_service.dart';
import 'package:apexload/shared/services/mock_subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final analyzeServiceProvider = Provider((ref) => ApiAnalyzeService());
final apiDownloadServiceProvider = Provider((ref) => ApiDownloadService());
final downloadServiceProvider = Provider((ref) => MockDownloadService());
final subscriptionServiceProvider = Provider(
  (ref) => MockSubscriptionService(),
);
final clipboardServiceProvider = Provider((ref) => ClipboardHelperService());

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, UserSubscriptionModel>(
      SubscriptionController.new,
    );
final libraryControllerProvider =
    NotifierProvider<LibraryController, List<DownloadItemModel>>(
      LibraryController.new,
    );

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void setSystem() => state = null;
  void setEnglish() => state = const Locale('en');
  void setArabic() => state = const Locale('ar');
}

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void setMode(ThemeMode mode) => state = mode;
}

class SubscriptionController extends Notifier<UserSubscriptionModel> {
  static const _isPremiumKey = 'subscription_is_premium';
  static const _planNameKey = 'subscription_plan_name';
  static const _downloadsUsedKey = 'subscription_downloads_used_today';
  static const _lastResetDateKey = 'subscription_last_reset_date';
  static const _premiumActivatedMockKey = 'subscription_premium_mock';

  SharedPreferences? _prefs;
  Future<void>? _loadFuture;

  @override
  UserSubscriptionModel build() {
    _loadFuture = _load();
    return UserSubscriptionModel.free();
  }

  Future<void> activatePremium(PremiumPlan plan) async {
    await _ensureLoaded();
    state = await ref.read(subscriptionServiceProvider).activatePremium(plan);
    await _save();
  }

  Future<DownloadAllowanceResult> checkDownloadAllowance({
    int requestedCount = 1,
  }) async {
    await _ensureLoaded();
    _resetDailyIfNeeded();
    if (state.canStartDownload(requestedCount)) {
      return const DownloadAllowanceResult(allowed: true);
    }
    return const DownloadAllowanceResult(
      allowed: false,
      reason: DownloadBlockReason.dailyLimitReached,
    );
  }

  Future<bool> recordSuccessfulDownload({int count = 1}) async {
    await _ensureLoaded();
    _resetDailyIfNeeded();
    if (state.isPremium) {
      return false;
    }

    final previousCount = state.downloadsUsedToday;
    state = state.incrementFreeDownload(DateTime.now(), count: count);
    await _save();
    return state.adsEnabled &&
        (previousCount ~/ 2) < (state.downloadsUsedToday ~/ 2);
  }

  Future<void> _ensureLoaded() async {
    final future = _loadFuture;
    if (future != null) await future;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    _prefs = prefs;

    final now = DateTime.now();
    final isPremium = prefs.getBool(_isPremiumKey) ?? false;
    final planName = prefs.getString(_planNameKey) ?? 'Free';
    final used = prefs.getInt(_downloadsUsedKey) ?? 0;
    final resetText = prefs.getString(_lastResetDateKey);
    final resetDate = DateTime.tryParse(resetText ?? '') ?? now;
    final premiumMock = prefs.getBool(_premiumActivatedMockKey) ?? false;

    if (isPremium) {
      state = UserSubscriptionModel.premium(planName: planName, now: now);
      return;
    }

    state = UserSubscriptionModel.free(now: resetDate, used: used);
    state = state.copyWith(premiumActivatedMock: premiumMock);
    _resetDailyIfNeeded();
  }

  void _resetDailyIfNeeded() {
    final now = DateTime.now();
    final last = state.lastResetDate;
    final sameDay =
        last.year == now.year && last.month == now.month && last.day == now.day;
    if (!sameDay) {
      state = state.resetDailyCounter(now);
      unawaited(_save(state));
    }
  }

  Future<void> _save([UserSubscriptionModel? model]) async {
    final snapshot = model ?? state;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    _prefs = prefs;
    await prefs.setBool(_isPremiumKey, snapshot.isPremium);
    await prefs.setString(_planNameKey, snapshot.planName);
    await prefs.setInt(_downloadsUsedKey, snapshot.downloadsUsedToday);
    await prefs.setString(
      _lastResetDateKey,
      snapshot.lastResetDate.toIso8601String(),
    );
    await prefs.setBool(
      _premiumActivatedMockKey,
      snapshot.premiumActivatedMock,
    );
  }
}

class LibraryController extends Notifier<List<DownloadItemModel>> {
  @override
  List<DownloadItemModel> build() => MockLibraryService().initialItems();

  void add(DownloadItemModel item) => state = [item, ...state];

  void delete(String id) =>
      state = state.where((item) => item.id != id).toList();

  void rename(String id, String fileName) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(fileName: fileName) else item,
    ];
  }
}
