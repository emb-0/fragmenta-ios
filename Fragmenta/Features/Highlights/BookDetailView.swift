import SwiftUI

struct BookDetailView: View {
    enum HighlightFilter: String, CaseIterable, Identifiable {
        case all
        case notesOnly

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "All Highlights"
            case .notesOnly:
                return "With Notes"
            }
        }
    }

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: BookDetailViewModel
    @StateObject private var discoveryModel = BookDiscoverySectionModel()
    @State private var markdownExportState: LoadableState<ExportArtifact> = .idle
    @State private var highlightFilter: HighlightFilter = .all
    @State private var isShowingCollectionsSheet = false

    private let bookID: String

    init(
        bookID: String,
        focusHighlightID: String? = nil,
        booksService: BooksServiceProtocol
    ) {
        self.bookID = bookID
        _viewModel = StateObject(
            wrappedValue: BookDetailViewModel(
                bookID: bookID,
                focusHighlightID: focusHighlightID,
                booksService: booksService
            )
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            FragmentaScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                        detailContent
                    }
                    .padding(.horizontal, FragmentaSpacing.large)
                    .padding(.top, FragmentaSpacing.large)
                    .padding(.bottom, FragmentaSpacing.xxLarge)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    viewModel.refresh()
                    discoveryModel.refresh(
                        bookID: bookID,
                        service: appState.container.discoveryService
                    )
                }
            }
            .navigationTitle("Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                viewModel.loadIfNeeded()
                discoveryModel.loadIfNeeded(
                    bookID: bookID,
                    service: appState.container.discoveryService
                )
            }
            .onChange(of: viewModel.focusedHighlightID, initial: false) { _, focusedHighlightID in
                guard let focusedHighlightID else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.28)) {
                    proxy.scrollTo(focusedHighlightID, anchor: .center)
                }
            }
            .sheet(isPresented: $isShowingCollectionsSheet) {
                if let book = viewModel.detailState.value?.book {
                    BookCollectionsSheet(
                        book: book,
                        collectionsService: appState.container.collectionsService
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        let detail = viewModel.detailState.value
        let highlights = viewModel.highlightsState.value ?? []
        let displayedHighlights = visibleHighlights(from: highlights)

        if detail == nil && highlights.isEmpty {
            switch viewModel.detailState {
            case .idle, .loading:
                VStack(spacing: FragmentaSpacing.large) {
                    BookDetailHeroSkeletonView()
                    ForEach(0 ..< 2, id: \.self) { _ in
                        HighlightCardSkeletonView()
                    }
                }
            case .failed(let message, _):
                DetailStatusCard(title: "Book unavailable", message: message)
            case .loaded:
                EmptyView()
            }
        } else {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                if let detail {
                    BookDetailHeroView(
                        detail: detail,
                        isShowingFocusedContext: viewModel.focusedHighlightID != nil
                    )

                    BookDetailActionStrip(
                        book: detail.book,
                        exportState: markdownExportState,
                        generateMarkdown: {
                            generateMarkdownExport(for: detail.book.id)
                        },
                        showCollections: {
                            isShowingCollectionsSheet = true
                        }
                    )
                }

                if case .failed(let message, let previous) = viewModel.detailState, previous != nil {
                    DetailStatusCard(title: "Showing saved book detail", message: message)
                }

                if case .failed(let message, let previous) = viewModel.highlightsState, previous != nil {
                    DetailStatusCard(title: "Showing saved highlights", message: message)
                }

                discoverySection

                VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                        Text("Captured passages")
                            .font(FragmentaTypography.sectionTitle)
                            .foregroundStyle(FragmentaColor.textPrimary)

                        Text("A scrolling notebook of the lines, notes, and locations carried back from the book.")
                            .font(FragmentaTypography.metadata)
                            .foregroundStyle(FragmentaColor.textSecondary)
                    }

                    if highlights.isEmpty == false {
                        HighlightFilterStrip(
                            filter: $highlightFilter,
                            noteCount: highlights.filter { ($0.note?.isBlank == false) }.count
                        )
                    }

                    if case .failed(let message, let previous) = viewModel.highlightsState, previous == nil {
                        DetailStatusCard(title: "Highlights unavailable", message: message)
                    } else if highlights.isEmpty {
                        DetailStatusCard(
                            title: "No highlights yet",
                            message: "This book is present in the library, but fragmenta-core has not returned any saved passages yet."
                        )
                    } else if displayedHighlights.isEmpty {
                        DetailStatusCard(
                            title: "No noted highlights",
                            message: "This book has highlights loaded, but none of the currently loaded passages include notes yet."
                        )
                    } else {
                        ForEach(displayedHighlights) { highlight in
                            HighlightCardView(
                                highlight: highlight,
                                citation: highlightCitation(for: highlight, detail: detail),
                                isFocused: highlight.id == viewModel.focusedHighlightID
                            )
                            .id(highlight.id)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentHighlight: highlight)
                            }
                        }
                    }

                    if highlightFilter == .notesOnly, let actualLastHighlight = highlights.last {
                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentHighlight: actualLastHighlight)
                            }
                    }

                    if viewModel.isLoadingMore {
                        LoadMoreHighlightsFooter()
                    } else if let loadMoreFailureMessage = viewModel.loadMoreFailureMessage {
                        LoadMoreRetryFooter(
                            message: loadMoreFailureMessage,
                            retryAction: {
                                viewModel.retryLoadMore()
                            }
                        )
                    } else if viewModel.pageInfo.hasMore == false, highlights.isEmpty == false {
                        Text("End of notebook")
                            .font(FragmentaTypography.metadata)
                            .foregroundStyle(FragmentaColor.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, FragmentaSpacing.small)
                    }
                }
            }
        }
    }

    private func visibleHighlights(from highlights: [Highlight]) -> [Highlight] {
        switch highlightFilter {
        case .all:
            return highlights
        case .notesOnly:
            return highlights.filter { $0.note?.isBlank == false }
        }
    }

    private func highlightCitation(for highlight: Highlight, detail: BookDetail?) -> HighlightCitation? {
        if let detail {
            return HighlightCitation(
                bookTitle: detail.book.title,
                author: detail.book.author,
                chapter: highlight.chapter,
                locationLabel: highlight.locationLabel
            )
        }

        if let reference = highlight.book {
            return HighlightCitation(
                bookTitle: reference.title,
                author: reference.author,
                chapter: highlight.chapter,
                locationLabel: highlight.locationLabel
            )
        }

        return nil
    }

    @ViewBuilder
    private var discoverySection: some View {
        let discovery = discoveryModel.state.value

        if let discovery, discovery.isEmpty == false {
            BookDiscoverySection(
                discovery: discovery,
                bookID: bookID,
                booksService: appState.container.booksService,
                focusHighlight: { highlightID in
                    viewModel.focus(highlightID: highlightID)
                }
            )
        } else if case .loading(let previous) = discoveryModel.state, previous != nil {
            DetailStatusCard(
                title: "Refreshing discovery",
                message: "Updating the AI-assisted summary and related threads for this book."
            )
        } else if case .failed(let message, let previous) = discoveryModel.state, previous != nil {
            DetailStatusCard(title: "Showing saved discovery", message: message)
        } else if case .failed(let message, nil) = discoveryModel.state {
            DetailStatusCard(title: "Discovery unavailable", message: message)
        }
    }

    private func generateMarkdownExport(for bookID: String) {
        markdownExportState = .loading(previous: markdownExportState.value)

        Task { @MainActor in
            do {
                let artifact = try await appState.container.exportService.exportBook(
                    bookID: bookID,
                    format: .markdown
                )
                markdownExportState = .loaded(artifact, source: .remote)
            } catch is CancellationError {
                return
            } catch {
                markdownExportState = .failed(Self.errorMessage(for: error), previous: markdownExportState.value)
            }
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return "Book export is temporarily unavailable."
    }
}

