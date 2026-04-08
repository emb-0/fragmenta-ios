import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    private let booksService: BooksServiceProtocol

    init(booksService: BooksServiceProtocol) {
        self.booksService = booksService
        _viewModel = StateObject(wrappedValue: LibraryViewModel(booksService: booksService))
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Fragmenta",
                        title: "Your reading shelf",
                        subtitle: "Books and highlights from fragmenta-core arrive here as a native library instead of a wrapped web surface."
                    )

                    content
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, FragmentaSpacing.xxLarge)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.refresh()
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            VStack(spacing: FragmentaSpacing.medium) {
                ProgressView()
                    .tint(FragmentaColor.textPrimary)

                Text("Loading books from fragmenta-core...")
                    .font(FragmentaTypography.subheadline)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, FragmentaSpacing.xxLarge)

        case .failed(let message):
            EmptyLibraryState(
                title: "Library unavailable",
                message: message,
                actionTitle: "Try again",
                action: {
                    Task {
                        await viewModel.refresh()
                    }
                }
            )

        case .loaded(let books):
            if books.isEmpty {
                EmptyLibraryState(
                    title: "No imported books yet",
                    message: "Once fragmenta-core receives a Kindle export, this shelf will populate with books, details, and searchable highlights.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                    LibrarySummaryView(books: books)

                    LazyVStack(spacing: FragmentaSpacing.large) {
                        ForEach(books) { book in
                            NavigationLink {
                                BookDetailView(bookID: book.id, booksService: booksService)
                            } label: {
                                BookShelfCardView(book: book)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct LibrarySummaryView: View {
    let books: [Book]

    private var totalHighlights: Int {
        books.reduce(into: 0) { partialResult, book in
            partialResult += book.highlightCount
        }
    }

    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            summaryCard(
                value: "\(books.count)",
                label: books.count == 1 ? "book" : "books"
            )

            summaryCard(
                value: "\(totalHighlights)",
                label: totalHighlights == 1 ? "highlight" : "highlights"
            )
        }
    }

    private func summaryCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(value)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

private struct EmptyLibraryState: View {
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
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibraryView(booksService: PreviewBooksService())
        }
    }
}
#endif
