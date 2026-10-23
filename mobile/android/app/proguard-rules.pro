# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# shared_preferences (Pigeon + Kotlin suspend) — R8 otherwise strips
# SharedPreferencesApiRegistrar.getAll(..., Continuation) and crashes at startup.
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keepclassmembers class ** {
    kotlin.coroutines.Continuation *(***);
}

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services (Maps, Location)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# flutter_background_service
-keep class id.flutter.** { *; }

# Sentry — keep unobfuscated frames for stack traces
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Preserve line numbers for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
