import 'dart:async';
import 'dart:convert';

import 'package:apexload/core/constants/app_config.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/models/user_subscription_model.dart';
import 'package:apexload/shared/services/active_operation_wakelock_service.dart';
import 'package:apexload/shared/services/api_analyze_service.dart';
import 'package:apexload/shared/services/api_download_service.dart';
import 'package:apexload/shared/services/clipboard_helper_service.dart';
import 'package:apexload/shared/services/legal_consent_service.dart';
import 'package:apexload/shared/services/local_editor_service.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:apexload/shared/services/mock_download_service.dart';
import 'package:apexload/shared/services/whatsapp_status_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final analyzeServiceProvider = Provider((ref) => ApiAnalyzeService());
final apiDownloadServiceProvider = Provider((ref) => ApiDownloadService());
final activeOperationWakelockServiceProvider =
    Provider<ActiveOperationWakelockService>((ref) {
      final service = ActiveOperationWakelockService();
      ref.onDispose(() => unawaited(service.dispose()));
      return service;
    });
final localMediaServiceProvider = Provider(
  (ref) => LocalMediaService(
    wakelockService: ref.watch(activeOperationWakelockServiceProvider),
  ),
);
final localEditorServiceProvider = Provider(
  (ref) =>
      LocalEditorService(mediaService: ref.watch(localMediaServiceProvider)),
);
final whatsappStatusServiceProvider = Provider(
  (ref) =>
      WhatsAppStatusService(mediaService: ref.watch(localMediaServiceProvider)),
);
final downloadServiceProvider = Provider((ref) => MockDownloadService());
final clipboardServiceProvider = Provider((ref) => ClipboardHelperService());
final legalConsentServiceProvider = Provider(
  (ref) => const LegalConsentService(),
);

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
final autoSaveToGalleryControllerProvider =
    NotifierProvider<AutoSaveToGalleryController, bool>(
      AutoSaveToGalleryController.new,
    );
final keepScreenAwakeControllerProvider =
    NotifierProvider<KeepScreenAwakeController, bool>(
      KeepScreenAwakeController.new,
    );
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

class AutoSaveToGalleryController extends Notifier<bool> {
  static const _preferenceKey = 'auto_save_to_gallery';
  static const _defaultEnabledMigrationKey =
      'auto_save_to_gallery_default_enabled_v2';
  Future<void>? _loadFuture;

  @override
  bool build() {
    _loadFuture = _load();
    return true;
  }

  Future<void> setEnabled(bool enabled) async {
    final load = _loadFuture;
    if (load != null) await load;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, enabled);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    if (prefs.getBool(_defaultEnabledMigrationKey) != true) {
      await prefs.setBool(_preferenceKey, true);
      await prefs.setBool(_defaultEnabledMigrationKey, true);
      if (!ref.mounted) return;
      state = true;
      return;
    }
    state = prefs.getBool(_preferenceKey) ?? true;
  }
}

class KeepScreenAwakeController extends Notifier<bool> {
  static const preferenceKey = 'keep_screen_awake_during_downloads';
  Future<void>? _loadFuture;

  @override
  bool build() {
    _loadFuture = _load();
    return true;
  }

  Future<void> setEnabled(bool enabled) async {
    final load = _loadFuture;
    if (load != null) await load;
    state = enabled;
    await ref
        .read(activeOperationWakelockServiceProvider)
        .setUserEnabled(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferenceKey, enabled);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final enabled = prefs.getBool(preferenceKey) ?? true;
    state = enabled;
    await ref
        .read(activeOperationWakelockServiceProvider)
        .setUserEnabled(enabled);
  }
}

class SubscriptionController extends Notifier<UserSubscriptionModel> {
  static const _isPremiumKey = 'subscription_is_premium';
  static const _planNameKey = 'subscription_plan_name';
  static const _downloadsUsedKey = 'subscription_downloads_used_today';
  static const _lastResetDateKey = 'subscription_last_reset_date';
  static const _premiumActivatedMockKey = 'subscription_premium_mock';
  static const _expiresAtKey = 'subscription_expires_at';

  SharedPreferences? _prefs;
  Future<void>? _loadFuture;

  @override
  UserSubscriptionModel build() {
    if (AppConfig.testerPremiumEnabled) {
      _loadFuture = Future<void>.value();
      return _testerPremiumEntitlement();
    }
    _loadFuture = _load();
    return UserSubscriptionModel.free();
  }

  UserSubscriptionModel _testerPremiumEntitlement() {
    return UserSubscriptionModel.premium(
      planName: 'TestFlight Tester',
      expiresAt: DateTime(2099, 1, 1),
      premiumActivatedMock: true,
    );
  }

  Future<void> activateStoreEntitlement({
    required PremiumPlan plan,
    required DateTime expiresAt,
  }) async {
    await _ensureLoaded();
    if (AppConfig.testerPremiumEnabled) {
      state = _testerPremiumEntitlement();
      return;
    }
    state = UserSubscriptionModel.premium(
      planName: plan.label,
      expiresAt: expiresAt,
    );
    await _save();
  }

