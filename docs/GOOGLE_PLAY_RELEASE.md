# ApexLoad — Google Play release guide

Last updated: 2026-08-06
App: `com.yahyazlab.apexload` · version `1.0.0+15`

Companion to `CLAUDE.md` (project guide) and `MAC_CODEX_HANDOFF.md` (iOS work).

## Build status

The signed release bundle is produced and verified:

`build/app/outputs/bundle/release/app-release.aab` — 164.9 MB

| Check | Result |
| --- | --- |
| Signature | Upload key, `CN=Yahya Al Hadhrami, OU=YahyazLab, O=YahyazLab` — `jar verified` |
| targetSdk | 36 (Play requires ≥ 35) |
| minSdk | 24 |
| 16 KB page size | 28 / 28 sixty-four-bit libraries aligned ≥ 16384 |
| Per-device download | ~58 MB on arm64 (limit 200 MB) |
| Permissions | `INTERNET`, `ACCESS_NETWORK_STATE` only |

The 164.9 MB figure is the whole bundle: three ABIs plus ~29 MB of
`BUNDLE-METADATA` (debug symbols) that is never delivered to devices.

### Signing

The upload key lives **outside the repo**:

- Keystore: `C:\Users\ThaherTech\Documents\ApexLoad Keystore\apexload-upload.jks`
- Alias: `apexload-upload`
- Password: stored beside the keystore in `apexload-upload-key-password.txt`
  and in the owner's password manager

`android/key.properties` points Gradle at it. Both that file and `**/*.jks` are
gitignored — keep it that way. `android/app/build.gradle.kts` falls back to the
debug key when `key.properties` is missing, so `flutter run --release` still
works on a machine without the key. **A bundle built that way is rejected by
Play**, so confirm `key.properties` exists before building an upload.

Because Play App Signing holds the real app signing key, a lost upload key can
be reset through Play support. Losing it is recoverable; losing it silently and
noticing after launch is not. Back it up.

### Release build command

```bash
flutter build appbundle --release --dart-define=ANDROID_STORE_URL=https://play.google.com/store/apps/details?id=com.yahyazlab.apexload
```

The `ANDROID_STORE_URL` define makes Settings → Rate app open the Play listing.
Without it the app shows "rating available after release" — harmless, but the
final upload should carry it.

Never pass `--dart-define=APEXLOAD_TESTER_PREMIUM=true` to a Play build. It
unlocks Premium without any purchase.

### Known build-environment issue on Windows

Gradle fails with `java.io.IOException: Unable to establish loopback connection`
when launched from an agent/automation sandbox — `Selector.open()` cannot create
its loopback socket pair. Plain sockets, NIO channels and `Pipe.open()` all work,
so the network stack is fine. This is **not** caused by Kaspersky; pausing
protection changes nothing.

Fix: run the build from a normal user-opened terminal. It works there.

## Play Console setup

### 1. Create the app

Play Console → **Create app**.

| Field | Value |
| --- | --- |
| App name | `ApexLoad: Video Saver & Editor` (29 / 30 chars) |
| Default language | English (United States) |
| App or game | App |
| Free or paid | Free (with in-app subscriptions) |

### 2. Subscriptions

Monetize → **Subscriptions**. Create both with the exact IDs the app queries —
a mismatch means the paywall shows nothing:

- `com.yahyazlab.apexload.premium.monthly`
- `com.yahyazlab.apexload.premium.yearly`

Do **not** add a lifetime product. It was deliberately removed.

Products stay inactive until a build containing the billing library has been
uploaded to a track, so upload the AAB first, then create the products.

### 3. Store listing

**Short description** (80 max):

```
Save videos and photos, then trim, crop and convert them right on your phone.
```

**Full description** (4000 max) — draft:

