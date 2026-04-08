import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: LibraryViewModel
    private let booksService: BooksServiceProtocol

    init(
        booksService: BooksServiceProtocol,
        preferencesStore: AppPreferencesStore
    ) {
        self.booksService = booksService
        _viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                booksService: booksService,
                preferencesStore: preferencesStore
            )
        )
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Fragmenta",
                        title: "Your reading shelf",
                        subtitle: "A calmer, publication-minded library for the lines you wanted to keep."
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CollectionsView(
                        collectionsService: appState.container.collectionsService,
                        booksService: booksService
                    )
                } label: {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(FragmentaColor.textSecondary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.viewMode)
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
                    message: "Adjust the current lens or import a new Kindle export to restore the shelf.",
                    actionTitle: nil,
                    action: nil
                )
            }
        } else {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                statusBanner
                LibrarySummaryView(books: displayedBooks, viewMode: viewModel.viewMode)

                switch viewModel.viewMode {
                case .journal:
                    journalContent(displayedBooks: displayedBooks)
                case .bookshelf:
                    bookshelfContent(displayedBooks: displayedBooks)
                }
            }
        }
    }

    private func journalContent(displayedBooks: [Book]) -> some View {
        let shelves = featuredShelves(for: displayedBooks)

        return VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
            ForEach(shelves) { shelf in
                VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                    LibrarySectionHeading(title: shelf.title, subtitle: shelf.subtitle)

                    ForEach(shelf.books) { book in
                        navigationCard(for: book, emphasized: shelf.emphasized)
                    }
                }
            }

            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                LibrarySectionHeading(
                    title: shelves.isEmpty ? "Shelf" : "Full shelf",
                    subtitle: "The complete reading index, sorted by the current lens."
                )

                LazyVStack(spacing: FragmentaSpacing.large) {
                    ForEach(displayedBooks) { book in
                        navigationCard(for: book)
                    }
                }
            }
        }
    }

    private func bookshelfContent(displayedBooks: [Book]) -> some View {
        let frontShelfBooks = featuredBooks(for: displayedBooks)

        return VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
            if frontShelfBooks.isEmpty == false {
                VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                    LibrarySectionHeading(
                        title: "Front shelf",
                        subtitle: "A smaller ledge for the books that feel most alive right now."
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: FragmentaSpacing.large) {
                            ForEach(frontShelfBooks) { book in
                                navigationTile(for: book, emphasis: .featured)
                                    .frame(width: 176)
                            }
                        }
                        .padding(.vertical, FragmentaSpacing.small)
                    }
                }
            }

            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                LibrarySectionHeading(
                    title: "Bookshelf",
                    subtitle: "A fast, cover-led shelf built for browsing with many books on hand."
                )

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 148, maximum: 190), spacing: FragmentaSpacing.medium)],
                    alignment: .leading,
                    spacing: FragmentaSpacing.large
                ) {
                    ForEach(displayedBooks) { book in
                        navigationTile(for: book, emphasis: .standard)
                    }
                }
            }
        }
    }

    private func featuredShelves(for books: [Book]) -> [LibraryShelfSection] {
        var sections: [LibraryShelfSection] = []

        let recentBooks = Array(books.filter(\.isRecentlyImported).prefix(2))
        let annotatedBooks = Array(
            books
                .filter { ($0.noteCount ?? 0) > 0 }
                .sorted { ($0.noteCount ?? 0) > ($1.noteCount ?? 0) }
                .prefix(2)
        )
        let mostHighlightedBooks = Array(
            books
                .sorted { $0.highlightCount > $1.highlightCount }
                .prefix(2)
        )

        if recentBooks.isEmpty == false {
            sections.append(
                LibraryShelfSection(
                    title: "Recently Imported",
                    subtitle: "Fresh arrivals from the latest parsing pass.",
                    books: recentBooks,
                    emphasized: true
                )
            )
        }

        if annotatedBooks.isEmpty == false {
            sections.append(
                LibraryShelfSection(
                    title: "With Notes",
                    subtitle: "Books that hold more than highlighted lines.",
                    books: annotatedBooks,
                    emphasized: false
                )
            )
        }

        if mostHighlightedBooks.isEmpty == false {
            sections.append(
                LibraryShelfSection(
                    title: "Most Highlighted",
                    subtitle: "The densest notebooks in the collection.",
                    books: mostHighlightedBooks,
                    emphasized: false
                )
            )
        }

        return sections
    }

    private func featuredBooks(for books: [Book]) -> [Book] {
        let recent = books.filter(\.isRecentlyImported)
        if recent.isEmpty == false {
            return Array(recent.prefix(6))
        }

        return Array(books.prefix(6))
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch viewModel.state {
        case .loaded(_, let source) where source == .cache:
            LibraryStatusBanner(
                title: "Cached shelf",
                message: "Showing the last saved library snapshot while fragmenta-core catches up."
            )
        case .failed(let message, let previous) where previous != nil:
            LibraryStatusBanner(
                title: "Saved shelf",
                message: message
            )
        case .loading(let previous) where previous != nil:
            HStack(spacing: FragmentaSpacing.small) {
                ProgressView()
                    .tint(FragmentaColor.textSecondary)
                Text("Refreshing your shelf...")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .insetSurfaceStyle()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        switch viewModel.viewMode {
        case .journal:
            VStack(spacing: FragmentaSpacing.large) {
                LibrarySummarySkeletonView()

                ForEach(0 ..< 3, id: \.self) { _ in
                    BookShelfCardSkeletonView()
                }
            }
        case .bookshelf:
            VStack(spacing: FragmentaSpacing.large) {
                LibrarySummarySkeletonView()
                BookshelfGridSkeletonView()
            }
        }
    }

    private func navigationCard(for book: Book, emphasized: Bool = false) -> some View {
        NavigationLink {
            BookDetailView(bookID: book.id, booksService: booksService)
        } label: {
            BookShelfCardView(book: book, emphasized: emphasized)
        }
        .buttonStyle(.plain)
    }

    private func navigationTile(for book: Book, emphasis: BookshelfCoverTileView.Emphasis) -> some View {
        NavigationLink {
            BookDetailView(bookID: book.id, booksService: booksService)
        } label: {
            BookshelfCoverTileView(book: book, emphasis: emphasis)
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryShelfSection: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let books: [Book]
    let emphasized: Bool
}

private struct LibraryControlsView: View {
    @ObservedObject var viewModel: LibraryViewModel

    private var activeFilterCount: Int {
        var count = 0
        if viewModel.query.source != .all { count += 1 }
        if viewModel.query.hasNotesOnly { count += 1 }
        if viewModel.query.recentOnly { count += 1 }
        return count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: FragmentaSpacing.tiny) {
                    Text("Shelf lens")
                        .font(FragmentaTypography.sectionTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text("Sort and filter the library without breaking the quiet rhythm of the shelf.")
                        .font(FragmentaTypography.body)
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
                ForEach(LibraryViewMode.allCases) { mode in
                    Button {
                        viewModel.setViewMode(mode)
                    } label: {
                        HStack(spacing: FragmentaSpacing.xSmall) {
                            Image(systemName: mode.systemImage)
                            Text(mode.title)
                        }
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(viewModel.viewMode == mode ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                        .chipSurfaceStyle()
                    }
                    .buttonStyle(.plain)
                }
            }

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
        .sectionSurfaceStyle()
    }
}

private struct LibrarySectionHeading: View {
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

private struct LibrarySummaryView: View {
    let books: [Book]
    let viewMode: LibraryViewMode

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

    private var recentBookLine: String {
        guard
            let latest = books.sorted(by: {
                ($0.lastImportedAt ?? .distantPast) > ($1.lastImportedAt ?? .distantPast)
            }).first
        else {
            return "Your library is ready for the next import."
        }

        if viewMode == .bookshelf {
            return "Shelf mode remembers where to look first: \(latest.title) was refreshed most recently."
        }

        return "Most recently refreshed: \(latest.title) by \(latest.displayAuthor)."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 94), spacing: FragmentaSpacing.medium)],
                alignment: .leading,
                spacing: FragmentaSpacing.medium
            ) {
                summaryCard(value: "\(books.count)", label: books.count == 1 ? "book" : "books")
                summaryCard(value: "\(totalHighlights)", label: totalHighlights == 1 ? "highlight" : "highlights")
                summaryCard(value: "\(totalNotes)", label: totalNotes == 1 ? "note" : "notes")
            }

            Text(recentBookLine)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .insetSurfaceStyle()
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

private struct BookshelfCoverTileView: View {
    enum Emphasis {
        case featured
        case standard
    }

    let book: Book
    let emphasis: Emphasis

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            ZStack(alignment: .topLeading) {
                BookCoverArtView(book: book, presentation: .bookshelf)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(CGFloat(book.resolvedCoverAspectRatio), contentMode: .fit)

                if book.isRecentlyImported {
                    Text("RECENT")
                        .font(FragmentaTypography.eyebrow)
                        .foregroundStyle(FragmentaColor.textPrimary)
                        .padding(.horizontal, FragmentaSpacing.xSmall)
                        .padding(.vertical, FragmentaSpacing.tiny)
                        .background(
                            Capsule()
                                .fill(FragmentaColor.background.opacity(0.82))
                        )
                        .padding(FragmentaSpacing.small)
                }
            }

            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                Text(book.title)
                    .font(emphasis == .featured ? FragmentaTypography.cardTitle : FragmentaTypography.bodyEmphasized)
                    .foregroundStyle(FragmentaColor.textPrimary)
                    .lineLimit(emphasis == .featured ? 3 : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(book.displayAuthor)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .lineLimit(1)

                HStack(spacing: FragmentaSpacing.small) {
                    tileChip(book.highlightCountLabel)

                    if let noteCountLabel = book.noteCountLabel, emphasis == .featured {
                        tileChip(noteCountLabel)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func tileChip(_ text: String) -> some View {
        Text(text)
            .font(FragmentaTypography.caption)
            .foregroundStyle(FragmentaColor.textTertiary)
            .chipSurfaceStyle()
    }
}

private struct LibrarySummarySkeletonView: View {
    var body: some View {
        VStack(spacing: FragmentaSpacing.medium) {
            HStack(spacing: FragmentaSpacing.medium) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                        .fill(FragmentaColor.surfaceOverlay)
                        .frame(height: 92)
                }
            }

            RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 64)
        }
        .redacted(reason: .placeholder)
    }
}

private struct BookshelfGridSkeletonView: View {
    private let columns = [GridItem(.adaptive(minimum: 148, maximum: 190), spacing: FragmentaSpacing.medium)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: FragmentaSpacing.large) {
            ForEach(0 ..< 6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                        .fill(FragmentaColor.surfaceOverlay)
                        .aspectRatio(0.67, contentMode: .fit)

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FragmentaColor.surfaceOverlay)
                        .frame(height: 18)

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FragmentaColor.surfaceOverlay)
                        .frame(width: 92, height: 14)
                }
            }
        }
        .redacted(reason: .placeholder)
    }
}

private struct LibraryStatusBanner: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(title.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
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
            Image(systemName: "books.vertical")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(FragmentaColor.textTertiary)

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
            LibraryView(
                booksService: PreviewBooksService(),
                preferencesStore: AppPreferencesStore()
            )
        }
    }
}
#endif
