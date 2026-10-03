# ChangeView

A small SwiftUI package for What's New and changelog screens. Requires Swift 6.2 and iOS 17 or later.

## Development status

The portfolio-modernisation branch contains a first implementation. Keep this PR in draft until the iOS simulator build, accessibility checks and consumer example are verified. Eight model/selection tests passed on Swift 6.2.1 on Linux; that does not validate SwiftUI compilation or rendering.

## Use the public API

Add this repository as a Swift package dependency. Import `ChangeView`.

```swift
import SwiftUI
import ChangeView

struct ReleaseNotesExample: View {
    var body: some View {
        WhatsNewView(
            onDismiss: {},
            lastSeenVersion: "1.0",
            changelog: [
                VersionEntry(
                    version: "1.1",
                    title: "Library updates",
                    changes: [
                        ChangeItem(title: "Search", description: "Find a book by its title.")
                    ]
                )
            ],
            currentVersion: "1.1"
        )
    }
}
```

In an application, use `onDismiss` to close the sheet and save the installed version as the last seen version. The explicit `currentVersion` above makes the example independent of bundle metadata. In production it defaults to `CFBundleShortVersionString`.

Without the `changelog` argument, both views load `changelog.json` from the supplied bundle (default: the main bundle). Use `Changelog.load`, `Changelog.decode` or `Changelog.validate` to receive detailed errors before creating a view.

```json
[{"version":"1.1","title":"Library updates","changes":[{"title":"Search","description":"Find a book by its title."}]}]
```

## Contract

Versions are dot-separated non-negative integers, not full Semantic Versioning. Prerelease and build suffixes are rejected. Trailing zero components compare equally; duplicate equivalent versions are rejected. `AppVersion` provides throwing validation. The existing `compareVersionStrings` helper returns false for invalid input and treats an empty last-seen value as zero.

What's New displays only `lastSeenVersion < entry.version <= currentVersion`, newest first. A missing or empty last-seen value shows all entries through the installed version. ChangelogScreen shows the complete validated changelog.

Change IDs are stored once, not regenerated on every property access. Legacy JSON without IDs receives IDs on decoding; include explicit UUID IDs when identity must remain stable across repeated reloads. VersionEntry uses its version string as identity. Duplicate IDs within a release are rejected.

Both views apply the supplied tint. Empty data and invalid data show different messages; the package no longer invents release notes when loading fails.

## Tests

Run `swift test` for model, decoding and version-selection tests. These tests import the public module without `@testable`. SwiftUI views are compiled only for iOS. An iOS simulator build remains a required release check.

## Licence

The existing MIT licence is unchanged. See LICENSE.
