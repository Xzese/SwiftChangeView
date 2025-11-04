# ChangeView

A lightweight SwiftUI component for displaying **“What’s New”** and **Changelog** screens in your app, using a simple JSON file as the data source.

---

## Overview

The package provides two views:

1. **`WhatsNewView`**  
   Displays the latest version's release notes in a modal sheet when users update the app.

2. **`ChangelogScreen`**  
   Displays the full changelog in a scrollable, sectioned list (perfect for embedding in Settings or an About screen).

---

## Installation

1. Add the package to your project (local or remote).  
2. Import the library where needed:

   ```swift
   import ChangeView
   ```
3. Make sure your main app target includes a changelog.json file in the app bundle.


## Usage

### Showing the “What’s New” prompt automatically

To present WhatsNewView automatically after a new app update:

```swift
@AppStorage("lastSeenVersion") private var lastSeenVersion = ""
@State private var showWhatsNew = false

private var currentVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
}

var body: some View {
    // Your main app view
    ContentView()
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView(
                onDismiss: {
                    showWhatsNew = false
                    lastSeenVersion = currentVersion
                },
                lastSeenVersion: lastSeenVersion,
                tintColor: Helper.appTintColor()
            )
            .presentationDetents([.fraction(0.7), .large])
        }
        .onAppear {
            if compareVersionStrings(lastSeenVersion, currentVersion) {
                showWhatsNew = true
            }
        }
}
```

This compares the stored version with the current app version using compareVersionStrings().
If the current version is newer, the What’s New screen automatically appears.

Make sure you pass lastSeenVersion into the WhatsNewView so it knows which entries to display.

### Adding a Changelog section to Settings

You can embed the full changelog anywhere in your app — for example, in a Settings or About screen:

```
NavigationLink(destination: ChangelogScreen(onDismiss: { dismiss() })) {
    Label("Changelog", systemImage: "text.page.fill")
        .foregroundStyle(.primary)
}
```

This presents a navigable list of all past updates.

## JSON Format

Your app must include a changelog.json file in the main bundle, following this structure:

```swift
[
  {
    "version": "1.0.0",
    "title": "Initial Release",
    "changes": [
      {
        "title": "App Launch",
        "description": "The first release of your app — providing a fast, private, and intuitive experience with all core features available."
      }
    ]
  },
  {
    "version": "1.1.0",
    "title": "Feature and Stability Improvements",
    "changes": [
      {
        "title": "New Feature",
        "description": "Introduced a new feature to enhance functionality and improve the overall user experience."
      },
      {
        "title": "Visual Enhancements",
        "description": "Updated layouts, icons, and animations for a more polished and modern look."
      },
      {
        "title": "Performance Improvements",
        "description": "Optimised loading times and responsiveness across the app."
      },
      {
        "title": "Bug Fixes",
        "description": "Resolved various issues to ensure smoother operation."
      }
    ]
  }
]
```

## Customisation

- **Tint Colour**  
  You can pass a custom accent color when presenting the `WhatsNewView`:

  ```swift
  WhatsNewView(onDismiss: { ... }, tintColor: .blue)
  ```

- **Layout Adjustments**  
  Both views use SwiftUI and support dynamic type, dark mode, and system appearance automatically.

---

## Utility Functions

The package includes a helper for safely comparing semantic version strings:

```swift
/// Returns true if `lhs` < `rhs`
public func compareVersionStrings(_ lhs: String, _ rhs: String) -> Bool
```

## 🧰 Requirements

- iOS 17.0+  
- Swift 6.2+  
- SwiftUI framework

---

## ⚙️ License

Free for personal and commercial use.  
Attribution is appreciated but not required.

---

**ChangelogView** makes it easy to show users what’s new — automatically and consistently, every release.
