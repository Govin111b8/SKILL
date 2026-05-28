plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.skillconnect.skillconnect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            // Read from environment variables (CI/CD) or local.properties (local dev)
            val keystoreFile = System.getenv("KEYSTORE_PATH") ?: project.findProperty("keystorePath")?.toString()
            val keystorePass = System.getenv("STORE_PASSWORD") ?: project.findProperty("storePassword")?.toString()
            val keyAlias = System.getenv("KEY_ALIAS") ?: project.findProperty("keyAlias")?.toString()
            val keyPass = System.getenv("KEY_PASSWORD") ?: project.findProperty("keyPassword")?.toString()
            if (keystoreFile != null && keystorePass != null && keyAlias != null && keyPass != null) {
                storeFile = file(keystoreFile)
                storePassword = keystorePass
                this.keyAlias = keyAlias
                keyPassword = keyPass
            }
        }
    }

    defaultConfig {
        applicationId = "com.skillconnect.app"
        minSdk = 21  // Required by FCM, geolocator, speech_to_text
        targetSdk = 35 // Android 15
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Build-time environment config — injected via --dart-define
        resValue("string", "app_env", System.getenv("APP_ENV") ?: "dev")
    }

    // Phase 1: App size optimization — Split APKs per ABI
    splits {
        abi {
            isEnabled = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = false
        }
    }

    // Phase 4: Lite version — Product flavors for rural markets
    flavorDimensions += "version"
    productFlavors {
        create("full") {
            dimension = "version"
            applicationIdSuffix = ""
            versionNameSuffix = ""
        }
        create("lite") {
            dimension = "version"
            applicationIdSuffix = ".lite"
            versionNameSuffix = "-lite"
            // Lite version targets smaller APK < 15MB
            // Strips heavy features: chat media, portfolio, large assets
        }
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = if (releaseSigning.storeFile != null) releaseSigning else signingConfigs.getByName("debug")
            // Enable code shrinking and resource shrinking for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
