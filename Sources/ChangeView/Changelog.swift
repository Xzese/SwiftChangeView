import Foundation

public struct ChangeItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String

    public init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }

    private enum CodingKeys: String, CodingKey { case id, title, description }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        description = try values.decode(String.self, forKey: .description)
    }
}

public struct VersionEntry: Codable, Identifiable, Equatable, Sendable {
    public var id: String { version }
    public let version: String
    public let title: String
    public let changes: [ChangeItem]

    public init(version: String, title: String, changes: [ChangeItem]) {
        self.version = version
        self.title = title
        self.changes = changes
    }
}

public enum ChangelogError: Error, Equatable {
    case missingResource
    case invalidVersion(String)
    case duplicateVersion(String)
    case duplicateChangeID(String)
}

/// Numeric application versions only. Prerelease and build suffixes are rejected.
public struct AppVersion: Comparable, Hashable, Sendable {
    private let parts: [Int]

    public init(_ value: String) throws {
        let pieces = value.split(separator: ".", omittingEmptySubsequences: false)
        guard !value.isEmpty,
              pieces.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy({ (48...57).contains($0) }) })
        else { throw ChangelogError.invalidVersion(value) }
        let numbers = pieces.compactMap { Int($0) }
        guard numbers.count == pieces.count else { throw ChangelogError.invalidVersion(value) }
        var normalized = numbers
        while normalized.count > 1 && normalized.last == 0 { normalized.removeLast() }
        parts = normalized
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        for i in 0..<max(lhs.parts.count, rhs.parts.count) {
            let left = i < lhs.parts.count ? lhs.parts[i] : 0
            let right = i < rhs.parts.count ? rhs.parts[i] : 0
            if left != right { return left < right }
        }
        return false
    }
}

/// Compatibility helper. An empty last-seen value means version zero.
/// Invalid non-empty input returns false; use AppVersion for throwing validation.
public func compareVersionStrings(_ lhs: String, _ rhs: String) -> Bool {
    guard let left = try? AppVersion(lhs.isEmpty ? "0" : lhs),
          let right = try? AppVersion(rhs) else { return false }
    return left < right
}

public enum Changelog {
    public static func decode(_ data: Data) throws -> [VersionEntry] {
        try validate(JSONDecoder().decode([VersionEntry].self, from: data))
    }

    public static func load(bundle: Bundle = .main) throws -> [VersionEntry] {
        guard let url = bundle.url(forResource: "changelog", withExtension: "json")
        else { throw ChangelogError.missingResource }
        return try decode(Data(contentsOf: url))
    }

    public static func validate(_ entries: [VersionEntry]) throws -> [VersionEntry] {
        var versions = Set<AppVersion>()
        for entry in entries {
            let version = try AppVersion(entry.version)
            guard versions.insert(version).inserted
            else { throw ChangelogError.duplicateVersion(entry.version) }
            guard Set(entry.changes.map(\.id)).count == entry.changes.count
            else { throw ChangelogError.duplicateChangeID(entry.version) }
        }
        return entries.sorted { compareVersionStrings($1.version, $0.version) }
    }

    public static func entriesToShow(
        _ entries: [VersionEntry], lastSeenVersion: String?, currentVersion: String
    ) throws -> [VersionEntry] {
        let current = try AppVersion(currentVersion)
        let last = try lastSeenVersion.flatMap { $0.isEmpty ? nil : try AppVersion($0) }
        return try validate(entries).filter {
            let version = try AppVersion($0.version)
            return version <= current && (last.map { version > $0 } ?? true)
        }
    }
}
