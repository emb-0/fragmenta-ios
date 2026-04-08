import Foundation

struct IncomingImportDraft: Codable, Identifiable, Hashable, Sendable {
    enum Source: String, Codable, Hashable, Sendable {
        case pastedText = "pasted_text"
        case documentPicker = "document_picker"
        case filesApp = "files_app"
        case shareExtension = "share_extension"

        var title: String {
            switch self {
            case .pastedText:
                return "Pasted text"
            case .documentPicker:
                return "Files picker"
            case .filesApp:
                return "Files"
            case .shareExtension:
                return "Share sheet"
            }
        }

        var prefersFilePresentation: Bool {
            switch self {
            case .documentPicker, .filesApp:
                return true
            case .pastedText, .shareExtension:
                return false
            }
        }
    }

    let id: UUID
    let source: Source
    let filename: String?
    let rawText: String
    let byteCount: Int
    let receivedAt: Date

    init(
        id: UUID = UUID(),
        source: Source,
        filename: String?,
        rawText: String,
        byteCount: Int? = nil,
        receivedAt: Date = .now
    ) {
        self.id = id
        self.source = source
        self.filename = filename?.trimmed.nilIfBlank
        self.rawText = rawText
        self.byteCount = byteCount ?? rawText.lengthOfBytes(using: .utf8)
        self.receivedAt = receivedAt
    }

    var displayFilename: String {
        if let filename {
            return filename
        }

        switch source {
        case .pastedText:
            return "Pasted Kindle Export"
        case .documentPicker, .filesApp:
            return "kindle-highlights.txt"
        case .shareExtension:
            return "Shared Kindle Export"
        }
    }

    var preferredSourceMode: ImportInputMode {
        if source.prefersFilePresentation || filename != nil {
            return .file
        }

        return .paste
    }
}

enum ImportInputMode: String, Sendable {
    case paste
    case file
}

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
