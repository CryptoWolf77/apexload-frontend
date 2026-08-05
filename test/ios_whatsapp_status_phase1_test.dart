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

    test('allows official WhatsApp linking hosts', () {
      expect(
        isAllowedIosWhatsAppNavigation(
          Uri.parse('https://flows.whatsapp.net/'),
        ),
        isTrue,
      );
      expect(
        isAllowedIosWhatsAppNavigation(
          Uri.parse('https://cache.flows.whatsapp.net/cleanup'),
        ),
        isTrue,
      );
      expect(
        isAllowedIosWhatsAppNavigation(
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
    expect(iosWhatsAppWebProbeScript, contains('__apexloadRecoverStatus'));
    expect(iosWhatsAppWebProbeScript, contains('__apexloadRequestState'));
  });

  test('probe script exposes a versioned liveness ping to Dart', () {
    expect(iosWhatsAppWebProbeScript, contains('__apexloadPing'));
    expect(
      iosWhatsAppWebProbeScript,
      contains('const bridgeVersion = $iosWhatsAppBridgeVersion'),
    );
    // Re-injection must never install a second observer or handler set.
    expect(
      iosWhatsAppWebProbeScript,
      contains('if (window.__apexloadStatusBridgeInstalled)'),
    );
  });

  test('probe script snapshots existing statuses and keeps observing', () {
    expect(iosWhatsAppWebProbeScript, contains('__apexloadSynchronizeStatuses'));
    expect(iosWhatsAppWebProbeScript, contains('hydrateStatusList'));
    expect(iosWhatsAppWebProbeScript, contains('scheduleInitialSync'));
    expect(iosWhatsAppWebProbeScript, contains('isSyncing'));
    expect(iosWhatsAppWebProbeScript, contains('visibilitychange'));
    expect(iosWhatsAppWebProbeScript, contains('MutationObserver'));
    // Every retry loop must be bounded.
    expect(iosWhatsAppWebProbeScript, contains('readinessChecks++ >= 120'));
    expect(iosWhatsAppWebProbeScript, contains('const maxSteps = 12'));
    expect(iosWhatsAppWebProbeScript, isNot(contains('setInterval')));
  });

  test('status tab detection never targets the chat list', () {
    expect(iosWhatsAppWebProbeScript, contains("target.closest('#pane-side')"));
    expect(iosWhatsAppWebProbeScript, contains('statusLabelExact'));
    // Repeated recovery passes must not toggle the tab back and forth.
    expect(iosWhatsAppWebProbeScript, contains('lastStatusClickAt'));
  });

  test('desktop WhatsApp Web gets a stable edge-to-edge viewport', () {
    expect(
      iosWhatsAppWebViewportScript,
      contains('__apexloadFitDesktopViewport'),
    );
    expect(iosWhatsAppWebViewportScript, contains('const layoutWidth = 980'));
    expect(iosWhatsAppWebViewportScript, contains('initial-scale'));
    expect(iosWhatsAppWebViewportScript, isNot(contains('setInterval')));
  });

  test('pinch zoom stays enabled but bounded to a safe range', () {
    expect(iosWhatsAppWebViewportScript, contains('user-scalable=yes'));
    expect(iosWhatsAppWebViewportScript, isNot(contains('user-scalable=no')));
    // Zooming out below fit is barred; zooming in is capped well under the
    // 2.5 absolute ceiling that starved the WebContent process.
    expect(iosWhatsAppWebViewportScript, contains('minimum-scale=\${scale'));
    expect(
      iosWhatsAppWebViewportScript,
      contains('maximum-scale=\${zoomCeiling'),
    );
    expect(
      iosWhatsAppWebViewportScript,
      contains('Math.min(2, Math.max(1, scale * 2.5))'),
    );
    // The tag must survive WhatsApp Web replacing its own head tags.
    expect(iosWhatsAppWebViewportScript, contains('__apexloadViewportObserver'));
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
