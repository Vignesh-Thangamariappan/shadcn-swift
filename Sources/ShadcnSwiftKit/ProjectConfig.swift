import Foundation

/// Mirrors shadcn/ui's `components.json` — lives in the CONSUMER project, not this repo.
///
/// `registryPath` is resolved relative to the current working directory at read time
/// (see `AddCommand`), so a relative path (e.g. `../shadcn-swift/registry/registry.json`)
/// works and travels with a cloned project. `init` defaults to whatever path you pass it,
/// though — if that was absolute, the resulting `components.json` is machine-local. See README.
public struct ProjectConfig: Codable {
    public var registryPath: String
    public var destination: String
    public var installed: [String]

    public static let fileName = "components.json"

    public init(registryPath: String, destination: String, installed: [String]) {
        self.registryPath = registryPath
        self.destination = destination
        self.installed = installed
    }

    public static func load(from directory: URL) throws -> ProjectConfig {
        let url = directory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ProjectConfig.self, from: data)
    }

    public func save(to directory: URL) throws {
        let url = directory.appendingPathComponent(Self.fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}
