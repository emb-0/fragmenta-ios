import Foundation

struct ImportRequest: Codable, Hashable, Sendable {
    enum Source: String, Codable, Sendable {
        case kindleText = "kindle_txt"
    }

    let source: Source
    let rawText: String
    let filename: String?
    let dryRun: Bool
}
