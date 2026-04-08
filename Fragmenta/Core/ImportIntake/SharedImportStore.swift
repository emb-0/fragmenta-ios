import Foundation

actor SharedImportStore {
    enum StoreError: LocalizedError {
        case missingAppGroup
        case unavailableContainer(String)

        var errorDescription: String? {
            switch self {
            case .missingAppGroup:
                return "Set FRAGMENTA_APP_GROUP_IDENTIFIER before using shared ingest."
            case .unavailableContainer(let identifier):
                return "The shared container for \(identifier) is unavailable."
            }
        }
    }

    private enum Constants {
        static let directoryName = "IncomingImports"
        static let pendingDraftFilename = "pending-import-draft.json"
    }

    private let fileManager: FileManager
    private let directoryURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let appGroupIdentifier: String?

    init(
        fileManager: FileManager = .default,
        appGroupIdentifier: String?
    ) {
        self.fileManager = fileManager
        self.appGroupIdentifier = appGroupIdentifier?.trimmed.nilIfBlank
        self.encoder = JSONEncoder.fragmenta
        self.decoder = JSONDecoder.fragmenta

        if
            let appGroupIdentifier = self.appGroupIdentifier,
            let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        {
            let directoryURL = containerURL.appendingPathComponent(Constants.directoryName, isDirectory: true)
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            self.directoryURL = directoryURL
        } else {
            self.directoryURL = nil
        }
    }

    func loadPendingDraft() -> IncomingImportDraft? {
        guard let draftURL = try? pendingDraftURL() else {
            return nil
        }

        guard
            fileManager.fileExists(atPath: draftURL.path),
            let data = try? Data(contentsOf: draftURL),
            let draft = try? decoder.decode(IncomingImportDraft.self, from: data)
        else {
            return nil
        }

        return draft
    }

    func save(_ draft: IncomingImportDraft) throws {
        let draftURL = try pendingDraftURL()
        let data = try encoder.encode(draft)
        try data.write(to: draftURL, options: .atomic)
    }

    func clearPendingDraft() throws {
        guard let draftURL = try? pendingDraftURL() else {
            return
        }

        guard fileManager.fileExists(atPath: draftURL.path) else {
            return
        }

        try fileManager.removeItem(at: draftURL)
    }

    private func pendingDraftURL() throws -> URL {
        guard let appGroupIdentifier else {
            throw StoreError.missingAppGroup
        }

        guard let directoryURL else {
            throw StoreError.unavailableContainer(appGroupIdentifier)
        }

        return directoryURL.appendingPathComponent(Constants.pendingDraftFilename)
    }
}

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
