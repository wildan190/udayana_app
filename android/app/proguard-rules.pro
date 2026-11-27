# Flutter Engine & Plugin Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Keep Native FFI libraries
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep App Models & Classes
-keep class com.udayana_store.** { *; }

# Don't warn on play services / androidx
-dontwarn android.support.**
-dontwarn androidx.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.play.core.**
