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
        // Older decoders ignored id metadata of any type.
        id = (try? values.decode(UUID.self, forKey: .id)) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        description = try values.decode(String.self, forKey: .description)
    }
}

public struct VersionEntry: Codable, Identifiable, Equatable, Sendable {
    /// Stored identity preserves the original public UUID type.
    public let id: UUID
    public let version: String
    public let title: String
    public let changes: [ChangeItem]

    public init(version: String, title: String, changes: [ChangeItem], id: UUID = UUID()) {
        self.id = id
        self.version = version
        self.title = title
        self.changes = changes
    }

    private enum CodingKeys: String, CodingKey { case id, version, title, changes }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // Older decoders ignored id metadata of any type.
        id = (try? values.decode(UUID.self, forKey: .id)) ?? UUID()
        version = try values.decode(String.self, forKey: .version)
        title = try values.decode(String.self, forKey: .title)
        changes = try values.decode([ChangeItem].self, forKey: .changes)
    }
}

public enum ChangelogError: Error, Equatable {
    case missingResource
    case invalidVersion(String)
    case duplicateVersion(String)
    case duplicateReleaseID
    case duplicateChangeID(String)
}

public enum ChangelogValidation: Sendable {
    /// Retains the original views' permissive numeric-component parsing.
    case compatible
    /// Rejects malformed versions, equivalent releases and duplicate IDs.
    case strict
}

/// Numeric application versions only. Prerelease and build suffixes are rejected.
public struct AppVersion: Comparable, Hashable, Sendable {
    private let parts: [Int]

    // The original helper skipped components Int could not parse. Keep its
    // parsing contract separate from validation, sharing the ordering below.
    fileprivate init(legacy value: String) {
        parts = value.split(separator: ".").compactMap { Int($0) }
    }

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

/// Returns true if lhs < rhs, preserving the original permissive parsing.
/// Empty input compares as zero; unparseable components are skipped.
/// Use AppVersion or Changelog for strict numeric-version validation.
public func compareVersionStrings(_ lhs: String, _ rhs: String) -> Bool {
    AppVersion(legacy: lhs) < AppVersion(legacy: rhs)
}

public enum Changelog {
    public static func decode(_ data: Data, validation: ChangelogValidation = .strict) throws -> [VersionEntry] {
        try prepare(JSONDecoder().decode([VersionEntry].self, from: data), validation: validation)
    }

    public static func load(bundle: Bundle = .main, validation: ChangelogValidation = .strict) throws -> [VersionEntry] {
        guard let url = bundle.url(forResource: "changelog", withExtension: "json")
        else { throw ChangelogError.missingResource }
        return try decode(Data(contentsOf: url), validation: validation)
    }

    static func prepare(_ entries: [VersionEntry], validation: ChangelogValidation) throws -> [VersionEntry] {
        switch validation {
        case .strict: return try validate(entries)
        case .compatible: return entries.sorted { compareVersionStrings($1.version, $0.version) }
        }
    }

    public static func validate(_ entries: [VersionEntry]) throws -> [VersionEntry] {
        var versions = Set<AppVersion>()
        var releaseIDs = Set<UUID>()
        for entry in entries {
            let version = try AppVersion(entry.version)
            guard versions.insert(version).inserted
            else { throw ChangelogError.duplicateVersion(entry.version) }
            guard releaseIDs.insert(entry.id).inserted
            else { throw ChangelogError.duplicateReleaseID }
            guard Set(entry.changes.map(\.id)).count == entry.changes.count
            else { throw ChangelogError.duplicateChangeID(entry.version) }
        }
        return entries.sorted { compareVersionStrings($1.version, $0.version) }
    }

    public static func entriesToShow(
        _ entries: [VersionEntry], lastSeenVersion: String?, currentVersion: String,
        validation: ChangelogValidation = .strict
    ) throws -> [VersionEntry] {
        if validation == .strict {
            _ = try AppVersion(currentVersion)
            if let lastSeenVersion, !lastSeenVersion.isEmpty { _ = try AppVersion(lastSeenVersion) }
        }
        // "0" was also used as a first-launch sentinel by the original views.
        let last = lastSeenVersion.flatMap { $0.isEmpty || $0 == "0" ? nil : $0 }
        return try prepare(entries, validation: validation).filter { entry in
            !compareVersionStrings(currentVersion, entry.version)
                && (last.map { compareVersionStrings($0, entry.version) } ?? true)
        }
    }
}
