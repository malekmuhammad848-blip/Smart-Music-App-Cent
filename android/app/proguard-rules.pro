# Flutter Core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core Libraries (إضافة هذه السطور)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Audio & Media Handling
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Networking & JSON
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

# Provider & State Management
-keep class com.provider.** { *; }

# Multidex Support
-keep public class * extends android.app.Application {
    public <init>();
}
-keep class androidx.multidex.** { *; }

# YouTube Explode
-keep class com.github.** { *; }
-dontwarn com.github.**

# Optimization settings
-dontobfuscate
-dontoptimize
