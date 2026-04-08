import Foundation

enum DiagnosticEventKind: String, Codable, Hashable, Sendable {
    case library
    case search
    case importPreview = "import_preview"
    case importCommit = "import_commit"
    case exports
    case cache
}

enum DiagnosticEventStatus: String, Codable, Hashable, Sendable {
    case success
    case failure
}

struct DiagnosticEvent: Codable, Hashable, Sendable {
    let kind: DiagnosticEventKind
    let status: DiagnosticEventStatus
    let detail: String
    let recordedAt: Date
}

struct DiagnosticsSnapshot: Codable, Hashable, Sendable {
    var lastLibraryEvent: DiagnosticEvent?
    var lastSearchEvent: DiagnosticEvent?
    var lastImportPreviewEvent: DiagnosticEvent?
    var lastImportCommitEvent: DiagnosticEvent?
    var lastExportEvent: DiagnosticEvent?
    var lastCacheEvent: DiagnosticEvent?

    static let empty = DiagnosticsSnapshot()
}

final class DiagnosticsStore {
    private enum Key {
        static let snapshot = "fragmenta.diagnostics.snapshot"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            if let date = ISO8601DateFormatter().date(from: rawValue) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date.")
        }
    }

    func snapshot() -> DiagnosticsSnapshot {
        guard
            let data = defaults.data(forKey: Key.snapshot),
            let snapshot = try? decoder.decode(DiagnosticsSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }

    func record(
        event kind: DiagnosticEventKind,
        status: DiagnosticEventStatus,
        detail: String
    ) {
        var snapshot = snapshot()
        let event = DiagnosticEvent(kind: kind, status: status, detail: detail, recordedAt: .now)

        switch kind {
        case .library:
            snapshot.lastLibraryEvent = event
        case .search:
            snapshot.lastSearchEvent = event
        case .importPreview:
            snapshot.lastImportPreviewEvent = event
        case .importCommit:
            snapshot.lastImportCommitEvent = event
        case .exports:
            snapshot.lastExportEvent = event
        case .cache:
            snapshot.lastCacheEvent = event
        }

        if let data = try? encoder.encode(snapshot) {
            defaults.setValue(data, forKey: Key.snapshot)
        }
    }
}
