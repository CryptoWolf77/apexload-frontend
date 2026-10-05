# Google Play release 1.0.2 (26)

Status recorded on 2026-10-05. The production update was **submitted for
review** with a 100% rollout. Publishing overview lists ApexLoad 1.0.2 under
**Changes in review**, together with the Advertising ID and foreground-service
declarations. Google's automated quick checks are running. The update has
**not yet been approved or published**.

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

The data-sync / download declaration was initially sent for review separately.
Submitting the production binary restarted that review to include version 26
and both declarations. Publishing overview now lists the production release
and the foreground-services declaration under **Changes in review**.

## Advertising-ID override and support

Production version 24 and uploaded version 26 contain
`com.google.android.gms.permission.AD_ID`. Obsolete version 23 lacks it and
remains active on both testing tracks. Google Play's global advertising-ID
validation initially blocked production and replacement releases while that
artifact was active. Both replacement and an empty retirement release were
attempted; each was blocked by the same validation error.

The user subsequently gave explicit approval to use the "Release without
permission" override and submit version 26. The advertising-ID declaration
remains **Yes**, with its existing advertising, analytics and fraud-prevention
purposes. The **Turn off release errors** acknowledgement is now checked and
saved. The production preview confirms that advertising-ID validation is a
warning instead of an error. Version 26 retains its AD_ID permission and live
AdMob configuration.

Releases containing version 26 and excluding the previous build:

| Track | Track ID | Release | Status |
| --- | --- | --- | --- |
| Production | `4697650771094576252` | `4` | Submitted; 100% rollout |
| Internal testing | `4700612000721633493` | `8` | Draft |
| Closed testing - Alpha | `4698592169422027994` | `2` | Draft |

The production submission includes the Advertising ID declaration change.
Managed publishing remains off, so approved changes are set to publish
automatically, as described in [Google's publishing guidance](https://support.google.com/googleplay/android-developer/answer/9859654?hl=en).
Google must complete automated checks and review first. The
remaining preview warnings were the old artifact's missing AD_ID and the
missing Java deobfuscation file.

With the user's explicit approval, a Google Play Support ticket was submitted
requesting retirement of version 23 or unblocking its replacement without
disabling validation. Console confirmed **Ticket submitted** and **Pending**.
The acknowledgement email supplied by the user confirms case
**8-678900041484**. Google says replies will be sent by email; no resolution
has been received yet.

After the production update is published, replace obsolete version 23 on both
testing tracks with a compliant bundle and verify that it is no longer active.
Then uncheck **Turn off release errors**, save and submit that declaration
change to restore validation. The override does not automatically expire.
Version 26 already contains the advertising-ID permission; a new production
binary is not required solely to add that permission. Live serving remains
subject to AdMob's readiness review, consent and available ads.
