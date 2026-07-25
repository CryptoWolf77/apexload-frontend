import 'package:apexload/features/whatsapp_status/ios/ios_whatsapp_guide_store.dart';
import 'package:apexload/features/whatsapp_status/ios/ios_whatsapp_media_bridge.dart';
import 'package:apexload/features/whatsapp_status/ios/ios_whatsapp_web_scripts.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('iOS WhatsApp Phase 1 navigation', () {
    test('allows only the official WhatsApp Web host', () {
      expect(
        isAllowedIosWhatsAppNavigation(Uri.parse('https://web.whatsapp.com/')),
        isTrue,
      );
      expect(
        isAllowedIosWhatsAppNavigation(
          Uri.parse('https://web.whatsapp.com/status'),
        ),
        isTrue,
      );
      expect(
        isAllowedIosWhatsAppNavigation(
          Uri.parse('https://example.com/web.whatsapp.com'),
        ),
        isFalse,
      );
      expect(
        isAllowedIosWhatsAppNavigation(Uri.parse('http://web.whatsapp.com/')),
        isFalse,
      );
    });

    test('allows WebKit internal media URLs', () {
      expect(isAllowedIosWhatsAppNavigation(Uri.parse('about:blank')), isTrue);
      expect(
        isAllowedIosWhatsAppNavigation(Uri.parse('blob:https://example.com/1')),
        isTrue,
      );
      expect(
        isAllowedIosWhatsAppNavigation(Uri.parse('javascript:alert(1)')),
        isFalse,
      );
    });

    test('recognizes WhatsApp linking return pages without opening Safari', () {
      expect(
        isIosWhatsAppReturnNavigation(Uri.parse('https://flows.whatsapp.net/')),
        isTrue,
      );
      expect(
        isIosWhatsAppReturnNavigation(
          Uri.parse('https://cache.flows.whatsapp.net/cleanup'),
        ),
        isTrue,
      );
      expect(
        isIosWhatsAppReturnNavigation(
          Uri.parse('https://flows.whatsapp.net.example.com/'),
        ),
        isFalse,
      );
    });
  });

  group('iOS WhatsApp Phase 1 media mapping', () {
    test('maps supported MIME types to safe extensions', () {
      expect(statusExtensionForMime('video/mp4'), 'mp4');
      expect(statusExtensionForMime('video/quicktime'), 'mov');
      expect(statusExtensionForMime('image/png'), 'png');
      expect(statusExtensionForMime('image/jpeg'), 'jpg');
      expect(statusExtensionForMime('image/webp'), 'png');
      expect(statusExtensionForMime('image/gif'), 'png');
      expect(statusExtensionForMime('application/octet-stream'), 'jpg');
    });

    test('maps media MIME types to ApexLoad download types', () {
      expect(statusTypeForMime('video/mp4'), DownloadType.video);
      expect(statusTypeForMime('image/jpeg'), DownloadType.image);
    });
  });

  test('probe script installs both state and chunk bridges', () {
    expect(iosWhatsAppWebProbeScript, contains('apexloadWhatsAppState'));
    expect(iosWhatsAppWebProbeScript, contains('apexloadMediaChunk'));
    expect(iosWhatsAppWebProbeScript, contains('URL.createObjectURL'));
    expect(iosWhatsAppWebProbeScript, contains('element.srcset'));
    expect(iosWhatsAppWebProbeScript, contains('createImageBitmap'));
    expect(iosWhatsAppWebProbeScript, contains("'image/png'"));
    expect(iosWhatsAppWebProbeScript, contains('element.naturalWidth'));
    expect(iosWhatsAppWebProbeScript, contains('placeholder image'));
    expect(
      iosWhatsAppWebProbeScript,
      contains('__apexloadExportCurrentStatus'),
    );
  });

  test('desktop WhatsApp Web gets an edge-to-edge adaptive viewport', () {
    expect(
      iosWhatsAppWebViewportScript,
      contains('__apexloadFitDesktopViewport'),
    );
    expect(iosWhatsAppWebViewportScript, contains('initial-scale'));
    expect(iosWhatsAppWebViewportScript, contains('user-scalable=yes'));
    expect(iosWhatsAppWebViewportScript, contains('minimumDesktopWidth = 800'));
  });

  test(
    'guide completion persists only after connection and first save',
    () async {
      const store = IosWhatsAppGuideStore();
      var state = await store.load();
      expect(state.connectionComplete, isFalse);
      expect(state.firstSaveComplete, isFalse);

      await store.markConnectionComplete();
      state = await store.load();
      expect(state.connectionComplete, isTrue);
      expect(state.firstSaveComplete, isFalse);

      await store.markFirstSaveComplete();
      state = await store.load();
      expect(state.firstSaveComplete, isTrue);

      await store.resetConnection();
      state = await store.load();
      expect(state.connectionComplete, isFalse);
      expect(state.firstSaveComplete, isTrue);
    },
  );
}
