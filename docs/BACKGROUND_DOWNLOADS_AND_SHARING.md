# Background downloads and shared links

Version 1.0.2 (25) moves backend polling, saving, and library insertion into
app-owned download tasks. Navigation away from the progress screen leaves the
task running. Transient polling failures retry the existing backend job with
backoff; explicit backend failures and permanent API errors remain failures.
Android file-transfer connection failures also retry, up to five attempts.

## Android

User-initiated downloads start a `dataSync` foreground service before creating
the backend job. Its low-priority notification and CPU wake lock remain active
until every download completes or fails. Screen wake-lock preferences do not
disable background download protection. Android 15's foreground-service timeout
stops the service and releases resources.

`ACTION_SEND` shares with `text/plain` or `text/html` launch the existing
single-task activity. Initial and subsequent shares use an acknowledged native
inbox. Flutter extracts the video URL from captions, fills Home, and analyzes
automatically. Onboarding and responsible-use consent still apply; unsupported
sources remain blocked. A newer shared link supersedes an older analysis result.

Google Play may require a foreground-service declaration and demonstration
video for the new `FOREGROUND_SERVICE_DATA_SYNC` permission. Use the data-sync /
download use case and demonstrate a user starting a download, switching apps,
and returning to the completed download.

## iPhone

Backend status checks and file transfers use an OS-managed background
`URLSession`. A short background execution allowance covers scheduling and
completion handling. Transfers wait for connectivity and retry transient
network errors. Files move from URLSession's temporary location into ApexLoad's
private documents folder before the download delegate returns. Existing iOS
playback preparation and library/gallery handling run afterward.

The native `ApexLoadShare` extension appears for web URLs and text. It detects
the URL, saves it in the shared app-group inbox, and automatically analyzes it
if responsible-use consent was already accepted. When the user opens ApexLoad,
the link fills Home and analysis proceeds automatically. Apple does not permit
a Share extension to force-open its containing app; this implementation uses
extension-safe APIs and tells the user to open ApexLoad.

Before building on a Mac:

1. Register `com.yahyazlab.apexload.share` for the existing Apple team.
2. Enable App Groups for Runner and ApexLoadShare, using
   `group.com.yahyazlab.apexload`, and refresh their signing profiles.
3. Run `flutter pub get`, `pod install` in `ios`, and build/archive Runner.
   Runner embeds ApexLoadShare through its target dependency and copy phase.
4. Verify that the extension's version/build match Runner's generated Flutter
   settings, and that both targets carry the app-group entitlement.

Native iOS compilation and device behavior cannot be verified on Windows.

## Validation on this Windows workstation

An Android Pixel_10 emulator received a cold `ACTION_SEND` link and automatically
opened download options after analysis against a local test backend. A 16 MiB
controlled transfer completed while the launcher was foreground, with the screen
wake setting disabled. The file and one library record were present before
returning to ApexLoad, and the foreground service had stopped afterward. This
checks the native share/transfer lifecycle independently of social-site extraction.
Warm sharing to the already-open activity also triggered analysis successfully.

Final validation passed: `flutter analyze` reported no issues, all 183 Flutter
tests passed, and `flutter build appbundle --release --no-pub` produced the
signed version 1.0.2 (25) bundle using the production API and normal store
subscription settings.

Existing Quick Editor phone-viewport tests also exposed overflow in its source
picker and platform preset cards; their layouts now reserve room for the action
button and card text on small screens.

## Regression checks

Run `flutter analyze` and `flutter test`. New behavioral tests cover extracting
caption links, cold/warm share delivery, automatic analysis, blocked sources,
overlapping background operations, retrying the same job on resume, saving after
detaching the progress UI, and preserving terminal failures.

On devices, test Android 14/15+ and iOS 15+ with:

- A large video download while another app is foreground, then with screen off.
- A temporary network disconnect during polling and during file transfer.
- A new shared link while the app is closed, open, and downloading another file.
- First-launch onboarding/consent followed by the queued shared link.
- Download completion in the library and optional gallery, without duplicate items.

Force-stop, explicit iOS force-quit, OS termination, and manufacturer battery
restrictions are different from switching apps and should be tested separately;
the changes do not promise unrestricted execution after a force-stop.
