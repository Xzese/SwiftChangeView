import SwiftUI

// MARK: - Models
internal struct ChangeItem: Codable, Identifiable {
    var id: UUID { UUID() }
    let title: String
    let description: String
}

internal struct VersionEntry: Codable, Identifiable {
    var id: UUID { UUID() }
    let version: String
    let title: String
    let changes: [ChangeItem]
}

// MARK: - Shared Changelog Loader
@discardableResult
fileprivate func loadChangelog(previewData: [VersionEntry]? = nil) -> [VersionEntry] {
    if let previewData = previewData {
        return previewData
    }

    guard
        let url = Bundle.main.url(forResource: "changelog", withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let decoded = try? JSONDecoder().decode([VersionEntry].self, from: data)
    else {
        return []
    }

    return decoded
}

public struct WhatsNewView: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    private let changelog: [VersionEntry]
    
    // MARK: - Version
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    
    private var currentEntry: VersionEntry? {
        // Try to match the current app version first
        if let match = changelog.first(where: { $0.version == currentVersion }) {
            return match
        }
        // Fallback to the most recent version if version is missing or doesn't match
        return changelog.last
    }
    
    internal init(
        onDismiss: @escaping () -> Void,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil
    ) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
        self.changelog = loadChangelog(previewData: changelog)
    }

    // MARK: - Body
    public var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text("What’s New")
                    .font(.largeTitle.bold())
                Image(systemName: "party.popper")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            ScrollView {
                if let entry = currentEntry {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("\(entry.title) (\(entry.version))")
                            .font(.title3.bold())
                            .padding(.bottom, 5)
                        
                        ForEach(entry.changes) { change in
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(change.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(change.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                } else {
                    Text("Bug fixes and performance improvements.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Continue") { onDismiss() }
                .buttonStyle(.borderedProminent)
                .tint(tintColor)
        }
        .padding(30)
        .presentationDetents([.fraction(0.7)])
    }
}

// MARK: - Changelog Screen
public struct ChangelogScreen: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    private let changelog: [VersionEntry]
    
    internal init(
        onDismiss: @escaping () -> Void,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil
    ) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
        self.changelog = loadChangelog(previewData: changelog).reversed()
    }

    // MARK: - View
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    ForEach(changelog) { entry in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("Version \(entry.version)")
                                    .font(.title3.bold())
                                Spacer()
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.primary)
                            }

                            Text(entry.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.bottom, 4)

                            ForEach(entry.changes) { change in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(change.title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text(change.description)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .navigationTitle("Changelog")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("WhatsNewView") {
    WhatsNewView(
        onDismiss: {},
        changelog: [
            VersionEntry(
                version: "1.0.0",
                title: "Initial Release",
                changes: [
                    ChangeItem(
                        title: "App Launch",
                        description: "The first release of your app — providing a fast, private, and intuitive experience with all core features available."
                    )
                ]
            ),
            VersionEntry(
                version: "1.1.0",
                title: "Feature and Stability Improvements",
                changes: [
                    ChangeItem(title: "New Feature", description: "Introduced a new feature to enhance functionality and improve the overall user experience."),
                    ChangeItem(title: "Visual Enhancements", description: "Updated layouts, icons, and animations for a more polished and modern look."),
                    ChangeItem(title: "Performance Improvements", description: "Optimised loading times and responsiveness across the app."),
                    ChangeItem(title: "Bug Fixes", description: "Resolved various issues to ensure smoother operation.")
                ]
            )
        ]
    )
}

#Preview("ChangelogScreen") {
    ChangelogScreen(onDismiss: {}, changelog: [
        VersionEntry(
            version: "1.0.0",
            title: "Initial Release",
            changes: [
                ChangeItem(title: "App Launch", description: "The first release of your app.")
            ]
        ),
        VersionEntry(
            version: "1.1.0",
            title: "Enhancements",
            changes: [
                ChangeItem(title: "Visual Improvements", description: "Refined animations and icons."),
                ChangeItem(title: "Bug Fixes", description: "Resolved issues for stability.")
            ]
        )
    ])
}
