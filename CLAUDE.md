# ApexLoad — project guide

ApexLoad: Social Downloader. Flutter app (iOS + Android) with a Python/FastAPI
backend. Owner/developer: Yahya Al Hadhrami (YahyazLab).

## Repositories

| Part | Location | Remote |
| --- | --- | --- |
| Frontend (this repo) | `/Users/administrator/Projects/apexload-frontend` | `https://github.com/CryptoWolf77/apexload-frontend.git`, branch `master` |
| Backend | `apexload-backend/` (nested) | **local path only** — `/Users/administrator/Desktop/New project 4/apexload-backend` |

### Known repository hazards — check these before assuming work is safe

- `apexload-backend` is recorded in the frontend index as a **gitlink
  (mode 160000) with no `.gitmodules`**. It is a broken submodule reference:
  cloning this repo does not fetch the backend, and backend commits are not
  pushed anywhere off this Mac.
- The backend has **no GitHub remote**. Its only remote is a folder on the
  Desktop, so GitHub holds no backup of backend code.
- Confirm with `git log origin/master..HEAD` before starting — this tree has
  historically carried several unpushed commits plus a large uncommitted
  working set.

## Stack

- **Flutter** stable 3.44.6, Dart SDK `^3.11.5`
- **State**: `flutter_riverpod` 3 · **Routing**: `go_router` 17
- **Network**: `dio` → `https://api.apexload.org`
- **Media**: `ffmpeg_kit_flutter_new`, `video_player`, `image_picker`
- **WebView**: `flutter_inappwebview` 6.1.5 (iOS WhatsApp Status Saver)
- **Payments**: `in_app_purchase` + `in_app_purchase_storekit`
- **Backend**: FastAPI + `yt-dlp` (pinned `2026.07.04`) + Docker, deployed on
  Coolify. See `apexload-backend/README.md` — it is the real backend
  documentation and is far more complete than this file.

## App identity

| | |
| --- | --- |
| Bundle / applicationId | `com.yahyazlab.apexload` (iOS and Android) |
| Store name | `ApexLoad: Video Saver & Editor` — **not** "Social Downloader" |
| Version | `1.0.0+15` (`pubspec.yaml`) |
| Apple team | `3393P2G2T3` |
| iOS deployment target | 15 (Runner target) |
| Locales | `en`, `ar` — both must be updated together |
| Site / API | `https://apexload.org` · `https://api.apexload.org` |

### In-app purchases

Only two products, both subscriptions:

- `com.yahyazlab.apexload.premium.monthly`
- `com.yahyazlab.apexload.premium.yearly`

**Do not reintroduce a lifetime plan or batch-file features** — both were
deliberately removed.

`AppConfig.testerPremiumEnabled` (`--dart-define=APEXLOAD_TESTER_PREMIUM=true`)
unlocks Premium without StoreKit, for TestFlight builds only. **Never build an
App Store release with it**, and never promote a tester archive to release —
Premium would ship free to everyone.

## App Store guideline 5.2.3 — hard constraints on iOS

Apple rejected 1.0.0 (14) under **5.2.3 (Audio/Video Downloading)**. Build 15
resubmitted with compliance changes. **Never undo these on iOS:**

- **No YouTube downloading, on any build.** The shared supported-platform list
  excludes it, and `AppConstants.isBlockedSource()` refuses those URLs before
  any network call. Guarded by `test/youtube_source_policy_test.dart`.
- **No watermark removal.** Feature, Premium bullet and marketing claims are
  gone; `noWatermark` is hard-coded `false`. Advertising removal of a
  platform's attribution mark is the single worst 5.2.3 signal.
- **Non-affiliation notice** stays on the home screen (EN + AR).
- Never hide functionality from App Review behind a flag or remote config —
  that risks account termination, not just rejection.

If 5.2.3 recurs, the WhatsApp Status Saver is the next thing to cut: it also
saves third-party media.

## Working rules

- **Preserve uncommitted work.** This tree is usually dirty on purpose. Never
  `git reset --hard`, never discard unrelated changes, never commit or push
  unless explicitly asked.
- **The user runs all Coolify and server operations personally.** Do not deploy.
- **Never commit cookies** (Instagram `.txt` cookie files) or bake them
  into Docker images. They are gitignored; keep it that way.
