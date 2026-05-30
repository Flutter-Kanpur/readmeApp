import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingProperty(
    codemagicEnv: String,
    keyPropertiesKey: String,
): String? {
    return System.getenv(codemagicEnv)
        ?: keystoreProperties.getProperty(keyPropertiesKey)
}

android {
    namespace = "com.flutterkanpur.readme"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH")
            val propertiesStoreFile = keystoreProperties.getProperty("storeFile")

            val resolvedStoreFile = when {
                !cmKeystorePath.isNullOrBlank() -> file(cmKeystorePath)
                !propertiesStoreFile.isNullOrBlank() -> rootProject.file(propertiesStoreFile)
                else -> null
            }

            if (resolvedStoreFile != null) {
                storeFile = resolvedStoreFile
                storePassword = signingProperty("CM_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingProperty("CM_KEY_ALIAS", "keyAlias")
                keyPassword = signingProperty("CM_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.flutterkanpur.readme"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val releaseSigning = signingConfigs.getByName("release")
            signingConfig = releaseSigning.takeIf { it.storeFile?.exists() == true }
                ?: error(
                    """
                    Release signing is not configured.
                    - Local: create android/key.properties (see key.properties.example)
                    - Codemagic: enable Android code signing in app settings
                    """.trimIndent(),
                )
        }
    }
}

flutter {
    source = "../.."
}
