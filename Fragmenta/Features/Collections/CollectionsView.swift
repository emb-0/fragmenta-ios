import SwiftUI

struct CollectionsView: View {
    @StateObject private var viewModel: CollectionsViewModel

    private let booksService: BooksServiceProtocol
    private let collectionsService: CollectionsServiceProtocol

    init(
        collectionsService: CollectionsServiceProtocol,
        booksService: BooksServiceProtocol
    ) {
        _viewModel = StateObject(wrappedValue: CollectionsViewModel(collectionsService: collectionsService))
        self.collectionsService = collectionsService
        self.booksService = booksService
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Collections",
                        title: "Organize the private shelf",
                        subtitle: "A quieter way to group books by season, mood, theme, or whatever reading logic makes sense to you."
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
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        let collections = viewModel.state.value ?? []

            if collections.isEmpty {
                switch viewModel.state {
                case .idle, .loading:
                    VStack(spacing: FragmentaSpacing.large) {
                        ForEach(0 ..< 3, id: \.self) { _ in
                            CollectionCardSkeletonView()
                        }
                    }
                case .failed(let message, _):
                    CollectionsStatusCard(title: "Collections unavailable", message: message)
                case .loaded:
                    CollectionsStatusCard(
                        title: "No collections yet",
                        message: "Once fragmenta-core starts returning saved collections, they will appear here as a calmer organizational layer above the shelf."
                    )
                }
        } else {
            VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                if case .failed(let message, let previous) = viewModel.state, previous != nil {
                    CollectionsStatusCard(title: "Showing saved collections", message: message)
                }

                ForEach(collections) { collection in
                    NavigationLink {
                        CollectionDetailView(
                            collectionID: collection.id,
                            collectionsService: collectionsService,
                            booksService: booksService
                        )
                    } label: {
                        CollectionCardView(collection: collection)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct CollectionDetailView: View {
    @StateObject private var viewModel: CollectionDetailViewModel

    private let booksService: BooksServiceProtocol

    init(
        collectionID: String,
        collectionsService: CollectionsServiceProtocol,
        booksService: BooksServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CollectionDetailViewModel(
                collectionID: collectionID,
                collectionsService: collectionsService
            )
        )
        self.booksService = booksService
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxxLarge) {
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
        .navigationTitle("Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        let detail = viewModel.state.value

        if detail == nil {
            switch viewModel.state {
            case .idle, .loading:
                VStack(spacing: FragmentaSpacing.large) {
                    CollectionCardSkeletonView()
                    ForEach(0 ..< 2, id: \.self) { _ in
                        BookShelfCardSkeletonView()
                    }
                }
            case .failed(let message, _):
                CollectionsStatusCard(title: "Collection unavailable", message: message)
            case .loaded:
                EmptyView()
            }
        } else if let detail {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                CollectionDetailHero(detail: detail)

                if case .failed(let message, let previous) = viewModel.state, previous != nil {
                    CollectionsStatusCard(title: "Showing saved collection", message: message)
                }

                VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                    CollectionsSectionHeading(
                        title: detail.books.isEmpty ? "Books" : "\(detail.books.count) books",
                        subtitle: "The books currently gathered under this collection."
                    )

                    if detail.books.isEmpty {
                        CollectionsStatusCard(
                            title: "No books here yet",
                            message: "Add books from the book detail screen when you want this collection to start holding part of your shelf."
                        )
                    } else {
                        ForEach(detail.books) { book in
                            NavigationLink {
                                BookDetailView(bookID: book.id, booksService: booksService)
                            } label: {
                                BookShelfCardView(book: book)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if viewModel.removingBookIDs.contains(book.id) {
                                    Text("Removing...")
                                } else {
                                    Button("Remove from Collection", role: .destructive) {
                                        viewModel.remove(book)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BookCollectionsSheet: View {
    @StateObject private var viewModel = BookCollectionsSheetModel()

    let book: Book
    let collectionsService: CollectionsServiceProtocol

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Collections",
                        title: book.title,
                        subtitle: "Place this book into the collections fragmenta-core already knows about."
                    )

                    if let errorMessage = viewModel.errorMessage {
                        CollectionsStatusCard(title: "Membership issue", message: errorMessage)
                    }

                    let collections = viewModel.state.value ?? []

                    if collections.isEmpty {
                        switch viewModel.state {
                        case .idle, .loading:
                            VStack(spacing: FragmentaSpacing.large) {
                                ForEach(0 ..< 2, id: \.self) { _ in
                                    CollectionCardSkeletonView()
                                }
                            }
                        case .failed(let message, _):
                            CollectionsStatusCard(title: "Collections unavailable", message: message)
                        case .loaded:
                            CollectionsStatusCard(
                                title: "No collections returned",
                                message: "The backend did not return any collections for this book yet."
                            )
                        }
                    } else {
                        ForEach(collections) { collection in
                            Button {
                                viewModel.toggleMembership(
                                    for: collection,
                                    bookID: book.id,
                                    service: collectionsService
                                )
                            } label: {
                                CollectionMembershipRow(
                                    collection: collection,
                                    isUpdating: viewModel.updatingCollectionIDs.contains(collection.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.vertical, FragmentaSpacing.large)
            }
        }
        .task {
            viewModel.load(bookID: book.id, service: collectionsService)
        }
    }
}

private struct CollectionCardView: View {
    let collection: Collection

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
                CollectionPreviewStack(books: collection.previewBooks)
                    .frame(width: 88)

                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    Text(collection.title)
                        .font(FragmentaTypography.cardTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text(collection.subtitleLine)
                        .font(FragmentaTypography.body)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .lineLimit(3)

                    if collection.tags.isEmpty == false {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: FragmentaSpacing.small) {
                                ForEach(Array(collection.tags.prefix(4)), id: \.self) { tag in
                                    Text(tag)
                                        .font(FragmentaTypography.chip)
                                        .foregroundStyle(FragmentaColor.textSecondary)
                                        .chipSurfaceStyle()
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: FragmentaSpacing.small) {
                collectionMetric(collection.bookCount == 1 ? "1 book" : "\(collection.bookCount) books")

                if let highlightCount = collection.highlightCount {
                    collectionMetric(highlightCount == 1 ? "1 highlight" : "\(highlightCount) highlights")
                }

                if let noteCount = collection.noteCount {
                    collectionMetric(noteCount == 1 ? "1 note" : "\(noteCount) notes")
                }
            }
        }
        .sectionSurfaceStyle()
    }

    private func collectionMetric(_ title: String) -> some View {
        Text(title)
            .font(FragmentaTypography.chip)
            .foregroundStyle(FragmentaColor.textTertiary)
            .chipSurfaceStyle()
    }
}

private struct CollectionDetailHero: View {
    let detail: CollectionDetail

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            HStack(alignment: .top, spacing: FragmentaSpacing.large) {
                CollectionPreviewStack(books: Array(detail.books.prefix(3)))
                    .frame(width: 104)

                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    Text(detail.title)
                        .font(FragmentaTypography.heroDisplay)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    if let summary = detail.summary, summary.isBlank == false {
                        Text(summary)
                            .font(FragmentaTypography.body)
                            .foregroundStyle(FragmentaColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: FragmentaSpacing.medium) {
                detailMetric("\(detail.bookCount)", label: "books")

                if let highlightCount = detail.highlightCount {
                    detailMetric("\(highlightCount)", label: "highlights")
                }

                if let noteCount = detail.noteCount {
                    detailMetric("\(noteCount)", label: "notes")
                }
            }

            if detail.tags.isEmpty == false {
                HStack(spacing: FragmentaSpacing.small) {
                    ForEach(detail.tags, id: \.self) { tag in
                        Text(tag)
                            .font(FragmentaTypography.chip)
                            .foregroundStyle(FragmentaColor.textSecondary)
                            .chipSurfaceStyle()
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .journalCardStyle()
    }

    private func detailMetric(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(value)
                .font(FragmentaTypography.bodyEmphasized)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct CollectionMembershipRow: View {
    let collection: Collection
    let isUpdating: Bool

    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            CollectionPreviewStack(books: collection.previewBooks)
                .frame(width: 72)

            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                Text(collection.title)
                    .font(FragmentaTypography.bodyEmphasized)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(collection.subtitleLine)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isUpdating {
                ProgressView()
                    .tint(FragmentaColor.textPrimary)
            } else {
                Image(systemName: collection.containsBook == true ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(collection.containsBook == true ? FragmentaColor.accentSoft : FragmentaColor.textTertiary)
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct CollectionPreviewStack: View {
    let books: [Book]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)

            if let leadBook = books.first {
                BookCoverArtView(book: leadBook, presentation: .list)
                    .clipShape(RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous))
            }

            HStack(spacing: -14) {
                ForEach(Array(books.dropFirst().prefix(2))) { book in
                    BookCoverArtView(book: book, presentation: .list)
                        .frame(width: 28, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(FragmentaColor.background.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(FragmentaSpacing.small)
        }
        .aspectRatio(0.78, contentMode: .fit)
    }
}

private struct CollectionsSectionHeading: View {
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

private struct CollectionsStatusCard: View {
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

private struct CollectionCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 120)
        }
        .redacted(reason: .placeholder)
    }
}

#if DEBUG
struct CollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CollectionsView(
                collectionsService: PreviewCollectionsService(),
                booksService: PreviewBooksService()
            )
        }
        .environmentObject(AppState(container: .preview))
    }
}
#endif
