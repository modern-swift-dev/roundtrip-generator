import Foundation
import KotlinAndroidApiGenerator
import KotlinApiGenerator
import KotlinSpringBootGenerator
import OpenApiYamlGenerator
import SwiftApiGenerator
import SwiftVaporGenerator
import TypeScriptApiGenerator

func main() {
    do {
        if CommandLine.arguments.contains("--android-only") {
            try KotlinAndroidApiPackageGenerator(
                package: .globalAndroid,
                options: KotlinAndroidGeneratorOptions(generateKoinModule: true, generateMocks: true),
            ).write()
            print("Success!")
            return
        }
        try ApiPackageGenerator(package: .global).write()
        try KotlinApiPackageGenerator(package: .globalKotlin).write()
        try KotlinAndroidApiPackageGenerator(
            package: .globalAndroid,
            options: KotlinAndroidGeneratorOptions(generateKoinModule: true, generateMocks: true),
        ).write()
        try KotlinSpringBootApiPackageGenerator(package: .globalSpring).write()
        try TypeScriptApiPackageGenerator(
            package: .globalTypeScript,
            options: TypeScriptGeneratorOptions(flavor: .tanStackQuery),
        ).write()
        try OpenApiYamlPackageGenerator(package: .globalOpenApi).write()
        try SwiftVaporApiPackageGenerator(
            package: .globalVapor,
            options: SwiftVaporGeneratorOptions(),
        ).write()
        print("Success!")
        exit(0)
    } catch {
        print(error.localizedDescription)
        exit(1)
    }

    // Let the executable live until we call exit()
    // to allow async http calls
    RunLoop.main.run()
}

// Execute main function
main()
