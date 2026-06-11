# Release safety for Flutter plugins. Shrinking is disabled for ApexLoad
# release builds right now, but these rules keep plugin entry points safe if
# R8 is enabled later.
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class com.crazecoder.openfile.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn com.arthenica.ffmpegkit.**
-dontwarn io.flutter.plugins.**
