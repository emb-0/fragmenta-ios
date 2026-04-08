import Foundation

struct ImportRequest: Encodable, Hashable, Sendable {
    enum Source: String, Codable, Sendable {
        case kindleText = "kindle_txt"
    }

    let source: Source
    let rawText: String
    let filename: String?
    let dryRun: Bool

    enum CodingKeys: String, CodingKey {
        case source
        case text
        case filename
        case dryRun = "dry_run"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(rawText, forKey: .text)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encode(dryRun, forKey: .dryRun)
    }
}
