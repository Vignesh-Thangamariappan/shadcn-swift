import Foundation
import MCP
import ShadcnSwiftKit

/// Read-only MCP server over the shadcn-swift registry.
///
/// Deliberately has no `add_component` / write tool: the point of the vendored
/// model is that a human (or the CLI they typed) reviews what lands in their
/// project, and a component they've hand-edited must not get silently clobbered
/// by an agent's tool call. Writing stays with `shadcn-swift add`, run by hand.

enum ConfigurationError: LocalizedError {
    case missingRegistryPath

    var errorDescription: String? {
        "Couldn't find a bundled registry.json next to this executable, and " +
        "SHADCN_SWIFT_REGISTRY isn't set — point it at the path of registry.json (see README)."
    }
}

struct ComponentSummary: Codable, Sendable {
    let name: String
    let description: String
    let dependencies: [String]
    let platforms: [String]
}

struct ComponentFile: Codable, Sendable {
    let path: String
    let contents: String
}

struct ComponentDetail: Codable, Sendable {
    let name: String
    let dependencies: [String]
    let files: [ComponentFile]
}

struct ResolvedComponent: Codable, Sendable {
    let name: String
    let description: String
}

func jsonText(_ value: some Codable) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    return String(data: data, encoding: .utf8) ?? "{}"
}

func textResult(_ string: String, isError: Bool = false) -> CallTool.Result {
    .init(content: [.text(text: string, annotations: nil, _meta: nil)], isError: isError)
}

@main
struct ShadcnSwiftMCP {
    static func main() async throws {
        let registryURL: URL
        if let registryPath = ProcessInfo.processInfo.environment["SHADCN_SWIFT_REGISTRY"] {
            registryURL = URL(fileURLWithPath: registryPath)
        } else if let found = DefaultRegistryLocation.find() {
            registryURL = found
        } else {
            throw ConfigurationError.missingRegistryPath
        }
        let registry = try Registry.load(from: registryURL)
        let sourcesRoot = registryURL.deletingLastPathComponent().appendingPathComponent("swiftui")

        let readOnly = Tool.Annotations(
            readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false
        )

        let listComponentsTool = Tool(
            name: "list_components",
            description: "List every component in the shadcn-swift registry: name, description, dependencies, and which platforms (swiftui/compose) it's available for.",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])]),
            annotations: readOnly
        )

        let getComponentTool = Tool(
            name: "get_component",
            description: "Return one component's own source file(s) with full contents, for the given platform. Does NOT include dependency files — call resolve_plan first, then get_component once per name in that order.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "name": .object(["type": .string("string"), "description": .string("Component name, e.g. \"card\"")]),
                    "platform": .object(["type": .string("string"), "description": .string("Registry platform key, default \"swiftui\"")])
                ]),
                "required": .array([.string("name")])
            ]),
            annotations: readOnly
        )

        let resolvePlanTool = Tool(
            name: "resolve_plan",
            description: "Resolve one or more component names into the full transitive dependency list, dependencies first, in the order they should be fetched and written.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "names": .object([
                        "type": .string("array"),
                        "items": .object(["type": .string("string")]),
                        "description": .string("Component names to resolve, e.g. [\"card\"]")
                    ])
                ]),
                "required": .array([.string("names")])
            ]),
            annotations: readOnly
        )

        let server = Server(
            name: "shadcn-swift",
            version: "0.1.0",
            capabilities: .init(tools: .init(listChanged: false))
        )

        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: [listComponentsTool, getComponentTool, resolvePlanTool])
        }

        await server.withMethodHandler(CallTool.self) { params in
            do {
                switch params.name {
                case "list_components":
                    let summaries = registry.components.map { component in
                        ComponentSummary(
                            name: component.name,
                            description: component.description,
                            dependencies: component.dependencies,
                            platforms: [
                                component.platforms.swiftui != nil ? "swiftui" : nil,
                                component.platforms.compose != nil ? "compose" : nil
                            ].compactMap { $0 }
                        )
                    }
                    return textResult(try jsonText(summaries))

                case "get_component":
                    guard let name = params.arguments?["name"]?.stringValue else {
                        return textResult("Missing required \"name\" argument", isError: true)
                    }
                    let platform = params.arguments?["platform"]?.stringValue ?? "swiftui"
                    guard let component = registry.component(named: name) else {
                        return textResult("Unknown component \"\(name)\"", isError: true)
                    }
                    guard platform == "swiftui", let target = component.platforms.swiftui else {
                        return textResult("No \"\(platform)\" target for component \"\(name)\"", isError: true)
                    }

                    let componentDir = sourcesRoot.appendingPathComponent(component.name)
                    let files = try target.files.map { file -> ComponentFile in
                        let fileURL = componentDir.appendingPathComponent(file)
                        let contents = try String(contentsOf: fileURL, encoding: .utf8)
                        return ComponentFile(path: "\(component.name)/\(file)", contents: contents)
                    }
                    let detail = ComponentDetail(name: component.name, dependencies: component.dependencies, files: files)
                    return textResult(try jsonText(detail))

                case "resolve_plan":
                    guard let namesValue = params.arguments?["names"] else {
                        return textResult("Missing required \"names\" argument", isError: true)
                    }
                    let names: [String]
                    switch namesValue {
                    case .array(let values):
                        names = values.compactMap(\.stringValue)
                    case .string(let single):
                        names = [single]
                    default:
                        return textResult("\"names\" must be an array of strings", isError: true)
                    }

                    let resolved = try registry.resolve(names)
                    let payload = resolved.map { ResolvedComponent(name: $0.name, description: $0.description) }
                    return textResult(try jsonText(payload))

                default:
                    return textResult("Unknown tool \"\(params.name)\"", isError: true)
                }
            } catch {
                return textResult("Error: \(error.localizedDescription)", isError: true)
            }
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}
