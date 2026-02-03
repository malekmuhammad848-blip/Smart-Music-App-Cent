-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.ryanheise.audioservice.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class com.google.android.exoplayers.** { *; }

-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod

-keep public class * extends android.app.Application {
    public <init>();
}

-dontobfuscate
-dontoptimize
