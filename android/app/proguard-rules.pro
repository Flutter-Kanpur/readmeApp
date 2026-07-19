# Project-specific ProGuard / R8 rules for ReadMe.
# Flutter and plugins also contribute consumer ProGuard rules.

# Keep Flutter embedding / engine entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Optional Play Core / signing paths some plugins reference.
-dontwarn com.google.android.play.core.**
