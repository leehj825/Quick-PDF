import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. CI passes the secrets as environment variables (nothing is written to disk
// except the keystore file); locally you can use android/key.properties (git-ignored) instead.
// Without either, release builds fall back to the debug key so `flutter run --release` still works.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signingValue(env: String, prop: String): String? =
    System.getenv(env)?.takeIf { it.isNotBlank() } ?: keyProps.getProperty(prop)
val releaseStoreFile = signingValue("KEYSTORE_PATH", "storeFile")
val releaseStorePassword = signingValue("KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = signingValue("KEY_ALIAS", "keyAlias")
val releaseKeyPassword = signingValue("KEY_PASSWORD", "keyPassword")
val canSignRelease = releaseStoreFile != null && releaseStorePassword != null &&
    releaseKeyAlias != null && releaseKeyPassword != null

android {
    namespace = "app.quickpdf.quick_pdf"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.quickpdf.quick_pdf"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 24) // ML Kit scanner / AdMob
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // ARM only (no emulator x86): third-party AARs (ML Kit) ship x86_64 libs that
        // --target-platform does not strip.
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") }
    }

    packaging {
        jniLibs {
            excludes += setOf("lib/x86_64/**", "lib/x86/**") // no-emulator-libs (ARM-only APK)
        }
    }

    signingConfigs {
        if (canSignRelease) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            // Never use the real ad ids while developing/testing: clicking your own ads can get the
            // AdMob account limited for invalid traffic.
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713" // Google test app id
        }
        release {
            manifestPlaceholders["admobAppId"] = "ca-app-pub-4400173019354346~2281968732" // Quick PDF
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (canSignRelease) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
