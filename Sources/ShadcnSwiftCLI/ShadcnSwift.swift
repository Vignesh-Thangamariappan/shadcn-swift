import ArgumentParser

@main
struct ShadcnSwift: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shadcn-swift",
        abstract: "shadcn/ui's copy-the-code model, for SwiftUI.",
        subcommands: [InitCommand.self, AddCommand.self, ListCommand.self]
    )
}
