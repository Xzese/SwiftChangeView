import SwiftUI

// MARK: - Models
private struct ChangeItem: Codable, Identifiable {
    var id: UUID { UUID() }
    let title: String
    let description: String
}

private struct VersionEntry: Codable, Identifiable {
    var id: UUID { UUID() }
    let version: String
    let title: String
    let changes: [ChangeItem]
}

public struct WhatsNewView: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    
    // MARK: - Version
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    // MARK: - Load changelog
    private var changelog: [VersionEntry] {
        guard
            let url = Bundle.main.url(forResource: "changelog", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([VersionEntry].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private var currentEntry: VersionEntry? {
        changelog.first { $0.version == currentVersion }
    }
    
    public init(onDismiss: @escaping () -> Void, tintColor: Color = .accentColor) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
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
                        Text("\(currentVersion) \(entry.title)")
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

    // MARK: - Load changelog
    private var changelog: [VersionEntry] {
        guard
            let url = Bundle.main.url(forResource: "changelog", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([VersionEntry].self, from: data)
        else {
            return []
        }
        // Reverse order — newest first
        return decoded.reversed()
    }
    
    public init(onDismiss: @escaping () -> Void, tintColor: Color = .accentColor) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
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
