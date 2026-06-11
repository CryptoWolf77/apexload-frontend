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
  Widget build(BuildContext context) => fallback;
}
