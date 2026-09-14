import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // must be last
}

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties().apply {
    if (releaseSigningPropertiesFile.isFile) {
        releaseSigningPropertiesFile.inputStream().use(::load)
    }
}
val releaseSigningPropertyNames = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val releaseSigningValues = releaseSigningPropertyNames.associateWith {
    releaseSigningProperties.getProperty(it)?.trim().orEmpty()
}

val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    group = "verification"
    description = "Validates the local signing configuration required for release builds."

    doLast {
        val missingProperties = releaseSigningValues.filterValues { it.isBlank() }.keys
        check(missingProperties.isEmpty()) {
            "Release signing requires ${releaseSigningPropertiesFile.path} with: " +
                releaseSigningPropertyNames.joinToString(", ") +
                ". Missing: ${missingProperties.joinToString(", ")}."
        }

        check(file(releaseSigningValues.getValue("storeFile")).isFile) {
            "Release signing keystore does not exist: ${releaseSigningValues.getValue("storeFile")}."
        }
    }
}

tasks.configureEach {
    if (name.matches(Regex("^(assemble|bundle|package|sign|install|validateSigning).*Release.*"))) {
        dependsOn(validateReleaseSigning)
    }
}

android {
    namespace = "com.hexora.hexora"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.hexora.hexora.app" // Play Store identity
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseSigningValues.values.all { it.isNotBlank() }) {
                storeFile = file(releaseSigningValues.getValue("storeFile"))
                storePassword = releaseSigningValues.getValue("storePassword")
                keyAlias = releaseSigningValues.getValue("keyAlias")
                keyPassword = releaseSigningValues.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // minifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
