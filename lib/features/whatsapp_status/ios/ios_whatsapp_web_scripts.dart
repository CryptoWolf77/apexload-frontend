const iosWhatsAppWebDesktopUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/136.0.0.0 Safari/537.36';

/// WhatsApp Web requires a desktop-width layout. On iPhone, give WebKit a
/// stable desktop viewport and let it scale that viewport edge-to-edge.
///
/// The script keeps one authoritative viewport tag, grows the layout only
/// when WhatsApp needs more horizontal space, and retains user pinch zoom.
const iosWhatsAppWebViewportScript = r'''
(() => {
  const minimumDesktopWidth = 800;
  const maximumDesktopWidth = 1440;

  const physicalViewportWidth = () => {
    const viewport = window.visualViewport;
    const measured = viewport
      ? viewport.width * viewport.scale
      : Math.min(window.innerWidth, window.screen.width || window.innerWidth);
    return Math.max(320, Math.round(measured));
  };

  const applyDesktopViewport = () => {
    if (!document.head || !document.documentElement) return null;

    const documentWidth = Math.max(
      document.documentElement.scrollWidth || 0,
      document.body?.scrollWidth || 0,
    );
    const layoutWidth = Math.min(
      maximumDesktopWidth,
      Math.max(minimumDesktopWidth, documentWidth),
    );
    const scale = Math.min(1, physicalViewportWidth() / layoutWidth);
    const content = [
      `width=${layoutWidth}`,
      `initial-scale=${scale.toFixed(4)}`,
      'minimum-scale=0.25',
      'maximum-scale=2.5',
      'user-scalable=yes',
      'viewport-fit=cover',
    ].join(', ');

    const viewportTags = [
      ...document.head.querySelectorAll('meta[name="viewport"]'),
    ];
    const viewport = viewportTags.shift() || document.createElement('meta');
    viewport.name = 'viewport';
    if (viewport.content !== content) viewport.content = content;
    if (!viewport.isConnected) document.head.appendChild(viewport);
    viewportTags.forEach((duplicate) => duplicate.remove());

    return { layoutWidth, scale };
  };

  window.__apexloadFitDesktopViewport = applyDesktopViewport;

  let fitTimer = null;
  const scheduleFit = () => {
    clearTimeout(fitTimer);
    fitTimer = setTimeout(applyDesktopViewport, 100);
  };

  if (!window.__apexloadViewportObserverInstalled) {
    window.__apexloadViewportObserverInstalled = true;
    const start = () => {
      applyDesktopViewport();
      new MutationObserver(scheduleFit).observe(
        document.head || document.documentElement,
        {
          childList: true,
        },
      );
    };
    if (document.documentElement) {
      start();
    } else {
      addEventListener('DOMContentLoaded', start, { once: true });
    }
    addEventListener('resize', scheduleFit);
    addEventListener('orientationchange', scheduleFit);
    setInterval(applyDesktopViewport, 2000);
  } else {
    applyDesktopViewport();
  }
})();
''';

