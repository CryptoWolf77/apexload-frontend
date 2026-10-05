# Android background download demonstration

[Watch the recording](apexload-foreground-service-demo.mp4).

Recorded on an Android Pixel_10 emulator on 2026-10-05 using ApexLoad 1.0.2
and a controlled local test server. The server supplies a real 4.8 MB MP4 over
about 32 seconds, exercising ApexLoad's native transfer and dataSync foreground
service. The recording shows the user starting a download, switching to Android
Settings, then returning to a successfully saved download.

This checks app-switching behavior independently of social-platform extraction.
The test build uses a local API and Google's test ads; the Google Play bundle
uses the production API and live AdMob unit. No private user data or live ad
clicks are included. The file is a continuous emulator screen recording with
container metadata removed and fast-start MP4 indexing added.
