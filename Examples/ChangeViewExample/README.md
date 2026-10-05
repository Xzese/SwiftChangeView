# External consumer example

Open `ChangeViewExample.xcodeproj` in Xcode 26 or later and run the
`ChangeViewExample` scheme on an iPhone simulator. The app imports the public
`ChangeView` product through a local Swift package reference; it does not copy
library sources or use `@testable`.

Its own bundled `changelog.json` and `CFBundleShortVersionString` exercise the
original initializer calls. What's New shows only release 1.1 after last-seen
1.0, while the full changelog includes future release 1.2. Dismissing the sheet
(including swiping it down) stores 1.1. Delete the app to reset the saved state,
or pass `--reset-state` in the scheme's launch arguments.

The Changelog link uses `embedsInNavigationStack: false` to keep the app's back
navigation. Empty and invalid data can be inspected from the main screen.
Pass `--large-text` to preview an accessibility Dynamic Type size and
`--dark` to force dark appearance, including in sheets.

Run its two UI journeys from Xcode's Test action or:

```sh
xcodebuild -project Examples/ChangeViewExample/ChangeViewExample.xcodeproj \
  -scheme ChangeViewExample \
  -destination 'platform=iOS Simulator,name=<an installed iPhone simulator>' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

The second journey uses dark appearance and accessibility text, verifies the
Close action remains reachable, and attaches a screenshot to the test result.
These automated checks do not replace a manual VoiceOver review.
