import 'package:shared_preferences/shared_preferences.dart';

class IosWhatsAppGuideState {
  const IosWhatsAppGuideState({
    required this.connectionComplete,
    required this.firstSaveComplete,
  });

  final bool connectionComplete;
  final bool firstSaveComplete;
}

class IosWhatsAppGuideStore {
  const IosWhatsAppGuideStore();

  static const connectionCompleteKey =
      'ios_whatsapp_connection_guide_complete_v1';
  static const firstSaveCompleteKey =
      'ios_whatsapp_first_save_guide_complete_v1';

  Future<IosWhatsAppGuideState> load() async {
    final preferences = await SharedPreferences.getInstance();
    return IosWhatsAppGuideState(
      connectionComplete: preferences.getBool(connectionCompleteKey) ?? false,
      firstSaveComplete: preferences.getBool(firstSaveCompleteKey) ?? false,
    );
  }

  Future<void> markConnectionComplete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(connectionCompleteKey, true);
  }

  Future<void> resetConnection() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(connectionCompleteKey, false);
  }

  Future<void> markFirstSaveComplete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(firstSaveCompleteKey, true);
  }
}
