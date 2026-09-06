import Foundation

/// Mirrors shadcn/ui's `components.json` — lives in the CONSUMER project, not this repo.
struct ProjectConfig: Codable {
    var registryPath: String
    var destination: String
    var installed: [String]

    static let fileName = "components.json"

    static func load(from directory: URL) throws -> ProjectConfig {
        let url = directory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ProjectConfig.self, from: data)
    }

    func save(to directory: URL) throws {
        let url = directory.appendingPathComponent(Self.fileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}
