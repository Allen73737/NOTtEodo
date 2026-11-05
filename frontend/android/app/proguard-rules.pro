# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Cryptography Flutter & Secure Storage
-keep class com.itKey.cryptography_flutter.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.biometric.** { *; }
-keep class androidx.appcompat.** { *; }

# Prevent native method stripping
-keepclasseswithmembernames class * {
    native <methods>;
}

-dontwarn io.flutter.**
-dontwarn androidx.biometric.**
