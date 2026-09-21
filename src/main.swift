import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Models

struct ReleaseItem: Identifiable, Hashable {
    let id: String
    let tag: String
    let name: String
    let ipaURL: String
    let isLatest: Bool

    var displayTitle: String {
        let latestBadge = isLatest ? " (Latest Release)" : ""
        let ipaBadge = ipaURL.isEmpty ? " [no IPA asset]" : " [IPA ready]"
        return "\(tag)\(latestBadge)\(ipaBadge)"
    }
}

enum PairingType {
    case none
    case lockdown
    case rpPairingComplete
    case rpPairingIncomplete
    case custom

    var title: String {
        switch self {
        case .none: return "No pairing file selected"
        case .lockdown: return "Legacy Lockdown Record (USB only)"
        case .rpPairingComplete: return "RemotePairing Record with alt_irk (Verified for iOS 26+)"
        case .rpPairingIncomplete: return "RemotePairing Record (Missing alt_irk key)"
        case .custom: return "Custom Property List"
        }
    }

    var badgeText: String {
        switch self {
        case .none: return "Awaiting File"
        case .lockdown: return "Legacy Lockdown"
        case .rpPairingComplete: return "iOS 26 Ready ✅"
        case .rpPairingIncomplete: return "Missing alt_irk ⚠️"
        case .custom: return "Custom .plist"
        }
    }

    var color: Color {
        switch self {
        case .none: return .secondary
        case .lockdown: return .orange
        case .rpPairingComplete: return .green
        case .rpPairingIncomplete: return .red
        case .custom: return .blue
        }
    }

