import Foundation

struct BookCover: Codable, Hashable, Sendable {
    let thumbnailURL: URL?
    let mediumURL: URL?
    let largeURL: URL?
    let backgroundHex: String?
    let foregroundHex: String?
    let width: Double?
    let height: Double?
    let source: String?

    init(
        thumbnailURL: URL? = nil,
        mediumURL: URL? = nil,
        largeURL: URL? = nil,
        backgroundHex: String? = nil,
        foregroundHex: String? = nil,
        width: Double? = nil,
        height: Double? = nil,
        source: String? = nil
    ) {
        self.thumbnailURL = thumbnailURL
        self.mediumURL = mediumURL
        self.largeURL = largeURL
        self.backgroundHex = backgroundHex?.trimmed.nilIfBlank
        self.foregroundHex = foregroundHex?.trimmed.nilIfBlank
        self.width = width
        self.height = height
        self.source = source?.trimmed.nilIfBlank
    }

    init(from decoder: Decoder) throws {
        let singleValue = try? decoder.singleValueContainer()
        if let url = try? singleValue?.decode(URL.self) {
            self.init(mediumURL: url)
            return
        }

        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.init(
            thumbnailURL: try container.decodeFirstPresent(URL.self, keys: ["thumbnail_url", "thumb_url", "small_url", "small", "thumbnail"]),
            mediumURL: try container.decodeFirstPresent(URL.self, keys: ["medium_url", "url", "image_url", "cover_url"]),
            largeURL: try container.decodeFirstPresent(URL.self, keys: ["large_url", "full_url", "high_res_url", "hd_url"]),
            backgroundHex: try container.decodeFirstPresent(String.self, keys: ["background_hex", "dominant_hex", "color_hex"]),
            foregroundHex: try container.decodeFirstPresent(String.self, keys: ["foreground_hex", "text_hex"]),
            width: try container.decodeFirstPresent(Double.self, keys: ["width"]),
            height: try container.decodeFirstPresent(Double.self, keys: ["height"]),
            source: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("source"))
        )
    }

    var shelfURL: URL? {
        thumbnailURL ?? mediumURL ?? largeURL
    }

    var detailURL: URL? {
        largeURL ?? mediumURL ?? thumbnailURL
    }

    var hasRemoteImage: Bool {
        shelfURL != nil || detailURL != nil
    }

    var resolvedAspectRatio: Double {
        guard let width, let height, width > 0, height > 0 else {
            return 0.67
        }

        return width / height
    }

    static func resolve(from container: KeyedDecodingContainer<AnyCodingKey>) throws -> BookCover? {
        if let nestedCover = try container.decodeFirstPresent(BookCover.self, keys: ["cover", "cover_art", "cover_image"]) {
            return nestedCover
        }

        if let enrichment = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: AnyCodingKey("enrichment")) {
            if let nestedCover = try enrichment.decodeFirstPresent(BookCover.self, keys: ["cover", "cover_art", "cover_image"]) {
                return nestedCover
            }

            if let cover = try partialCover(from: enrichment) {
                return cover
            }
        }

        return try partialCover(from: container)
    }

    private static func partialCover(from container: KeyedDecodingContainer<AnyCodingKey>) throws -> BookCover? {
        let thumbnailURL = try container.decodeFirstPresent(
            URL.self,
            keys: ["cover_thumbnail_url", "thumbnail_url", "thumbnail", "cover_thumb_url", "image_thumbnail_url"]
        )
        let mediumURL = try container.decodeFirstPresent(
            URL.self,
            keys: ["cover_url", "cover_image_url", "image_url", "cover_medium_url", "image"]
        )
        let largeURL = try container.decodeFirstPresent(
            URL.self,
            keys: ["cover_large_url", "cover_full_url", "large_image_url", "cover_high_res_url", "full_image_url"]
        )
        let backgroundHex = try container.decodeFirstPresent(
            String.self,
            keys: ["cover_background_hex", "background_hex", "cover_dominant_hex", "dominant_hex"]
        )
        let foregroundHex = try container.decodeFirstPresent(
            String.self,
            keys: ["cover_foreground_hex", "foreground_hex", "cover_text_hex", "text_hex"]
        )
        let width = try container.decodeFirstPresent(Double.self, keys: ["cover_width", "width"])
        let height = try container.decodeFirstPresent(Double.self, keys: ["cover_height", "height"])
        let source = try container.decodeFirstPresent(String.self, keys: ["cover_source", "source"])

        guard
            thumbnailURL != nil
                || mediumURL != nil
                || largeURL != nil
                || backgroundHex?.isBlank == false
                || foregroundHex?.isBlank == false
                || width != nil
                || height != nil
        else {
            return nil
        }

        return BookCover(
            thumbnailURL: thumbnailURL,
            mediumURL: mediumURL,
            largeURL: largeURL,
            backgroundHex: backgroundHex,
            foregroundHex: foregroundHex,
            width: width,
            height: height,
            source: source
        )
    }
}

