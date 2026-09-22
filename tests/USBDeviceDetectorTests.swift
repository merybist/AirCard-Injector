import Foundation

private func expect(_ actual: USBConnectionStatus, _ expected: USBConnectionStatus, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

@main
struct USBDeviceDetectorTests {
    static func main() {
        let connectedFixture = """
        {"SPUSBDataType":[{"_name":"USB 3.1 Bus","_items":[{"_name":"USB 2.0 Hub","_items":[{"_name":"Alice’s iPhone"}]}]}]}
        """.data(using: .utf8)!
        expect(USBDeviceDetector.connectionStatus(fromSystemProfilerJSON: connectedFixture), .connected(name: "Alice’s iPhone"), "nested iPhone must be detected")

        let disconnectedFixture = """
        {"SPUSBDataType":[{"_name":"USB 3.1 Bus","_items":[{"_name":"USB Keyboard"}]}]}
        """.data(using: .utf8)!
        expect(USBDeviceDetector.connectionStatus(fromSystemProfilerJSON: disconnectedFixture), .disconnected, "non-iPhone USB devices must not pass the preflight")

        expect(USBDeviceDetector.connectionStatus(fromSystemProfilerJSON: Data("not JSON".utf8)), .unavailable, "invalid profiler output must be reported as unavailable")
        print("USBDeviceDetectorTests: 3 passed")
    }
}
