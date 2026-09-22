import Foundation

enum CommandRunner {
    static func run(
        executable: URL,
        arguments: [String] = [],
        currentDirectoryURL: URL? = nil
    ) throws {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let command = ([executable.lastPathComponent] + arguments).joined(separator: " ")
            throw NSError(
                domain: "AirCardInjector.CommandRunner",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Command failed (exit \(process.terminationStatus)): \(command)"]
            )
        }
    }
}
