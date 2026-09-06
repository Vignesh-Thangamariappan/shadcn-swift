import Foundation

struct Registry: Codable {
    struct Component: Codable {
        struct Platforms: Codable {
            struct Target: Codable {
                let files: [String]
            }
            let swiftui: Target?
            let compose: Target?
        }

        let name: String
        let description: String
        let dependencies: [String]
        let platforms: Platforms
    }

    let version: Int
    let components: [Component]

    func component(named name: String) -> Component? {
        components.first { $0.name == name }
    }

    /// Resolves a component and every transitive dependency, dependencies first,
    /// so `add card` also emits `tokens` and `button` in an install-safe order.
    func resolve(_ names: [String]) throws -> [Component] {
        var seen = Set<String>()
        var ordered: [Component] = []

        func visit(_ name: String) throws {
            guard !seen.contains(name) else { return }
            guard let component = component(named: name) else {
                throw RegistryError.unknownComponent(name)
            }
            seen.insert(name)
            for dependency in component.dependencies {
                try visit(dependency)
            }
            ordered.append(component)
        }

        for name in names {
            try visit(name)
        }
        return ordered
    }

    static func load(from url: URL) throws -> Registry {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Registry.self, from: data)
    }
}

enum RegistryError: LocalizedError {
    case unknownComponent(String)

    var errorDescription: String? {
        switch self {
        case .unknownComponent(let name):
            "Unknown component \"\(name)\" — run `shadcn-swift list` to see what's available."
        }
    }
}
