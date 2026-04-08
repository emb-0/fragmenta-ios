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
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Search",
                        title: "Find a remembered line",
                        subtitle: "Query the backend by phrase, book, author, or notes, then step directly into the matching highlight."
                    )

                    SearchComposer(text: Binding(
                        get: { viewModel.query.text },
                        set: { viewModel.setQueryText($0) }
                    ))

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
                SearchEmptyState(title: "Search unavailable", message: message)
            case .loaded:
                SearchEmptyState(
                    title: "No matching highlights",
                    message: "Try a different phrase, widen the filters, or import more reading material."
                )
            }
        } else {
            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                switch viewModel.state {
                case .failed(let message, let previous) where previous != nil:
                    SearchEmptyState(title: "Showing saved results", message: message)
                case .loading(let previous) where previous != nil:
                    HStack(spacing: FragmentaSpacing.small) {
                        ProgressView()
                            .tint(FragmentaColor.textSecondary)
                        Text("Refreshing results...")
                            .font(FragmentaTypography.metadata)
                            .foregroundStyle(FragmentaColor.textSecondary)
                    }
                default:
                    EmptyView()
                }

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

    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FragmentaColor.textTertiary)

            TextField("Search passages, authors, or titles", text: $text)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .fieldSurfaceStyle()
    }
}

private struct SearchFilterCard: View {
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack {
                Text("Filters")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Spacer()

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
            }

            HStack(spacing: FragmentaSpacing.small) {
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

private struct RecentSearchesSection: View {
    let recentSearches: [String]
    let applyRecentSearch: (String) -> Void
    let clearRecentSearches: () -> Void

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
                FlowingRecentSearches(recentSearches: recentSearches, applyRecentSearch: applyRecentSearch)

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

private struct FlowingRecentSearches: View {
    let recentSearches: [String]
    let applyRecentSearch: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
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
    }
}

private struct SearchEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
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
