import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Klucz Google Maps NIE jest w repo. Źródła (pierwsze niepuste):
//   1) zmienna środowiskowa MAPS_API_KEY (CI: GitHub Secret)
//   2) android/local.properties → MAPS_API_KEY=... (lokalnie, plik w .gitignore)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val mapsApiKey: String = (System.getenv("MAPS_API_KEY")
    ?: localProperties.getProperty("MAPS_API_KEY")
    ?: "").trim()

android {
    namespace = "pl.u235.alertmap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "pl.u235.alertmap"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Jeśli key.properties istnieje i storeFile jest prawidłowy → użyj release signing,
            // inaczej fallback na debug (tylko dla dev builds).
            signingConfig = if (keystorePropertiesFile.exists() && signingConfigs.getByName("release").storeFile?.exists() == true) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Wydanie bez klucza Map = pusta mapa u użytkowników, więc release bez klucza przerywamy.
// Buildy debug (np. CI) przechodzą — mapa po prostu się nie załaduje.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { it.project == project && it.name.contains("Release") && (it.name.startsWith("assemble") || it.name.startsWith("bundle")) }
    if (buildingRelease && mapsApiKey.isEmpty()) {
        throw GradleException("Brak MAPS_API_KEY: dodaj MAPS_API_KEY=... do android/local.properties albo ustaw zmienną środowiskową MAPS_API_KEY.")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    androidTestUtil("androidx.test:orchestrator:1.4.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
}
