# ApexLoad Mac Codex Handoff

Last updated: 2026-07-24
Project: ApexLoad / Social Media Downloader
Current objective: Validate the new iOS-only WhatsApp Status Saver on a real iPhone.

## Prompt for the new Mac Codex task

Copy the following message into a new Codex task on the Mac after opening the
ApexLoad project folder:

> Continue the ApexLoad project from `docs/MAC_CODEX_HANDOFF.md`. Read the
> entire handoff first, inspect the current working tree without discarding any
> changes, and then help me run Phase 1 of the iOS WhatsApp Status Saver on a
> real iPhone. Preserve the existing Android WhatsApp Status Saver exactly as
> it is. Do not restore the pre-Phase-1 backup unless I explicitly request it.
> I will handle all Coolify operations myself.

## Important project rules

- The Android WhatsApp Status Saver is working well and must remain unchanged.
- The iOS saver is a separate implementation selected by the platform route.
- The user handles every Coolify deployment and server-side operation.
- Preserve all existing uncommitted changes. The project was already dirty
  before the iOS feature began.
- Do not use destructive Git operations such as `git reset --hard` or discard
  unrelated changes.
- Keep Premium limited to the monthly and yearly plans. Do not restore the
  removed lifetime or batch-file features.

## Restore point made before Phase 1

Windows location:

`C:\Users\ThaherTech\Documents\ApexLoad Backups\ApexLoad_before_iOS_WhatsApp_Status_Phase1_2026-07-23_214400.zip`

SHA-256:

`DAB4FC148305F96317B100709DA7895D98CA3BB10BE4FEEA08193E979D1B9191`

This archive contains the complete source state from immediately before the
iOS Phase 1 work, including the main and nested backend Git histories and all
uncommitted source changes. It excludes only regenerable `build`,
`.dart_tool`, `.pytest_cache`, and `apexload-backend/venv` directories.

Do not restore this archive merely to troubleshoot Phase 1. It exists as the
full rollback option if the user later decides to remove the iOS feature.

## Portable Mac source package

The Windows handoff process also creates:

`C:\Users\ThaherTech\Documents\ApexLoad Backups\ApexLoad_Phase1_Mac_Handoff_2026-07-24.zip`

This is the current post-Phase-1 source intended for transfer to the Mac. For
security and portability, it excludes generated build caches, the backend
virtual environment, backend runtime storage, and backend secrets. Those
excluded backend items are not needed to build or test the iOS application.

## Current Phase 1 implementation

Phase 1 is implemented in:

- `lib/features/whatsapp_status/ios/ios_whatsapp_status_screen.dart`
- `lib/features/whatsapp_status/ios/ios_whatsapp_media_bridge.dart`
- `lib/features/whatsapp_status/ios/ios_whatsapp_web_scripts.dart`
- `test/ios_whatsapp_status_phase1_test.dart`

Related integration changes:

- `lib/core/routing/app_router.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/premium/premium_screen.dart`
- `pubspec.yaml`
- `pubspec.lock`

Dependency added:

`flutter_inappwebview: 6.1.5`

The iOS deployment target is already iOS 15.0.

## Phase 1 behavior

The iOS route now:

1. Keeps the existing Premium gate.
2. Opens an iOS-specific introduction screen.
3. Loads only `https://web.whatsapp.com/` in a native WebKit view using a
   desktop browser user agent.
4. Keeps WhatsApp Web cookies/session data locally on the iPhone.
5. Provides a Disconnect action that clears the local web session.
6. Detects whether WhatsApp Web appears linked and whether visible media is
   present.
7. Saves only after an explicit user tap.
8. Transfers the current image/video from JavaScript to Dart in 256 KB chunks
   rather than loading the complete media file into Dart memory.
9. Stores the result in ApexLoad's status media folders.
10. Adds the saved item to the existing ApexLoad Downloads library.

The WebView blocks top-level navigation away from `web.whatsapp.com`. External
links are opened outside ApexLoad.

No WhatsApp session cookie, contact, chat, or status media is intentionally
sent to the ApexLoad backend.

## Current validation results

Phase 1 was validated on a real iPhone on July 24, 2026:

