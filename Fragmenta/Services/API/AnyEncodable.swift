import Foundation

struct AnyEncodable: Encodable, Sendable {
    private let encodeBody: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        self.encodeBody = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeBody(encoder)
    }
}
