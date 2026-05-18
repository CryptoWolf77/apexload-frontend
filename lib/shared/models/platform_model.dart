import 'package:flutter/material.dart';

class PlatformModel {
  const PlatformModel({
    required this.name,
    required this.hostHints,
    required this.icon,
  });

  final String name;
  final List<String> hostHints;
  final IconData icon;
}
