import Foundation

final class AppPreferencesStore {
    private enum Key {
        static let developmentBaseURLOverride = "fragmenta.preferences.developmentBaseURLOverride"
        static let recentSearches = "fragmenta.preferences.recentSearches"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var developmentBaseURLOverride: String? {
        get {
            defaults.string(forKey: Key.developmentBaseURLOverride)
        }
        set {
            defaults.setValue(newValue, forKey: Key.developmentBaseURLOverride)
        }
    }

    func recentSearches(limit: Int = 8) -> [String] {
        let searches = defaults.stringArray(forKey: Key.recentSearches) ?? []
        return Array(searches.prefix(limit))
    }

    func saveRecentSearch(_ query: String, limit: Int = 8) {
        let trimmed = query.trimmed
        guard trimmed.isEmpty == false else {
            return
        }

        var searches = recentSearches(limit: limit)
        searches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        searches.insert(trimmed, at: 0)
        defaults.setValue(Array(searches.prefix(limit)), forKey: Key.recentSearches)
    }

    func clearRecentSearches() {
        defaults.removeObject(forKey: Key.recentSearches)
    }
}
