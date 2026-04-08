import Foundation

protocol InsightsServiceProtocol {
    func loadCachedInsights() async -> ReadingInsights?
    func fetchInsights() async throws -> ReadingInsights
}

struct InsightsService: InsightsServiceProtocol {
    private let apiClient: APIClient
    private let cacheStore: FragmentaCacheStore
    private let diagnosticsStore: DiagnosticsStore

    init(
        apiClient: APIClient,
        cacheStore: FragmentaCacheStore,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.diagnosticsStore = diagnosticsStore
    }

    func loadCachedInsights() async -> ReadingInsights? {
        await cacheStore.load(ReadingInsights.self, forKey: CacheKey.insights)
    }

    func fetchInsights() async throws -> ReadingInsights {
        do {
            let insights: ReadingInsights = try await apiClient.request(.readingInsights())
            try await cacheStore.save(insights, forKey: CacheKey.insights)
            diagnosticsStore.record(
                event: .insights,
                status: .success,
                detail: "Fetched reading insights for \(insights.totals.bookCount) books."
            )
            return insights
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Self.shouldUseStatsFallback(error) {
                let insights = try await fetchStatsFallbackInsights()
                try await cacheStore.save(insights, forKey: CacheKey.insights)
                diagnosticsStore.record(
                    event: .insights,
                    status: .success,
                    detail: "Fetched reading insights from stats endpoints for \(insights.totals.bookCount) books."
                )
                return insights
            }

            diagnosticsStore.record(
                event: .insights,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }

    private func fetchStatsFallbackInsights() async throws -> ReadingInsights {
        async let overview: StatsOverviewPayload = apiClient.request(APIEndpoint(path: "/api/stats/overview"))
        async let activity: [StatsActivityPayload] = apiClient.request(
            APIEndpoint(
                path: "/api/stats/activity",
                queryItems: [URLQueryItem(name: "months", value: "12")]
            )
        )
        async let topBooks: [Book] = apiClient.request(
            APIEndpoint(
                path: "/api/stats/books",
                queryItems: [URLQueryItem(name: "limit", value: "10")]
            )
        )

        let overviewPayload = try await overview
        let activityPayload = try await activity
        let topBooksPayload = try await topBooks

        let weeklyDivisor = max(Double(activityPayload.count) * 4.345, 1)
        let averageHighlightsPerWeek = activityPayload.isEmpty
            ? nil
            : Double(activityPayload.reduce(0) { $0 + $1.highlights }) / weeklyDivisor
        let averageNotesPerWeek = activityPayload.isEmpty
            ? nil
            : Double(activityPayload.reduce(0) { $0 + $1.notes }) / weeklyDivisor
        let paceSummary = overviewPayload.avgHighlightsPerBook > 0
            ? String(format: "%.1f avg highlights per book", overviewPayload.avgHighlightsPerBook)
            : nil

        return ReadingInsights(
            totals: ReadingInsights.Totals(
                bookCount: overviewPayload.bookCount,
                highlightCount: overviewPayload.highlightCount,
                noteCount: overviewPayload.noteCount,
                currentStreakDays: nil,
                activeDays: nil,
                averageHighlightsPerWeek: averageHighlightsPerWeek,
                averageNotesPerWeek: averageNotesPerWeek,
                paceSummary: paceSummary
            ),
            activity: activityPayload.compactMap { payload in
                guard let date = Self.monthStartDate(from: payload.month) else {
                    return nil
                }

                return ReadingInsights.ActivityPoint(
                    date: date,
                    highlightCount: payload.highlights,
                    noteCount: payload.notes
                )
            },
            topAnnotatedBooks: topBooksPayload,
            topAnnotatedPassages: [],
            generatedAt: .now
        )
    }

    private static func shouldUseStatsFallback(_ error: Error) -> Bool {
        guard let apiError = error as? APIError, let statusCode = apiError.statusCode else {
            return false
        }

        return [400, 404, 405, 501].contains(statusCode)
    }

    private static func monthStartDate(from rawValue: String) -> Date? {
        monthFormatter.date(from: rawValue)
    }
}

private enum CacheKey {
    static let insights = "reading-insights"
}

private struct StatsOverviewPayload: Decodable, Sendable {
    let bookCount: Int
    let highlightCount: Int
    let noteCount: Int
    let avgHighlightsPerBook: Double
}

private struct StatsActivityPayload: Decodable, Sendable {
    let month: String
    let highlights: Int
    let notes: Int
}

private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM"
    return formatter
}()
