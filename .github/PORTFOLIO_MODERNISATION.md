# Package modernisation

Placeholder for finishing SwiftChangeView as a small, polished reusable Swift package.

## Scope
- Replace computed random UUID identities with stable model identity.
- Define a deliberate public model API, including public construction where appropriate.
- Remove duplicated version comparison logic.
- Define and test the supported version-format contract, including prerelease behaviour if supported.
- Ensure What's New only shows entries newer than the last seen version and not newer than the installed app version.
- Apply the supplied tint configuration or remove unsupported API surface.
- Distinguish empty changelog data from malformed/loading failures.
- Extract repeated release-card presentation without over-engineering the package.
- Improve accessibility and Dynamic Type behaviour.
- Add a SwiftPM test target and CI.
- Add a separate example consumer that imports the package through its public API.
- Refresh README examples and add screenshots/tagged release guidance.

## Portfolio outcome
Produce a compact library with a clear public contract, stable behaviour, tests and a working external integration example.

No implementation is included in this placeholder PR.