    var icon: String {
        switch self {
        case .none: return "questionmark.circle"
        case .lockdown: return "exclamationmark.triangle.fill"
        case .rpPairingComplete: return "checkmark.seal.fill"
        case .rpPairingIncomplete: return "xmark.octagon.fill"
        case .custom: return "doc.fill"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class InjectorViewModel: ObservableObject {
    @Published var pairingPath: String = ""
    @Published var pairingType: PairingType = .none
    @Published var releases: [ReleaseItem] = []
    @Published var selectedReleaseTag: String = ""
    @Published var customIPAPath: String = ""
    @Published var isLoadingReleases: Bool = false
    @Published var isProcessing: Bool = false
    @Published var progressMessage: String = ""
    @Published var generatedIPAURL: URL? = nil
    @Published var logs: [String] = []

    private var watchTimer: Timer?

    init() {
        autoDetectPairingFile()
        fetchReleases()
    }

    func log(_ msg: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        logs.append("[\(timestamp)] \(msg)")
    }

    func autoDetectPairingFile() {
        let checkLocations = [
            NSHomeDirectory() + "/Documents/pairingFile.plist",
            NSHomeDirectory() + "/Downloads/pairingFile.plist",
            NSHomeDirectory() + "/Documents/aircard_pairing.plist",
            NSHomeDirectory() + "/Downloads/aircard_pairing.plist"
        ]

        // 1. Priority: files containing verified alt_irk
        for candidate in checkLocations {
            if FileManager.default.fileExists(atPath: candidate),
               let data = try? Data(contentsOf: URL(fileURLWithPath: candidate)),
               let dict = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] {
                if dict["alt_irk"] != nil {
                    setPairingFile(path: candidate)
                    log("Auto-detect: found RemotePairing file with alt_irk (\(URL(fileURLWithPath: candidate).lastPathComponent))")
                    return
                }
            }
        }

        // 2. Any other pairing files in user folders
        for candidate in checkLocations {
            if FileManager.default.fileExists(atPath: candidate) {
                setPairingFile(path: candidate)
                log("Auto-detect: found pairing file (\(URL(fileURLWithPath: candidate).lastPathComponent))")
                return
            }
        }

        // 3. System lockdown directory
        let lockdownDir = URL(fileURLWithPath: "/var/db/lockdown")
        if let files = try? FileManager.default.contentsOfDirectory(at: lockdownDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) {
            let candidates = files.filter { url in
                let ext = url.pathExtension.lowercased()
                let name = url.lastPathComponent.lowercased()
                return (ext == "plist" || ext == "mobiledevicepairing") && name != "systemconfiguration.plist" && name != "root.plist"
            }
            if let mostRecent = candidates.sorted(by: { (a, b) -> Bool in
                let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return dateA > dateB
            }).first {
                setPairingFile(path: mostRecent.path)
                log("Auto-detect: found system pairing record (\(mostRecent.lastPathComponent))")
            }
        }
    }

    func launchIdevicePair() {
        let embedded = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/idevice_pair.app").path
        let appPaths = [
            embedded,
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("idevice_pair.app").path,
            "/Applications/idevice_pair.app",
            NSHomeDirectory() + "/Applications/idevice_pair.app"
        ]

        for path in appPaths {
            if FileManager.default.fileExists(atPath: path) {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
                log("Launched pairing generator: \(URL(fileURLWithPath: path).lastPathComponent)")
                startWatchingForPairingFile()
                return
            }
        }
        log("Notice: idevice_pair.app was not found. Please install it or open manually.")
    }

    func startWatchingForPairingFile() {
        watchTimer?.invalidate()
        log("Listening for new pairing file in ~/Documents or ~/Downloads...")
        watchTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let checkPaths = [
                    NSHomeDirectory() + "/Documents/pairingFile.plist",
                    NSHomeDirectory() + "/Downloads/pairingFile.plist"
                ]
                for p in checkPaths {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: p),
                       let modDate = attrs[.modificationDate] as? Date,
                       Date().timeIntervalSince(modDate) < 120 {
                        if let data = try? Data(contentsOf: URL(fileURLWithPath: p)),
                           let dict = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any],
                           dict["alt_irk"] != nil {
                            self.setPairingFile(path: p)
                            self.log("Success: Auto-detected fresh pairing file with alt_irk: \(URL(fileURLWithPath: p).lastPathComponent)")
                            self.watchTimer?.invalidate()
                            self.watchTimer = nil
                            return
                        }
                    }
                }
            }
        }
    }

    func setPairingFile(path: String) {
        pairingPath = path
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let dict = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any] else {
            pairingType = .custom
            return
        }

        if dict["alt_irk"] != nil {
            pairingType = .rpPairingComplete
        } else if dict["HostPrivateKey"] != nil || dict["DeviceCertificate"] != nil {
            pairingType = .lockdown
        } else if dict["e_private_key"] != nil || dict["identifier"] != nil {
            pairingType = .rpPairingIncomplete
        } else {
            pairingType = .custom
        }
    }

    func selectPairingFile() {
        let panel = NSOpenPanel()
        panel.title = "Select Pairing File (.plist)"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "plist") ?? .propertyList,
            UTType(filenameExtension: "mobiledevicepairing") ?? .data
        ]

        if panel.runModal() == .OK, let url = panel.url {
            setPairingFile(path: url.path)
            log("Selected pairing file: \(url.lastPathComponent)")
        }
    }

    func selectCustomIPA() {
        let panel = NSOpenPanel()
        panel.title = "Select Local AirCard-iOS.ipa"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "ipa") ?? .data]

        if panel.runModal() == .OK, let url = panel.url {
            customIPAPath = url.path
            selectedReleaseTag = "__custom__"
            log("Selected custom IPA: \(url.lastPathComponent)")
        }
    }

    func fetchReleases() {
        isLoadingReleases = true
        log("Fetching latest releases from GitHub (Mak5er/AirCard-iOS)...")

        Task {
            var loaded: [ReleaseItem] = []

            do {
                let url = URL(string: "https://api.github.com/repos/Mak5er/AirCard-iOS/releases")!
                var req = URLRequest(url: url)
                req.setValue("AirCard-Injector", forHTTPHeaderField: "User-Agent")
                req.timeoutInterval = 6.0

                let (data, _) = try await URLSession.shared.data(for: req)
                let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []

                for (idx, obj) in json.prefix(8).enumerated() {
                    guard let tag = obj["tag_name"] as? String else { continue }
                    let name = (obj["name"] as? String) ?? tag
                    var ipaURL = ""
                    if let assets = obj["assets"] as? [[String: Any]] {
                        for a in assets {
                            if let aName = a["name"] as? String, aName.lowercased().hasSuffix(".ipa"),
                               let dUrl = a["browser_download_url"] as? String {
                                ipaURL = dUrl
                                break
                            }
                        }
                    }
                    loaded.append(ReleaseItem(id: tag, tag: tag, name: name, ipaURL: ipaURL, isLatest: idx == 0))
                }

                self.releases = loaded
                if self.selectedReleaseTag.isEmpty || !loaded.contains(where: { $0.tag == self.selectedReleaseTag }) {
                    self.selectedReleaseTag = loaded.first?.tag ?? ""
                }
                self.isLoadingReleases = false
                self.log("Loaded \(loaded.count) release options from GitHub.")
            } catch {
                self.isLoadingReleases = false
                self.releases = loaded
                if self.selectedReleaseTag.isEmpty {
                    self.selectedReleaseTag = loaded.first?.tag ?? ""
                }
                self.log("GitHub releases offline: \(error.localizedDescription)")
            }
        }
    }

    func startInjection() {
        guard !pairingPath.isEmpty, FileManager.default.fileExists(atPath: pairingPath) else {
            log("Error: Please provide an existing pairing file.")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.title = "Save Personalized IPA"
        savePanel.nameFieldStringValue = "AirCard-iOS-Ready.ipa"
        savePanel.allowedContentTypes = [UTType(filenameExtension: "ipa") ?? .data]

        guard savePanel.runModal() == .OK, let outURL = savePanel.url else { return }

        isProcessing = true
        progressMessage = "Preparing files..."
        generatedIPAURL = nil

        Task.detached(priority: .userInitiated) {
            do {
                let rawPairingData = try Data(contentsOf: URL(fileURLWithPath: await self.pairingPath))
                var sanitizedPairingData = rawPairingData

                // Auto-sanitize: if lockdown record without alt_irk, strip partial RSD keys to avoid timeouts
                if var dict = (try? PropertyListSerialization.propertyList(from: rawPairingData, format: nil)) as? [String: Any] {
                    if (dict["HostPrivateKey"] != nil || dict["DeviceCertificate"] != nil) && dict["alt_irk"] == nil {
                        dict.removeValue(forKey: "identifier")
                        dict.removeValue(forKey: "private_key")
                        dict.removeValue(forKey: "public_key")
                        if let sanitized = try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0) {
                            sanitizedPairingData = sanitized
                            await self.log("Auto-sanitization applied: stripped incomplete RSD keys")
                        }
                    }
                }

                var baseIPAPath: URL
                let isCustom = await self.selectedReleaseTag == "__custom__"
                let customPath = await self.customIPAPath
                let selectedTag = await self.selectedReleaseTag
                let currentReleases = await self.releases

                if isCustom && !customPath.isEmpty {
                    baseIPAPath = URL(fileURLWithPath: customPath)
                    await self.log("Using custom base IPA: \(baseIPAPath.lastPathComponent)")
                } else {
                    guard let rel = currentReleases.first(where: { $0.tag == selectedTag }), !rel.ipaURL.isEmpty,
                          let downloadURL = URL(string: rel.ipaURL) else {
                        throw NSError(domain: "Injector", code: 1, userInfo: [NSLocalizedDescriptionKey: "The selected release does not contain a downloadable .ipa file. Please choose a custom IPA."])
                    }

                    await self.updateProgress("Downloading \(rel.tag) from GitHub...")
                    await self.log("Downloading \(rel.tag)...")

                    let tempDownload = FileManager.default.temporaryDirectory.appendingPathComponent("base_\(rel.tag).ipa")
                    let (dlURL, _) = try await URLSession.shared.download(from: downloadURL)
                    try? FileManager.default.removeItem(at: tempDownload)
                    try FileManager.default.moveItem(at: dlURL, to: tempDownload)
                    baseIPAPath = tempDownload
                    await self.log("Base IPA downloaded successfully.")
                }

                await self.updateProgress("Unpacking IPA archive...")
                await self.log("Extracting Payload directory...")

                let tempWorkspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: tempWorkspace, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: tempWorkspace) }

                let unzipProcess = Process()
                unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
                unzipProcess.arguments = ["-q", baseIPAPath.path, "-d", tempWorkspace.path]
                try unzipProcess.run()
                unzipProcess.waitUntilExit()

                let payloadDir = tempWorkspace.appendingPathComponent("Payload")
                let contents = try FileManager.default.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil)
                guard let appDir = contents.first(where: { $0.pathExtension.lowercased() == "app" }) else {
                    throw NSError(domain: "Injector", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find Payload/*.app directory inside IPA."])
                }

                await self.updateProgress("Injecting pairing credentials...")
                let originalFileName = URL(fileURLWithPath: await self.pairingPath).lastPathComponent
                let injectedNames = ["aircard_pairing.plist", "airlift_pairing.plist", "pairing.plist", "pairingFile.plist", originalFileName]

                for name in Set(injectedNames) {
                    let dest = appDir.appendingPathComponent(name)
                    try sanitizedPairingData.write(to: dest, options: .atomic)
                    await self.log("Injected: \(appDir.lastPathComponent)/\(name)")
                }

                await self.updateProgress("Repackaging personalized IPA...")
                await self.log("Creating output archive...")

                try? FileManager.default.removeItem(at: outURL)
                let zipProcess = Process()
                zipProcess.currentDirectoryURL = tempWorkspace
                zipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
                zipProcess.arguments = ["-q", "-r", "-y", outURL.path, "Payload"]
                try zipProcess.run()
                zipProcess.waitUntilExit()

                await self.log("Done! Personalized IPA created: \(outURL.path)")

                await MainActor.run {
                    self.isProcessing = false
                    self.progressMessage = "Successfully created!"
                    self.generatedIPAURL = outURL
                }
            } catch {
                await self.log("ERROR: \(error.localizedDescription)")
                await MainActor.run {
                    self.isProcessing = false
                    self.progressMessage = "Injection failed"
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText = "Failed to Create IPA"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    private func updateProgress(_ msg: String) async {
        await MainActor.run {
            self.progressMessage = msg
        }
    }
}

// MARK: - SwiftUI View

struct ContentView: View {
    @StateObject private var vm = InjectorViewModel()
    @State private var showCredits = false

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 14) {
                ZStack {
                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AirCard Injector")
                        .font(.system(size: 20, weight: .bold))
                    Text("Automated RemotePairing generator & IPA injector for iOS 26+")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // CREDITS BUTTON IN APP
                Button {
                    showCredits = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                        Text("Credits")
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.49, green: 0.23, blue: 0.93))
                .controlSize(.regular)

                // Status Badge
                HStack(spacing: 6) {
                    Image(systemName: vm.pairingType.icon)
                    Text(vm.pairingType.badgeText)
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(vm.pairingType.color.opacity(0.12))
                .foregroundStyle(vm.pairingType.color)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // STEP 1: PAIRING CARD
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Step 1. Device Pairing (RemotePairing / alt_irk)", systemImage: "link.badge.plus")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }

                        // Launch Generator Button
                        Button {
                            vm.launchIdevicePair()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "key.horizontal.fill")
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Launch Key Generator (idevice_pair)")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("Connect iPhone via USB → Select Remote Pairing → Click Pair")
                                        .font(.system(size: 11))
                                        .opacity(0.85)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        // Path Picker Row
                        HStack(spacing: 8) {
                            TextField("Path to pairingFile.plist...", text: $vm.pairingPath)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))

                            Button("Browse…") {
                                vm.selectPairingFile()
                            }

                            Button {
                                vm.autoDetectPairingFile()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .help("Auto-detect saved pairing files")
                        }

                        // Status details
                        HStack(spacing: 6) {
                            Image(systemName: vm.pairingType.icon)
                                .foregroundStyle(vm.pairingType.color)
                            Text(vm.pairingType.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(vm.pairingType.color)
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // STEP 2: BASE IPA CARD
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Step 2. AirCard-iOS Base Version", systemImage: "app.gift.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            if vm.isLoadingReleases {
                                ProgressView().scaleEffect(0.6)
                            }
                        }

                        if !vm.releases.isEmpty {
                            Picker("Release:", selection: $vm.selectedReleaseTag) {
                                ForEach(vm.releases) { rel in
                                    Text(rel.displayTitle).tag(rel.tag)
                                }
                                if !vm.customIPAPath.isEmpty {
                                    Text("Custom: \(URL(fileURLWithPath: vm.customIPAPath).lastPathComponent)").tag("__custom__")
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        HStack {
                            Button("Choose Custom .ipa…") {
                                vm.selectCustomIPA()
                            }
                            .font(.system(size: 11))

                            Spacer()

                            if vm.releases.isEmpty && !vm.isLoadingReleases {
                                Text("No internet. Please select a local .ipa file.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // STEP 3: ACTION CARD
                    VStack(spacing: 12) {
                        Button {
                            vm.startInjection()
                        } label: {
                            HStack(spacing: 10) {
                                if vm.isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 18, height: 18)
                                } else {
                                    Image(systemName: "bolt.badge.checkmark.fill")
                                        .font(.system(size: 16))
                                }
                                Text(vm.isProcessing ? vm.progressMessage : "Inject Pairing & Create Ready IPA")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(vm.pairingType == .rpPairingComplete ? .green : .blue)
                        .disabled(vm.pairingPath.isEmpty || vm.isProcessing)

                        if let generatedURL = vm.generatedIPAURL {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("IPA created: \(generatedURL.lastPathComponent)")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Button("Reveal in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([generatedURL])
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(10)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // TERMINAL LOG
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Activity Log:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Clear") {
                                vm.logs.removeAll()
                            }
                            .font(.system(size: 10))
                        }

                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 3) {
                                    ForEach(vm.logs.indices, id: \.self) { idx in
                                        Text(vm.logs[idx])
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(Color.green.opacity(0.9))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id(idx)
                                    }
                                }
                                .padding(8)
                            }
                            .background(Color.black.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(height: 110)
                            .onChange(of: vm.logs.count) {
                                if let last = vm.logs.indices.last {
                                    proxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // CREDITS FOOTER
                    HStack(spacing: 4) {
                        Text("AirCard Injector v2.0")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("• Fix by")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Link("@merybist", destination: URL(string: "https://github.com/merybist")!)
                            .font(.system(size: 10, weight: .medium))
                        Text("• AirCard by")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Link("@Mak5er", destination: URL(string: "https://github.com/Mak5er")!)
                            .font(.system(size: 10, weight: .medium))
                        Text("• idevice_pair by")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Link("@jkcoxson", destination: URL(string: "https://github.com/jkcoxson/idevice_pair")!)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .frame(width: 640, height: 690)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showCredits) {
            CreditsModalView()
        }
    }
}

// MARK: - Credits Modal

struct CreditsModalView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.49, green: 0.23, blue: 0.93), Color(red: 0.08, green: 0.53, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Credits & Acknowledgements")
                        .font(.system(size: 16, weight: .bold))
                    Text("AirCard Injector for iOS 26+")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            VStack(spacing: 10) {
                CreditCardRow(
                    name: "merybist",
                    role: "Creator of AirCard Injector • iOS 26 lockdown pairing fix • macOS GUI & DMG",
                    url: "https://github.com/merybist",
                    icon: "hammer.fill",
                    color: Color(red: 0.49, green: 0.23, blue: 0.93)
                )

                CreditCardRow(
                    name: "Mak5er",
                    role: "Creator of AirCard-iOS • Apple Wallet card artwork replacement",
                    url: "https://github.com/Mak5er",
                    icon: "creditcard.fill",
                    color: Color(red: 0.08, green: 0.53, blue: 0.95)
                )

                CreditCardRow(
                    name: "jkcoxson",
                    role: "Creator of idevice_pair • Rust idevice ecosystem for RemotePairing",
                    url: "https://github.com/jkcoxson/idevice_pair",
                    icon: "key.horizontal.fill",
                    color: Color(red: 0.12, green: 0.65, blue: 0.53)
                )
            }

            Divider()

            HStack {
                Text("Crafted for iOS 26+ pairing automation")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.49, green: 0.23, blue: 0.93))
                .controlSize(.regular)
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct CreditCardRow: View {
    let name: String
    let role: String
    let url: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Link(destination: URL(string: url)!) {
                        HStack(spacing: 3) {
                            Text("GitHub")
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                Text(role)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - App Entry

@main
struct AirCardInjectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
