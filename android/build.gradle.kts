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
// Plugins que todavía compilan contra Android 33 (p. ej. flutter_blue_plus)
// fallan con las librerías androidx actuales, que exigen 34 o más. Se fuerza
// el mismo compileSdk de la app (36) a todos los módulos de librería.
subprojects {
    val fijarCompileSdk = { p: Project ->
        val android = p.extensions.findByName("android")
        if (android != null && p.name != "app") {
            try {
                android.javaClass.getMethod("setCompileSdk", Integer::class.java).invoke(android, 36)
            } catch (e: Exception) {
                try {
                    android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType).invoke(android, 36)
                } catch (_: Exception) {}
            }
        }
    }
    if (state.executed) fijarCompileSdk(this) else afterEvaluate { fijarCompileSdk(this) }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
