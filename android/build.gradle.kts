allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// flutter_native_splash 2.4.4 hardcodes compileSdkVersion 31 in its own
// android/build.gradle, which is now too low for other plugins' transitive
// deps (they require 33+). Force it up to match the app's compileSdk.
subprojects {
    val fixCompileSdk: (org.gradle.api.Project) -> Unit = { proj ->
        proj.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { android ->
            if (android.compileSdkVersion == "android-31") {
                android.compileSdkVersion(36)
            }
        }
    }
    if (state.executed) {
        fixCompileSdk(this)
    } else {
        afterEvaluate { fixCompileSdk(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
