import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing config from android/key.properties if present.
// Generate with: keytool -genkey -v -keystore brolly-release.jks -keyalg RSA \
//                       -keysize 2048 -validity 10000 -alias brolly
// Then create android/key.properties with: storeFile, storePassword, keyAlias, keyPassword.
// key.properties is gitignored — never commit it.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.brolly.brolly"
    // compileSdk = 36 satisfies the plugins that now require it
    // (google_mobile_ads, geolocator, shared_preferences, sqflite, etc.).
    // targetSdk stays at 35 to match the current Play Store requirement.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.brolly.brolly"
        // google_mobile_ads requires minSdk 23.
        minSdk = flutter.minSdkVersion
        // Play Store requires targetSdk 35 as of late 2025.
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Fall back to debug signing so `flutter run --release` still works
                // locally. The Play Store will reject debug-signed builds.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