const iosWhatsAppWebProbeScript = r'''
(() => {
  if (window.__apexloadStatusBridgeInstalled) return;
  window.__apexloadStatusBridgeInstalled = true;

  const objectUrls = new Map();
  const originalCreateObjectURL = URL.createObjectURL.bind(URL);
  const originalRevokeObjectURL = URL.revokeObjectURL.bind(URL);

  URL.createObjectURL = (object) => {
    const url = originalCreateObjectURL(object);
    if (object instanceof Blob) objectUrls.set(url, object);
    return url;
  };

  URL.revokeObjectURL = (url) => {
    objectUrls.delete(url);
    return originalRevokeObjectURL(url);
  };

  const isVisible = (element) => {
    if (!element) return false;
    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    return rect.width >= 180 &&
      rect.height >= 180 &&
      rect.bottom > 0 &&
      rect.right > 0 &&
      rect.top < innerHeight &&
      rect.left < innerWidth &&
      style.display !== 'none' &&
      style.visibility !== 'hidden' &&
      Number(style.opacity || '1') > 0;
  };

  const highestQualitySource = (element) => {
    if (!(element instanceof HTMLImageElement)) {
      return element.currentSrc || element.src;
    }
    const srcset = (element.srcset || '')
      .split(',')
      .map((entry) => entry.trim())
      .filter(Boolean)
      .map((entry) => {
        const parts = entry.split(/\s+/);
        const descriptor = parts[parts.length - 1] || '';
        const score = descriptor.endsWith('w')
          ? Number.parseFloat(descriptor) || 0
          : descriptor.endsWith('x')
          ? (Number.parseFloat(descriptor) || 0) * 10000
          : 0;
        return {
          source: parts.length > 1 ? parts.slice(0, -1).join(' ') : entry,
          score,
        };
      })
      .sort((a, b) => b.score - a.score);
    return srcset[0]?.source || element.src || element.currentSrc;
  };

  const currentMediaCandidates = () => {
    return [...document.querySelectorAll('video, img')]
      .filter(isVisible)
      .map((element) => {
        const rect = element.getBoundingClientRect();
        const source = highestQualitySource(element);
        const isVideo = element instanceof HTMLVideoElement;
        const intrinsicWidth = isVideo
          ? (element.videoWidth || rect.width)
          : element.naturalWidth;
        const intrinsicHeight = isVideo
          ? (element.videoHeight || rect.height)
          : element.naturalHeight;
        const intrinsicArea = intrinsicWidth * intrinsicHeight;
        const videoBonus = isVideo ? 1e15 : 0;
        return {
          element,
          source,
          intrinsicWidth,
          intrinsicHeight,
          score: videoBonus + intrinsicArea * 10000 +
            rect.width * rect.height,
        };
      })
      .filter((candidate) => candidate.source &&
        candidate.intrinsicWidth >= 96 &&
        candidate.intrinsicHeight >= 96)
      .sort((a, b) => b.score - a.score);
  };

  const currentMedia = () => currentMediaCandidates()[0] || null;

  let lastState = '';
  let stateTimer = null;
  const reportState = () => {
    clearTimeout(stateTimer);
    stateTimer = setTimeout(async () => {
      const connected = Boolean(document.querySelector(
        '#pane-side, [data-testid="chat-list"], [aria-label*="Chat list"]'
      ));
      const qrVisible = Boolean(document.querySelector(
        'canvas, [data-ref], [data-testid*="qrcode"]'
      )) && !connected;
      const media = currentMedia();
      const state = JSON.stringify({
        connected,
        qrVisible,
        statusOpen: Boolean(media),
        mediaKind: media?.element instanceof HTMLVideoElement ? 'video' :
          (media ? 'image' : ''),
      });
      if (state === lastState || !window.flutter_inappwebview) return;
      lastState = state;
      await window.flutter_inappwebview.callHandler(
        'apexloadWhatsAppState',
        JSON.parse(state),
      );
    }, 350);
  };

  const toBase64 = (buffer) => {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    const step = 0x8000;
    for (let offset = 0; offset < bytes.length; offset += step) {
      binary += String.fromCharCode(
        ...bytes.subarray(offset, Math.min(offset + step, bytes.length)),
      );
    }
    return btoa(binary);
  };

  const normalizeStillImage = async (blob) => {
    const mime = (blob.type || '').toLowerCase().split(';')[0].trim();
    const bitmap = await createImageBitmap(blob);
    try {
      if (bitmap.width < 96 || bitmap.height < 96) {
        throw new Error('WhatsApp returned a placeholder image.');
      }
      if (mime === 'image/jpeg' || mime === 'image/jpg' ||
          mime === 'image/png') {
        return blob;
      }
      const canvas = document.createElement('canvas');
      canvas.width = bitmap.width;
      canvas.height = bitmap.height;
      const context = canvas.getContext('2d', { alpha: true });
      if (!context) throw new Error('Image conversion is unavailable.');
      context.drawImage(bitmap, 0, 0);
      const png = await new Promise((resolve, reject) => {
        canvas.toBlob(
          (converted) => converted
            ? resolve(converted)
            : reject(new Error('Image conversion failed.')),
          'image/png',
        );
      });
      return png;
    } finally {
      bitmap.close?.();
    }
  };

  window.__apexloadExportCurrentStatus = async (captureId) => {
    const media = currentMedia();
    if (!media) {
      return { ok: false, error: 'Open a photo or video status first.' };
    }

    try {
      let blob = objectUrls.get(media.source);
      if (!blob) {
        const response = await fetch(media.source, {
          credentials: 'include',
          cache: 'force-cache',
        });
        if (!response.ok) {
          throw new Error(`Media request failed (${response.status}).`);
        }
        blob = await response.blob();
      }

      if (!(media.element instanceof HTMLVideoElement)) {
        blob = await normalizeStillImage(blob);
      }
      const mime = blob.type ||
        (media.element instanceof HTMLVideoElement ? 'video/mp4' : 'image/jpeg');
      const chunkSize = 256 * 1024;
      let index = 0;
      for (let offset = 0; offset < blob.size; offset += chunkSize) {
        const slice = blob.slice(offset, Math.min(offset + chunkSize, blob.size));
        const buffer = await slice.arrayBuffer();
        await window.flutter_inappwebview.callHandler('apexloadMediaChunk', {
          captureId,
          index,
          mime,
          totalBytes: blob.size,
          data: toBase64(buffer),
          done: false,
        });
        index += 1;
      }

      await window.flutter_inappwebview.callHandler('apexloadMediaChunk', {
        captureId,
        index,
        mime,
        totalBytes: blob.size,
        data: '',
        done: true,
      });
      return { ok: true, mime, totalBytes: blob.size };
    } catch (error) {
      return {
        ok: false,
        error: error?.message || 'The current status could not be captured.',
      };
    }
  };

  const startObserver = () => {
    if (!document.documentElement) return;
    new MutationObserver(reportState).observe(document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['src', 'style', 'class'],
    });
    reportState();
  };
  if (document.documentElement) {
    startObserver();
  } else {
    addEventListener('DOMContentLoaded', startObserver, { once: true });
  }
  addEventListener('popstate', reportState);
  addEventListener('hashchange', reportState);
  setInterval(reportState, 2500);
})();
''';

bool isAllowedIosWhatsAppNavigation(Uri? uri) {
  if (uri == null) return false;
  if (const {'about', 'blob', 'data'}.contains(uri.scheme)) return true;
  if (uri.scheme != 'https') return false;
  return uri.host.toLowerCase() == 'web.whatsapp.com';
}

/// WhatsApp briefly visits this first-party cleanup endpoint after an iOS
/// linking flow. ApexLoad consumes it inside the WebView and returns directly
/// to WhatsApp Web instead of sending the user to a blank Safari page.
bool isIosWhatsAppReturnNavigation(Uri? uri) {
  if (uri == null || uri.scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  return host == 'flows.whatsapp.net' || host.endsWith('.flows.whatsapp.net');
}
