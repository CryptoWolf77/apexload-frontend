const iosWhatsAppWebDesktopUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';

/// WhatsApp Web requires a desktop-width layout. On iPhone, give WebKit a
/// stable desktop viewport and let it scale that viewport edge-to-edge.
///
/// The script keeps one authoritative viewport tag and bounds the zoom range.
///
/// Pinch zoom stays enabled, but only between "fits the screen" and a modest
/// ceiling. The blue screen was caused by the *range*, not by zooming: the
/// previous tag allowed `minimum-scale=0.25, maximum-scale=2.5` against a fit
/// scale of roughly 0.4, so the user could zoom more than six times past fit.
/// Re-rasterising every composited layer of a 980px WhatsApp Web layout at
/// that magnification holds the outgoing and incoming tiles at once, and the
/// resulting spike is what iOS killed the WebContent process for.
///
/// Zoom is bounded here rather than through `InAppWebViewSettings.supportZoom`,
/// because the iOS plugin implements that flag by appending its own
/// `width=device-width` viewport tag, which would destroy the desktop layout
/// WhatsApp Web needs.
const iosWhatsAppWebViewportScript = r'''
(() => {
  const layoutWidth = 980;

  const physicalViewportWidth = () => {
    const viewport = window.visualViewport;
    const measured = viewport
      ? viewport.width * viewport.scale
      : Math.min(window.innerWidth, window.screen.width || window.innerWidth);
    return Math.max(320, Math.round(measured));
  };

  let applying = false;

  const applyDesktopViewport = () => {
    if (!document.head || applying) return null;

    const scale = Math.min(1, physicalViewportWidth() / layoutWidth);
    // Allow roughly 2.5x magnification from fit, never beyond 2.0 absolute.
    // Zooming out below fit is not useful and triggers the same re-raster, so
    // the fit scale is also the floor.
    const zoomCeiling = Math.min(2, Math.max(1, scale * 2.5));
    const content = [
      `width=${layoutWidth}`,
      `initial-scale=${scale.toFixed(4)}`,
      `minimum-scale=${scale.toFixed(4)}`,
      `maximum-scale=${zoomCeiling.toFixed(4)}`,
      'user-scalable=yes',
      'viewport-fit=cover',
    ].join(', ');

    applying = true;
    try {
      // Collapse any extra viewport tags WhatsApp Web (or a plugin script)
      // added so a single authoritative tag decides the scale.
      const tags = [...document.head.querySelectorAll('meta[name="viewport"]')];
      for (const extra of tags.slice(1)) extra.remove();
      let viewport = tags[0];
      if (!viewport) {
        viewport = document.createElement('meta');
        viewport.name = 'viewport';
        document.head.appendChild(viewport);
      }
      if (viewport.content !== content) viewport.content = content;
    } finally {
      applying = false;
    }

    return { layoutWidth, scale, zoomCeiling };
  };

  window.__apexloadFitDesktopViewport = applyDesktopViewport;

  // WhatsApp Web is a single-page app that can swap its own head tags. Watch
  // the head instead of polling so the pinned scale survives SPA navigation.
  const watchHead = () => {
    if (!document.head || window.__apexloadViewportObserver) return;
    window.__apexloadViewportObserver = new MutationObserver(() => {
      applyDesktopViewport();
    });
    window.__apexloadViewportObserver.observe(document.head, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['content', 'name'],
    });
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      applyDesktopViewport();
      watchHead();
    }, { once: true });
  } else {
    applyDesktopViewport();
    watchHead();
  }
  addEventListener('orientationchange', applyDesktopViewport);
})();
''';

/// Bridge contract version. Bump whenever the injected handler surface changes
/// so Dart can detect a stale bridge left behind by an older page session.
const iosWhatsAppBridgeVersion = 2;

