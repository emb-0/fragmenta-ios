import Foundation

struct AppConfig: Hashable, Sendable {
    let apiBaseURL: URL
    let requestTimeout: TimeInterval
    let appDisplayName: String

    static func live(bundle: Bundle = .main) -> AppConfig {
        guard
            let rawBaseURL = bundle.object(forInfoDictionaryKey: "FragmentaAPIBaseURL") as? String,
            let apiBaseURL = URL(string: rawBaseURL)
        else {
            fatalError("Missing FragmentaAPIBaseURL. Set FRAGMENTA_API_BASE_URL in Config/*.xcconfig.")
        }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Fragmenta"

        return AppConfig(
            apiBaseURL: apiBaseURL,
            requestTimeout: 20,
            appDisplayName: displayName
        )
    }
}
