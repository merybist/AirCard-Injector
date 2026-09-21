import SwiftUI
import AppKit

struct CreditItem: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let url: String
    let icon: String
    let color: Color
}

struct CreditsContentView: View {
    let credits: [CreditItem] = [
        CreditItem(
            name: "merybist",
            role: "AirCard Injector creator • iOS 26 lockdown pairing fix • macOS GUI & DMG",
            url: "https://github.com/merybist",
            icon: "hammer.fill",
            color: Color(red: 0.49, green: 0.23, blue: 0.93)
        ),
        CreditItem(
            name: "Mak5er",
            role: "Creator of AirCard-iOS • Apple Wallet card artwork replacement",
            url: "https://github.com/Mak5er",
            icon: "creditcard.fill",
            color: Color(red: 0.08, green: 0.53, blue: 0.95)
        ),
        CreditItem(
            name: "jkcoxson",
            role: "Creator of idevice_pair • Rust idevice ecosystem for RemotePairing",
            url: "https://github.com/jkcoxson/idevice_pair",
            icon: "key.horizontal.fill",
            color: Color(red: 0.12, green: 0.65, blue: 0.53)
        )
    ]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AirCard Injector")
                        .font(.system(size: 17, weight: .bold))
                    Text("Credits & Project Attribution")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)

            Divider()

            // List of credits
            VStack(spacing: 10) {
                ForEach(credits) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(item.color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: item.icon)
                                .font(.system(size: 15))
                                .foregroundStyle(item.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Link(destination: URL(string: item.url)!) {
                                    HStack(spacing: 3) {
                                        Text("Visit")
                                            .font(.system(size: 10, weight: .medium))
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 9))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            Text(item.role)
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

            Divider()

            // Footer
            HStack {
                Text("iOS 26+ Pairing & Customization Suite")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("OK") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.49, green: 0.23, blue: 0.93))
                .controlSize(.small)
            }
        }
        .padding(18)
        .frame(width: 440)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

@main
struct CreditsApp: App {
    var body: some Scene {
        WindowGroup {
            CreditsContentView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
