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

// camera_android_camerax 0.6.x compiles against CameraX 1.5.3, whose POM keeps
// androidx.concurrent:concurrent-futures off the compile classpath. Gradle 9
// then fails with "class file for CallbackToFutureAdapter not found".
// Declaring it explicitly for that plugin module fixes the build.
// Remove once `camera` is upgraded to a version that declares it itself.
subprojects {
    if (name == "camera_android_camerax") {
        afterEvaluate {
            dependencies {
                add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
            }
        }
    }
}

// tflite_flutter 0.12.x compiles its Java at target 11 but leaves the Kotlin
// target unset, so Kotlin defaults to the JDK Gradle runs on (25 here) and the
// JVM-target validation fails. Pin Kotlin to 11 for that plugin only.
// Reflection is used because the Kotlin Gradle Plugin classes are not on this
// root script's classpath.
subprojects {
    if (name == "tflite_flutter") {
        afterEvaluate {
            tasks.configureEach {
                if (javaClass.name.startsWith("org.jetbrains.kotlin.gradle.tasks.KotlinCompile")) {
                    val options = javaClass.getMethod("getCompilerOptions").invoke(this)
                    @Suppress("UNCHECKED_CAST")
                    val jvmTarget = options.javaClass.getMethod("getJvmTarget").invoke(options)
                        as org.gradle.api.provider.Property<Any>
                    val targetEnum = Class.forName(
                        "org.jetbrains.kotlin.gradle.dsl.JvmTarget",
                        true,
                        options.javaClass.classLoader,
                    )
                    jvmTarget.set(targetEnum.enumConstants.first { (it as Enum<*>).name == "JVM_11" })
                }
            }
        }
    }
}

// vibration 2.x is compiled against android-33, but the AndroidX libraries it
// pulls in require compileSdk >= 34 (checkDebugAarMetadata fails otherwise).
// Raise it for that plugin only; remove after upgrading `vibration`.
subprojects {
    if (name == "vibration") {
        afterEvaluate {
            extensions.getByName("android").withGroovyBuilder {
                "compileSdkVersion"(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
