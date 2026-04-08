import Foundation

enum ContentSource: Hashable {
    case cache
    case remote
}

enum LoadableState<Value> {
    case idle
    case loading(previous: Value? = nil)
    case loaded(Value, source: ContentSource = .remote)
    case failed(String, previous: Value? = nil)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var value: Value? {
        switch self {
        case .idle:
            return nil
        case .loading(let previous):
            return previous
        case .loaded(let value, _):
            return value
        case .failed(_, let previous):
            return previous
        }
    }

    var source: ContentSource? {
        if case .loaded(_, let source) = self {
            return source
        }

        return nil
    }
}
