import XCTest
@testable import ShadcnSwiftKit

final class DefaultRegistryLocationTests: XCTestCase {
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("shadcn-swift-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    func testFindsReleaseTarballLayout() throws {
        // <root>/bin/shadcn-swift, <root>/registry/registry.json — same directory.
        let root = try makeTempDir()
        let registryDir = root.appendingPathComponent("registry")
        try FileManager.default.createDirectory(at: registryDir, withIntermediateDirectories: true)
        try "{}".write(to: registryDir.appendingPathComponent("registry.json"), atomically: true, encoding: .utf8)

        let executable = root.appendingPathComponent("shadcn-swift")
        let found = DefaultRegistryLocation.find(executableURL: executable)

        XCTAssertEqual(found?.path, registryDir.appendingPathComponent("registry.json").path)
    }

    func testFindsHomebrewStyleLayout() throws {
        // <prefix>/bin/shadcn-swift, <prefix>/share/shadcn-swift/registry/registry.json
        let prefix = try makeTempDir()
        let shareDir = prefix.appendingPathComponent("share/shadcn-swift/registry")
        try FileManager.default.createDirectory(at: shareDir, withIntermediateDirectories: true)
        try "{}".write(to: shareDir.appendingPathComponent("registry.json"), atomically: true, encoding: .utf8)

        let executable = prefix.appendingPathComponent("bin/shadcn-swift")
        let found = DefaultRegistryLocation.find(executableURL: executable)

        XCTAssertEqual(found?.path, shareDir.appendingPathComponent("registry.json").path)
    }

    func testFindsRepoRootFromDebugBuildLayout() throws {
        // <repo>/.build/<triple>/debug/shadcn-swift, <repo>/registry/registry.json
        let repo = try makeTempDir()
        let registryDir = repo.appendingPathComponent("registry")
        try FileManager.default.createDirectory(at: registryDir, withIntermediateDirectories: true)
        try "{}".write(to: registryDir.appendingPathComponent("registry.json"), atomically: true, encoding: .utf8)

        let executable = repo.appendingPathComponent(".build/arm64-apple-macosx/debug/shadcn-swift")
        let found = DefaultRegistryLocation.find(executableURL: executable)

        XCTAssertEqual(found?.path, registryDir.appendingPathComponent("registry.json").path)
    }

    func testReturnsNilWhenNoLayoutMatches() throws {
        let empty = try makeTempDir()
        let executable = empty.appendingPathComponent("shadcn-swift")

        XCTAssertNil(DefaultRegistryLocation.find(executableURL: executable))
    }

    func testReleaseLayoutTakesPrecedenceOverHomebrewLayout() throws {
        // If both a sibling registry/ AND a Homebrew share/ layout somehow
        // exist, the sibling one (checked first) wins.
        let root = try makeTempDir()
        let siblingRegistryDir = root.appendingPathComponent("registry")
        try FileManager.default.createDirectory(at: siblingRegistryDir, withIntermediateDirectories: true)
        try "{}".write(to: siblingRegistryDir.appendingPathComponent("registry.json"), atomically: true, encoding: .utf8)

        let shareDir = root.appendingPathComponent("share/shadcn-swift/registry")
        try FileManager.default.createDirectory(at: shareDir, withIntermediateDirectories: true)
        try "{}".write(to: shareDir.appendingPathComponent("registry.json"), atomically: true, encoding: .utf8)

        let executable = root.appendingPathComponent("shadcn-swift")
        let found = DefaultRegistryLocation.find(executableURL: executable)

        XCTAssertEqual(found?.path, siblingRegistryDir.appendingPathComponent("registry.json").path)
    }
}
