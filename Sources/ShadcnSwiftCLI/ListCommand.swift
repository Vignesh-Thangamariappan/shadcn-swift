import ArgumentParser
import Foundation
import ShadcnSwiftKit

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List components available in a registry."
    )

    @Option(name: .long, help: "Path to registry.json.")
    var registry: String

    func run() throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let registryURL = URL(fileURLWithPath: registry, relativeTo: cwd)
        let reg = try Registry.load(from: registryURL)

        for component in reg.components {
            let deps = component.dependencies.isEmpty ? "" : "  (needs: \(component.dependencies.joined(separator: ", ")))"
            print("\(component.name)\(deps)")
            print("  \(component.description)")
        }
    }
}
