import Foundation

enum USBConnectionStatus: Equatable {
    case checking
    case connected(name: String)
    case disconnected
    case unavailable

    var title: String {
        switch self {
        case .checking:
            return "Checking USB connection…"
        case let .connected(name):
            return "iPhone connected via USB: \(name)"
        case .disconnected:
            return "No iPhone detected via USB"
        case .unavailable:
            return "Could not check the USB connection"
        }
    }

    var symbolName: String {
        switch self {
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .connected:
            return "cable.connector.horizontal"
        case .disconnected:
            return "cable.connector.slash"
        case .unavailable:
            return "exclamationmark.triangle"
        }
    }
}

enum USBDeviceDetector {
    static func connectionStatus(fromSystemProfilerJSON data: Data) -> USBConnectionStatus {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unavailable
        }

        guard let deviceName = firstIPhoneName(in: root) else {
            return .disconnected
        }

        return .connected(name: deviceName)
    }

    static func currentConnectionStatus() -> USBConnectionStatus {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPUSBDataType", "-json"]
        process.standardOutput = output

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return .unavailable }
            return connectionStatus(fromSystemProfilerJSON: output.fileHandleForReading.readDataToEndOfFile())
        } catch {
            return .unavailable
        }
    }

    private static func firstIPhoneName(in value: Any) -> String? {
        if let dictionary = value as? [String: Any] {
            if let name = dictionary["_name"] as? String,
               name.localizedCaseInsensitiveContains("iphone") {
                return name
            }

            for child in dictionary.values {
                if let name = firstIPhoneName(in: child) {
                    return name
                }
            }
        } else if let array = value as? [Any] {
            for child in array {
                if let name = firstIPhoneName(in: child) {
                    return name
                }
            }
        }

        return nil
    }
}
