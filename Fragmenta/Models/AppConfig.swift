import Foundation

struct AppConfig: Hashable, Sendable {
    enum APIBaseURLSource: String, Hashable, Sendable {
        case bundledDefault
        case developmentOverride

        var title: String {
            switch self {
            case .bundledDefault:
                return "Bundled default"
            case .developmentOverride:
                return "Development override"
            }
        }
    }

    let apiBaseURL: URL
    let defaultAPIBaseURL: URL
    let apiBaseURLSource: APIBaseURLSource
    let rawDefaultAPIBaseURL: String
    let rawDevelopmentBaseURLOverride: String?
    let baseURLConfigurationIssue: String?
    let isUsingFallbackAPIBaseURL: Bool
    let requestTimeout: TimeInterval
    let appDisplayName: String
    let appVersion: String
    let buildNumber: String
    let appGroupIdentifier: String?

    static func live(
        bundle: Bundle = .main,
        baseURLOverride: String? = nil
    ) -> AppConfig {
        guard let configuredDefaultBaseURL = bundle.object(forInfoDictionaryKey: "FragmentaAPIBaseURL") as? String else {
            fatalError("Missing FragmentaAPIBaseURL. Set FRAGMENTA_API_BASE_URL in Config/*.xcconfig.")
        }

        let trimmedOverride = baseURLOverride?.trimmed.nilIfBlank
        let defaultResolution = resolveBaseURL(from: configuredDefaultBaseURL)
        let overrideResolution = trimmedOverride.map(resolveBaseURL(from:))

        let resolvedAPIBaseURL: URL
        let resolvedSource: APIBaseURLSource
        let resolvedIssue: String?
        let usingFallbackAPIBaseURL: Bool

        if let overrideURL = overrideResolution?.url {
            resolvedAPIBaseURL = overrideURL
            resolvedSource = .developmentOverride
            resolvedIssue = nil
            usingFallbackAPIBaseURL = false
        } else if let defaultAPIBaseURL = defaultResolution.url {
            resolvedAPIBaseURL = defaultAPIBaseURL
            resolvedSource = .bundledDefault
            resolvedIssue = overrideResolution?.issue ?? defaultResolution.issue
            usingFallbackAPIBaseURL = false
        } else {
            resolvedAPIBaseURL = fallbackAPIBaseURL
            resolvedSource = .bundledDefault
            resolvedIssue = overrideResolution?.issue ?? defaultResolution.issue
            usingFallbackAPIBaseURL = true
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
            defaultAPIBaseURL: defaultResolution.url ?? fallbackAPIBaseURL,
            apiBaseURLSource: resolvedSource,
            rawDefaultAPIBaseURL: configuredDefaultBaseURL,
            rawDevelopmentBaseURLOverride: trimmedOverride,
            baseURLConfigurationIssue: resolvedIssue,
            isUsingFallbackAPIBaseURL: usingFallbackAPIBaseURL,
            requestTimeout: 20,
            appDisplayName: displayName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            appGroupIdentifier: resolvedAppGroupIdentifier
        )
    }

    static func validationIssue(forBaseURLString rawValue: String) -> String? {
        resolveBaseURL(from: rawValue).issue
    }

    var baseURLConnectivityGuidance: String {
        let host = apiBaseURL.host?.lowercased() ?? ""

        if host == "127.0.0.1" || host == "localhost" {
            return "Use \(host) only for Simulator testing on this Mac mini. A physical iPhone cannot reach the Mac through localhost or 127.0.0.1."
        }

        if apiBaseURL.scheme?.lowercased() == "http" {
            return "Plain HTTP is configured. This is fine for local LAN testing if the phone and Mac mini are on the same network and fragmenta-core is running at this host."
        }

        return "This URL is suitable for Simulator and device testing as long as the deployed backend is reachable from the current network."
    }

    private static func resolveBaseURL(from rawValue: String) -> BaseURLResolution {
        let trimmed = rawValue.trimmed

        guard trimmed.isEmpty == false else {
            return BaseURLResolution(
                url: nil,
                issue: "The backend base URL is empty. Set FRAGMENTA_API_BASE_URL to an absolute http or https URL."
            )
        }

        guard var components = URLComponents(string: trimmed) else {
            return BaseURLResolution(
                url: nil,
                issue: "The backend base URL “\(trimmed)” could not be parsed. Use a full URL such as http://127.0.0.1:3000 or https://api.example.com."
            )
        }

        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return BaseURLResolution(
                url: nil,
                issue: "The backend base URL “\(trimmed)” must include an http:// or https:// scheme."
            )
        }

        guard let host = components.host?.trimmed, host.isEmpty == false else {
            return BaseURLResolution(
                url: nil,
                issue: "The backend base URL “\(trimmed)” is missing a host. Use 127.0.0.1, localhost, a LAN IP, or a production hostname."
            )
        }

        components.host = host

        guard let url = components.url else {
            return BaseURLResolution(
                url: nil,
                issue: "The backend base URL “\(trimmed)” is malformed. Use a full URL such as http://192.168.1.20:3000."
            )
        }

        return BaseURLResolution(url: url, issue: nil)
    }
}

private struct BaseURLResolution {
    let url: URL?
    let issue: String?
}

private let fallbackAPIBaseURL = URL(string: "https://invalid.fragmenta.local")!

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
