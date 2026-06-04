allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Paksa seluruh subproject (termasuk home_widget) menggunakan glance versi stabil
    // agar tidak butuh compileSdk 37+ yang dibawa oleh glance-appwidget:1.3.0-alpha01
    configurations.all {
        resolutionStrategy {
            force("androidx.glance:glance:1.1.0")
            force("androidx.glance:glance-appwidget:1.1.0")
            force("androidx.glance:glance-material:1.1.0")
            force("androidx.glance:glance-material3:1.1.0")
        }
        // Exclude remote-creation-android yang merupakan transitive dep dari glance alpha
        exclude(group = "androidx.compose.remote", module = "remote-creation-android")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "11"
        targetCompatibility = "11"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
