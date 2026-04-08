import Foundation

struct AppConfig: Hashable, Sendable {
    let apiBaseURL: URL
    let defaultAPIBaseURL: URL
    let requestTimeout: TimeInterval
    let appDisplayName: String
    let appVersion: String
    let buildNumber: String
    let appGroupIdentifier: String?

    static func live(
        bundle: Bundle = .main,
        baseURLOverride: String? = nil
    ) -> AppConfig {
        guard
            let rawBaseURL = bundle.object(forInfoDictionaryKey: "FragmentaAPIBaseURL") as? String,
            let defaultAPIBaseURL = URL(string: rawBaseURL)
        else {
            fatalError("Missing FragmentaAPIBaseURL. Set FRAGMENTA_API_BASE_URL in Config/*.xcconfig.")
        }

        let resolvedAPIBaseURL: URL
        if
            let baseURLOverride,
            baseURLOverride.isBlank == false,
            let overrideURL = URL(string: baseURLOverride)
        {
            resolvedAPIBaseURL = overrideURL
        } else {
            resolvedAPIBaseURL = defaultAPIBaseURL
        }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Fragmenta"
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let appGroupIdentifier = (bundle.object(forInfoDictionaryKey: "FragmentaAppGroupIdentifier") as? String)?.trimmed
        let resolvedAppGroupIdentifier = appGroupIdentifier?.isEmpty == false ? appGroupIdentifier : nil

        return AppConfig(
            apiBaseURL: resolvedAPIBaseURL,
            defaultAPIBaseURL: defaultAPIBaseURL,
            requestTimeout: 20,
            appDisplayName: displayName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            appGroupIdentifier: resolvedAppGroupIdentifier
        )
    }
}
