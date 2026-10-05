import SwiftUI
import ChangeView

@main
struct ChangeViewExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleRoot()
                .modifier(ExampleAppearance())
        }
    }
}

private struct ExampleRoot: View {
    @AppStorage("lastSeenVersion") private var lastSeenVersion = "1.0"
    @State private var showWhatsNew = false
    @State private var didCheckVersion = false
    @State private var showEmpty = false
    @State private var showMalformed = false
    private let currentVersion = "1.1"
    // Also compile the exact original initializer references used by factories.
    private let whatsNewFactory = WhatsNewView.init(onDismiss:lastSeenVersion:tintColor:changelog:)
    private let changelogFactory = ChangelogScreen.init(onDismiss:tintColor:changelog:)

    var body: some View {
        NavigationStack {
            List {
                Section("Release notes") {
                    Button("What's New") { showWhatsNew = true }
                    NavigationLink("Changelog") { ChangelogDestination() }
                    Text("Last seen: \(lastSeenVersion)")
                }
                Section("Empty and invalid data") {
                    Button("Empty changelog") { showEmpty = true }
                    Button("Invalid changelog") { showMalformed = true }
                }
            }
            .navigationTitle("ChangeView Example")
            .sheet(isPresented: $showWhatsNew, onDismiss: markSeen) {
                // Original call shape: data and installed version come from the app bundle.
                whatsNewFactory({ showWhatsNew = false }, lastSeenVersion, .purple, nil)
                    .modifier(ExampleAppearance())
            }
            .sheet(isPresented: $showEmpty) {
                changelogFactory({ showEmpty = false }, .purple, [])
                    .modifier(ExampleAppearance())
            }
            .sheet(isPresented: $showMalformed) {
                ChangelogScreen(onDismiss: { showMalformed = false }, changelog: [
                    VersionEntry(version: "not-a-version", title: "Invalid", changes: [])
                ], validation: .strict)
                    .modifier(ExampleAppearance())
            }
            .onAppear {
                guard !didCheckVersion else { return }
                didCheckVersion = true
                if ProcessInfo.processInfo.arguments.contains("--reset-state") {
                    lastSeenVersion = "1.0"
                }
                showWhatsNew = compareVersionStrings(lastSeenVersion, currentVersion)
            }
        }
    }

    private func markSeen() { lastSeenVersion = currentVersion }
}

private struct ChangelogDestination: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChangelogScreen(onDismiss: { dismiss() }, tintColor: .purple, embedsInNavigationStack: false)
    }
}

// Apply preview overrides to presentations too: sheets own their environment.
private struct ExampleAppearance: ViewModifier {
    @Environment(\.dynamicTypeSize) private var textSize

    func body(content: Content) -> some View {
        let arguments = ProcessInfo.processInfo.arguments
        content
            .dynamicTypeSize(arguments.contains("--large-text") ? .accessibility3 : textSize)
            .preferredColorScheme(arguments.contains("--dark") ? .dark : nil)
    }
}
