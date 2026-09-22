import Foundation

private func expectSuccess(_ executable: String) {
    do {
        try CommandRunner.run(executable: URL(fileURLWithPath: executable))
    } catch {
        fatalError("Expected \(executable) to succeed, got \(error)")
    }
}

private func expectFailure(_ executable: String) {
    do {
        try CommandRunner.run(executable: URL(fileURLWithPath: executable))
        fatalError("Expected \(executable) to throw for a non-zero exit status")
    } catch {
        print("Expected failure: \(error.localizedDescription)")
    }
}

@main
struct CommandRunnerTests {
    static func main() {
        expectSuccess("/usr/bin/true")
        expectFailure("/usr/bin/false")
        print("CommandRunnerTests: 2 passed")
    }
}
