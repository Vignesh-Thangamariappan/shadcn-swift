import Foundation

public struct Registry: Codable, Sendable {
    public struct Component: Codable, Sendable {
        public struct Platforms: Codable, Sendable {
            public struct Target: Codable, Sendable {
                public let files: [String]
            }
            public let swiftui: Target?
            public let compose: Target?
        }

        public let name: String
        public let description: String
        public let dependencies: [String]
        public let platforms: Platforms
    }

    public let version: Int
    public let components: [Component]

    public init(version: Int, components: [Component]) {
        self.version = version
        self.components = components
    }

    public func component(named name: String) -> Component? {
        components.first { $0.name == name }
    }

    /// Resolves a component and every transitive dependency, dependencies first,
    /// so `add card` also emits `tokens` and `button` in an install-safe order.
    public func resolve(_ names: [String]) throws -> [Component] {
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

    public static func load(from url: URL) throws -> Registry {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Registry.self, from: data)
    }
}

public enum RegistryError: LocalizedError {
    case unknownComponent(String)

    public var errorDescription: String? {
        switch self {
        case .unknownComponent(let name):
            "Unknown component \"\(name)\" — run `shadcn-swift list` to see what's available."
        }
    }
}