```
ApexLoad is a fast, private way to save videos and photos you have the right to
use, then edit them without leaving your phone.

SAVE WHAT YOU'RE ALLOWED TO SAVE
Paste a link and ApexLoad fetches the available quality options. Pick the
resolution and format you want, and the file lands in your device library.

BUILT-IN QUICK EDITOR
- Trim to the exact moment you need
- Crop and change aspect ratio for any feed
- Convert between formats
- Extract audio
- Compress large videos before sharing

WHATSAPP STATUS SAVER
Keep a status you were shown, saved straight to your device.

VIDEO OPTIMIZER
Shrink big files for sharing while keeping the quality you care about.

PRIVATE BY DESIGN
No account required. No ads. No analytics or tracking SDKs. Your saved files
stay on your device.

WORKS IN ENGLISH AND ARABIC
Full right-to-left support throughout.

PREMIUM
An optional subscription unlocks unlimited saves, higher output quality and the
full editing toolkit. Monthly and yearly plans are available.

RESPONSIBLE USE
ApexLoad is intended for content you own, have permission to use, or that is
publicly allowed to be downloaded. You are responsible for respecting copyright
and the terms of the platforms you use. ApexLoad is not affiliated with,
endorsed by, or sponsored by any social media platform.
```

**Listing copy rules — these matter for policy review:**

- Do **not** name YouTube anywhere in the listing, screenshots or graphics.
- Do **not** advertise watermark removal. It is removed from the product and
  advertising it is the strongest policy signal against a downloader app.
- Do **not** use any platform's logo, wordmark or brand colours in the icon,
  feature graphic or screenshots.
- Keep the non-affiliation sentence in the description.

### 4. Graphic assets

| Asset | Spec | Status |
| --- | --- | --- |
| App icon | 512 × 512 PNG, 32-bit | Available — `web/icons/Icon-512.png` |
| Feature graphic | 1024 × 500 PNG/JPG, no alpha | **Needs creating** |
| Phone screenshots | 2–8, 16:9 or 9:16, min 1080px on the short side | **Needs capturing** |
| Tablet screenshots | Optional, but required to be listed as tablet-optimised | Optional |

Suggested screenshot set: Home / paste-link, download options with quality
picker, Quick Editor trim view, Library, Premium plans, Settings.

### 5. Data safety form

Verified against the source — the app has no analytics SDK, no crash reporting,
no advertising ID, no account system, and the API client sends only an
`Accept: application/json` header.

| Question | Answer |
| --- | --- |
| Does your app collect or share required user data? | **Yes** (see below) |
| Is all data encrypted in transit? | Yes — HTTPS to `api.apexload.org` |
| Do you provide a way to request data deletion? | Yes — email route on `apexload.org` |

**The form must agree with the published privacy policy at
`https://apexload.org/privacy` (verified live, last updated 2026-07-15).** That
policy discloses more than the client code alone suggests — it states that
technical request information "may also include an IP address, user agent,
server and security logs, errors, and diagnostic information". Declare against
the policy, not against the Flutter code.

Declare:

- **App activity → Other user-generated content**: the media URL the user pastes
  is sent to the ApexLoad backend to resolve download options.
  Collected · Not shared · **Not** linked to identity · Not used for tracking ·
  Purpose: App functionality.

- **App info and performance → Crash logs / Diagnostics**: the backend records
  errors and diagnostic information per the privacy policy.
  Collected · Not shared · Not linked to identity · Purpose: App functionality.

- **Device or other IDs → IP address and user agent**: decide this one against
  how `api.apexload.org` is actually configured on Coolify, which only you can
  confirm.

  Play exempts data that is *processed ephemerally* (held in memory only, not
  retained) or *collected solely for security and abuse prevention*. IP used
  purely for rate limiting can fall under that exemption. But the privacy policy
  says "server and security logs" are kept, and in-app the IP is recorded in the
  takedown abuse-protection path (`app/core/takedown_protection.py`).

  **If those logs are retained on the server, declare it.** Under-declaring is a
  common cause of Play enforcement, and the cost of declaring is nearly zero
  here — it is not linked to identity and not used for tracking.

