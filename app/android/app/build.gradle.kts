import java.util.Properties
import java.io.FileInputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

plugins {
  id("com.android.application")
  id("com.google.gms.google-services")
  id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
  keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
var dateFormat = LocalDateTime.now().format(formatter)

base {
  archivesName = "skyfrog-" + "Dev-" + "${flutter.versionName}" + "-build-${flutter.versionCode}-" + "${dateFormat}"
}

android {

  namespace = "com.example.skyfrog"

  compileSdk = 37
  ndkVersion = flutter.ndkVersion

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  defaultConfig {
    applicationId = "com.example.skyfrog"
    minSdk = flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
  }

  signingConfigs {
    create("release") {
      keyAlias = keystoreProperties["keyAlias"] as String
      keyPassword = keystoreProperties["keyPassword"] as String
      storeFile = keystoreProperties["storeFile"]?.let { file(it) }
      storePassword = keystoreProperties["storePassword"] as String
    }
  }

  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("release")
    }
    debug {
      signingConfig = signingConfigs.getByName("debug")
    }
  }

}

dependencies {
  implementation("androidx.window:window:1.0.0")
  implementation("androidx.window:window-java:1.0.0")
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