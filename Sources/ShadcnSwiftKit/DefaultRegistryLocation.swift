import Foundation

/// Where the CLI and MCP server look for `registry.json` when the caller
/// doesn't pass one explicitly — the thing that lets `shadcn-swift init`
/// and an MCP registration work with zero required flags, the same way
/// `npx shadcn init` needs no `--registry` for its own default registry.
///
/// Checked in order, first existing path wins:
/// 1. `registry/registry.json` next to the running executable — the
///    release tarball's own layout (binaries and `registry/` side by side).
/// 2. `../share/shadcn-swift/registry/registry.json` relative to the
///    executable — a Homebrew-style `<prefix>/bin/<exe>` install layout,
///    ready for if/when this ships as a formula.
/// 3. `registry/registry.json` at the repo root, found by walking up from
///    a `swift run`/`swift build` debug executable
///    (`.build/<triple>/debug/<exe>`) — so a from-source dev workflow
///    inside a clone of this repo also needs no flags.
///
/// Returns `nil` if none exist, so callers fall back to requiring an
/// explicit `--registry` / `SHADCN_SWIFT_REGISTRY` and can say so in their
/// own error message.
public enum DefaultRegistryLocation {
    public static func find(executableURL: URL? = Bundle.main.executableURL) -> URL? {
        guard let executableURL else { return nil }
        let executableDir = executableURL.resolvingSymlinksInPath().deletingLastPathComponent()

        let candidates = [
            executableDir.appendingPathComponent("registry/registry.json"),
            executableDir.deletingLastPathComponent()
                .appendingPathComponent("share/shadcn-swift/registry/registry.json"),
            executableDir.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("registry/registry.json")
        ]

        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
