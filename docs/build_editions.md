# ApexLoad Build Editions

ApexLoad ships two transparent builds from the same Flutter codebase:

- **Store Edition**: local video editor and media library tools for Google Play and Apple App Store.
- **Full Edition**: the complete social downloader build with backend analyze/download integration.

## Edition Entry Points

- Store Edition: `lib/main_store.dart`
- Full Edition: `lib/main_full.dart`
- Default entry point `lib/main.dart` reads Flutter's compile-time `appFlavor`.
  `--flavor store` launches Store Edition and `--flavor full` launches Full Edition.

## Run Locally

```powershell
flutter run --flavor store
flutter run --flavor full
```

For Chrome/web checks:

```powershell
flutter run -d chrome -t lib/main_store.dart
flutter run -d chrome -t lib/main_full.dart
```

## Android Builds

Android product flavors:

- `store`: `com.yahyazlab.apexload`, app name `ApexLoad`
- `full`: `com.yahyazlab.apexload.full`, app name `ApexLoad Full`

Store debug APK:

```powershell
flutter build apk --flavor store -t lib/main_store.dart --debug
flutter build apk --flavor store --debug
```

Store release AAB for Google Play:

```powershell
flutter build appbundle --flavor store -t lib/main_store.dart --release
flutter build appbundle --flavor store --release
```

Full release APK:

```powershell
flutter build apk --flavor full -t lib/main_full.dart --release
flutter build apk --flavor full --release
```

## iOS Store Build

The iOS Store build uses bundle ID `com.yahyazlab.apexload` and the Store entry point.

```powershell
flutter build ipa -t lib/main_store.dart --release
```

Open `ios/Runner.xcworkspace` in Xcode for signing, archive, and App Store upload.

## Validation

```powershell
dart format .
flutter analyze
flutter test
flutter build apk --flavor store --release
flutter build apk --flavor full --release
```

## Notes

- The Store Edition does not register social analyze/download routes in the app UI.
- The Store Edition home screen focuses on local import, Quick Editor, local library, settings, Premium, privacy, terms, and support.
- The Full Edition preserves the existing ApexLoad backend configuration and social downloader behavior.
- Do not use hidden runtime reviewer checks, remote flags, date checks, geographic checks, or account-based hiding to switch edition behavior.
