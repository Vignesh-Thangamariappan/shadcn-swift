import ArgumentParser
import Foundation

struct InitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create components.json in the current directory."
    )

    @Option(name: .long, help: "Path to this registry's registry.json (local path for now).")
    var registry: String

    @Option(name: .long, help: "Directory (relative to cwd) components get copied into.")
    var destination: String = "Sources/UI"

    func run() throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let configURL = cwd.appendingPathComponent(ProjectConfig.fileName)

        guard !FileManager.default.fileExists(atPath: configURL.path) else {
            throw ValidationError("\(ProjectConfig.fileName) already exists here.")
        }

        let config = ProjectConfig(registryPath: registry, destination: destination, installed: [])
        try config.save(to: cwd)
        try FileManager.default.createDirectory(
            at: cwd.appendingPathComponent(destination),
            withIntermediateDirectories: true
        )

        print("Wrote \(ProjectConfig.fileName). Destination: \(destination)")
        print("Components land under the `UI` namespace (UI.Button, UI.Card, ...) — see README for why.")
    }
}