- WhatsApp Web loads and links successfully inside ApexLoad.
- The session persists and can be disconnected.
- Image and video statuses save into ApexLoad Downloads.
- Saved media opens correctly and retains source quality.
- English and Arabic guides are available.
- `flutter analyze` passes with no issues.
- All 60 Flutter tests pass.
- The signed iOS release builds, installs, and launches successfully.

## Required real-iPhone Phase 1 test

On the Mac:

1. Install the current stable Xcode and accept its license/components.
2. Install Flutter and CocoaPods if they are not already installed.
3. Open Terminal in the ApexLoad project.
4. Run:

   ```bash
   flutter doctor -v
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter devices
   ```

5. Open `ios/Runner.xcworkspace` in Xcode.
6. Select the user's Apple development team and confirm the bundle signing.
7. Connect and trust the test iPhone.
8. Run from Xcode or use:

   ```bash
   flutter run -d <iphone-device-id>
   ```

9. In ApexLoad, ensure Premium is active.
10. Open **WhatsApp Status Saver**.
11. Tap **Start iOS connection test**.
12. Prefer **Link with phone number** for same-iPhone testing. Use QR linking
    only when another display is available.
13. Confirm the linked session survives closing and reopening ApexLoad.
14. Open and save:
    - one image status;
    - one short video status;
    - one larger video status if available.
15. Confirm each saved file appears in ApexLoad Downloads and opens correctly.
16. Test **Disconnect WhatsApp**, then confirm the WebView asks to link again.

## Evidence to record

For each test, record:

- Whether the WhatsApp Web page loads.
- Whether phone-number linking appears and succeeds.
- Whether ApexLoad displays “WhatsApp connected.”
- Whether “Status detected” appears when viewing an image or video status.
- The save progress behavior.
- Whether the resulting file appears and plays in Downloads.
- Whether the session persists after an app restart.
- Any visible error message and a screenshot.

## Phase 1 decision gate — passed

Do not begin the full production UI until these points are proven:

- WhatsApp Web loads reliably in the iOS WebView.
- Same-device account linking works or a practical supported alternative is
  established.
- The session persists and can be cleared.
- Both image and video statuses can be captured.
- Saved media is complete, playable, and does not cause excessive memory use.

If media detection fails, inspect the live WhatsApp Web DOM on the iPhone/Mac
Web Inspector and update only the iOS probe selectors. Do not modify Android
folder scanning.

If the media URL is inaccessible but the media is visible, inspect whether the
page creates its object URL before the document-start hook or uses a media
source mechanism that bypasses `URL.createObjectURL`. Adjust the iOS bridge
after collecting evidence; do not guess blindly.

## App Store and WhatsApp risk

The attached research PDF described this method as an approved workaround, but
that statement was not verified. Similar apps appearing on the App Store does
not guarantee approval for ApexLoad.

Before production submission:

- Keep the action manual and user-initiated.
- Do not add automatic or bulk status collection.
- Keep the session and media local.
- Add clear disconnect/deletion controls.
- Update the Privacy Policy and Responsible Use text.
- Explain the feature accurately in App Review notes.
- Be prepared for Apple to request proof that use of the third-party service
  is permitted.

## Existing ApexLoad context to preserve

- The Android `.Statuses` folder implementation is mature and working.
- Download/device-saving performance was recently optimized.
- Quick Editor large-file processing and completion UI were recently improved.
- The screen-awake feature works on the user's Android phone.
- The “Download job created” developer-style notification was removed.
- Batch-file and lifetime Premium features were removed.
- The landing-page takedown workflow was simplified to an email-based option.
- The user prefers to perform Coolify steps personally.

## After Phase 1 succeeds

Proceed with the previously approved plan:

1. Refine the iOS onboarding and linking instructions.
2. Harden status detection and saving.
3. Add iOS Photos export.
4. Complete privacy/session controls and legal copy.
5. Localize the feature in English and Arabic.
6. Test slow networks, low storage, relinking, denied permissions, iPad, and
   larger videos.
7. Produce an ApexLoad-branded tutorial video after the workflow is stable.
