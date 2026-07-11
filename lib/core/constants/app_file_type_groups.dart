import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

abstract final class AppFileTypeGroups {
  static const video = XTypeGroup(
    label: 'Video',
    extensions: ['mp4', 'mov', 'm4v', 'webm'],
    mimeTypes: ['video/mp4', 'video/quicktime', 'video/webm'],
    uniformTypeIdentifiers: ['public.movie'],
  );

  static const audio = XTypeGroup(
    label: 'Audio',
    extensions: ['mp3', 'm4a', 'aac', 'wav'],
    mimeTypes: ['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav'],
    uniformTypeIdentifiers: ['public.audio'],
  );

  static const image = XTypeGroup(
    label: 'Image',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
    uniformTypeIdentifiers: ['public.image'],
  );
}

bool isFilePickerCancellation(Object error) {
  if (error is! PlatformException) return false;
  final code = error.code.toLowerCase();
  return code == 'cancelled' ||
      code == 'canceled' ||
      code == 'user_cancelled' ||
      code == 'user_canceled';
}
