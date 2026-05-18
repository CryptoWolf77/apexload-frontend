import 'package:apexload/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      extendBody: extendBody,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? const [
                    AppColors.lightBackground,
                    Color(0xFFFFFFFF),
                    AppColors.lightSurfaceSecondary,
                  ]
                : const [
                    AppColors.background,
                    Color(0xFF111735),
                    AppColors.background,
                  ],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
