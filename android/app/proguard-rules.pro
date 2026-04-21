# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Postgrest / Gotrue Rules
-keep class io.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }

# Cashfree SDK Rules
-keep class com.cashfree.** { *; }
-dontwarn com.cashfree.**

# General rules for reflection used by many plugins
-keepattributes Signature,Exceptions,Annotation
-keep class com.google.gson.** { *; }
-keep class com.google.android.gms.** { *; }

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
