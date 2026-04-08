import Charts
import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel: InsightsViewModel

    private let booksService: BooksServiceProtocol

    init(
        insightsService: InsightsServiceProtocol,
        booksService: BooksServiceProtocol
    ) {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(insightsService: insightsService))
        self.booksService = booksService
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Insights",
                        title: "Your reading cadence",
                        subtitle: "A calmer view into what the library has been collecting: pace, annotation density, and the books asking for the most attention."
                    )

                    content
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, FragmentaSpacing.xxLarge)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                viewModel.refresh()
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        let insights = viewModel.state.value

        if insights == nil {
            switch viewModel.state {
            case .idle, .loading:
                InsightsLoadingView()
            case .failed(let message, _):
                InsightsStatusCard(
                    title: "Insights unavailable",
                    message: message,
                    actionTitle: "Try again",
                    action: {
                        viewModel.refresh()
                    }
                )
            case .loaded:
                EmptyView()
            }
        } else if let insights {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xxxLarge) {
                if case .failed(let message, let previous) = viewModel.state, previous != nil {
                    InsightsStatusCard(
                        title: "Showing saved insights",
                        message: message,
                        actionTitle: nil,
                        action: nil
                    )
                } else if case .loading(let previous) = viewModel.state, previous != nil {
                    InsightsStatusBanner(message: "Refreshing your latest reading activity...")
                }

                InsightsSummaryGrid(totals: insights.totals)
                InsightsActivityCard(insights: insights)

                if insights.topAnnotatedBooks.isEmpty == false {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                        InsightsSectionHeading(
                            title: "Top annotated books",
                            subtitle: "The books currently carrying the densest reading life."
                        )

                        ForEach(insights.topAnnotatedBooks) { book in
                            NavigationLink {
                                BookDetailView(bookID: book.id, booksService: booksService)
                            } label: {
                                BookShelfCardView(book: book, emphasized: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if insights.topAnnotatedPassages.isEmpty == false {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                        InsightsSectionHeading(
                            title: "Most annotated passages",
                            subtitle: "A short index of the passages that drew the strongest response."
                        )

                        ForEach(insights.topAnnotatedPassages) { passage in
                            NavigationLink {
                                BookDetailView(
                                    bookID: passage.highlight.bookID,
                                    focusHighlightID: passage.highlight.id,
                                    booksService: booksService
                                )
                            } label: {
                                InsightPassageRow(passage: passage)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if insights.isEmpty {
                    InsightsStatusCard(
                        title: "No activity yet",
                        message: "Once fragmenta-core has enough reading history, this screen will turn the library into a quieter ledger of pace and attention.",
                        actionTitle: nil,
                        action: nil
                    )
                }
            }
        }
    }
}

private struct InsightsSummaryGrid: View {
    let totals: ReadingInsights.Totals

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: FragmentaSpacing.medium)]

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: FragmentaSpacing.medium) {
                metric("\(totals.bookCount)", label: "books")
                metric("\(totals.highlightCount)", label: "highlights")
                metric("\(totals.noteCount)", label: "notes")

                if let activeDays = totals.activeDays {
                    metric("\(activeDays)", label: "active days")
                }

                if let currentStreakDays = totals.currentStreakDays {
                    metric("\(currentStreakDays)", label: "day streak")
                }

                if let averageHighlightsPerWeek = totals.averageHighlightsPerWeek {
                    metric(String(format: "%.1f", averageHighlightsPerWeek), label: "highlights / week")
                }
            }

            Text(totals.paceSummary ?? fallbackSummary)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .insetSurfaceStyle()
        }
    }

    private var fallbackSummary: String {
        if let averageHighlightsPerWeek = totals.averageHighlightsPerWeek {
            return String(format: "The library is moving at about %.1f highlights per week, with notes appearing whenever a passage needs a second margin.", averageHighlightsPerWeek)
        }

        return "Fragmenta is tracking the pace of the library so repeated visits feel more like opening a private ledger than checking a dashboard."
    }

    private func metric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(value)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

private struct InsightsActivityCard: View {
    let insights: ReadingInsights

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            InsightsSectionHeading(
                title: "Activity over time",
                subtitle: "Highlights and notes plotted together, so the pace of reading and response stays visible at a glance."
            )

            if insights.activity.isEmpty {
                InsightsStatusCard(
                    title: "No timeline yet",
                    message: "The backend has not returned enough dated activity to plot a reading timeline.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                Chart(insights.activity) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Highlights", point.highlightCount)
                    )
                    .foregroundStyle(FragmentaColor.accent.opacity(0.2))

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Highlights", point.highlightCount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(FragmentaColor.accent)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Notes", point.noteCount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(FragmentaColor.accentSoft)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 220)
                .padding(FragmentaSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                        .fill(FragmentaColor.surfaceTertiary.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )

                HStack(spacing: FragmentaSpacing.small) {
                    legendChip("Highlights", color: FragmentaColor.accent)
                    legendChip("Notes", color: FragmentaColor.accentSoft)
                }
            }
        }
        .sectionSurfaceStyle()
    }

    private func legendChip(_ title: String, color: Color) -> some View {
        HStack(spacing: FragmentaSpacing.xSmall) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .chipSurfaceStyle()
    }
}

private struct InsightsSectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(subtitle)
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
    }
}

private struct InsightPassageRow: View {
    let passage: ReadingInsights.Passage

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack(spacing: FragmentaSpacing.small) {
                if let annotationCount = passage.annotationCount {
                    Text(annotationCount == 1 ? "1 note" : "\(annotationCount) notes")
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.accentSoft)
                        .chipSurfaceStyle()
                }

                if let locationLabel = passage.highlight.locationLabel {
                    Text(locationLabel)
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .chipSurfaceStyle()
                }

                Spacer()
            }

            Text(passage.highlight.text.trimmed)
                .font(FragmentaTypography.narrative)
                .foregroundStyle(FragmentaColor.textPrimary)
                .lineLimit(5)

            if let summary = passage.summary, summary.isBlank == false {
                Text(summary)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            if let book = passage.book {
                Text(book.title + " · " + book.displayAuthor)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textTertiary)
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct InsightsLoadingView: View {
    var body: some View {
        VStack(spacing: FragmentaSpacing.large) {
            RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 180)

            RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 280)

            ForEach(0 ..< 2, id: \.self) { _ in
                BookShelfCardSkeletonView()
            }
        }
        .redacted(reason: .placeholder)
    }
}

private struct InsightsStatusCard: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .fragmentaAdaptiveGlassButton(prominent: true)
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct InsightsStatusBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            ProgressView()
                .tint(FragmentaColor.textSecondary)

            Text(message)
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

#if DEBUG
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InsightsView(
                insightsService: PreviewInsightsService(),
                booksService: PreviewBooksService()
            )
        }
        .environmentObject(AppState(container: .preview))
    }
}
#endif
