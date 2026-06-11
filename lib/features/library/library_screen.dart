import 'package:apexload/core/constants/app_constants.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:apexload/features/quick_editor/quick_editor_gate.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/app_state.dart';
import 'package:apexload/shared/widgets/app_notification.dart';
import 'package:apexload/shared/widgets/download_item_card.dart';
import 'package:apexload/shared/widgets/empty_state.dart';
import 'package:apexload/shared/widgets/platform_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();
  var _type = 'All';
  var _platform = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(libraryControllerProvider).where((item) {
      final query = _search.text.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.fileName.toLowerCase().contains(query);
      final matchesType =
          _type == 'All' ||
          (_type == 'Video' && item.type == DownloadType.video) ||
          (_type == 'Audio' && item.type == DownloadType.audio) ||
          (_type == 'Images' && item.type == DownloadType.image) ||
          (_type == 'Edited' && item.isEdited);
      final matchesPlatform = _platform == 'All' || item.platform == _platform;
      return matchesQuery && matchesType && matchesPlatform;
    }).toList();
    final groups = _groupItems(items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 104),
      children: [
        Text(
          l.t('downloads'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: l.t('searchDownloads'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final type in ['All', 'Video', 'Audio', 'Images'])
              ChoiceChip(
                label: Text(_typeLabel(l, type)),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              ),
            ChoiceChip(
              label: Text(l.t('edited')),
              selected: _type == 'Edited',
              onSelected: (_) => setState(() => _type = 'Edited'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              PlatformChip(
                label: l.t('all'),
                selected: _platform == 'All',
                onTap: () => setState(() => _platform = 'All'),
              ),
              const SizedBox(width: 8),
              for (final platform in [
                ...AppConstants.supportedPlatforms,
                'Editor',
              ]) ...[
                PlatformChip(
                  label: platform == 'Editor' ? l.t('editor') : platform,
                  selected: _platform == platform,
                  onTap: () => setState(() => _platform = platform),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          SizedBox(
            height: 360,
            child: EmptyState(
              icon: Icons.folder_open_rounded,
              title: l.t('noDownloadsYet'),
              description: l.t('pasteLinkOnHome'),
            ),
          )
        else
          for (final group in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final item in group.value) ...[
              DownloadItemCard(
                item: item,
                onOpen: () => _openItem(item),
                onShare: () => _shareItem(item),
                onDelete: () => _confirmDelete(item),
                onRename: () => _rename(item.id, item.fileName),
                onEdit: () => _openQuickEditor(item),
              ),
              const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }

  Map<String, List<DownloadItemModel>> _groupItems(
    List<DownloadItemModel> items,
  ) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final groups = <String, List<DownloadItemModel>>{
      l.t('today'): [],
      l.t('yesterday'): [],
      l.t('older'): [],
    };
    for (final item in items) {
      final date = item.date;
      final today =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final yesterdayDate = now.subtract(const Duration(days: 1));
      final yesterday =
          date.year == yesterdayDate.year &&
          date.month == yesterdayDate.month &&
          date.day == yesterdayDate.day;
      if (today) {
        groups[l.t('today')]!.add(item);
      } else if (yesterday) {
        groups[l.t('yesterday')]!.add(item);
      } else {
        groups[l.t('older')]!.add(item);
      }
    }
    groups.removeWhere((_, value) => value.isEmpty);
    return groups;
  }

  Future<void> _openItem(DownloadItemModel item) async {
    try {
      await ref.read(localMediaServiceProvider).openItem(item);
    } on Object catch (error) {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t(
          _isMissingFileError(error)
              ? 'fileNoLongerAvailable'
              : 'couldNotOpenFile',
        ),
      );
    }
  }

  Future<void> _shareItem(DownloadItemModel item) async {
    try {
      await ref.read(localMediaServiceProvider).shareItem(item);
    } on Object catch (error) {
      if (!mounted) return;
      AppNotification.error(
        context,
        message: AppLocalizations.of(context).t(
          _isMissingFileError(error)
              ? 'fileNoLongerAvailable'
              : 'sharingFailed',
        ),
      );
    }
  }

  Future<void> _confirmDelete(DownloadItemModel item) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.t('deleteThisFile')),
        content: Text(item.fileName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(localMediaServiceProvider).deleteItemFiles(item);
    ref.read(libraryControllerProvider.notifier).delete(item.id);
    if (!mounted) return;
    AppNotification.success(context, message: l.t('fileDeleted'));
  }

  void _openQuickEditor(DownloadItemModel item) {
    final premium = ref.read(subscriptionControllerProvider).isPremium;
    if (!premium) {
      showQuickEditorPremiumSheet(context);
      return;
    }
    context.push('/quick-editor/edit', extra: item);
  }

  String _typeLabel(AppLocalizations l, String type) {
    return switch (type) {
      'Video' => l.t('video'),
      'Audio' => l.t('audio'),
      'Images' => l.t('images'),
      'Edited' => l.t('edited'),
      _ => l.t('all'),
    };
  }

  bool _isMissingFileError(Object error) {
    return error.toString().contains('localFileMissing');
  }

  Future<void> _rename(String id, String current) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('renameFile')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('filename'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context).t('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      ref.read(libraryControllerProvider.notifier).rename(id, value);
    }
  }
}