- **Personal info → Email address**: only applies to the support/legal email
  route described in the policy, which is ordinary email rather than in-app
  collection. Declare it only if you consider the support flow part of the app.

Do **not** declare: name, phone, location, contacts, photos read from the device
library, or financial info. Subscription payments are handled entirely by Google
Play and are not declared as your own collection.

Media the user saves stays on the device and is never uploaded — the policy says
the same, so the two are consistent.

### 6. Content rating

Complete the IARC questionnaire honestly. Expect **Everyone** / **PEGI 3**
unless you answer yes to user-to-user communication (you should answer no —
ApexLoad has none).

Flag in the questionnaire: the app can access and display user-supplied web
content (WhatsApp Web on iOS; on Android the status saver reads a local folder).

### 7. App access

Premium is gated behind a real subscription, so tell reviewers how to see it:

```
Most of ApexLoad works without any account or login.

Premium features (unlimited saves, full Quick Editor toolkit, WhatsApp Status
Saver) require an active subscription purchased through Google Play. No login
credentials exist — there is no account system.

To review Premium features without charge, please add the review account as a
license tester, or contact us and we will provide a promo code.
```

Do **not** upload a build with `APEXLOAD_TESTER_PREMIUM=true` to give reviewers
access. That ships Premium free to every user.

### 8. Closed testing requirement

Individual (personal) developer accounts created after November 2023 must run a
**closed test with at least 12 testers who stay opted in for 14 continuous
days** before production access is granted. Organisation accounts are exempt.

Plan for this: it is a two-week floor on the launch date, not a formality. Start
the closed test as early as possible.

## Policy risk — read before submitting

ApexLoad on Android currently offers all 8 platforms, including
`YouTube Shorts` (`AppConstants.supportedPlatforms`).

Google Play's **Device and Network Abuse** policy prohibits apps that facilitate
downloading YouTube content in violation of YouTube's terms. This is the single
most common reason downloader apps are removed from Play. Apple already required
this cut on iOS under guideline 5.2.3, which is why
`AppConstants.iosSupportedPlatforms` excludes it.

The owner has decided to submit **with** YouTube support and see how review
goes. That is a deliberate, informed choice.

If review flags it, the fix is small and already designed — the iOS path does
exactly this:

1. Remove `'YouTube Shorts'` from `AppConstants.supportedPlatforms`.
2. Make `AppConstants.isBlockedSource()` return true for YouTube URLs on all
   platforms, not just iOS (drop the `if (!isIosBuild) return false;` guard).
3. Update `test/ios_source_policy_test.dart` to cover Android too.

Repeat violations can escalate from app removal to developer-account
termination, so if it is flagged once, fix it rather than resubmitting as-is.

## Pre-submission checklist

- [ ] Keystore and password backed up in a password manager
- [ ] AAB rebuilt with `ANDROID_STORE_URL`
- [ ] `key.properties` present so the bundle is upload-key signed
- [x] Privacy policy live at `https://apexload.org/privacy` (verified 2026-08-06)
- [x] Terms live at `https://apexload.org/terms` (verified 2026-08-06)
- [ ] Feature graphic created
- [ ] Screenshots captured (no platform logos visible)
- [ ] Both subscription products created with exact IDs
- [ ] Data safety form submitted
- [ ] Content rating questionnaire completed
- [ ] App access notes filled in for reviewers
- [ ] Closed test started (individual accounts)

## Deferred / optional improvements

- **Adaptive launcher icon.** There is no `mipmap-anydpi-v26`, so Android 8+
  shows the square icon on a shim background instead of a properly masked
  adaptive icon. Cosmetic, not a blocker.
- **R8 / resource shrinking** is off (`isMinifyEnabled = false`). Left off
  deliberately: nearly all of this app's size is ffmpeg and WebView native
  libraries, which R8 does not touch, so shrinking buys little and risks
  stripping plugin entry points.
- The root `README.md` is still the default Flutter template.
