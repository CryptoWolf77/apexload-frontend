import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/whatsapp_status/whatsapp_status_models.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/glass_card.dart';
import 'package:apexload/shared/widgets/gradient_scaffold.dart';
import 'package:apexload/shared/widgets/local_thumbnail_view.dart';
import 'package:apexload/shared/widgets/premium_locked_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _StatusSavedAction { keepBrowsing, goToDownloads }

class WhatsAppStatusScreen extends ConsumerStatefulWidget {
  const WhatsAppStatusScreen({super.key});

  @override
  ConsumerState<WhatsAppStatusScreen> createState() =>
      _WhatsAppStatusScreenState();
}

class _WhatsAppStatusScreenState extends ConsumerState<WhatsAppStatusScreen> {
  var _items = <WhatsAppStatusItem>[];
  var _selectedIds = <String>{};
  var _filter = 'all';
  var _business = false;
  var _isLoading = true;
  var _sources = <WhatsAppStatusSource>[];
  var _connectionState = WhatsAppStatusConnectionState.detecting;
  String? _folderPath;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final premium = ref.watch(subscriptionControllerProvider).isPremium;
    final visible = _filteredItems;
    final connected = _isValidatedConnection(_connectionState);

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          l.t('statusSaver'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: l.t('refresh'),
            onPressed: _isLoading ? null : _scan,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l.t('folderSettings'),
            onPressed: _isLoading ? null : _disconnect,
            icon: const Icon(Icons.folder_off_rounded),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _IntroCard(
            connected: connected,
            business: _business,
            sources: _sources,
            connectionState: _connectionState,
            onSelectSource: _selectSource,
            onConnectStandard: () => _connect(business: false),
            onConnectBusiness: () => _connect(business: true),
            onHelp: _showFolderHelp,
            onDisconnect: _disconnect,
          ),
          const SizedBox(height: 14),
          if (!premium)
            PremiumLockedCard(
              title: l.t('whatsappStatusPremiumTitle'),
              description: l.t('whatsappStatusPremiumMessage'),
              onUpgrade: () => context.push('/premium'),
            ),
          const SizedBox(height: 14),
          _StatusHeader(
            connected: connected,
            business: _business,
            total: _items.length,
            selectedCount: _selectedIds.length,
            onRefresh: _scan,
            onSelectAll: _selectAllVisible,
            onSaveSelected: premium ? _saveSelected : _showPremiumNotice,
          ),
          const SizedBox(height: 12),
          _FilterTabs(
            value: _filter,
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_folderPath == null)
            _EmptyCard(message: l.t('connectWhatsappFolderFirst'))
          else if (!connected)
            _EmptyCard(message: l.t('wrongWhatsappFolderSelected'))
          else if (visible.isEmpty)
            _EmptyCard(message: l.t('noWhatsappStatusesFound'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final item = visible[index];
                return _StatusCard(
                  item: item,
                  selected: _selectedIds.contains(item.id),
                  onToggleSelected: () => _toggleSelected(item),
                  onPreview: () => _preview(item),
                  onSave: premium ? () => _save(item) : _showPremiumNotice,
                  onShare: () => _shareOriginal(item),
                );
              },
            ),
        ],
      ),
    );
  }

  List<WhatsAppStatusItem> get _filteredItems {
    return switch (_filter) {
      'videos' =>
        _items.where((item) => item.type == DownloadType.video).toList(),
      'images' =>
        _items.where((item) => item.type == DownloadType.image).toList(),
      'saved' => _items.where((item) => item.isSaved).toList(),
      _ => _items,
    };
  }

  bool _isValidatedConnection(WhatsAppStatusConnectionState state) {
    return state == WhatsAppStatusConnectionState.connectedAutomatic ||
        state == WhatsAppStatusConnectionState.connectedNoStatuses;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final service = ref.read(whatsappStatusServiceProvider);
    final sources = await service.detectSources();
    final connected = sources.where((source) => source.connected).toList();
    final active = connected.isNotEmpty ? connected.first : sources.first;
    _sources = sources;
    _business = active.business;
    _folderPath = active.folderPath;
    _connectionState = active.state;
    if (active.connected && mounted) {
      AppNotification.success(
        context,
        message: AppLocalizations.of(context).t('whatsappAutoDetected'),
      );
      await _scan(showLoading: false);
      return;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connect({required bool business}) async {
    setState(() => _connectionState = WhatsAppStatusConnectionState.validating);
    try {
      AppNotification.info(
        context,
        message: AppLocalizations.of(
          context,
        ).t(business ? 'whatsappBusinessPickerHint' : 'whatsappPickerHint'),
      );
      final service = ref.read(whatsappStatusServiceProvider);
      final path = await service.connectFolder(business: business);
      if (path == null) {
        setState(
          () => _connectionState = WhatsAppStatusConnectionState.setupRequired,
        );
        if (!mounted) return;
        AppNotification.info(
          context,
          message: AppLocalizations.of(context).t('folderConnectionCancelled'),
        );
        return;
      }
      setState(() {
        _business = business;
        _folderPath = path;
        _connectionState = WhatsAppStatusConnectionState.validating;
      });
      await _scan();
    } on Object catch (error) {
      if (!mounted) return;
      final wrong = error.toString().contains('wrongWhatsappFolder');
      setState(() {
        _business = business;
        _folderPath = null;
        _items = [];
        _connectionState = wrong
            ? WhatsAppStatusConnectionState.wrongFolder
            : WhatsAppStatusConnectionState.setupRequired;
      });
      AppNotification.warning(
        context,
        message: AppLocalizations.of(context).t(
          wrong ? 'wrongWhatsappFolderSelected' : 'whatsappFolderAccessError',
        ),
      );
    }
  }

  Future<void> _selectSource(WhatsAppStatusSource source) async {
    setState(() {
      _business = source.business;
      _folderPath = source.folderPath;
      _connectionState = source.state;
      _items = [];
      _selectedIds = {};
    });
    if (source.connected) {
      await _scan();
      return;
    }
    if (source.state == WhatsAppStatusConnectionState.permissionRequired ||
        source.state == WhatsAppStatusConnectionState.setupRequired ||
        source.state == WhatsAppStatusConnectionState.wrongFolder ||
        source.state == WhatsAppStatusConnectionState.permissionRevoked) {
      _showFolderHelp();
    }
  }

  Future<void> _disconnect() async {
    await ref
        .read(whatsappStatusServiceProvider)
        .disconnectFolder(business: _business);
    setState(() {
      _folderPath = null;
      _items = [];
      _selectedIds = {};
      _connectionState = WhatsAppStatusConnectionState.setupRequired;
    });
  }

  Future<void> _scan({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final items = await ref
          .read(whatsappStatusServiceProvider)
          .scan(business: _business);
      if (!mounted) return;
      setState(() {
        _items = items;
        _selectedIds = _selectedIds.intersection(
          items.map((e) => e.id).toSet(),
        );
        _connectionState = items.isEmpty && _folderPath != null
            ? WhatsAppStatusConnectionState.connectedNoStatuses
            : WhatsAppStatusConnectionState.connectedAutomatic;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t('whatsappFolderAccessError'),
      );
    }
  }

  Future<void> _save(
    WhatsAppStatusItem item, {
    bool showSavedActions = true,
  }) async {
    try {
      final saved = await ref
          .read(whatsappStatusServiceProvider)
          .saveStatus(item);
      ref.read(libraryControllerProvider.notifier).add(saved);
      if (!mounted) return;
      if (!showSavedActions) {
        AppNotification.success(
          context,
          message: AppLocalizations.of(context).t('statusSavedSuccess'),
        );
        await _scan(showLoading: false);
        return;
      }

      final action = await _showSavedActions();
      if (!mounted) return;
      if (action == _StatusSavedAction.goToDownloads) {
        context.go('/downloads');
        return;
      }
      await _scan(showLoading: false);
    } on Object catch (error) {
      if (!mounted) return;
      final key = error.toString().contains('statusAlreadySaved')
          ? 'statusAlreadySaved'
          : 'whatsappFolderAccessError';
      AppNotification.warning(
        context,
        message: AppLocalizations.of(context).t(key),
      );
    }
  }

  Future<_StatusSavedAction?> _showSavedActions() {
    final l = AppLocalizations.of(context);
    return showModalBottomSheet<_StatusSavedAction>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            key: const Key('android_status_saved_actions'),
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
                        l.t('statusSavedActionsTitle'),
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
                  l.t('statusSavedActionsDescription'),
                  style: TextStyle(color: AppTone.textSecondary(context)),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final keepBrowsing = OutlinedButton(
                      onPressed: () => Navigator.of(
                        sheetContext,
                      ).pop(_StatusSavedAction.keepBrowsing),
                      child: Text(l.t('statusKeepBrowsing')),
                    );
                    final goToDownloads = FilledButton.icon(
                      onPressed: () => Navigator.of(
                        sheetContext,
                      ).pop(_StatusSavedAction.goToDownloads),
                      icon: const Icon(Icons.download_done_rounded),
                      label: Text(l.t('statusGoToDownloads')),
                    );
                    if (constraints.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          keepBrowsing,
                          const SizedBox(height: 10),
                          goToDownloads,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: keepBrowsing),
                        const SizedBox(width: 10),
                        Expanded(child: goToDownloads),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSelected() async {
    final selected = _items
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    for (final item in selected) {
      await _save(item, showSavedActions: false);
    }
    setState(() => _selectedIds = {});
  }

  void _toggleSelected(WhatsAppStatusItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        _selectedIds.add(item.id);
      }
    });
  }

  void _selectAllVisible() {
    final ids = _filteredItems.map((item) => item.id).toSet();
    setState(() {
      _selectedIds = _selectedIds.containsAll(ids) ? {} : ids;
    });
  }

  Future<void> _preview(WhatsAppStatusItem item) async {
    await ref.read(localMediaServiceProvider).openItem(_asDownloadItem(item));
  }

  Future<void> _shareOriginal(WhatsAppStatusItem item) async {
    await ref.read(localMediaServiceProvider).shareItem(_asDownloadItem(item));
  }

  DownloadItemModel _asDownloadItem(WhatsAppStatusItem item) {
    return DownloadItemModel(
      id: item.id,
      title: item.title,
      platform: 'WhatsApp Status',
      date: item.modifiedAt,
      sizeLabel: item.sizeLabel,
      type: item.type,
      thumbnailUrl: '',
      fileName: item.fileName,
      localFilePath: item.sourcePath,
      thumbnailPath: item.thumbnailPath,
      duration: item.duration,
      quality: 'Status',
    );
  }

  void _showPremiumNotice() {
    AppNotification.warning(
      context,
      message: AppLocalizations.of(context).t('whatsappStatusPremiumTitle'),
    );
  }

  void _showFolderHelp() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _WhatsAppStatusTutorialSheet(),
    );
  }
}

