plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.toolshub.toolshub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // No applicationId here on purpose: each brand flavour sets its
        // own, so a build that somehow selects no flavour fails loudly
        // instead of shipping under the wrong id.
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // One dimension: brand. Environment (which backend) is a --dart-define,
    // not a flavour, because `flutter build web` has no --flavor flag at all
    // - an environment expressed as a Gradle flavour would be unreachable on
    // the web target.
    //
    // `namespace` above deliberately stays com.toolshub.toolshub: it has to
    // match the Kotlin package of MainActivity, and AGP has no per-flavour
    // namespace. Only applicationId varies, which is what the Play Store and
    // the launcher actually see.
    flavorDimensions += "brand"

    productFlavors {
        create("apexdeals") {
            dimension = "brand"
            applicationId = "com.apexdeals.app"
        }
        create("toolshub") {
            dimension = "brand"
            applicationId = "com.toolshub.app"
        }
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
