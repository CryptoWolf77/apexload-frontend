import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEdition {
  store,
  full;

  static AppEdition fromFlavor(String? flavor) {
    return flavor == 'store' ? AppEdition.store : AppEdition.full;
  }

  bool get isStore => this == AppEdition.store;
  bool get isFull => this == AppEdition.full;
}

final appEditionProvider = Provider<AppEdition>((ref) => AppEdition.full);
