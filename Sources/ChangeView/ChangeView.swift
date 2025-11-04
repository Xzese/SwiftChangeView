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
fileprivate func loadChangelog(previewData: [VersionEntry]? = nil) -> [VersionEntry] {
    if let previewData = previewData {
        return previewData.sorted(by: compareVersions)
    }

    guard
        let url = Bundle.main.url(forResource: "changelog", withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let decoded = try? JSONDecoder().decode([VersionEntry].self, from: data)
    else {
        return []
    }

    return decoded.sorted(by: compareVersions)
}

// MARK: - Version comparison helper
private func compareVersions(_ lhs: VersionEntry, _ rhs: VersionEntry) -> Bool {
    let lhsParts = lhs.version.split(separator: ".").compactMap { Int($0) }
    let rhsParts = rhs.version.split(separator: ".").compactMap { Int($0) }

    for i in 0..<max(lhsParts.count, rhsParts.count) {
        let left = i < lhsParts.count ? lhsParts[i] : 0
        let right = i < rhsParts.count ? rhsParts[i] : 0
        if left != right {
            return left < right
        }
    }
    return false
}

public struct WhatsNewView: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    private let changelog: [VersionEntry]
    private let lastSeenVersion: String?

    // MARK: - Version
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    // MARK: - Filtered Entries
    private var newEntries: [VersionEntry] {
        let sortedAscending = changelog.sorted(by: compareVersions)
        let sortedDescending = sortedAscending.reversed()

        guard let lastSeen = lastSeenVersion,
              !lastSeen.isEmpty,
              lastSeen != "0",
              let lastIndex = sortedAscending.firstIndex(where: { $0.version == lastSeen })
        else {
            // First launch or missing record → show all (newest first)
            return Array(sortedDescending)
        }

        // Try to match current app version or default to latest in changelog
        let currentVersionInChangelog = sortedAscending.last?.version ?? currentVersion
        let currentIndex = sortedAscending.firstIndex(where: { $0.version == currentVersionInChangelog }) ?? sortedAscending.endIndex - 1

        // Show entries *after* last seen version (exclude it)
        let start = sortedAscending.index(after: lastIndex)
        if start < sortedAscending.count {
            let range = Array(sortedAscending[start...currentIndex]).reversed()
            return Array(range)
        }

        // If the last seen is the latest version, show nothing new
        return []
    }

    // MARK: - Init
    internal init(
        onDismiss: @escaping () -> Void,
        lastSeenVersion: String? = nil,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil
    ) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
        self.lastSeenVersion = lastSeenVersion
        self.changelog = loadChangelog(previewData: changelog)
    }

    // MARK: - Body
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if newEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("Version \(currentVersion)")
                                    .font(.title3.bold())
                                Spacer()
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.primary)
                            }

                            Text("Minor Improvements")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.bottom, 4)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("General Enhancements")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text("Bug fixes and performance improvements.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(newEntries) { entry in
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
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            .navigationTitle("What’s New")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
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
        lastSeenVersion: "1.2.0",
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
        ),
        VersionEntry(
            version: "1.1.11",
            title: "Enhancements",
            changes: [
                ChangeItem(title: "Visual Improvements", description: "Refined animations and icons."),
                ChangeItem(title: "Bug Fixes", description: "Resolved issues for stability.")
            ]
        )
    ])
}
