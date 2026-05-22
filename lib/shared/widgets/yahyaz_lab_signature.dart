import 'package:apexload/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class YahyazLabSignature extends StatelessWidget {
  const YahyazLabSignature({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoWidth = compact ? 150.0 : 180.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Made by',
            style: TextStyle(
              color: AppTone.textSecondary(context),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 5 : 7),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? 170 : 220,
              maxHeight: compact ? 70 : 88,
            ),
            child: Image.asset(
              'assets/images/yahyaz_lab_logo.png',
              width: logoWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}