const iosWhatsAppWebProbeScript = r'''
(() => {
  const bridgeVersion = 2;
  if (window.__apexloadStatusBridgeInstalled) {
    // Never install a second set of observers or handler wrappers. Re-running
    // the script is a no-op apart from refreshing the reported state.
    window.__apexloadRequestState?.();
    return;
  }
  window.__apexloadStatusBridgeInstalled = true;
  window.__apexloadStatusBridgeVersion = bridgeVersion;
  window.__apexloadPing = () => bridgeVersion;

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

  const isActionVisible = (element) => {
    if (!element) return false;
    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    return rect.width > 0 &&
      rect.height > 0 &&
      rect.bottom > 0 &&
      rect.right > 0 &&
      rect.top < innerHeight &&
      rect.left < innerWidth &&
      style.display !== 'none' &&
      style.visibility !== 'hidden';
  };

  const statusLabel = /(status|updates|الحالة|الحالات|التحديثات)/i;
  const statusLabelExact =
    /^\s*(status|status updates|updates|الحالة|الحالات|التحديثات)\s*$/i;

  const isConnected = () => Boolean(document.querySelector(
    '#pane-side, [data-testid="chat-list"], [aria-label*="Chat list"]'
  ));

  // A freshly linked device downloads its history before WhatsApp Web can show
  // anything that existed before the link. Reloading or clicking during that
  // window restarts the sync, which is why statuses published earlier never
  // showed up. Detect the phase from WhatsApp's own progress affordances only
  // (no page text is read, so nothing private is inspected or transmitted).
  const isSyncing = () => {
    if (document.querySelector('#initial_startup, [data-testid="startup"]')) {
      return true;
    }
    for (const bar of document.querySelectorAll('progress,[role="progressbar"]')) {
      if (isActionVisible(bar)) return true;
    }
    return false;
  };

  // The chat/updates list is virtualized: only the rows near the viewport are
  // in the DOM. Nothing outside `#pane-side` is inspected.
  const listPane = () => document.querySelector('#pane-side');

  const renderedRowCount = () => {
    const pane = listPane();
    if (!pane) return 0;
    return pane.querySelectorAll('[role="listitem"],[role="row"]').length;
  };

  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  let hydrating = false;
  // Walk the virtualized list once so every already-synced entry is realised,
  // then restore the user's scroll position. Bounded by `maxSteps`.
  const hydrateStatusList = async () => {
    if (hydrating) return renderedRowCount();
    hydrating = true;
    try {
      const pane = listPane();
      if (!pane) return 0;
      const origin = pane.scrollTop;
      let seen = renderedRowCount();
      const maxSteps = 12;
      for (let step = 0; step < maxSteps; step++) {
        const before = pane.scrollTop;
        pane.scrollTop = Math.min(
          pane.scrollHeight,
          before + Math.max(240, pane.clientHeight * 0.9),
        );
        if (pane.scrollTop <= before) break;
        await sleep(180);
        seen = Math.max(seen, renderedRowCount());
      }
      pane.scrollTop = origin;
      return seen;
    } catch (_) {
      return 0;
    } finally {
      hydrating = false;
    }
  };

  let lastState = '';
  let stateTimer = null;
  let knownStatusCount = 0;
  const reportState = (force = false) => {
    clearTimeout(stateTimer);
    stateTimer = setTimeout(async () => {
      // A throw here would reject silently and permanently stop every future
      // state update, stranding the UI on "waiting". Always keep reporting.
      try {
        const connected = isConnected();
        const qrVisible = Boolean(document.querySelector(
          'canvas, [data-ref], [data-testid*="qrcode"]'
        )) && !connected;
        const media = currentMedia();
        const state = JSON.stringify({
          bridge: bridgeVersion,
          connected,
          qrVisible,
          syncing: !connected && !qrVisible ? false : isSyncing(),
          statusOpen: Boolean(media),
          statusCount: knownStatusCount,
          mediaKind: media?.element instanceof HTMLVideoElement ? 'video' :
            (media ? 'image' : ''),
        });
        if ((!force && state === lastState) || !window.flutter_inappwebview) {
          return;
        }
        lastState = state;
        await window.flutter_inappwebview.callHandler(
          'apexloadWhatsAppState',
          JSON.parse(state),
        );
      } catch (_) {
        lastState = '';
      }
    }, 350);
  };

  const statusTarget = () => {
    const selectors = [
      '[data-testid*="status"]',
      '[data-testid*="updates"]',
      '[data-icon*="status"]',
      '[data-icon*="updates"]',
      '[role="tab"]',
      '[aria-label]',
      '[title]',
    ];
    const seen = new Set();
    const loose = [];
    for (const candidate of document.querySelectorAll(selectors.join(','))) {
      const target =
        candidate.closest('[role="tab"],button,[role="button"],a') || candidate;
      // The navigation rail lives outside the list pane. Never click something
      // inside the chat/status list itself — a contact named "Status" would
      // otherwise be mistaken for the tab.
      if (seen.has(target) || target.closest('#pane-side')) continue;
      if (!isActionVisible(target)) continue;
      seen.add(target);
      const label = [
        candidate.getAttribute('aria-label'),
        candidate.getAttribute('title'),
        target.getAttribute('aria-label'),
        target.getAttribute('title'),
        candidate.getAttribute('data-testid'),
        target.getAttribute('data-testid'),
        candidate.getAttribute('data-icon'),
      ].filter(Boolean);
      if (!label.length) continue;
      if (label.some((value) => statusLabelExact.test(value))) return target;
      if (statusLabel.test(label.join(' '))) loose.push(target);
    }
    return loose[0] || null;
  };

  const isStatusViewActive = (target) => {
    if (!target) return false;
    return target.getAttribute('aria-selected') === 'true' ||
      target.getAttribute('aria-current') === 'page' ||
      target.getAttribute('aria-current') === 'true' ||
      Boolean(target.querySelector('[aria-selected="true"]'));
  };

  // Guard against the previous behaviour, where every recovery pass clicked the
  // tab several times and could toggle the user straight back out of it.
  let lastStatusClickAt = 0;
  const openStatusIfNeeded = () => {
    const target = statusTarget();
    if (!target) return false;
    if (isStatusViewActive(target)) return true;
    const now = Date.now();
    if (now - lastStatusClickAt < 5000) return true;
    lastStatusClickAt = now;
    target.click();
    return true;
  };

  const wakeStatusFeed = () => {
    try { window.focus(); } catch (_) {}
    window.__apexloadFitDesktopViewport?.();
    window.dispatchEvent(new Event('focus'));
    window.dispatchEvent(new Event('resize'));
  };

  // One bounded synchronisation pass: wait until the linked session is ready,
  // open the Status area, then realise everything already synced into it.
  let syncPass = null;
  const synchronizeStatuses = ({ openTab = true } = {}) => {
    if (syncPass) return syncPass;
    syncPass = (async () => {
      try {
        wakeStatusFeed();
        const maxWaits = 40; // ~20s ceiling, then report whatever we have.
        for (let attempt = 0; attempt < maxWaits; attempt++) {
          if (isConnected() && !isSyncing()) break;
          reportState();
          await sleep(500);
        }
        if (!isConnected()) return 0;
        if (openTab) {
          openStatusIfNeeded();
          await sleep(900);
          openStatusIfNeeded();
          await sleep(600);
        }
        knownStatusCount = await hydrateStatusList();
        reportState(true);
        return knownStatusCount;
      } catch (_) {
        return 0;
      } finally {
        syncPass = null;
      }
    })();
    return syncPass;
  };

  window.__apexloadRequestState = () => reportState(true);
  window.__apexloadSynchronizeStatuses = synchronizeStatuses;
  window.__apexloadRecoverStatus = () => {
    synchronizeStatuses({ openTab: true });
    return true;
  };

  // Run the snapshot automatically, once per page session, as soon as the tab
  // is authenticated and finished syncing. A reload, a WebView recreation or a
  // restored WebContent process all re-execute this script on a fresh page, so
  // the pass repeats itself without any extra Dart-side scheduling.
  let readinessChecks = 0;
  let readinessTimer = null;
  const scheduleInitialSync = () => {
    if (window.__apexloadInitialSyncStarted || readinessTimer !== null) return;
    const step = () => {
      readinessTimer = null;
      if (window.__apexloadInitialSyncStarted) return;
      if (isConnected() && !isSyncing()) {
        window.__apexloadInitialSyncStarted = true;
        synchronizeStatuses({ openTab: true });
        return;
      }
      if (readinessChecks++ >= 120) return; // ~2 minute bounded wait.
      readinessTimer = setTimeout(step, 1000);
    };
    step();
  };
  scheduleInitialSync();

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

  let observerRetries = 0;
  const startObserver = () => {
    if (window.__apexloadObserverStarted) return;
    if (!document.body || !document.documentElement) {
      if (observerRetries < 100) {
        observerRetries++;
        setTimeout(startObserver, 100);
      }
      return;
    }
    window.__apexloadObserverStarted = true;
    // Pass no arguments: the observer hands us a MutationRecord list, which
    // would otherwise be read as `force` and defeat the state de-duplication.
    new MutationObserver(() => reportState()).observe(document.documentElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['src', 'style', 'class'],
    });
    reportState();
  };
  startObserver();
  addEventListener('popstate', () => reportState());
  addEventListener('hashchange', () => reportState());
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState !== 'visible') return;
    // The pass is a no-op once it has already run for this page session.
    scheduleInitialSync();
    reportState(true);
  });
})();
''';

bool isAllowedIosWhatsAppNavigation(Uri? uri) {
  if (uri == null) return false;
  if (const {'about', 'blob', 'data'}.contains(uri.scheme)) return true;
  if (uri.scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  return host == 'web.whatsapp.com' ||
      host.endsWith('.web.whatsapp.com') ||
      host == 'flows.whatsapp.net' ||
      host.endsWith('.flows.whatsapp.net');
}
