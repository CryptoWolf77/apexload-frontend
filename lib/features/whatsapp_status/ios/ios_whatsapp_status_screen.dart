import 'dart:async';
import 'dart:collection';

import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/whatsapp_status/ios/ios_whatsapp_guide_store.dart';
import 'package:apexload/features/whatsapp_status/ios/ios_whatsapp_media_bridge.dart';
import 'package:apexload/features/whatsapp_status/ios/ios_whatsapp_web_scripts.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class IosWhatsAppStatusScreen extends ConsumerStatefulWidget {
  const IosWhatsAppStatusScreen({super.key});

  @override
  ConsumerState<IosWhatsAppStatusScreen> createState() =>
      _IosWhatsAppStatusScreenState();
}

class _IosWhatsAppStatusScreenState
    extends ConsumerState<IosWhatsAppStatusScreen> {
  InAppWebViewController? _controller;
  IosWhatsAppMediaBridge? _mediaBridge;
  final _guideStore = const IosWhatsAppGuideStore();
  var _started = false;
  var _preferencesLoaded = false;
  var _connectionGuideComplete = false;
  var _firstSaveComplete = false;
  var _saveGuideShownThisSession = false;
  var _loading = true;
  var _connected = false;
  var _qrVisible = false;
  var _statusOpen = false;
  var _mediaKind = '';
  var _capturing = false;
  var _captureProgress = 0.0;

  String _t(String key) => AppLocalizations.of(context).t(key);

  @override
  void initState() {
    super.initState();
    unawaited(_loadGuideState());
  }

  Future<void> _loadGuideState() async {
    final state = await _guideStore.load();
    if (!mounted) return;
    setState(() {
      _connectionGuideComplete = state.connectionComplete;
      _firstSaveComplete = state.firstSaveComplete;
      _started = state.connectionComplete;
      _preferencesLoaded = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mediaBridge ??= IosWhatsAppMediaBridge(
      mediaService: ref.read(localMediaServiceProvider),
    );
  }

  @override
  void dispose() {
    _mediaBridge?.dispose();
    super.dispose();
  }

  Future<void> _captureStatus() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() {
      _capturing = true;
      _captureProgress = 0;
    });
    try {
      final item = await _mediaBridge!.captureCurrentStatus(
        controller,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _captureProgress = progress);
        },
      );
      await ref.read(libraryControllerProvider.notifier).addAndSave(item);
      await _markFirstSaveComplete();
      if (!mounted) return;
      AppNotification.success(
        context,
        title: _t('iosWhatsappSaved'),
        message: _t(
          'iosWhatsappSavedFile',
        ).replaceFirst('{file}', item.fileName),
      );
      await _showSavedActions();
    } on Object catch (error) {
      if (!mounted) return;
      if (_isMissingStatusError(error)) {
        AppNotification.info(context, message: _t('iosWhatsappTryOpenStatus'));
        return;
      }
      AppNotification.error(
        context,
        title: _t('iosWhatsappSaveFailed'),
        message: _friendlyError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _captureProgress = 0;
        });
      }
    }
  }

  Future<void> _handleCapturePressed() async {
    if (!_firstSaveComplete && !_saveGuideShownThisSession) {
      setState(() => _saveGuideShownThisSession = true);
      await _showStatusGuide();
      return;
    }
    await _captureStatus();
  }

  Future<void> _markFirstSaveComplete() async {
    if (_firstSaveComplete) return;
    await _guideStore.markFirstSaveComplete();
    if (!mounted) return;
    setState(() => _firstSaveComplete = true);
  }

  Future<void> _markConnectionComplete() async {
    if (_connectionGuideComplete) return;
    await _guideStore.markConnectionComplete();
    if (!mounted) return;
    setState(() => _connectionGuideComplete = true);
  }

  Future<void> _showSavedActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('iosWhatsappSavedSuccess'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _t('iosWhatsappSavedDescription'),
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(_t('iosWhatsappKeepBrowsing')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.go('/downloads');
                        },
                        icon: const Icon(Icons.download_done_rounded),
                        label: Text(_t('downloads')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('iosWhatsappDisconnectQuestion')),
        content: Text(_t('iosWhatsappDisconnectMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t('iosWhatsappDisconnect')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CookieManager.instance().deleteAllCookies();
    await InAppWebViewController.clearAllCache();
    await _controller?.evaluateJavascript(
      source: 'localStorage.clear(); sessionStorage.clear();',
    );
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://web.whatsapp.com/')),
    );
    await _guideStore.resetConnection();
    if (!mounted) return;
    setState(() {
      _connectionGuideComplete = false;
      _connected = false;
      _qrVisible = false;
      _statusOpen = false;
    });
    AppNotification.info(context, message: _t('iosWhatsappDisconnected'));
  }

  Future<void> _showConnectionTutorial() async {
    if (_connectionGuideComplete) {
      setState(() {
        _loading = true;
        _started = true;
      });
      return;
    }
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConnectionTutorialSheet(),
    );
    if (proceed == true && mounted) {
      setState(() {
        _loading = true;
        _started = true;
      });
    }
  }

  Future<void> _showStatusGuide() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _StatusGuideSheet(onClose: () => Navigator.of(sheetContext).pop()),
    );
  }

  Future<void> _restoreWhatsAppWeb(InAppWebViewController controller) async {
    if (mounted) setState(() => _loading = true);
    await controller.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://web.whatsapp.com/')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      extendBody: false,
      appBar: AppBar(
        title: Text(_t('iosWhatsappTitle')),
        actions: [
          if (_started)
            IconButton(
              tooltip: _t('iosWhatsappRefresh'),
              onPressed: () => _controller?.reload(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          if (_started)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'disconnect') _clearSession();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'disconnect',
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(_t('iosWhatsappDisconnect')),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      child: !_preferencesLoaded
          ? const Center(child: CircularProgressIndicator())
          : _started
          ? _buildWebExperience()
          : _buildIntroduction(),
    );
  }

  Widget _buildIntroduction() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF11BFA5)],
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.mobile_screen_share_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t('iosWhatsappIntroTitle'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _t('iosWhatsappIntroDescription'),
                style: TextStyle(
                  color: AppTone.textSecondary(context),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _PrivacyPoint(
                icon: Icons.phonelink_lock_rounded,
                title: _t('iosWhatsappPrivacyTitle'),
                description: _t('iosWhatsappPrivacyDescription'),
              ),
              const SizedBox(height: 12),
              _PrivacyPoint(
                icon: Icons.touch_app_rounded,
                title: _t('iosWhatsappManualTitle'),
                description: _t('iosWhatsappManualDescription'),
              ),
              const SizedBox(height: 12),
              _PrivacyPoint(
                icon: Icons.gavel_rounded,
                title: _t('iosWhatsappResponsibleTitle'),
                description: _t('iosWhatsappResponsibleDescription'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primaryEnd,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t('iosWhatsappPhaseNote'),
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _showConnectionTutorial,
          icon: const Icon(Icons.lock_open_rounded),
          label: Text(_t('iosWhatsappStart')),
        ),
      ],
    );
  }

  Widget _buildWebExperience() {
    return Column(
      children: [
        _ConnectionBar(
          loading: _loading,
          connected: _connected,
          qrVisible: _qrVisible,
          statusOpen: _statusOpen,
        ),
        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://web.whatsapp.com/'),
                  ),
                  initialUserScripts: UnmodifiableListView([
                    UserScript(
                      source: iosWhatsAppWebViewportScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      forMainFrameOnly: true,
                    ),
                    UserScript(
                      source: iosWhatsAppWebProbeScript,
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      forMainFrameOnly: true,
                    ),
                  ]),
                  initialSettings: InAppWebViewSettings(
                    userAgent: iosWhatsAppWebDesktopUserAgent,
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    useShouldOverrideUrlLoading: true,
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    supportZoom: true,
                    isInspectable: false,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'apexloadWhatsAppState',
                      callback: _handleWhatsAppState,
                    );
                    controller.addJavaScriptHandler(
                      handlerName: 'apexloadMediaChunk',
                      callback: _mediaBridge!.handleMediaChunk,
                    );
                  },
                  onLoadStart: (controller, url) async {
                    final uri = url == null ? null : Uri.tryParse('$url');
                    if (isIosWhatsAppReturnNavigation(uri)) {
                      await _restoreWhatsAppWeb(controller);
                      return;
                    }
                    if (mounted) setState(() => _loading = true);
                  },
                  onLoadStop: (controller, url) async {
                    final uri = url == null ? null : Uri.tryParse('$url');
                    if (isIosWhatsAppReturnNavigation(uri)) {
                      await _restoreWhatsAppWeb(controller);
                      return;
                    }
                    await controller.evaluateJavascript(
                      source: iosWhatsAppWebViewportScript,
                    );
                    await controller.evaluateJavascript(
                      source: iosWhatsAppWebProbeScript,
                    );
                    if (mounted) setState(() => _loading = false);
                  },
                  onProgressChanged: (_, progress) {
                    if (mounted && progress == 100) {
                      setState(() => _loading = false);
                    }
                  },
                  onReceivedError: (_, request, error) {
                    if (request.isForMainFrame != true || !mounted) return;
                    setState(() => _loading = false);
                    AppNotification.error(
                      context,
                      title: _t('iosWhatsappLoadFailed'),
                      message: error.description,
                    );
                  },
                  shouldOverrideUrlLoading: (controller, action) async {
                    final url = action.request.url;
                    final uri = url == null ? null : Uri.tryParse('$url');
                    if (isIosWhatsAppReturnNavigation(uri)) {
                      if (action.isForMainFrame != false) {
                        await _restoreWhatsAppWeb(controller);
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    if (isAllowedIosWhatsAppNavigation(uri)) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    if (action.isForMainFrame == false) {
                      return NavigationActionPolicy.CANCEL;
                    }
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    return NavigationActionPolicy.CANCEL;
                  },
                ),
                if (_loading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
        ),
        _CaptureBar(
          connected: _connected,
          statusOpen: _statusOpen,
          mediaKind: _mediaKind,
          capturing: _capturing,
          progress: _captureProgress,
          onCapture: _handleCapturePressed,
        ),
      ],
    );
  }

  dynamic _handleWhatsAppState(List<dynamic> arguments) {
    if (arguments.isEmpty || arguments.first is! Map || !mounted) return null;
    final state = arguments.first as Map;
    setState(() {
      _connected = state['connected'] == true;
      _qrVisible = state['qrVisible'] == true;
      _statusOpen = state['statusOpen'] == true;
      _mediaKind = '${state['mediaKind'] ?? ''}';
    });
    if (state['connected'] == true) {
      unawaited(_markConnectionComplete());
    }
    return {'received': true};
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '').trim();
    return message.isEmpty ? _t('iosWhatsappTryOpenStatus') : message;
  }

  bool _isMissingStatusError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('open a photo or video status') ||
        message.contains('open a status and try again');
  }
}

