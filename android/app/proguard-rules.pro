# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*

# Just Audio
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Riverpod
-keep class **.riverpod.generated.** { *; }

# Keep - Applications. If you are using multi-dex, keep the second line.
-keep public class * extends android.app.Application {
    public <init>();
}
