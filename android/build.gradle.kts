allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // 🛠️ تم إصلاح السطر أدناه ليعمل بدون متغيرات مفقودة أو غير معرّفة
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    project.ext.set("ndkVersion", "25.1.8937393") // إجبار النظام على إصدار مستقر
    
    // منع محرك البحث التلقائي من استدعاء أداة sdkmanager المنهارة بالكمبيوتر
    project.tasks.matching { it.name.contains("sdkmanager") }.configureEach {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
