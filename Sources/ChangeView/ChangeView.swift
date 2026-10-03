#if canImport(SwiftUI) && os(iOS)
import SwiftUI

private struct ReleaseList: View {
    let result: Result<[VersionEntry], Error>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch result {
                case .failure:
                    Text("Release notes could not be loaded.")
                case .success(let entries) where entries.isEmpty:
                    Text("No release notes to show.")
                case .success(let entries):
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Version \(entry.version)").font(.title3.bold())
                            Text(entry.title).font(.headline)
                            ForEach(entry.changes) { change in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(change.title).font(.subheadline.bold())
                                    Text(change.description).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

public struct WhatsNewView: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    private let result: Result<[VersionEntry], Error>

    public init(
        onDismiss: @escaping () -> Void,
        lastSeenVersion: String? = nil,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil,
        currentVersion: String? = nil,
        bundle: Bundle = .main
    ) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
        result = Result {
            let entries = try changelog.map(Changelog.validate) ?? Changelog.load(bundle: bundle)
            let version = currentVersion ?? (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
            return try Changelog.entriesToShow(entries, lastSeenVersion: lastSeenVersion, currentVersion: version)
        }
    }

    public var body: some View {
        NavigationStack {
            ReleaseList(result: result)
                .navigationTitle("What’s New")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "xmark", action: onDismiss)
                            .labelStyle(.iconOnly)
                    }
                }
        }
        .tint(tintColor)
    }
}

public struct ChangelogScreen: View {
    private let onDismiss: () -> Void
    private let tintColor: Color
    private let result: Result<[VersionEntry], Error>

    public init(
        onDismiss: @escaping () -> Void,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil,
        bundle: Bundle = .main
    ) {
        self.onDismiss = onDismiss
        self.tintColor = tintColor
        result = Result { try changelog.map(Changelog.validate) ?? Changelog.load(bundle: bundle) }
    }

    public var body: some View {
        NavigationStack {
            ReleaseList(result: result)
                .navigationTitle("Changelog")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "xmark", action: onDismiss)
                            .labelStyle(.iconOnly)
                    }
                }
        }
        .tint(tintColor)
    }
}
#endif
