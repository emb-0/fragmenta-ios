import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel

    private let booksService: BooksServiceProtocol

    init(searchService: SearchServiceProtocol, booksService: BooksServiceProtocol) {
        _viewModel = StateObject(
            wrappedValue: SearchViewModel(
                searchService: searchService,
                booksService: booksService
            )
        )
        self.booksService = booksService
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Search",
                        title: "Find a remembered line",
                        subtitle: "Query by phrase, book, author, or notes, then step directly into the exact reading context."
                    )

                    SearchComposer(
                        text: Binding(
                            get: { viewModel.query.text },
                            set: { viewModel.setQueryText($0) }
                        ),
                        hasFilters: viewModel.query.hasActiveFilters
                    )

                    SearchFilterCard(viewModel: viewModel)
                    searchContent
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, FragmentaSpacing.xxLarge)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        let results = viewModel.state.value ?? []

        if results.isEmpty {
            switch viewModel.state {
            case .idle:
                RecentSearchesSection(
                    recentSearches: viewModel.recentSearches,
                    applyRecentSearch: { viewModel.applyRecentSearch($0) },
                    clearRecentSearches: viewModel.clearRecentSearches
                )
            case .loading:
                VStack(spacing: FragmentaSpacing.large) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        SearchResultRowSkeletonView()
                    }
                }
            case .failed(let message, _):
                SearchEmptyState(
                    title: "Search unavailable",
                    message: message,
                    actionTitle: "Try again",
                    action: {
                        viewModel.retryCurrentSearch()
                    }
                )
            case .loaded:
                SearchEmptyState(
                    title: "No matching highlights",
                    message: "Try a different phrase, widen the filters, or search by author or notes instead.",
                    actionTitle: nil,
                    action: nil
                )
            }
        } else {
            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                SearchResultsSummary(resultCount: results.count, state: viewModel.state)

                LazyVStack(spacing: FragmentaSpacing.large) {
                    ForEach(results) { result in
                        NavigationLink {
                            BookDetailView(
                                bookID: result.book.id,
                                focusHighlightID: result.highlight.id,
                                booksService: booksService
                            )
                        } label: {
                            SearchResultRowView(result: result)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentResult: result)
                        }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(FragmentaColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FragmentaSpacing.medium)
                    }
                }
            }
        }
    }
}

private struct SearchComposer: View {
    @Binding var text: String
    let hasFilters: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            HStack(spacing: FragmentaSpacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FragmentaColor.textTertiary)

                TextField("Search passages, authors, or titles", text: $text)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if text.isBlank == false {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(FragmentaColor.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .fieldSurfaceStyle()

            Text(hasFilters ? "Filters are active, so search can run even without a typed phrase." : "Type a remembered line and let the backend narrow it down.")
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
    }
}

private struct SearchFilterCard: View {
    @ObservedObject var viewModel: SearchViewModel

    private var activeFilterCount: Int {
        var count = 0
        if viewModel.query.bookID != nil { count += 1 }
        if viewModel.query.author.isBlank == false { count += 1 }
        if viewModel.query.hasNotesOnly { count += 1 }
        return count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: FragmentaSpacing.tiny) {
                    Text("Filters")
                        .font(FragmentaTypography.sectionTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text("Tighten the reading context without turning the search surface into a form.")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                Spacer()

                if activeFilterCount > 0 {
                    Text("\(activeFilterCount) ACTIVE")
                        .font(FragmentaTypography.eyebrow)
                        .foregroundStyle(FragmentaColor.textPrimary)
                        .tracking(1.2)
                        .chipSurfaceStyle()
                }
            }

            HStack(spacing: FragmentaSpacing.small) {
                Menu {
                    ForEach(SearchQuery.Sort.allCases) { sort in
                        Button(sort.title) {
                            viewModel.setSort(sort)
                        }
                    }
                } label: {
                    HStack(spacing: FragmentaSpacing.xSmall) {
                        Text("Sort")
                        Text(viewModel.query.sort.title)
                    }
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .chipSurfaceStyle()
                }

                Menu {
                    Button("All books") {
                        viewModel.selectBook(nil)
                    }

                    ForEach(viewModel.availableBooks) { book in
                        Button(book.title) {
                            viewModel.selectBook(book)
                        }
                    }
                } label: {
                    HStack(spacing: FragmentaSpacing.xSmall) {
                        Text("Book")
                        Text(selectedBookTitle)
                    }
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .chipSurfaceStyle()
                }

                Button(viewModel.query.hasNotesOnly ? "Notes Only" : "Any Notes") {
                    viewModel.toggleNotesOnly()
                }
                .font(FragmentaTypography.metadata)
                .foregroundStyle(viewModel.query.hasNotesOnly ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                .chipSurfaceStyle()
            }

            TextField(
                "Author filter",
                text: Binding(
                    get: { viewModel.query.author },
                    set: { viewModel.setAuthorFilter($0) }
                )
            )
            .font(FragmentaTypography.body)
            .foregroundStyle(FragmentaColor.textPrimary)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .fieldSurfaceStyle()
        }
        .sectionSurfaceStyle()
    }

    private var selectedBookTitle: String {
        if let selectedBook = viewModel.availableBooks.first(where: { $0.id == viewModel.query.bookID }) {
            return selectedBook.title
        }

        return "All"
    }
}

private struct SearchResultsSummary: View {
    let resultCount: Int
    let state: LoadableState<[HighlightSearchResult]>

    var body: some View {
        switch state {
        case .failed(let message, let previous) where previous != nil:
            SearchEmptyState(title: "Showing saved results", message: message, actionTitle: nil, action: nil)
        case .loading(let previous) where previous != nil:
            HStack(spacing: FragmentaSpacing.small) {
                ProgressView()
                    .tint(FragmentaColor.textSecondary)
                Text("Refreshing \(resultCount) results...")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .insetSurfaceStyle()
        default:
            Text(resultCount == 1 ? "1 result" : "\(resultCount) results")
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
    }
}

private struct RecentSearchesSection: View {
    let recentSearches: [String]
    let applyRecentSearch: (String) -> Void
    let clearRecentSearches: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: FragmentaSpacing.small)]

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text(recentSearches.isEmpty ? "Search is ready" : "Recent searches")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            if recentSearches.isEmpty {
                Text("Start with a phrase, then layer on book or author filters as needed.")
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: FragmentaSpacing.small) {
                    ForEach(recentSearches, id: \.self) { search in
                        Button(search) {
                            applyRecentSearch(search)
                        }
                        .font(FragmentaTypography.body)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fieldSurfaceStyle()
                    }
                }

                Button("Clear recent searches") {
                    clearRecentSearches()
                }
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

private struct SearchEmptyState: View {
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

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .fragmentaAdaptiveGlassButton(prominent: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

#if DEBUG
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SearchView(
                searchService: PreviewSearchService(),
                booksService: PreviewBooksService()
            )
        }
    }
}
#endif
