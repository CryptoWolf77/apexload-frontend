import 'package:apexload/features/whatsapp_status/whatsapp_status_models.dart';
import 'package:apexload/shared/models/download_item_model.dart';

class WhatsAppStatusService {
  WhatsAppStatusService({Object? mediaService});

  Future<String?> connectedFolder({bool business = false}) async => null;

  Future<List<WhatsAppStatusSource>> detectSources() async => const [
    WhatsAppStatusSource(
      id: 'standard',
      label: 'WhatsApp',
      business: false,
      state: WhatsAppStatusConnectionState.setupRequired,
    ),
    WhatsAppStatusSource(
      id: 'business',
      label: 'WhatsApp Business',
      business: true,
      state: WhatsAppStatusConnectionState.setupRequired,
    ),
  ];

  Future<String?> connectFolder({required bool business}) async => null;

  Future<void> disconnectFolder({bool business = false}) async {}

  Future<List<WhatsAppStatusItem>> scan({bool business = false}) async =>
      const [];

  Future<DownloadItemModel> saveStatus(WhatsAppStatusItem item) {
    throw const WhatsAppStatusException('whatsappFolderAccessError');
  }
}

class WhatsAppStatusException implements Exception {
  const WhatsAppStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}
