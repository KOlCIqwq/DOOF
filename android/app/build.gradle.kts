plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // This is the correct NDK version required by your plugins.
    ndkVersion = "27.0.12077973"
    namespace = "com.example.food"
    compileSdk = 35

    compileOptions {
        // Changed to VERSION_1_8 to match default Flutter project settings.
        // You can use VERSION_11 if needed, but 1.8 is more common and safer.
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.food"
        // Let Flutter control these values.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ZXing for barcode scanning
    implementation("com.google.zxing:core:3.5.3")
}