private struct BookDetailHeroView: View {
    let detail: BookDetail
    let isShowingFocusedContext: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: FragmentaSpacing.large) {
                heroCover(width: 116)
                heroCopy
            }

            VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                heroCover(width: 132)
                heroCopy
            }
        }
        .modifier(BookDetailHeroSurface(isShowingFocusedContext: isShowingFocusedContext))
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    if isShowingFocusedContext {
                        Text("SEARCH CONTEXT")
                            .font(FragmentaTypography.eyebrow)
                            .foregroundStyle(FragmentaColor.accentSoft)
                            .tracking(1.3)
                    }

                    Text(detail.book.title)
                        .font(FragmentaTypography.heroDisplay)
                        .foregroundStyle(FragmentaColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detail.book.displayAuthor)
                        .font(FragmentaTypography.subheadline)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                Spacer(minLength: FragmentaSpacing.medium)

                VStack(alignment: .trailing, spacing: FragmentaSpacing.small) {
                    chip(detail.book.source.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)

                    if let lastImportedAt = detail.stats.lastImportedAt {
                        chip(lastImportedAt.fragmentaDayMonthYearString())
                    }
                }
            }

            if let synopsis = detail.book.synopsis, synopsis.isBlank == false {
                Text(synopsis)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: FragmentaSpacing.medium) {
                metric(value: "\(detail.stats.highlightCount)", label: "highlights")
                metric(value: "\(detail.stats.noteCount)", label: "notes")

                if let firstHighlightAt = detail.stats.firstHighlightAt {
                    metric(value: firstHighlightAt.fragmentaDayMonthYearString(), label: "first saved")
                } else if let latestHighlightAt = detail.stats.latestHighlightAt {
                    metric(value: latestHighlightAt.fragmentaDayMonthYearString(), label: "last saved")
                }
            }
        }
    }

    private func heroCover(width: CGFloat) -> some View {
        BookCoverArtView(book: detail.book, presentation: .hero)
            .frame(width: width)
            .aspectRatio(CGFloat(detail.book.resolvedCoverAspectRatio), contentMode: .fit)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(FragmentaTypography.chip)
            .foregroundStyle(FragmentaColor.textSecondary)
            .chipSurfaceStyle()
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(value)
                .font(FragmentaTypography.bodyEmphasized)
                .foregroundStyle(FragmentaColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct HighlightFilterStrip: View {
    @Binding var filter: BookDetailView.HighlightFilter
    let noteCount: Int

    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            ForEach(BookDetailView.HighlightFilter.allCases) { candidate in
                Button {
                    filter = candidate
                } label: {
                    HStack(spacing: FragmentaSpacing.xSmall) {
                        Text(candidate.title)
                        if candidate == .notesOnly {
                            Text("\(noteCount)")
                                .foregroundStyle(FragmentaColor.textTertiary)
                        }
                    }
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(filter == candidate ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                    .chipSurfaceStyle()
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct BookDetailHeroSurface: ViewModifier {
    let isShowingFocusedContext: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isShowingFocusedContext {
            content.paperGlassCardStyle(tint: FragmentaColor.accentSoft.opacity(0.16))
        } else {
            content.journalCardStyle()
        }
    }
}

private struct BookDetailHeroSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: FragmentaSpacing.large) {
            RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 110, height: 162)

            VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(width: 140, height: 12)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(height: 56)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(width: 180, height: 18)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(height: 72)
            }
        }
        .redacted(reason: .placeholder)
        .journalCardStyle()
    }
}

