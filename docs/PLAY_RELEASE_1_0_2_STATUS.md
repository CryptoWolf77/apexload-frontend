# Google Play release 1.0.2 (26)

Status recorded on 2026-10-05. The update is uploaded and saved as drafts;
the production binary has **not** been submitted for review or published.

## Build and validation

- Source/build commit: `b0ed14b`, pushed to `origin/master`.
- Build: `1.0.2+26`, signed `build/app/outputs/bundle/release/app-release.aab`.
- Build command: `./tool/build_play_bundle.ps1 -FlutterExecutable C:/flutter/bin/flutter.bat -NoPub`.
- Production API, live Android AdMob, normal Play subscriptions; no tester
  Premium or mock fallback.
- `flutter analyze`: clean. `flutter test`: 184 passing tests.
- Signed bundle verification passed. The merged manifest contains AD_ID,
  FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, and WAKE_LOCK.
- Android cold/warm shared links and background saving verified on an emulator.
  Native iOS compilation, signing and device behavior still require a Mac.

## Advertising configuration

The values below match the existing Android app and interstitial in AdMob:

- App ID: `ca-app-pub-8135847965072867~3244534997`.
- Interstitial: `ca-app-pub-8135847965072867/5643467625`.
- Package: `com.yahyazlab.apexload`.

Free users remain eligible for an interstitial after every second successful
operation, subject to consent and an available ad. Premium users receive no ads.
Background completion queues the opportunity until the progress screen resumes;
the same task cannot count twice. Only Google test ads were used for emulator
validation. AdMob reports the app as **Getting ready**, so live serving remains
subject to Google's readiness review and ad availability.

## Foreground-service declaration

The real [unlisted background-download demonstration](https://youtube.com/shorts/ibR7jmZIozw)
is published on YahyazLab. Its controlled test setup is documented in
[release_media/README.md](release_media/README.md).

The data-sync / download declaration was saved and sent for review. Publishing
overview confirms **Changes in review** for the foreground-services declaration
only; this does not mean the version-26 binary is in review.

## Publishing blocker and support

Production version 24 and uploaded version 26 contain
`com.google.android.gms.permission.AD_ID`. Obsolete version 23 lacks it and
remains active on both testing tracks. Google Play's global advertising-ID
validation blocks production and replacement releases while that artifact is
active. Both replacement and an empty retirement release were attempted; each
was blocked by the same validation error.

The advertising-ID declaration remains **Yes** and permission validation remains
enabled, as requested. The "Release without permission" option was not applied.

Prepared releases, all containing version 26 and excluding the previous build:

| Track | Track ID | Draft release |
| --- | --- | --- |
| Production | `4697650771094576252` | `4` |
| Internal testing | `4700612000721633493` | `8` |
| Closed testing - Alpha | `4698592169422027994` | `2` |

With the user's explicit approval, a Google Play Support ticket was submitted
requesting retirement of version 23 or unblocking its replacement without
disabling validation. Console confirmed **Ticket submitted** and **Pending**.
The acknowledgement email supplied by the user confirms case
**8-678900041484**. Google says replies will be sent by email; no resolution
has been received yet.

Once Google resolves the validation block, preview and publish the compliant
testing replacements as needed, then submit the production draft with the
prepared 100% rollout and English release notes. Keep permission validation
enabled and inspect the current review status before submitting.
