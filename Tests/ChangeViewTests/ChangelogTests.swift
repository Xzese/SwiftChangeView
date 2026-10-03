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
        XCTAssertEqual(entry("1.0").id, "1.0")
    }

    func testLegacyJSONWithoutIDsStillDecodes() throws {
        let data = Data(#"[{"version":"1.0","title":"Release","changes":[{"title":"A","description":"B"}]}]"#.utf8)
        let entries = try Changelog.decode(data)
        XCTAssertEqual(entries[0].changes[0].id, entries[0].changes[0].id)
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
        XCTAssertFalse(compareVersionStrings("1.beta", "2"))
    }

    func testFutureVersionsAreExcludedOnFirstLaunch() throws {
        XCTAssertEqual(try Changelog.entriesToShow([entry("1"), entry("3"), entry("2")], lastSeenVersion: nil, currentVersion: "2").map(\.version), ["2", "1"])
    }

    func testSeenAndInstalledBounds() throws {
        let entries = [entry("1"), entry("2"), entry("3")]
        XCTAssertEqual(try Changelog.entriesToShow(entries, lastSeenVersion: "1", currentVersion: "2").map(\.version), ["2"])
        XCTAssertTrue(try Changelog.entriesToShow(entries, lastSeenVersion: "3", currentVersion: "2").isEmpty)
    }

    func testDuplicateVersionsAndChangeIDsAreRejected() {
        XCTAssertThrowsError(try Changelog.validate([entry("1"), entry("1.0")]))
        let change = ChangeItem(title: "A", description: "B")
        XCTAssertThrowsError(try Changelog.validate([VersionEntry(version: "1", title: "A", changes: [change, change])]))
    }

    func testMalformedAndEmptyDataAreDifferent() throws {
        XCTAssertThrowsError(try Changelog.decode(Data("not json".utf8)))
        XCTAssertEqual(try Changelog.decode(Data("[]".utf8)), [])
    }
}