private struct DetailStatusCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sectionSurfaceStyle()
    }
}

private struct BookDetailActionStrip: View {
    let book: Book
    let exportState: LoadableState<ExportArtifact>
    let generateMarkdown: () -> Void
    let showCollections: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text("Actions")
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: FragmentaSpacing.small) {
                    exportControls

                    Button("Collections") {
                        showCollections()
                    }
                    .fragmentaAdaptiveGlassButton()

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    exportControls

                    Button("Collections") {
                        showCollections()
                    }
                    .fragmentaAdaptiveGlassButton()
                }
            }

            switch exportState {
            case .loaded(let artifact, _):
                Text(artifact.fileURL.lastPathComponent)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            case .failed(let message, _):
                Text(message)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.negative)
            default:
                Text("Prepare a book-level markdown export from fragmenta-core and hand it off through the native share sheet.")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            if book.noteCountLabel != nil || book.highlightCount > 0 {
                HStack(spacing: FragmentaSpacing.small) {
                    Text(book.highlightCountLabel)
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .chipSurfaceStyle()

                    if let noteCountLabel = book.noteCountLabel {
                        Text(noteCountLabel)
                            .font(FragmentaTypography.chip)
                            .foregroundStyle(FragmentaColor.textTertiary)
                            .chipSurfaceStyle()
                    }
                }
            }
        }
        .sectionSurfaceStyle()
    }

    @ViewBuilder
    private var exportControls: some View {
        switch exportState {
        case .idle, .failed:
            Button("Export Markdown") {
                generateMarkdown()
            }
            .fragmentaAdaptiveGlassButton()
        case .loading:
            HStack(spacing: FragmentaSpacing.small) {
                ProgressView()
                    .tint(FragmentaColor.textPrimary)
                Text("Preparing Markdown")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .chipSurfaceStyle()
        case .loaded(let artifact, _):
            ShareLink(item: artifact.fileURL) {
                Text("Share Markdown")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textPrimary)
                    .chipSurfaceStyle()
            }

            Button("Refresh Export") {
                generateMarkdown()
            }
            .fragmentaAdaptiveGlassButton()
        }
    }
}

