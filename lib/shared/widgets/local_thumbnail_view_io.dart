import 'dart:io';

import 'package:flutter/material.dart';

class LocalThumbnailView extends StatelessWidget {
  const LocalThumbnailView({
    super.key,
    required this.path,
    required this.borderRadius,
    required this.fallback,
  });

  final String path;
  final BorderRadius borderRadius;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (path.trim().isEmpty || !file.existsSync()) return fallback;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
