import ArgumentParser
import Foundation
import ShadcnSwiftKit

struct AddCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Vendor a component (and its dependencies) into this project."
    )

    @Argument(help: "Component names, e.g. `card button`.")
    var components: [String]

    @Flag(name: .long, help: "Re-copy and overwrite even if already installed.")
    var force: Bool = false

    func run() throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var config = try ProjectConfig.load(from: cwd)

        let registryURL = URL(fileURLWithPath: config.registryPath, relativeTo: cwd)
        let registry = try Registry.load(from: registryURL)
        let sourcesRoot = registryURL.deletingLastPathComponent().appendingPathComponent("swiftui")
        let destinationRoot = cwd.appendingPathComponent(config.destination)

        let resolved = try registry.resolve(components)
        var newlyInstalled: [String] = []

        for component in resolved {
            let alreadyInstalled = config.installed.contains(component.name)
            if alreadyInstalled && !force {
                print("skip   \(component.name) (already installed, use --force to re-copy)")
                continue
            }
            guard let target = component.platforms.swiftui else {
                print("skip   \(component.name) (no swiftui platform target)")
                continue
            }

            let componentSourceDir = sourcesRoot.appendingPathComponent(component.name)
            let componentDestDir = destinationRoot.appendingPathComponent(component.name)
            try FileManager.default.createDirectory(at: componentDestDir, withIntermediateDirectories: true)

            for file in target.files {
                let from = componentSourceDir.appendingPathComponent(file)
                let to = componentDestDir.appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: to.path) {
                    try FileManager.default.removeItem(at: to)
                }
                try FileManager.default.copyItem(at: from, to: to)
            }

            print("\(alreadyInstalled ? "update" : "add   ") \(component.name)  -> \(config.destination)/\(component.name)/")
            if !alreadyInstalled {
                newlyInstalled.append(component.name)
            }
        }

        if !newlyInstalled.isEmpty {
            config.installed.append(contentsOf: newlyInstalled)
            try config.save(to: cwd)
        }
    }
}
