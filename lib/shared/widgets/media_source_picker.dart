import 'package:apexload/core/constants/app_file_type_groups.dart';
import 'package:apexload/core/localization/app_localizations.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart' show openFile;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

enum LocalMediaKind { video, audio }

enum _LocalMediaSource { files, library }

/// Lets people choose a video or audio file from Files, or a video from the
/// system media library. Audio extraction from a library video is supported by
/// the existing Quick Editor conversion flow.
Future<XFile?> pickLocalMedia(
  BuildContext context, {
  required LocalMediaKind kind,
}) async {
  final l = AppLocalizations.of(context);
  final isAudio = kind == LocalMediaKind.audio;
  final isIos = Theme.of(context).platform == TargetPlatform.iOS;

  final source = await showModalBottomSheet<_LocalMediaSource>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAudio ? l.t('chooseAudioSource') : l.t('chooseVideoSource'),
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            isAudio
                ? l.t('chooseVideoForAudio')
                : l.t('chooseVideoFromLibrary'),
            style: TextStyle(
              color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.folder_open_rounded)),
            title: Text(l.t('files')),
            subtitle: Text(l.t('browseDeviceFiles')),
            onTap: () =>
                Navigator.of(sheetContext).pop(_LocalMediaSource.files),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(
                isIos
                    ? Icons.photo_library_outlined
                    : Icons.photo_library_rounded,
              ),
            ),
            title: Text(isIos ? l.t('photoLibrary') : l.t('gallery')),
            subtitle: Text(
              isAudio
                  ? l.t('chooseVideoForAudio')
                  : l.t('chooseVideoFromLibrary'),
            ),
            onTap: () =>
                Navigator.of(sheetContext).pop(_LocalMediaSource.library),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;

  if (source == _LocalMediaSource.files) {
    return openFile(
      acceptedTypeGroups: [
        isAudio ? AppFileTypeGroups.audio : AppFileTypeGroups.video,
      ],
    );
  }

  return image_picker.ImagePicker().pickVideo(
    source: image_picker.ImageSource.gallery,
  );
}
