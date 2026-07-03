# ProGuard / R8 rules for release builds.
#
# Flutter's release build enables R8 minification by default. Without these
# keep rules, R8 strips ML Kit component registrar classes (referenced only
# via reflection by ComponentDiscovery), causing the scanner to fail with
# NoSuchMethodException at runtime.

# ── Google ML Kit (mobile_scanner dependency) ──
# ML Kit discovers its component registrars via reflection. These classes
# have no static references, so R8 strips them without these rules.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-keep class com.google.android.gms.vision.** { *; }

# ComponentDiscovery loads registrars by reflection via ServiceLoader.
# Keep the no-arg constructor that ComponentDiscovery looks for.
-keepclassmembers class com.google.mlkit.common.sdk.ComponentRegistrar {
    public <init>();
}
-keep class * extends com.google.mlkit.common.sdk.ComponentRegistrar { *; }

# ── mobile_scanner ──
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.mlkit.vision.interfaces.** { *; }

# ── audioplayers ──
-keep class xyz.luan.audioplayers.** { *; }

# ── vibration ──
-keep class com.devs.vibration.** { *; }
