allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom build directory using String paths for compatibility
val newBuildDir = rootDir.resolve("../build").canonicalFile
buildDir = newBuildDir

subprojects {
    buildDir = newBuildDir.resolve(project.name)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
