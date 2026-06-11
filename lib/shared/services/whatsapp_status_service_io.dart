import 'dart:io';

import 'package:apexload/features/whatsapp_status/whatsapp_status_models.dart';
import 'package:apexload/shared/models/download_format_model.dart';
import 'package:apexload/shared/models/download_item_model.dart';
import 'package:apexload/shared/services/local_media_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsAppStatusService {
  WhatsAppStatusService({LocalMediaService? mediaService})
    : _mediaService = mediaService ?? LocalMediaService();

  static const _folderKey = 'whatsapp_status_folder_path';
  static const _businessFolderKey = 'whatsapp_business_status_folder_path';
  static const _treeUriKey = 'whatsapp_status_tree_uri';
  static const _businessTreeUriKey = 'whatsapp_business_status_tree_uri';
  static const _savedKeysKey = 'whatsapp_status_saved_keys';

  final LocalMediaService _mediaService;
  static const _androidChannel = MethodChannel('apexload/android');

  Future<String?> connectedFolder({bool business = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(business ? _businessTreeUriKey : _treeUriKey) ??
        prefs.getString(business ? _businessFolderKey : _folderKey);
  }

  Future<List<WhatsAppStatusSource>> detectSources() async {
    final standard = await _detectSource(business: false);
    final business = await _detectSource(business: true);
    return [standard, business];
  }

  Future<String?> connectFolder({required bool business}) async {
    if (Platform.isAndroid) {
      final treeUri = await _openAndroidStatusTree(business: business);
      if (treeUri != null && treeUri.trim().isNotEmpty) {
        if (!_looksLikeStatusesFolder(treeUri)) {
          throw const WhatsAppStatusException('wrongWhatsappFolder');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          business ? _businessTreeUriKey : _treeUriKey,
          treeUri,
        );
        return treeUri;
      }
    }
    final path = await getDirectoryPath(
      confirmButtonText: business
          ? 'Connect WhatsApp Business Folder'
          : 'Connect WhatsApp Folder',
    );
    if (path == null || path.trim().isEmpty) return null;
    if (!_looksLikeStatusesFolder(path)) {
      throw const WhatsAppStatusException('wrongWhatsappFolder');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(business ? _businessFolderKey : _folderKey, path);
    return path;
  }

  Future<void> disconnectFolder({bool business = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(business ? _businessFolderKey : _folderKey);
    await prefs.remove(business ? _businessTreeUriKey : _treeUriKey);
  }

  Future<List<WhatsAppStatusItem>> scan({bool business = false}) async {
    final folderPath = await connectedFolder(business: business);
    if (folderPath == null || folderPath.trim().isEmpty) return const [];
    if (_isContentUri(folderPath)) {
      return _scanContentTree(folderPath);
    }
    final folder = Directory(folderPath);
    if (!folder.existsSync()) {
      throw const WhatsAppStatusException('whatsappFolderAccessError');
    }

    final prefs = await SharedPreferences.getInstance();
    final savedKeys = (prefs.getStringList(_savedKeysKey) ?? const []).toSet();
    final items = <WhatsAppStatusItem>[];

    await for (final entity in folder.list(followLinks: false)) {
      if (entity is! File) continue;
      final fileName = entity.uri.pathSegments.last;
      final type = _typeFor(fileName);
      if (type == null) continue;
      final stat = await entity.stat();
      final duplicateKey =
          '${entity.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
      final thumbnail = await _mediaService.generateThumbnail(
        localFilePath: entity.path,
        fileName: fileName,
        type: type,
      );
      items.add(
        WhatsAppStatusItem(
          id: duplicateKey,
          title: _titleFor(type, stat.modified),
          sourcePath: entity.path,
          fileName: fileName,
          type: type,
          sizeLabel: _formatBytes(stat.size),
          modifiedAt: stat.modified,
          duplicateKey: duplicateKey,
          thumbnailPath: thumbnail ?? '',
          isSaved: savedKeys.contains(duplicateKey),
        ),
      );
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }

  Future<WhatsAppStatusSource> _detectSource({required bool business}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(
      business ? _businessFolderKey : _folderKey,
    );
    final savedTreeUri = prefs.getString(
      business ? _businessTreeUriKey : _treeUriKey,
    );
    final label = business ? 'WhatsApp Business' : 'WhatsApp';
    if (savedTreeUri != null && savedTreeUri.trim().isNotEmpty) {
      if (!_looksLikeStatusesFolder(savedTreeUri)) {
        return WhatsAppStatusSource(
          id: business ? 'business' : 'standard',
          label: label,
          business: business,
          state: WhatsAppStatusConnectionState.wrongFolder,
          folderPath: savedTreeUri,
          installed: true,
        );
      }
      try {
        final rows = await _listAndroidDocuments(savedTreeUri);
        return WhatsAppStatusSource(
          id: business ? 'business' : 'standard',
          label: label,
          business: business,
          state:
              rows.any((row) => _typeFor(row['name'] as String? ?? '') != null)
              ? WhatsAppStatusConnectionState.connectedAutomatic
              : WhatsAppStatusConnectionState.connectedNoStatuses,
          folderPath: savedTreeUri,
          installed: true,
        );
      } on Object {
        return WhatsAppStatusSource(
          id: business ? 'business' : 'standard',
          label: label,
          business: business,
          state: WhatsAppStatusConnectionState.permissionRevoked,
          folderPath: savedTreeUri,
          installed: true,
        );
      }
    }
    if (savedPath != null && savedPath.trim().isNotEmpty) {
      if (!_looksLikeStatusesFolder(savedPath)) {
        return WhatsAppStatusSource(
          id: business ? 'business' : 'standard',
          label: label,
          business: business,
          state: WhatsAppStatusConnectionState.wrongFolder,
          folderPath: savedPath,
          installed: true,
        );
      }
      final saved = Directory(savedPath);
      if (_isReadableDirectory(saved)) {
        final hasMedia = saved
            .listSync(followLinks: false)
            .whereType<File>()
            .any((file) => _typeFor(file.path) != null);
        return WhatsAppStatusSource(
          id: business ? 'business' : 'standard',
          label: label,
          business: business,
          state: hasMedia
              ? WhatsAppStatusConnectionState.connectedAutomatic
              : WhatsAppStatusConnectionState.connectedNoStatuses,
          folderPath: saved.path,
          installed: true,
        );
      }
      return WhatsAppStatusSource(
        id: business ? 'business' : 'standard',
        label: label,
        business: business,
        state: WhatsAppStatusConnectionState.permissionRevoked,
        folderPath: savedPath,
        installed: true,
      );
    }

    final candidates = _candidateFolders(business: business);
    for (final path in candidates) {
      final folder = Directory(path);
      if (_isReadableDirectory(folder)) {
        await prefs.setString(business ? _businessFolderKey : _folderKey, path);
        return WhatsAppStatusSource(
          id: business ? 'business' : 'standard',
          label: label,
          business: business,
          state: WhatsAppStatusConnectionState.connectedAutomatic,
          folderPath: path,
          installed: true,
        );
      }
    }

    final installed =
        await _isPackageInstalled(
          business ? 'com.whatsapp.w4b' : 'com.whatsapp',
        ) ||
        _candidateAppFolders(
          business: business,
        ).any((path) => Directory(path).existsSync());
    return WhatsAppStatusSource(
      id: business ? 'business' : 'standard',
      label: label,
      business: business,
      state: installed
          ? WhatsAppStatusConnectionState.setupRequired
          : WhatsAppStatusConnectionState.folderNotFound,
      installed: installed,
    );
  }

  List<String> _candidateFolders({required bool business}) {
    final roots = ['/storage/emulated/0', '/sdcard'];
    final appPath = business
        ? 'Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses'
        : 'Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
    final legacyPath = business
        ? 'WhatsApp Business/Media/.Statuses'
        : 'WhatsApp/Media/.Statuses';
    return [
      for (final root in roots) '$root/$appPath',
      for (final root in roots) '$root/$legacyPath',
    ];
  }

  List<String> _candidateAppFolders({required bool business}) {
    final roots = ['/storage/emulated/0', '/sdcard'];
    final appPath = business
        ? 'Android/media/com.whatsapp.w4b/WhatsApp Business/Media'
        : 'Android/media/com.whatsapp/WhatsApp/Media';
    final legacyPath = business ? 'WhatsApp Business/Media' : 'WhatsApp/Media';
    return [
      for (final root in roots) '$root/$appPath',
      for (final root in roots) '$root/$legacyPath',
    ];
  }

  bool _isReadableDirectory(Directory folder) {
    try {
      if (!folder.existsSync()) return false;
      folder.listSync(followLinks: false);
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> _isPackageInstalled(String packageName) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _androidChannel.invokeMethod<bool>('isPackageInstalled', {
            'packageName': packageName,
          }) ??
          false;
    } on Object {
      return false;
    }
  }

  Future<DownloadItemModel> saveStatus(WhatsAppStatusItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = (prefs.getStringList(_savedKeysKey) ?? const []).toSet();
    if (savedKeys.contains(item.duplicateKey)) {
      throw const WhatsAppStatusException('statusAlreadySaved');
    }

    final result = await _mediaService.saveLocalFile(
      sourcePath: item.sourcePath,
      fileName: item.fileName,
      type: item.type,
      statusFile: true,
    );
    savedKeys.add(item.duplicateKey);
    await prefs.setStringList(_savedKeysKey, savedKeys.toList());

    return DownloadItemModel(
      id: 'whatsapp_status_${DateTime.now().millisecondsSinceEpoch}',
      title: item.title,
      platform: 'WhatsApp Status',
      date: DateTime.now(),
      sizeLabel: result.sizeLabel,
      type: item.type,
      thumbnailUrl: '',
      fileName: result.fileName,
      localFilePath: result.localFilePath,
      thumbnailPath: result.thumbnailPath,
      galleryUri: result.galleryUri,
      duration: item.duration,
      quality: 'Status',
      isEdited: true,
    );
  }

  Future<List<WhatsAppStatusItem>> _scanContentTree(String treeUri) async {
    final rows = await _listAndroidDocuments(treeUri);
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = (prefs.getStringList(_savedKeysKey) ?? const []).toSet();
    final items = <WhatsAppStatusItem>[];
    for (final row in rows) {
      final fileName = (row['name'] as String? ?? '').trim();
      final docUri = (row['uri'] as String? ?? '').trim();
      if (fileName.isEmpty || docUri.isEmpty) continue;
      final type = _typeFor(fileName);
      if (type == null) continue;
      final size = (row['size'] as num?)?.toInt() ?? 0;
      final modifiedMs = (row['modified'] as num?)?.toInt() ?? 0;
      final modified = modifiedMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(modifiedMs)
          : DateTime.now();
      final duplicateKey = '$docUri|$size|$modifiedMs';
      final cachePath = await _copyAndroidDocumentToCache(docUri, fileName);
      if (cachePath == null || cachePath.trim().isEmpty) continue;
      final thumbnail = await _mediaService.generateThumbnail(
        localFilePath: cachePath,
        fileName: fileName,
        type: type,
      );
      items.add(
        WhatsAppStatusItem(
          id: duplicateKey,
          title: _titleFor(type, modified),
          sourcePath: cachePath,
          fileName: fileName,
          type: type,
          sizeLabel: _formatBytes(size),
          modifiedAt: modified,
          duplicateKey: duplicateKey,
          thumbnailPath: thumbnail ?? '',
          isSaved: savedKeys.contains(duplicateKey),
        ),
      );
    }
    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }

  bool _isContentUri(String value) => value.startsWith('content://');

  bool _looksLikeStatusesFolder(String value) {
    final decoded = Uri.decodeFull(value).toLowerCase();
    final normalized = decoded.replaceAll('\\', '/');
    return normalized.endsWith('/.statuses') ||
        normalized.contains('/.statuses?') ||
        normalized.contains('%2f.statuses');
  }

  Future<String?> _openAndroidStatusTree({required bool business}) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _androidChannel.invokeMethod<String>('openStatusTree', {
        'business': business,
      });
    } on Object {
      return null;
    }
  }

  Future<List<Map<String, Object?>>> _listAndroidDocuments(
    String treeUri,
  ) async {
    if (!Platform.isAndroid) return const [];
    final result = await _androidChannel.invokeMethod<List<Object?>>(
      'listDocumentTree',
      {'treeUri': treeUri},
    );
    return (result ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map((row) => row.map((key, value) => MapEntry('$key', value)))
        .toList();
  }

  Future<String?> _copyAndroidDocumentToCache(
    String uri,
    String fileName,
  ) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _androidChannel.invokeMethod<String>('copyDocumentToCache', {
        'uri': uri,
        'fileName': fileName,
      });
    } on Object {
      return null;
    }
  }

  DownloadType? _typeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return DownloadType.image;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.mov')) {
      return DownloadType.video;
    }
    return null;
  }

  String _titleFor(DownloadType type, DateTime modified) {
    final prefix = type == DownloadType.video
        ? 'WhatsApp status video'
        : 'WhatsApp status photo';
    return '$prefix ${modified.month}/${modified.day}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}

class WhatsAppStatusException implements Exception {
  const WhatsAppStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}
