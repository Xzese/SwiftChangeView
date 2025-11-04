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
    
    // MARK: - Version
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    
    private var currentEntry: VersionEntry? {
        // Make sure changelog is sorted from lowest → highest version
        let sortedChangelog = changelog.sorted(by: compareVersions)
        
        // Try to match the current app version exactly
        if let match = sortedChangelog.first(where: { $0.version == currentVersion }) {
            return match
        }
        
        // Fallback to the latest available entry (highest version)
        return sortedChangelog.last
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
        NavigationStack {
            VStack(spacing: 10) {
                ScrollView {
                    if let entry = currentEntry {
                        VStack(alignment: .leading, spacing: 20) {
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
                        .padding(.vertical, 20)
                    } else {
                        Text("Bug fixes and performance improvements.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .presentationDetents([.fraction(0.7)])
            .navigationTitle("What's New")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
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