  Future<void> clearStoreEntitlement() async {
    await _ensureLoaded();
    if (AppConfig.testerPremiumEnabled) {
      state = _testerPremiumEntitlement();
      return;
    }
    if (!state.isStoreManagedPremium) return;
    state = UserSubscriptionModel.free(
      now: state.lastResetDate,
      used: state.downloadsUsedToday,
    );
    _resetDailyIfNeeded();
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

    state = state.incrementFreeDownload(DateTime.now(), count: count);
    await _save();
    // Real ad mediation is intentionally not enabled in this release build yet.
    // Keep tracking the free download count, but do not show placeholder ads.
    return false;
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
    final expiresAt = DateTime.tryParse(prefs.getString(_expiresAtKey) ?? '');

    if (isPremium &&
        (premiumMock || (expiresAt != null && expiresAt.isAfter(now)))) {
      state = UserSubscriptionModel.premium(
        planName: planName,
        now: now,
        expiresAt: premiumMock ? DateTime(2099, 1, 1) : expiresAt,
        premiumActivatedMock: premiumMock,
      );
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
    final expiresAt = snapshot.expiresAt;
    if (expiresAt == null) {
      await prefs.remove(_expiresAtKey);
    } else {
      await prefs.setString(_expiresAtKey, expiresAt.toIso8601String());
    }
  }
}

class LibraryController extends Notifier<List<DownloadItemModel>> {
  static const _libraryKey = 'apexload_download_library_v1';

  SharedPreferences? _prefs;
  Future<void>? _loadFuture;

  @override
  List<DownloadItemModel> build() {
    _loadFuture = _load();
    return const [];
  }

  void add(DownloadItemModel item) {
    final cleaned = _clean(item);
    state = [
      cleaned,
      ...state.where((existing) => !_sameLibraryIdentity(existing, cleaned)),
    ];
    unawaited(_save());
  }

  Future<void> addAndSave(DownloadItemModel item) async {
    final cleaned = _clean(item);
    state = [
      cleaned,
      ...state.where((existing) => !_sameLibraryIdentity(existing, cleaned)),
    ];
    await _save();
  }

  void delete(String id) {
    state = state.where((item) => item.id != id).toList();
    unawaited(_save());
  }

  void rename(String id, String fileName) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(fileName: fileName) else item,
    ];
    unawaited(_save());
  }

  void clearCachedThumbnails() {
    state = [
      for (final item in state)
        if (item.thumbnailPath.isNotEmpty)
          item.copyWith(thumbnailPath: '')
        else
          item,
    ];
    unawaited(_save());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    _prefs = prefs;
    final stored = prefs.getString(_libraryKey);
    var items = <DownloadItemModel>[];
    if (stored != null && stored.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          items = decoded
              .whereType<Map>()
              .map(
                (row) => DownloadItemModel.fromJson(
                  row.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .map(_clean)
              .where((item) => item.id.isNotEmpty)
              .toList();
        }
      } on Object {
        items = const [];
      }
    }
    final repaired = await ref
        .read(localMediaServiceProvider)
        .discoverExistingDownloads(existing: items);
    if (!ref.mounted) return;
    state = _dedupeAndSort([...repaired, ...items]);
    await _save();
  }

  Future<void> _save() async {
    final future = _loadFuture;
    if (future != null && _prefs == null) await future;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    _prefs = prefs;
    final rows = state.map((item) => item.toJson()).toList();
    await prefs.setString(_libraryKey, jsonEncode(rows));
  }

  DownloadItemModel _clean(DownloadItemModel item) {
    final title = item.title.trim().isEmpty ? item.fileName : item.title;
    final fileName = item.fileName.trim().isEmpty ? title : item.fileName;
    return item.copyWith(
      title: title.trim(),
      fileName: fileName.trim(),
      platform: item.platform.trim().isEmpty ? 'ApexLoad' : item.platform,
      sizeLabel: item.sizeLabel.trim(),
    );
  }

  List<DownloadItemModel> _dedupeAndSort(List<DownloadItemModel> items) {
    final result = <DownloadItemModel>[];
    for (final item in items) {
      if (item.id.trim().isEmpty) continue;
      final index = result.indexWhere(
        (existing) => _sameLibraryIdentity(existing, item),
      );
      if (index >= 0) {
        result[index] = item.date.isAfter(result[index].date)
            ? item
            : result[index];
      } else {
        result.add(item);
      }
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  bool _sameLibraryIdentity(
    DownloadItemModel existing,
    DownloadItemModel incoming,
  ) {
    if (existing.id == incoming.id) return true;
    if (incoming.fileId.trim().isNotEmpty &&
        existing.fileId == incoming.fileId) {
      return true;
    }
    if (incoming.localFilePath.trim().isNotEmpty &&
        existing.localFilePath == incoming.localFilePath) {
      return true;
    }
    if (incoming.downloadUrl.trim().isNotEmpty &&
        existing.downloadUrl == incoming.downloadUrl) {
      return true;
    }
    return false;
  }
}
