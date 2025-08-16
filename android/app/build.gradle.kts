plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace = "com.example.flutter_todo_app"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.flutter_todo_app"
        minSdk = 24
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        // Support pour les notifications locales
        manifestPlaceholders += [
            'appAuthRedirectScheme': 'com.example.flutter_todo_app'
        ]
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    buildFeatures {
        buildConfig = true
    }

    packagingOptions {
        resources {
            excludes += [
                '/META-INF/{AL2.0,LGPL2.1}',
                '/META-INF/DEPENDENCIES',
                '/META-INF/LICENSE',
                '/META-INF/LICENSE.txt',
                '/META-INF/license.txt',
                '/META-INF/NOTICE',
                '/META-INF/NOTICE.txt',
                '/META-INF/notice.txt',
                '/META-INF/ASL2.0'
            ]
        }
    }

    lint {
        disable += ["InvalidPackage"]
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // Support pour les notifications
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