- Run `flutter analyze` and `flutter test` before declaring work done.

## WhatsApp Status Saver — two separate implementations

Selected by platform in `lib/core/routing/app_router.dart` (`/whatsapp-status`),
behind the Premium gate.

- **Android** — `lib/features/whatsapp_status/whatsapp_status_screen.dart`.
  Scans the `.Statuses` folder. Mature and working. **Do not modify** unless a
  shared-code change is genuinely required and fully verified.
- **iOS** — `lib/features/whatsapp_status/ios/`. Embeds WhatsApp Web in a
  `WKWebView`; the user browses manually and taps to save the visible media.
  The app renders WhatsApp Web, it does not build its own status list.

### Confirmed platform limitation (do not try to "fix" this)

WhatsApp does **not** deliver status updates published *before* a device was
linked. Verified on 2026-08-01 in ApexLoad, Safari and Chrome — all three show
only statuses posted after linking. No app-side change can surface them. Say so
plainly if it comes up again, and keep it in user-facing copy.

### iOS WebView specifics

- The injected viewport (`ios_whatsapp_web_scripts.dart`) pins a 980px desktop
  layout and **bounds the zoom range** to ~2.5× from fit. The original
  `minimum-scale=0.25, maximum-scale=2.5` allowed >6× past fit; the resulting
  re-raster spike got the WebContent process killed, showing ApexLoad's blue
  gradient through an empty WebView.
- Do **not** use `InAppWebViewSettings.supportZoom: false` — on iOS the plugin
  implements it by appending its own `width=device-width` viewport tag, which
  destroys the desktop layout.
- `onWebContentProcessDidTerminate` drives a bounded recovery ladder:
  re-inject → reload → recreate the platform view (max 3 per 2 min). Cookies,
  localStorage and IndexedDB live in the shared WebKit data store, so recreation
  preserves the linked session — never clear them as a "fix".

## Build and release

```bash
flutter run -d <device-id>
flutter analyze
flutter test
```

**TestFlight build** (Premium unlocked for testers):

```bash
flutter build ipa --release --dart-define=APEXLOAD_TESTER_PREMIUM=true
```

**App Store release build** (Premium gated normally):

```bash
flutter build ipa --release
```

`flutter build ipa` writes `build/ios/archive/Runner.xcarchive`. Xcode's
Organizer reads `~/Library/Developer/Xcode/Archives/<date>/` instead, so copy
the archive there to distribute from the UI.

### Device-testing gotchas seen on this Mac

- `flutter run` on iOS drives Xcode over AppleScript and has failed with
  `Timed out waiting for CONFIGURATION_BUILD_DIR to update`. Quitting Xcode and
  granting Automation access to the terminal helps. Bypass it entirely with
  `flutter build ios --profile` + `xcrun devicectl device install app`.
- Only an **Apple Development** certificate is installed. Archives are
  development-signed; distribute through Organizer, which re-signs. Do not
  upload the raw IPA via Transporter.
- `flutter logs` and `devicectl --console` capture nothing from profile builds
  (`debugPrint` goes to `os_log`). `idevicesyslog` from `libimobiledevice` would
  fix this; it is not installed.

## Current known state

- `flutter analyze`: clean apart from one pre-existing `unnecessary_underscores`
  info in `lib/features/home/home_screen.dart:263`.
- `flutter test`: 72 pass, **2 pre-existing failures** — RenderFlex overflows in
  `test/quick_editor_test.dart`, from
  `lib/features/quick_editor/quick_editor_screen.dart:2194`. Unrelated to
  recent work.
- No CI. No GitHub Actions.
- The root `README.md` is still the default Flutter template and describes
  nothing about this project. `apexload-backend/README.md` is the real doc.

## Startup sequence

`main.dart` → `bootstrapApexLoad()` → `runApp` immediately (nothing may be
awaited before `runApp`; until it runs there is no Flutter app, so a stalled
platform channel would strand the native launch screen with no way to report
it) → router `initialLocation: '/splash'` → `SplashScreen` holds 2s while
resolving preferences → `/onboarding`, `/responsible-use`, or `/home`.

`ios/Runner/Base.lproj/LaunchScreen.storyboard` is a solid `#0B1020` fill
(matching `AppColors.background`) so the native→Flutter handoff is invisible.
iOS requires a launch screen; it cannot be removed.