struct Book: Codable, Identifiable, Hashable, Sendable {
    enum Source: String, Codable, CaseIterable, Sendable {
        case kindleExport = "kindle_export"
        case manualImport = "manual_import"
        case unknown

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            switch rawValue {
            case "kindle_export", "kindle_txt", "kindle_text", "kindle_notebook":
                self = .kindleExport
            case "manual_import":
                self = .manualImport
            default:
                self = .unknown
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    let id: String
    let title: String
    let author: String?
    let source: Source
    let highlightCount: Int
    let noteCount: Int?
    let cover: BookCover?
    let synopsis: String?
    let lastImportedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    init(
        id: String,
        title: String,
        author: String?,
        source: Source,
        highlightCount: Int,
        noteCount: Int?,
        cover: BookCover? = nil,
        coverURL: URL? = nil,
        synopsis: String?,
        lastImportedAt: Date?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.source = source
        self.highlightCount = highlightCount
        self.noteCount = noteCount
        self.cover = cover ?? coverURL.map { BookCover(mediumURL: $0) }
        self.synopsis = synopsis
        self.lastImportedAt = lastImportedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        self.init(
            id: try container.decode(String.self, forKey: AnyCodingKey("id")),
            title: try container.decodeFirstPresent(String.self, keys: ["title", "canonical_title", "name"]) ?? "Untitled",
            author: try container.decodeFirstPresent(String.self, keys: ["author", "canonical_author"]),
            source: try container.decodeFirstPresent(Source.self, keys: ["source", "source_type"]) ?? .unknown,
            highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights_count"]) ?? 0,
            noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes_count"]),
            cover: try BookCover.resolve(from: container),
            synopsis: try container.decodeFirstPresent(String.self, keys: ["synopsis", "description", "subtitle"]),
            lastImportedAt: try container.decodeFirstPresent(Date.self, keys: ["last_imported_at", "first_imported_at"]),
            createdAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at")),
            updatedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("updated_at"))
        )
    }

    var coverURL: URL? {
        cover?.detailURL
    }

    var coverThumbnailURL: URL? {
        cover?.shelfURL
    }

    var hasCoverArt: Bool {
        cover?.hasRemoteImage == true
    }

    var resolvedCoverAspectRatio: Double {
        cover?.resolvedAspectRatio ?? 0.67
    }

    var displayAuthor: String {
        let trimmedAuthor = author?.trimmed ?? ""
        return trimmedAuthor.isEmpty ? "Unknown author" : trimmedAuthor
    }

    var highlightCountLabel: String {
        highlightCount == 1 ? "1 highlight" : "\(highlightCount) highlights"
    }

    var noteCountLabel: String? {
        guard let noteCount else {
            return nil
        }

        return noteCount == 1 ? "1 note" : "\(noteCount) notes"
    }

    var isRecentlyImported: Bool {
        guard let lastImportedAt else {
            return false
        }

        return lastImportedAt > Date().addingTimeInterval(-86_400 * 10)
    }
}

struct BookReference: Codable, Hashable, Sendable {
    let id: String
    let title: String
    let author: String?

    init(id: String, title: String, author: String?) {
        self.id = id
        self.title = title
        self.author = author
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.init(
            id: try container.decode(String.self, forKey: AnyCodingKey("id")),
            title: try container.decodeFirstPresent(String.self, keys: ["title", "canonical_title", "name"]) ?? "Untitled",
            author: try container.decodeFirstPresent(String.self, keys: ["author", "canonical_author"])
        )
    }

    var displayAuthor: String {
        let trimmedAuthor = author?.trimmed ?? ""
        return trimmedAuthor.isEmpty ? "Unknown author" : trimmedAuthor
    }
}

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
