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
                        subtitle: "A calm, native library for imports that live in fragmenta-core but feel at home on iPhone."
                    )

                    LibraryControlsView(viewModel: viewModel)
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
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        let displayedBooks = viewModel.state.value ?? []

        if displayedBooks.isEmpty {
            switch viewModel.state {
            case .idle, .loading:
                loadingContent
            case .failed(let message, _):
                EmptyLibraryState(
                    title: "Library unavailable",
                    message: message,
                    actionTitle: "Try again",
                    action: {
                        viewModel.refresh()
                    }
                )
            case .loaded:
                EmptyLibraryState(
                    title: "No books match this shelf",
                    message: "Adjust the sort or filters, or import a new Kindle export to populate the library.",
                    actionTitle: nil,
                    action: nil
                )
            }
        } else {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                statusBanner
                LibrarySummaryView(books: displayedBooks)

                if recentBooks.isEmpty == false {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                        sectionLabel("Recently Imported")

                        ForEach(recentBooks) { book in
                            navigationCard(for: book, emphasized: true)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                    sectionLabel(recentBooks.isEmpty ? "Books" : "All Books")

                    LazyVStack(spacing: FragmentaSpacing.large) {
                        ForEach(mainShelfBooks) { book in
                            navigationCard(for: book)
                        }
                    }
                }
            }
        }
    }

    private var recentBooks: [Book] {
        Array((viewModel.state.value ?? []).filter(\.isRecentlyImported).prefix(2))
    }

    private var mainShelfBooks: [Book] {
        let books = viewModel.state.value ?? []
        guard recentBooks.isEmpty == false else {
            return books
        }

        let recentIDs = Set(recentBooks.map(\.id))
        return books.filter { recentIDs.contains($0.id) == false }
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch viewModel.state {
        case .loaded(_, let source) where source == .cache:
            LibraryStatusBanner(message: "Showing the last cached library snapshot while the backend catches up.")
        case .failed(let message, let previous) where previous != nil:
            LibraryStatusBanner(message: message)
        case .loading(let previous) where previous != nil:
            HStack(spacing: FragmentaSpacing.small) {
                ProgressView()
                    .tint(FragmentaColor.textSecondary)
                Text("Refreshing your shelf...")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
        default:
            EmptyView()
        }
    }

    private var loadingContent: some View {
        VStack(spacing: FragmentaSpacing.large) {
            LibrarySummarySkeletonView()

            ForEach(0 ..< 3, id: \.self) { _ in
                BookShelfCardSkeletonView()
            }
        }
    }

    @ViewBuilder
    private func navigationCard(for book: Book, emphasized: Bool = false) -> some View {
        NavigationLink {
            BookDetailView(bookID: book.id, booksService: booksService)
        } label: {
            BookShelfCardView(book: book, emphasized: emphasized)
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(FragmentaTypography.sectionTitle)
            .foregroundStyle(FragmentaColor.textPrimary)
    }
}

private struct LibraryControlsView: View {
    @ObservedObject var viewModel: LibraryViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FragmentaSpacing.small) {
                Menu {
                    ForEach(LibraryQuery.Sort.allCases) { sort in
                        Button(sort.title) {
                            viewModel.updateSort(sort)
                        }
                    }
                } label: {
                    HStack(spacing: FragmentaSpacing.xSmall) {
                        Text("Sort")
                        Text(viewModel.query.sort.title)
                            .foregroundStyle(FragmentaColor.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .chipSurfaceStyle()
                }

                ForEach(LibraryQuery.SourceFilter.allCases) { source in
                    Button(source.title) {
                        viewModel.updateSource(source)
                    }
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(viewModel.query.source == source ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                    .chipSurfaceStyle()
                }

                Button(viewModel.query.hasNotesOnly ? "With Notes" : "Any Notes") {
                    viewModel.toggleHasNotesOnly()
                }
                .font(FragmentaTypography.metadata)
                .foregroundStyle(viewModel.query.hasNotesOnly ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                .chipSurfaceStyle()

                Button(viewModel.query.recentOnly ? "Recent Only" : "All Dates") {
                    viewModel.toggleRecentOnly()
                }
                .font(FragmentaTypography.metadata)
                .foregroundStyle(viewModel.query.recentOnly ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                .chipSurfaceStyle()
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

    private var totalNotes: Int {
        books.reduce(into: 0) { partialResult, book in
            partialResult += book.noteCount ?? 0
        }
    }

    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            summaryCard(value: "\(books.count)", label: books.count == 1 ? "book" : "books")
            summaryCard(value: "\(totalHighlights)", label: totalHighlights == 1 ? "highlight" : "highlights")
            summaryCard(value: "\(totalNotes)", label: totalNotes == 1 ? "note" : "notes")
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

private struct LibrarySummarySkeletonView: View {
    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(height: 92)
            }
        }
        .redacted(reason: .placeholder)
    }
}

private struct LibraryStatusBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(FragmentaTypography.metadata)
            .foregroundStyle(FragmentaColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .insetSurfaceStyle()
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
