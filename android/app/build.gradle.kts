import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
// Llave de firma para Google Play (upload key). En Codemagic: Android code
// signing → se exportan CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD, CM_KEY_ALIAS y
// CM_KEY_PASSWORD. En un PC: android/key.properties (no se sube a git).
// Sin llave, el release se firma con la de prueba (sirve para el APK del
// portal, pero Google Play lo rechaza).
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}
val llaveRuta = System.getenv("CM_KEYSTORE_PATH") ?: keyProps.getProperty("storeFile")
val hayLlave = !llaveRuta.isNullOrBlank()

android {
    namespace = "health.hypokratia.app"
    compileSdk = 36   // Google Play exige apuntar a Android 16 (API 36) desde agosto 2026
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requerido por flutter_local_notifications — sin esto, Gradle
        // falla con "Dependency ':flutter_local_notifications' requires
        // core library desugaring to be enabled for :app."
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "health.hypokratia.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayLlave) {
            create("release") {
                storeFile = file(llaveRuta!!)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: keyProps.getProperty("storePassword")
                keyAlias = System.getenv("CM_KEY_ALIAS") ?: keyProps.getProperty("keyAlias")
                keyPassword = System.getenv("CM_KEY_PASSWORD") ?: keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hayLlave) "release" else "debug")
        }
    }
}

dependencies {
    // Requerido junto con isCoreLibraryDesugaringEnabled — provee las
    // APIs de java.time/java.util necesarias en versiones de Android
    // anteriores a la 26, que flutter_local_notifications usa.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
