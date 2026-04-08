import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel

    private let booksService: BooksServiceProtocol

    init(searchService: SearchServiceProtocol, booksService: BooksServiceProtocol) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(searchService: searchService))
        self.booksService = booksService
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Search",
                        title: "Find a remembered line",
                        subtitle: "Search across quotes, authors, and passages once fragmenta-core has indexed your imported Kindle exports."
                    )

                    SearchComposer(query: $viewModel.query)

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
        .onChange(of: viewModel.query) { _ in
            viewModel.queryDidChange()
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        switch viewModel.state {
        case .idle:
            SearchEmptyState(
                title: "Start with a phrase or author",
                message: "Fragmenta will query `/api/search?q=` and return native results here."
            )

        case .loading:
            VStack(spacing: FragmentaSpacing.medium) {
                ProgressView()
                    .tint(FragmentaColor.textPrimary)

                Text("Searching highlights...")
                    .font(FragmentaTypography.subheadline)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, FragmentaSpacing.xxLarge)

        case .failed(let message):
            SearchEmptyState(
                title: "Search unavailable",
                message: message
            )

        case .loaded(let results):
            if results.isEmpty {
                SearchEmptyState(
                    title: "No matching highlights",
                    message: "Try a different phrase, author, or book title once your library has more imported material."
                )
            } else {
                LazyVStack(spacing: FragmentaSpacing.large) {
                    ForEach(results) { result in
                        NavigationLink {
                            BookDetailView(bookID: result.book.id, booksService: booksService)
                        } label: {
                            SearchResultRowView(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct SearchComposer: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FragmentaColor.textTertiary)

            TextField("Search passages, authors, or titles", text: $query)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, FragmentaSpacing.medium)
        .padding(.vertical, FragmentaSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                .fill(FragmentaColor.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
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
