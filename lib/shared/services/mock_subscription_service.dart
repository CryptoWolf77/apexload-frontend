import 'dart:async';

import 'package:apexload/shared/models/user_subscription_model.dart';

class MockSubscriptionService {
  Future<UserSubscriptionModel> activatePremium(PremiumPlan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return UserSubscriptionModel.premium(planName: plan.label);
  }
}
