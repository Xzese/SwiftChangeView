# Package modernisation

Status: implementation started; keep this PR in draft.

## Implemented
- Stored change identity and release identity based on the version.
- Public models, properties and initialisers.
- One validated numeric application-version implementation.
- Installed-version and last-seen filtering.
- Explicit loading, validation and empty-data behaviour.
- Shared release-list UI and applied tint.
- A SwiftPM test target that imports the public API.
- Eight core tests passed on Swift 6.2.1/Linux.
- Self-contained README example and an explicit version-format contract.

## Remaining
- Compile and test the iOS SwiftUI views on an Apple runner.
- Build a separate example application, not only a core consumer test.
- Add CI, accessibility checks, Dynamic Type checks and screenshots.
- Review navigation embedding and release/tag compatibility.

No iOS build or UI test has been claimed. The original project history and licence are unchanged.
