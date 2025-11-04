import SwiftUI

// MARK: - Models
internal struct ChangeItem: Codable, Identifiable {
    var id: UUID { UUID() }
    let title: String
    let description: String
}

public struct VersionEntry: Codable, Identifiable {
    public var id: UUID { UUID() }
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
    compareVersionStrings(lhs.version, rhs.version)
}

/// Returns true if `lhs` < `rhs` (e.g. "1.0.9" < "1.0.10")
public func compareVersionStrings(_ lhs: String, _ rhs: String) -> Bool {
    let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
    let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }

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
              lastSeen != "0"
        else {
            // First launch or missing record → show all (newest first)
            return Array(sortedDescending)
        }

        guard let latestVersion = sortedAscending.last?.version else { return [] }

        // If last seen version is newer or equal to latest, show nothing
        if !compareVersionStrings(lastSeen, latestVersion) || lastSeen == latestVersion {
            return []
        }

        // Find lastSeen index if present
        if let lastIndex = sortedAscending.firstIndex(where: { $0.version == lastSeen }) {
            // Return entries *after* the lastSeen version
            let start = sortedAscending.index(after: lastIndex)
            guard start < sortedAscending.count else { return [] }
            return Array(sortedAscending[start...]).reversed()
        } else {
            // If the last seen version isn't in the changelog,
            // find the *first* version greater than it, and show from there
            let newerEntries = sortedAscending.filter { compareVersionStrings(lastSeen, $0.version) }
            return Array(newerEntries.reversed())
        }
    }
    
    /// Returns true if lhs < rhs
    private func compareVersionStrings(_ lhs: String, _ rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(lhsParts.count, rhsParts.count) {
            let left = i < lhsParts.count ? lhsParts[i] : 0
            let right = i < rhsParts.count ? rhsParts[i] : 0
            if left != right {
                return left < right
            }
        }
        return false
    }

    // MARK: - Init
    public init(
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
                                Text("Bug fixes and improvements.")
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
        }
    }
}

// MARK: - Changelog Screen
public struct ChangelogScreen: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    private let changelog: [VersionEntry]
    
    public init(
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
        lastSeenVersion: "1.0.0",
        changelog: [
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
                version: "1.1.1",
                title: "Enhancements",
                changes: [
                    ChangeItem(title: "Visual Improvements", description: "Refined animations and icons."),
                    ChangeItem(title: "Bug Fixes", description: "Resolved issues for stability.")
                ]
            )
        ]
    )
}

#Preview("ChangelogScreen") {
    ChangelogScreen(onDismiss: {}, changelog: [
        VersionEntry(
            version: "1.1.1",
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