class _ConnectionBar extends StatelessWidget {
  const _ConnectionBar({
    required this.loading,
    required this.connected,
    required this.qrVisible,
    required this.statusOpen,
  });

  final bool loading;
  final bool connected;
  final bool qrVisible;
  final bool statusOpen;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final (icon, label, color) = statusOpen
        ? (
            Icons.visibility_rounded,
            strings.t('iosWhatsappStatusDetected'),
            AppColors.primaryEnd,
          )
        : connected
        ? (
            Icons.link_rounded,
            strings.t('iosWhatsappConnected'),
            AppColors.success,
          )
        : qrVisible
        ? (
            Icons.qr_code_scanner_rounded,
            strings.t('iosWhatsappLinkAccount'),
            AppColors.premiumGold,
          )
        : (
            Icons.hourglass_top_rounded,
            loading
                ? strings.t('iosWhatsappOpening')
                : strings.t('iosWhatsappWaiting'),
            AppColors.textSecondary,
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTone.card(context).withValues(alpha: 0.96),
        border: Border(bottom: BorderSide(color: AppTone.border(context))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  const _CaptureBar({
    required this.connected,
    required this.statusOpen,
    required this.mediaKind,
    required this.capturing,
    required this.progress,
    required this.onCapture,
  });

  final bool connected;
  final bool statusOpen;
  final String mediaKind;
  final bool capturing;
  final double progress;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final captureLabel = switch (mediaKind) {
      'video' => strings.t('iosWhatsappSaveVideo'),
      'image' => strings.t('iosWhatsappSavePhoto'),
      _ => strings.t('iosWhatsappSaveStatus'),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppTone.card(context),
        border: Border(top: BorderSide(color: AppTone.border(context))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capturing) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.t('iosWhatsappSaving'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${(progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: connected && !capturing ? onCapture : null,
              icon: Icon(
                mediaKind == 'video'
                    ? Icons.video_file_rounded
                    : Icons.download_rounded,
              ),
              label: Text(
                statusOpen ? captureLabel : strings.t('iosWhatsappOpenStatus'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTutorialSheet extends StatefulWidget {
  const _ConnectionTutorialSheet();

  @override
  State<_ConnectionTutorialSheet> createState() =>
      _ConnectionTutorialSheetState();
}

class _ConnectionTutorialSheetState extends State<_ConnectionTutorialSheet> {
  final _pageController = PageController();
  var _page = 0;

  static const _images = [
    'assets/tutorials/whatsapp_status/ios_connect_step_1.png',
    'assets/tutorials/whatsapp_status/ios_connect_step_2.png',
    'assets/tutorials/whatsapp_status/ios_connect_step_3.png',
  ];

  static const _titleKeys = [
    'iosWhatsappTutorialStep1Title',
    'iosWhatsappTutorialStep2Title',
    'iosWhatsappTutorialStep3Title',
  ];

  static const _descriptionKeys = [
    'iosWhatsappTutorialStep1Description',
    'iosWhatsappTutorialStep2Description',
    'iosWhatsappTutorialStep3Description',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isLastPage = _page == _images.length - 1;
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTone.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTone.border(context)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF11BFA5)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.link_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('iosWhatsappTutorialTitle'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.t('iosWhatsappTutorialSubtitle'),
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: strings.t('close'),
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: _TutorialImageCard(
                          assetPath: _images[index],
                          title: strings.t(_titleKeys[index]),
                          description: strings.t(_descriptionKeys[index]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.t(_titleKeys[index]),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.t(_descriptionKeys[index]),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTone.textSecondary(context),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? AppColors.primaryEnd
                        : AppTone.border(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        ),
                        child: Text(strings.t('back')),
                      ),
                    )
                  else
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(strings.t('skip')),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (isLastPage) {
                          Navigator.of(context).pop(true);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      icon: Icon(
                        isLastPage
                            ? Icons.open_in_browser_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        strings.t(isLastPage ? 'iosWhatsappOpenWeb' : 'next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusGuideSheet extends StatefulWidget {
  const _StatusGuideSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_StatusGuideSheet> createState() => _StatusGuideSheetState();
}

class _StatusGuideSheetState extends State<_StatusGuideSheet> {
  final _pageController = PageController();
  var _page = 0;

  static const _images = [
    'assets/tutorials/whatsapp_status/ios_save_step_1_v1.png',
    'assets/tutorials/whatsapp_status/ios_save_step_2_v1.png',
    'assets/tutorials/whatsapp_status/ios_save_step_3_v1.png',
    'assets/tutorials/whatsapp_status/ios_save_step_4_v1.png',
  ];

  static const _titleKeys = [
    'iosWhatsappSaveGuideStep1Title',
    'iosWhatsappSaveGuideStep2Title',
    'iosWhatsappSaveGuideStep3Title',
    'iosWhatsappSaveGuideStep4Title',
  ];

  static const _descriptionKeys = [
    'iosWhatsappSaveGuideStep1Description',
    'iosWhatsappSaveGuideStep2Description',
    'iosWhatsappSaveGuideStep3Description',
    'iosWhatsappSaveGuideStep4Description',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isLastPage = _page == _images.length - 1;
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTone.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTone.border(context)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF11BFA5)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.download_done_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('iosWhatsappSaveGuideTitle'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.t('iosWhatsappSaveGuideSubtitle'),
                          style: TextStyle(
                            color: AppTone.textSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: strings.t('close'),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Expanded(
                        child: _TutorialImageCard(
                          assetPath: _images[index],
                          title: strings.t(_titleKeys[index]),
                          description: strings.t(_descriptionKeys[index]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.t(_titleKeys[index]),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        strings.t(_descriptionKeys[index]),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTone.textSecondary(context),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? AppColors.primaryEnd
                        : AppTone.border(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        ),
                        child: Text(strings.t('back')),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (isLastPage) {
                          widget.onClose();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      icon: Icon(
                        isLastPage
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        strings.t(isLastPage ? 'iosWhatsappGotIt' : 'next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialImageCard extends StatelessWidget {
  const _TutorialImageCard({
    required this.assetPath,
    required this.title,
    required this.description,
  });

  final String assetPath;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: strings.t('tapImageToEnlarge'),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => _TutorialImagePreview(
              assetPath: assetPath,
              title: title,
              description: description,
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4ED),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTone.border(context)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(assetPath, fit: BoxFit.contain),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  end: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE60A1020),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryEnd.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.zoom_out_map_rounded,
                          color: AppColors.primaryEnd,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialImagePreview extends StatelessWidget {
  const _TutorialImagePreview({
    required this.assetPath,
    required this.title,
    required this.description,
  });

  final String assetPath;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 10,
              end: 10,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: strings.t('close'),
              ),
            ),
            PositionedDirectional(
              start: 16,
              end: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xEB0A1020),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primaryEnd.withValues(alpha: 0.65),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD1D7E8),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryEnd.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primaryEnd, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: AppTone.textSecondary(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
