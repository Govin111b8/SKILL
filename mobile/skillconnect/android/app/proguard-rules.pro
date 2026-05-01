# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Hive annotations
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Razorpay / UPI intent (future)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
