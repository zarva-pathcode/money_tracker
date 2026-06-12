# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit Text Recognition
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Google Play Core (Flutter Deferred Components)
-dontwarn com.google.android.play.core.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# Timezone
-keep class com.jakewharton.threetenabp.** { *; }
-dontwarn com.jakewharton.threetenabp.**

# Hive (native storage layer)
-keep class com.hivedb.** { *; }

# Syncfusion Charts
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Google MLKit Document Scanner
-keep class com.google.mlkit.vision.documentscanner.** { *; }
-dontwarn com.google.mlkit.vision.documentscanner.**

# speech_to_text
-keep class com.speech_to_text.** { *; }
-dontwarn com.speech_to_text.**

# image_picker / permission_handler
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

