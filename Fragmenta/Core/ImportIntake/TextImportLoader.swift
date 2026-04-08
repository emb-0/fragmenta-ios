import Foundation

enum TextImportLoader {
    enum LoaderError: LocalizedError {
        case unreadable
        case undecodable
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "The selected file could not be opened."
            case .undecodable:
                return "The selected file could not be decoded as text."
            case .emptyContent:
                return "The selected text is empty."
            }
        }
    }

    static func draft(
        from url: URL,
        source: IncomingImportDraft.Source,
        accessSecurityScopedResource: Bool = true
    ) throws -> IncomingImportDraft {
        let didStartSecurityScope = accessSecurityScopedResource && url.startAccessingSecurityScopedResource()
        defer {
            if didStartSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoaderError.unreadable
        }

        guard let rawText = decodeText(from: data) else {
            throw LoaderError.undecodable
        }

        guard rawText.trimmed.isEmpty == false else {
            throw LoaderError.emptyContent
        }

        return IncomingImportDraft(
            source: source,
            filename: url.lastPathComponent,
            rawText: rawText,
            byteCount: data.count
        )
    }

    static func draft(
        from rawText: String,
        filename: String? = nil,
        source: IncomingImportDraft.Source
    ) throws -> IncomingImportDraft {
        guard rawText.trimmed.isEmpty == false else {
            throw LoaderError.emptyContent
        }

        return IncomingImportDraft(
            source: source,
            filename: filename,
            rawText: rawText
        )
    }

    private static func decodeText(from data: Data) -> String? {
        let candidateEncodings: [String.Encoding] = [.utf8, .utf16, .unicode, .ascii, .windowsCP1252]

        for encoding in candidateEncodings {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }

        return nil
    }
}