@MainActor
private final class BookDiscoverySectionModel: ObservableObject {
    @Published private(set) var state: LoadableState<BookDiscovery> = .idle

    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded(bookID: String, service: DiscoveryServiceProtocol) {
        if case .idle = state {
            load(bookID: bookID, service: service)
        }
    }

    func refresh(bookID: String, service: DiscoveryServiceProtocol) {
        load(bookID: bookID, service: service)
    }

    private func load(bookID: String, service: DiscoveryServiceProtocol) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad(bookID: bookID, service: service)
        }
    }

    private func performLoad(bookID: String, service: DiscoveryServiceProtocol) async {
        let cachedDiscovery = await service.loadCachedBookDiscovery(bookID: bookID)
        state = .loading(previous: state.value ?? cachedDiscovery)

        do {
            let discovery = try await service.fetchBookDiscovery(bookID: bookID)
            state = .loaded(discovery, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)
            if let previous = state.value ?? cachedDiscovery {
                state = .failed(message, previous: previous)
            } else {
                state = .failed(message)
            }
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "AI discovery is temporarily unavailable."
    }
}

private struct BookDiscoverySection: View {
    let discovery: BookDiscovery
    let bookID: String
    let booksService: BooksServiceProtocol
    let focusHighlight: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                Text("Discovery")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text("AI-backed summary and thematic echoes from fragmenta-core, kept small enough to support the reading surface rather than overwhelm it.")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            if let summary = discovery.summary, summary.isBlank == false {
                Text(summary)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .insetSurfaceStyle()
            }

            if discovery.themes.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FragmentaSpacing.small) {
                        ForEach(discovery.themes) { theme in
                            Text(theme.title)
                                .font(FragmentaTypography.chip)
                                .foregroundStyle(FragmentaColor.textSecondary)
                                .chipSurfaceStyle()
                        }
                    }
                }
            }

            if discovery.relatedHighlights.isEmpty == false {
                VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                    Text("Related highlights")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)

                    ForEach(discovery.relatedHighlights.prefix(4)) { relatedHighlight in
                        if relatedHighlight.highlight.bookID == bookID {
                            Button {
                                focusHighlight(relatedHighlight.highlight.id)
                            } label: {
                                RelatedHighlightRow(relatedHighlight: relatedHighlight)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                BookDetailView(
                                    bookID: relatedHighlight.highlight.bookID,
                                    focusHighlightID: relatedHighlight.highlight.id,
                                    booksService: booksService
                                )
                            } label: {
                                RelatedHighlightRow(relatedHighlight: relatedHighlight)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct RelatedHighlightRow: View {
    let relatedHighlight: BookDiscovery.RelatedHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            if let reason = relatedHighlight.reason, reason.isBlank == false {
                Text(reason)
                    .font(FragmentaTypography.caption)
                    .foregroundStyle(FragmentaColor.accentSoft)
            }

            Text(relatedHighlight.highlight.text.trimmed)
                .font(FragmentaTypography.narrative)
                .foregroundStyle(FragmentaColor.textPrimary)
                .lineLimit(4)

            HStack(spacing: FragmentaSpacing.small) {
                if let book = relatedHighlight.book {
                    Text(book.title)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .lineLimit(1)
                }

                if let locationLabel = relatedHighlight.highlight.locationLabel {
                    Text(locationLabel)
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .chipSurfaceStyle()
                }
            }
        }
        .insetSurfaceStyle()
    }
}

private struct LoadMoreHighlightsFooter: View {
    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            ProgressView()
                .tint(FragmentaColor.textPrimary)

            Text("Loading the next pages of the notebook...")
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, FragmentaSpacing.medium)
    }
}

private struct LoadMoreRetryFooter: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: FragmentaSpacing.small) {
            Text(message)
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                retryAction()
            }
            .fragmentaAdaptiveGlassButton()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FragmentaSpacing.medium)
    }
}

#if DEBUG
struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookDetailView(
                bookID: PreviewFixtures.books[0].id,
                focusHighlightID: PreviewFixtures.highlights[0].id,
                booksService: PreviewBooksService()
            )
        }
        .environmentObject(AppState(container: .preview))
    }
}
#endif
