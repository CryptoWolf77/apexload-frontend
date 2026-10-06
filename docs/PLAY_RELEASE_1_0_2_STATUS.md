# Google Play release 1.0.2 (26)

Status verified on 2026-10-06 in Google Play Console and AdMob. Production
version 26 is **Available on Google Play**, released on October 5 at 10:37 PM
(Asia/Muscat), with a **100% rollout** in all 178 targeted countries/regions.
The internal testing replacement has been published. The closed Alpha
replacement has been submitted and remains **In review**.

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
validation.

AdMob was checked again on October 6 in the publisher account matching these
IDs. The app is **Verified**, linked to the correct Google Play package, and
still **Getting ready**. The existing interstitial matches the production ID
above; neither the app nor the ad unit has an impression cap. Policy centre
reports **No current issues** and **No disapproved apps**.

AdMob Home identifies an additional blocker: **Your account isn't approved
yet** / **Your account is being verified**. Its **payment profile is complete**
and its first ad unit is set up; no incomplete setup action was presented.
The last-seven-days overview reports zero requests and zero impressions, so
live ad delivery has not been demonstrated. Google must complete account and
app approval before normal serving can be confirmed. Google's
[app readiness guidance](https://support.google.com/admob/answer/10564477?hl=en)
explains that apps can remain Getting ready while the account is unverified.
No AdMob settings or payment details were changed, and no live ads were clicked.

## Foreground-service declaration

The real [unlisted background-download demonstration](https://youtube.com/shorts/ibR7jmZIozw)
is published on YahyazLab. Its controlled test setup is documented in
[release_media/README.md](release_media/README.md).

The data-sync / download declaration was initially sent for review separately.
Submitting the production binary restarted that review to include version 26
and both declarations. The production update was subsequently approved and
published.

## Advertising-ID override and support

Production version 24 and uploaded version 26 contain
`com.google.android.gms.permission.AD_ID`. Obsolete version 23 lacks it and
was active on both testing tracks on October 5. Google Play's global advertising-ID
validation initially blocked production and replacement releases while that
artifact was active. Both replacement and an empty retirement release were
attempted; each was blocked by the same validation error.

The user subsequently gave explicit approval to use the "Release without
permission" override and submit version 26. The advertising-ID declaration
remains **Yes**, with its existing advertising, analytics and fraud-prevention
purposes. On October 5 the **Turn off release errors** acknowledgement was checked
and saved. The production preview confirmed that advertising-ID validation was a
warning instead of an error. Version 26 retains its AD_ID permission and live
AdMob configuration.

Releases containing version 26 and excluding the previous build:

| Track | Track ID | Release | Status |
| --- | --- | --- | --- |
| Production | `4697650771094576252` | `4` | Published October 5, 10:37 PM; 100% rollout |
| Internal testing | `4700612000721633493` | `8` | Published October 6, 8:22 PM; available to internal testers |
| Closed testing - Alpha | `4698592169422027994` | `2` | Submitted October 6, 8:23 PM; In review; 100% rollout requested |

The production submission included the Advertising ID declaration change.
Managed publishing remains off, so approved changes are set to publish
automatically, as described in [Google's publishing guidance](https://support.google.com/googleplay/android-developer/answer/9859654?hl=en).
Google must complete the Alpha release's automated checks and review before
that replacement is published. Its preview had nonblocking warnings about the
old artifact's missing AD_ID and the missing Java deobfuscation file. The
internal preview also warned that the track has no configured testers; tester
membership was left unchanged.

With the user's explicit approval, a Google Play Support ticket was submitted
requesting retirement of version 23 or unblocking its replacement without
disabling validation. Console confirmed **Ticket submitted** and **Pending**.
The acknowledgement email supplied by the user confirms case
**8-678900041484**. Google says replies will be sent by email; no resolution
had been received as of October 5; the support inbox was not rechecked on October 6.

On October 6, both testing replacements were confirmed to contain version 26
and exclude version 23. Internal release 8 was saved and published; Alpha
release 2 was saved and sent for review. The **App versions** table now lists
26 as **Active** and 23, 24 and 25 as **Inactive**. Alpha's previous release
still appears as available in release history while its replacement is in
review; this is distinct from the bundle's current Inactive status.

The Advertising ID declaration was revisited after these changes. It still
says **Yes** with the same three purposes and now explicitly recognises the
manifest's AD_ID permission. The **Turn off release errors** acknowledgement
is no longer displayed and Save is disabled. Consequently, no separate
override-off declaration change could be made or submitted on October 6.
Do not claim the stored override flag was independently verified as disabled.
After Alpha is approved, recheck this control and turn it off if it becomes
available; do not declare No while the app uses the advertising SDK.

Version 26 already contains the permission and correct live ad IDs; a new
production binary is not required solely to add AD_ID. The remaining live-ad
blocker identified today is AdMob's account/app approval. Once approved, verify
delivery with the Play-installed version, a free account, appropriate consent,
and successful operations; do not click live ads or create artificial traffic.

These October 6 changes affected Console releases and this status document,
not app source. The existing analysis and 184-test validation apply to the
unchanged version 26 code.
