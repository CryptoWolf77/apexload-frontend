class UserSubscriptionModel {
  const UserSubscriptionModel({
    required this.isPremium,
    required this.planName,
    required this.dailyDownloadLimit,
    required this.downloadsUsedToday,
    required this.lastResetDate,
    required this.premiumActivatedMock,
    this.expiresAt,
  });

  final bool isPremium;
  final String planName;
  final int dailyDownloadLimit;
  final int downloadsUsedToday;
  final DateTime lastResetDate;
  final bool premiumActivatedMock;
  final DateTime? expiresAt;

  bool get adsEnabled => !isPremium;
  bool get hasDailyLimit => !isPremium;
  int get remainingDownloadsToday => isPremium
      ? 999999
      : (dailyDownloadLimit - downloadsUsedToday).clamp(0, dailyDownloadLimit);
  bool canStartDownload([int requestedCount = 1]) =>
      isPremium || remainingDownloadsToday >= requestedCount;

  String get displayPlanName => isPremium ? 'Premium $planName' : 'Free Plan';

  static UserSubscriptionModel free({DateTime? now, int used = 0}) {
    final date = now ?? DateTime.now();
    return UserSubscriptionModel(
      isPremium: false,
      planName: 'Free',
      dailyDownloadLimit: 5,
      downloadsUsedToday: used,
      lastResetDate: DateTime(date.year, date.month, date.day),
      premiumActivatedMock: false,
    );
  }

  factory UserSubscriptionModel.premium({
    required String planName,
    DateTime? now,
  }) {
    final date = now ?? DateTime.now();
    return UserSubscriptionModel(
      isPremium: true,
      planName: planName,
      dailyDownloadLimit: 5,
      downloadsUsedToday: 0,
      lastResetDate: DateTime(date.year, date.month, date.day),
      premiumActivatedMock: true,
      expiresAt: DateTime(2099, 1, 1),
    );
  }

  UserSubscriptionModel copyWith({
    bool? isPremium,
    String? planName,
    int? dailyDownloadLimit,
    int? downloadsUsedToday,
    DateTime? lastResetDate,
    bool? premiumActivatedMock,
    DateTime? expiresAt,
  }) {
    return UserSubscriptionModel(
      isPremium: isPremium ?? this.isPremium,
      planName: planName ?? this.planName,
      dailyDownloadLimit: dailyDownloadLimit ?? this.dailyDownloadLimit,
      downloadsUsedToday: downloadsUsedToday ?? this.downloadsUsedToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      premiumActivatedMock: premiumActivatedMock ?? this.premiumActivatedMock,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  UserSubscriptionModel resetDailyCounter(DateTime now) {
    return copyWith(
      downloadsUsedToday: 0,
      lastResetDate: DateTime(now.year, now.month, now.day),
    );
  }

  UserSubscriptionModel incrementFreeDownload(DateTime now, {int count = 1}) {
    if (isPremium) return this;
    final normalized = _isSameDay(lastResetDate, now)
        ? this
        : resetDailyCounter(now);
    return normalized.copyWith(
      downloadsUsedToday: normalized.downloadsUsedToday + count,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

enum PremiumPlan {
  monthly('Monthly'),
  yearly('Yearly'),
  lifetime('Lifetime');

  const PremiumPlan(this.label);

  final String label;

  static PremiumPlan fromKey(String key) {
    return switch (key) {
      'monthly' => PremiumPlan.monthly,
      'yearly' => PremiumPlan.yearly,
      'lifetime' => PremiumPlan.lifetime,
      _ => PremiumPlan.yearly,
    };
  }
}

class DownloadAllowanceResult {
  const DownloadAllowanceResult({
    required this.allowed,
    this.reason = DownloadBlockReason.none,
  });

  final bool allowed;
  final DownloadBlockReason reason;
}

enum DownloadBlockReason { none, dailyLimitReached }
