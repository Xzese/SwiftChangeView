# Package modernisation

Status: implemented with local Apple build and test verification. Review CI
and the release checks below before tagging.

## Implemented

- Stable stored UUID model IDs; public properties and initializers.
- Original public ID type, exact view initializer overloads and defaults,
  permissive comparison helper, and legacy JSON decoding preserved.
- Shared numeric ordering with opt-in strict version/data validation.
- Last-seen and installed-version filtering, including first-launch sentinels.
- Explicit empty/loading-error states instead of invented release notes.
- Shared release UI, applied tint, accessible headings and Close labels.
- Optional embedding in the consumer's existing navigation stack.
- SwiftPM tests that import the public module without `@testable`.
- Separate iOS consumer app, with its own bundled JSON and public API imports.
- Two representative UI journeys; CI builds the library and tests the consumer.
- README usage, compatibility contract, screenshots and first-tag guidance.

## Local verification (5 October 2026)

Xcode 27.0 / Swift 6.4, using the unchanged Swift 6.2 package manifest:

- `swift test`: nine tests passed, including UUID/JSON round trips, legacy ID
  metadata, compatible and strict parsing, duplicates and selection bounds.
- Generic iOS Simulator package build: passed for arm64 and x86_64.
- Consumer build and two UI tests: passed on iPhone 16 Pro / iOS 18.0.
- The consumer compiles both exact original initializer references as factories.
- UI tests verify sheet filtering, dismissal persistence, navigation,
  empty/error messages and reachable Close at accessibility text size.
- Exported screenshots visually checked in default light and accessibility
  text/dark appearance. Long release notes scroll at the large text size.
- Independent compatibility review findings fixed and rechecked.

## Release checks

- Require passing CI on the final PR head.
- Manually review VoiceOver reading order and navigation in the consumer.
- Run on the minimum supported iOS 17 runtime/device; local runtime testing
  used iOS 18, while builds retain the iOS 17 deployment target.
- No physical-device, VoiceOver or iOS 17 runtime check is claimed.
- Create the first version tag only after release review. There are no existing
  tags to migrate. Preserve the Swift 6.2/iOS 17 requirements for this update.

The original project history and MIT licence are unchanged.