class _TutorialStepData {
  const _TutorialStepData({
    required this.assetPath,
    required this.titleKey,
    required this.descriptionKey,
  });

  final String assetPath;
  final String titleKey;
  final String descriptionKey;
}

class _WhatsAppStatusTutorialSheet extends StatefulWidget {
  const _WhatsAppStatusTutorialSheet();

  @override
  State<_WhatsAppStatusTutorialSheet> createState() =>
      _WhatsAppStatusTutorialSheetState();
}

class _WhatsAppStatusTutorialSheetState
    extends State<_WhatsAppStatusTutorialSheet> {
  static const _steps = [
    _TutorialStepData(
      assetPath:
          'assets/tutorials/whatsapp_status/mobile_app_tutorial_change_whatsapp_folder.png',
      titleKey: 'whatsappTutorialStep1Title',
      descriptionKey: 'whatsappTutorialStep1Description',
    ),
    _TutorialStepData(
      assetPath:
          'assets/tutorials/whatsapp_status/show_hidden_files_tutorial_part_2.png',
      titleKey: 'whatsappTutorialStep2Title',
      descriptionKey: 'whatsappTutorialStep2Description',
    ),
    _TutorialStepData(
      assetPath:
          'assets/tutorials/whatsapp_status/step_3_open_the_.statuses_folder.png',
      titleKey: 'whatsappTutorialStep3Title',
      descriptionKey: 'whatsappTutorialStep3Description',
    ),
    _TutorialStepData(
      assetPath:
          'assets/tutorials/whatsapp_status/step_4_use_this_folder_tutorial.png',
      titleKey: 'whatsappTutorialStep4Title',
      descriptionKey: 'whatsappTutorialStep4Description',
    ),
    _TutorialStepData(
      assetPath:
          'assets/tutorials/whatsapp_status/allow_access_to_apexload_tutorial.png',
      titleKey: 'whatsappTutorialStep5Title',
      descriptionKey: 'whatsappTutorialStep5Description',
    ),
    _TutorialStepData(
      assetPath:
          'assets/tutorials/whatsapp_status/step_6_scroll_down_for_statuses.png',
      titleKey: 'whatsappTutorialStep6Title',
      descriptionKey: 'whatsappTutorialStep6Description',
    ),
  ];

  late final PageController _controller;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final isLast = _index == _steps.length - 1;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height * 0.94),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTone.card(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(top: BorderSide(color: AppTone.border(context))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 30,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + viewPadding.bottom),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTone.textSecondary(
                        context,
                      ).withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.t('whatsappTutorialTitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        label: l.t('close'),
                        button: true,
                        child: IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: l.t('close'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF25D366,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFF25D366,
                            ).withValues(alpha: 0.36),
                          ),
                        ),
                        child: Text(
                          '${_index + 1} / ${_steps.length}',
                          style: const TextStyle(
                            color: Color(0xFF25D366),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < _steps.length; i++) ...[
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i <= _index
                                        ? const Color(0xFF25D366)
                                        : AppTone.border(context),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              if (i < _steps.length - 1)
                                const SizedBox(width: 4),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _steps.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return _TutorialStepPage(step: step);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEnd.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryEnd.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: AppColors.primaryEnd,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.t('whatsappTutorialHiddenFilesNote'),
                            style: TextStyle(
                              color: AppTone.textSecondary(context),
                              height: 1.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _index == 0 ? null : _previous,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(l.t('back')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isLast
                              ? () => Navigator.pop(context)
                              : _next,
                          icon: Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                          label: Text(l.t(isLast ? 'done' : 'next')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _TutorialStepPage extends StatelessWidget {
  const _TutorialStepPage({required this.step});

  final _TutorialStepData step;

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _TutorialImagePreview(assetPath: step.assetPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                Text(
                  l.t(step.titleKey),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l.t(step.descriptionKey),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _openPreview(context),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTone.border(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryEnd.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 2.6,
                      child: Image.asset(
                        step.assetPath,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _openPreview(context),
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
                  label: Text(l.t('tapImageToEnlarge')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryEnd,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TutorialImagePreview extends StatelessWidget {
  const _TutorialImagePreview({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  maxScale: 4,
                  child: Center(
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 10,
              end: 10,
              child: Semantics(
                label: l.t('close'),
                button: true,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l.t('close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.connected,
    required this.business,
    required this.sources,
    required this.connectionState,
    required this.onSelectSource,
    required this.onConnectStandard,
    required this.onConnectBusiness,
    required this.onHelp,
    required this.onDisconnect,
  });

  final bool connected;
  final bool business;
  final List<WhatsAppStatusSource> sources;
  final WhatsAppStatusConnectionState connectionState;
  final ValueChanged<WhatsAppStatusSource> onSelectSource;
  final VoidCallback onConnectStandard;
  final VoidCallback onConnectBusiness;
  final VoidCallback onHelp;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.message_rounded,
                color: Color(0xFF25D366),
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.t('whatsappStatusSaver'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _Badge(text: connected ? l.t('connected') : l.t('notConnected')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            connected
                ? l.t('whatsappStatusLocalOnly')
                : l.t('connectWhatsappSetupExplanation'),
            style: TextStyle(color: AppTone.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          _HowToUseCard(onTap: onHelp),
          const SizedBox(height: 10),
          _ConnectionStateBanner(state: connectionState),
          if (sources.length > 1) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final source in sources)
                  ChoiceChip(
                    selected: source.business == business,
                    label: Text(
                      '${source.label} · ${_stateLabel(l, source.state)}',
                    ),
                    onSelected: (_) => onSelectSource(source),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onConnectStandard,
                icon: const Icon(Icons.folder_rounded),
                label: Text(
                  connected
                      ? l.t('changeFolder')
                      : l.t('connectWhatsappStatuses'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onConnectBusiness,
                icon: const Icon(Icons.business_rounded),
                label: Text(l.t('connectWhatsappBusinessFolder')),
              ),
              if (connected)
                TextButton.icon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.link_off_rounded),
                  label: Text(l.t('disconnectFolder')),
                ),
            ],
          ),
          if (connected) ...[
            const SizedBox(height: 8),
            Text(
              business
                  ? l.t('whatsappBusinessConnected')
                  : l.t('whatsappConnected'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }

  String _stateLabel(AppLocalizations l, WhatsAppStatusConnectionState state) {
    return switch (state) {
      WhatsAppStatusConnectionState.detecting => l.t('detectingWhatsapp'),
      WhatsAppStatusConnectionState.connectedAutomatic => l.t(
        'connectedAutomatically',
      ),
      WhatsAppStatusConnectionState.connectedNoStatuses => l.t(
        'connectedNoStatuses',
      ),
      WhatsAppStatusConnectionState.setupRequired => l.t('setupRequired'),
      WhatsAppStatusConnectionState.validating => l.t('validatingFolder'),
      WhatsAppStatusConnectionState.wrongFolder => l.t('wrongFolderSelected'),
      WhatsAppStatusConnectionState.permissionRequired => l.t(
        'permissionRequired',
      ),
      WhatsAppStatusConnectionState.permissionRevoked => l.t(
        'permissionRevoked',
      ),
      WhatsAppStatusConnectionState.folderNotFound => l.t('folderNotFound'),
      WhatsAppStatusConnectionState.noStatusesFound => l.t('noStatusesFound'),
    };
  }
}

class _ConnectionStateBanner extends StatelessWidget {
  const _ConnectionStateBanner({required this.state});

  final WhatsAppStatusConnectionState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = switch (state) {
      WhatsAppStatusConnectionState.detecting => l.t('detectingWhatsapp'),
      WhatsAppStatusConnectionState.connectedAutomatic => l.t(
        'connectedAutomatically',
      ),
      WhatsAppStatusConnectionState.connectedNoStatuses => l.t(
        'connectedNoStatuses',
      ),
      WhatsAppStatusConnectionState.setupRequired => l.t(
        'guidedPermissionText',
      ),
      WhatsAppStatusConnectionState.validating => l.t('validatingFolder'),
      WhatsAppStatusConnectionState.wrongFolder => l.t(
        'wrongWhatsappFolderSelected',
      ),
      WhatsAppStatusConnectionState.permissionRequired => l.t(
        'guidedPermissionText',
      ),
      WhatsAppStatusConnectionState.permissionRevoked => l.t(
        'permissionRevoked',
      ),
      WhatsAppStatusConnectionState.folderNotFound => l.t('folderNotFound'),
      WhatsAppStatusConnectionState.noStatusesFound => l.t('noStatusesFound'),
    };
    final connected =
        state == WhatsAppStatusConnectionState.connectedAutomatic ||
        state == WhatsAppStatusConnectionState.connectedNoStatuses;
    final icon = connected
        ? Icons.check_circle_rounded
        : state == WhatsAppStatusConnectionState.wrongFolder
        ? Icons.warning_rounded
        : Icons.info_rounded;
    final accent = connected
        ? const Color(0xFF25D366)
        : state == WhatsAppStatusConnectionState.wrongFolder
        ? AppColors.error
        : AppColors.primaryEnd;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _HowToUseCard extends StatelessWidget {
  const _HowToUseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryStart.withValues(alpha: 0.20),
                const Color(0xFF25D366).withValues(alpha: 0.16),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.help_rounded, color: Color(0xFF25D366)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('whatsappHowToUseCta'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.t('whatsappHowToUseSubtitle'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTone.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.keyboard_arrow_up_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.connected,
    required this.business,
    required this.total,
    required this.selectedCount,
    required this.onRefresh,
    required this.onSelectAll,
    required this.onSaveSelected,
  });

  final bool connected;
  final bool business;
  final int total;
  final int selectedCount;
  final VoidCallback onRefresh;
  final VoidCallback onSelectAll;
  final VoidCallback onSaveSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF25D366).withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('statusGallery'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      connected
                          ? '${business ? 'WhatsApp Business' : 'WhatsApp'} · $total'
                          : l.t('notConnected'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(color: AppTone.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: onRefresh,
                tooltip: l.t('refresh'),
                icon: const Icon(Icons.refresh_rounded),
              ),
              TextButton(onPressed: onSelectAll, child: Text(l.t('selectAll'))),
              FilledButton(
                onPressed: selectedCount == 0 ? null : onSaveSelected,
                child: Text('${l.t('saveSelected')} ($selectedCount)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        selected: {value},
        onSelectionChanged: (value) => onChanged(value.first),
        segments: [
          ButtonSegment(value: 'all', label: Text(l.t('all'))),
          ButtonSegment(value: 'videos', label: Text(l.t('videos'))),
          ButtonSegment(value: 'images', label: Text(l.t('images'))),
          ButtonSegment(value: 'saved', label: Text(l.t('saved'))),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.item,
    required this.selected,
    required this.onToggleSelected,
    required this.onPreview,
    required this.onSave,
    required this.onShare,
  });

  final WhatsAppStatusItem item;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LocalThumbnailView(
                    path: item.thumbnailPath,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    fallback: _StatusFallback(type: item.type),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: InkWell(
                    onTap: onToggleSelected,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? AppColors.primaryEnd
                            : Colors.black.withValues(alpha: 0.36),
                        border: Border.all(color: Colors.white70),
                      ),
                      child: Icon(
                        selected ? Icons.check_rounded : Icons.add_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (item.type == DownloadType.video)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _Badge(
                      text: item.duration.isEmpty
                          ? l.t('video')
                          : item.duration,
                    ),
                  ),
                if (item.isSaved)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _Badge(text: l.t('saved')),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  item.sizeLabel,
                  style: TextStyle(
                    color: AppTone.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CompactActionButton(
                      tooltip: l.t('preview'),
                      icon: Icons.visibility_rounded,
                      onPressed: onPreview,
                    ),
                    _CompactActionButton(
                      tooltip: l.t('save'),
                      onPressed: item.isSaved ? null : onSave,
                      icon: Icons.save_alt_rounded,
                    ),
                    _CompactActionButton(
                      tooltip: l.t('share'),
                      onPressed: onShare,
                      icon: Icons.share_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 19,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _StatusFallback extends StatelessWidget {
  const _StatusFallback({required this.type});

  final DownloadType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF25D366), AppColors.primaryEnd],
        ),
      ),
      child: Icon(
        type == DownloadType.video
            ? Icons.play_arrow_rounded
            : Icons.image_rounded,
        color: Colors.white,
        size: 42,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryEnd.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryEnd.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryEnd,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
