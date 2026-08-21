import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest contains the ApexLoad AdMob application ID', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android:name="com.google.android.gms.ads.APPLICATION_ID"'),
    );
    expect(
      manifest,
      contains('android:value="ca-app-pub-8135847965072867~3244534997"'),
    );
  });

  test('Android manifest removes dependency-injected broad media access', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('xmlns:tools="http://schemas.android.com/tools"'),
    );

    for (final permission in const [
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
      'android.permission.READ_MEDIA_AUDIO',
      'android.permission.READ_EXTERNAL_STORAGE',
    ]) {
      final declaration = RegExp(
        '<uses-permission\\s+'
        '[^>]*android:name="$permission"'
        '[^>]*tools:node="remove"\\s*/>',
        multiLine: true,
      );
      expect(
        manifest,
        matches(declaration),
        reason: '$permission must be removed during Android manifest merging.',
      );
    }

    for (final permission in const [
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.MANAGE_EXTERNAL_STORAGE',
      'android.permission.ACCESS_MEDIA_LOCATION',
      'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
      'com.google.android.gms.permission.AD_ID',
    ]) {
      expect(
        manifest,
        isNot(contains(permission)),
        reason: '$permission must not be declared by ApexLoad.',
      );
    }
  });
}
