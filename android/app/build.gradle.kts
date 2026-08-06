plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase: uncomment once android/app/google-services.json is in place
    // (run `flutterfire configure` to generate it).
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.example.apx_task_management"
    compileSdk = flutter.compileSdkVersion

    // Pinned rather than `flutter.ndkVersion`: several Firebase plugins ship
    // native code built against a newer NDK, and Gradle requires the highest
    // one requested by any dependency (NDK releases are backward compatible).
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // Required by flutter_local_notifications, which uses java.time APIs
        // that do not exist on older Android releases.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.apx_task_management"

        // Firebase Messaging requires API 23+; desugaring requires multidex
        // below API 21, which this floor avoids entirely.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Backports java.time (and friends) to older Android versions.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
