import ArgumentParser
import Foundation
import ShadcnSwiftKit

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List components available in a registry."
    )

    @Option(name: .long, help: "Path to registry.json. Defaults to the copy bundled next to this executable.")
    var registry: String?

    func run() throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let registryURL: URL
        if let registry {
            registryURL = URL(fileURLWithPath: registry, relativeTo: cwd)
        } else if let found = DefaultRegistryLocation.find() {
            registryURL = found
        } else {
            throw ValidationError(
                "Couldn't find a bundled registry.json next to this executable — pass --registry explicitly."
            )
        }

        let reg = try Registry.load(from: registryURL)

        for component in reg.components {
            let deps = component.dependencies.isEmpty ? "" : "  (needs: \(component.dependencies.joined(separator: ", ")))"
            print("\(component.name)\(deps)")
            print("  \(component.description)")
        }
    }
}
