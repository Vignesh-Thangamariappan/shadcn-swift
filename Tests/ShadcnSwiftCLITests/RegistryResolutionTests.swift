import XCTest
@testable import ShadcnSwiftCLI

final class RegistryResolutionTests: XCTestCase {
    private func makeRegistry() -> Registry {
        let json = """
        {
          "version": 1,
          "components": [
            { "name": "tokens", "description": "d", "dependencies": [],
              "platforms": { "swiftui": { "files": ["Theme.swift"] } } },
            { "name": "button", "description": "d", "dependencies": ["tokens"],
              "platforms": { "swiftui": { "files": ["Button.swift"] } } },
            { "name": "card", "description": "d", "dependencies": ["tokens", "button"],
              "platforms": { "swiftui": { "files": ["Card.swift"] } } }
          ]
        }
        """
        return try! JSONDecoder().decode(Registry.self, from: Data(json.utf8))
    }

    func testAddingCardPullsTransitiveDependenciesDependenciesFirst() throws {
        let resolved = try makeRegistry().resolve(["card"])
        XCTAssertEqual(resolved.map(\.name), ["tokens", "button", "card"])
    }

    func testResolvingAlreadySatisfiedDependencyDoesNotDuplicate() throws {
        let resolved = try makeRegistry().resolve(["button", "card"])
        XCTAssertEqual(resolved.map(\.name), ["tokens", "button", "card"])
    }

    func testUnknownComponentThrows() {
        XCTAssertThrowsError(try makeRegistry().resolve(["nonexistent"]))
    }
}
