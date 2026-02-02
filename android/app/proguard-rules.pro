# Flutter Core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Audio & Media Handling (Just Audio & Audio Service)
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class com.google.android.exoplayers.** { *; }

# Networking & JSON (Used by YouTube Explode)
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

# Provider & State Management
-keep class com.provider.** { *; }

# Multidex Support for 50k+ lines
-keep public class * extends android.app.Application {
    public <init>();
}
-keep class androidx.multidex.** { *; }

# Optimization settings
-dontobfuscate
-dontoptimize
