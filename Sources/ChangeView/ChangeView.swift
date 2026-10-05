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
                            Text("Version \(entry.version)")
                                .font(.title3.bold())
                                .accessibilityAddTraits(.isHeader)
                            Text(entry.title).font(.headline)
                            ForEach(entry.changes) { change in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(change.title).font(.subheadline.bold())
                                    Text(change.description).font(.callout).foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
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

private struct ReleaseScreen: View {
    let title: String
    let onDismiss: () -> Void
    let tintColor: Color
    let result: Result<[VersionEntry], Error>
    let embedsInNavigationStack: Bool

    private var content: some View {
        ReleaseList(result: result)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: embedsInNavigationStack ? .topBarLeading : .topBarTrailing) {
                    Button("Close", systemImage: "xmark", action: onDismiss)
                        .labelStyle(.iconOnly)
                        .accessibilityIdentifier("releaseNotes.close")
                }
            }
    }

    var body: some View {
        Group {
            if embedsInNavigationStack {
                NavigationStack { content }
            } else {
                content
            }
        }
        .tint(tintColor)
    }
}

/// Release notes newer than the saved version, through the installed version.
public struct WhatsNewView: View {
    private let screen: ReleaseScreen

    /// Retains the original initializer, including references used as factories.
    public init(
        onDismiss: @escaping () -> Void,
        lastSeenVersion: String? = nil,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil
    ) {
        self.init(onDismiss: onDismiss, lastSeenVersion: lastSeenVersion,
                  tintColor: tintColor, changelog: changelog, currentVersion: nil)
    }

    /// Existing calls retain their defaults. Disable the internal navigation
    /// stack when pushing this view inside your application's NavigationStack.
    public init(
        onDismiss: @escaping () -> Void,
        lastSeenVersion: String? = nil,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil,
        currentVersion: String? = nil,
        bundle: Bundle = .main,
        embedsInNavigationStack: Bool = true,
        validation: ChangelogValidation = .compatible
    ) {
        let result = Result {
            let entries = try changelog ?? Changelog.load(bundle: bundle, validation: validation)
            let version = currentVersion ?? (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
            return try Changelog.entriesToShow(entries, lastSeenVersion: lastSeenVersion,
                                              currentVersion: version, validation: validation)
        }
        screen = ReleaseScreen(title: "What’s New", onDismiss: onDismiss, tintColor: tintColor,
                               result: result, embedsInNavigationStack: embedsInNavigationStack)
    }

    public var body: some View { screen }
}

/// All releases, newest first. Uses the original bundle-based JSON by default.
public struct ChangelogScreen: View {
    private let screen: ReleaseScreen

    /// Retains the original initializer, including references used as factories.
    public init(
        onDismiss: @escaping () -> Void,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil
    ) {
        self.init(onDismiss: onDismiss, tintColor: tintColor, changelog: changelog, bundle: .main)
    }

    public init(
        onDismiss: @escaping () -> Void,
        tintColor: Color = .accentColor,
        changelog: [VersionEntry]? = nil,
        bundle: Bundle = .main,
        embedsInNavigationStack: Bool = true,
        validation: ChangelogValidation = .compatible
    ) {
        let result = Result {
            try changelog.map { try Changelog.prepare($0, validation: validation) }
                ?? Changelog.load(bundle: bundle, validation: validation)
        }
        screen = ReleaseScreen(title: "Changelog", onDismiss: onDismiss, tintColor: tintColor,
                               result: result, embedsInNavigationStack: embedsInNavigationStack)
    }

    public var body: some View { screen }
}
#endif
