import Foundation
import XCTest
import ChangeView

final class ChangelogTests: XCTestCase {
    func entry(_ version: String) -> VersionEntry {
        VersionEntry(version: version, title: "Release", changes: [ChangeItem(title: "Change", description: "Details")])
    }

    func testPublicModelsHaveStableIdentity() throws {
        let item = ChangeItem(title: "A", description: "B")
        XCTAssertEqual(item.id, item.id)
        XCTAssertEqual(try JSONDecoder().decode(ChangeItem.self, from: JSONEncoder().encode(item)), item)
        let release = entry("1.0")
        let legacyID: UUID = release.id
        XCTAssertEqual(release.id, legacyID)
        XCTAssertEqual(try JSONDecoder().decode(VersionEntry.self, from: JSONEncoder().encode(release)), release)
    }

    func testLegacyJSONWithoutIDsStillDecodes() throws {
        let data = Data(#"[{"version":"1.0","title":"Release","changes":[{"title":"A","description":"B"}]}]"#.utf8)
        let entries = try Changelog.decode(data)
        XCTAssertEqual(entries[0].changes[0].id, entries[0].changes[0].id)
        let id: UUID = entries[0].id
        XCTAssertEqual(entries[0].id, id)
        XCTAssertEqual(entries[0].version, "1.0")
        let metadata = Data(#"[{"id":42,"version":"1.0","title":"Release","changes":[{"id":"legacy-slug","title":"A","description":"B"}]}]"#.utf8)
        XCTAssertEqual(try Changelog.decode(metadata)[0].version, "1.0")
    }

    func testNumericOrderingAndEquality() throws {
        XCTAssertTrue(compareVersionStrings("1.0.9", "1.0.10"))
        XCTAssertEqual(try AppVersion("1.0"), try AppVersion("1.0.0"))
        XCTAssertFalse(compareVersionStrings("1.0.0", "1"))
        XCTAssertTrue(compareVersionStrings("", "1.0"))
    }

    func testInvalidVersionsAreRejected() {
        for version in ["", "1..0", "1.-1", "1.0-beta", "1.0+build", " 1.0", "1.a", "999999999999999999999999999999"] {
            XCTAssertThrowsError(try AppVersion(version), version)
        }
        // The existing helper remains permissive; the new parser is strict.
        XCTAssertTrue(compareVersionStrings("1.beta", "2"))
        XCTAssertTrue(compareVersionStrings("1..0", "1.1"))
        XCTAssertTrue(compareVersionStrings("-1", "0"))
        XCTAssertFalse(compareVersionStrings("1", ""))
    }

    func testFutureVersionsAreExcludedOnFirstLaunch() throws {
        XCTAssertEqual(try Changelog.entriesToShow([entry("1"), entry("3"), entry("2")], lastSeenVersion: nil, currentVersion: "2").map(\.version), ["2", "1"])
    }

    func testSeenAndInstalledBounds() throws {
        let entries = [entry("1"), entry("2"), entry("3")]
        XCTAssertEqual(try Changelog.entriesToShow(entries, lastSeenVersion: "1", currentVersion: "2").map(\.version), ["2"])
        XCTAssertTrue(try Changelog.entriesToShow(entries, lastSeenVersion: "3", currentVersion: "2").isEmpty)
        XCTAssertEqual(try Changelog.entriesToShow(entries, lastSeenVersion: "1.5", currentVersion: "2").map(\.version), ["2"])
        for firstLaunch in [nil, "", "0"] as [String?] {
            XCTAssertEqual(try Changelog.entriesToShow(entries, lastSeenVersion: firstLaunch, currentVersion: "2").map(\.version), ["2", "1"])
        }
        XCTAssertThrowsError(try Changelog.entriesToShow(entries, lastSeenVersion: "invalid", currentVersion: "2"))
    }

    func testDuplicateVersionsAndChangeIDsAreRejected() {
        XCTAssertThrowsError(try Changelog.validate([entry("1"), entry("1.0")]))
        let id = UUID()
        XCTAssertThrowsError(try Changelog.validate([
            VersionEntry(version: "1", title: "A", changes: [], id: id),
            VersionEntry(version: "2", title: "B", changes: [], id: id)
        ]))
        let change = ChangeItem(title: "A", description: "B")
        XCTAssertThrowsError(try Changelog.validate([VersionEntry(version: "1", title: "A", changes: [change, change])]))
    }

    func testCompatibleSelectionAcceptsLegacyVersionsAndStrictSelectionRejectsThem() throws {
        let entries = [entry("1.0-beta"), entry("2"), entry("3")]
        XCTAssertThrowsError(try Changelog.entriesToShow(entries, lastSeenVersion: nil, currentVersion: "2"))
        XCTAssertEqual(try Changelog.entriesToShow(entries, lastSeenVersion: "", currentVersion: "2",
                                                  validation: .compatible).map(\.version), ["2", "1.0-beta"])
        let data = try JSONEncoder().encode(entries)
        XCTAssertEqual(try Changelog.decode(data, validation: .compatible).map(\.version), ["3", "2", "1.0-beta"])
    }

    func testMalformedAndEmptyDataAreDifferent() throws {
        XCTAssertThrowsError(try Changelog.decode(Data("not json".utf8)))
        XCTAssertEqual(try Changelog.decode(Data("[]".utf8)), [])
    }
}
