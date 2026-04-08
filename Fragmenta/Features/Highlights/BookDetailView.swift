import SwiftUI

struct BookDetailView: View {
    @StateObject private var viewModel: BookDetailViewModel

    init(bookID: String, booksService: BooksServiceProtocol) {
        _viewModel = StateObject(wrappedValue: BookDetailViewModel(bookID: bookID, booksService: booksService))
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    detailContent
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
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            VStack(spacing: FragmentaSpacing.medium) {
                ProgressView()
                    .tint(FragmentaColor.textPrimary)

                Text("Loading book details...")
                    .font(FragmentaTypography.subheadline)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, FragmentaSpacing.xxLarge)

        case .failed(let message):
            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                Text("Book unavailable")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(message)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionSurfaceStyle()

        case .loaded(let detail):
            VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                BookDetailHeroView(detail: detail)

                VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                    Text("Highlights")
                        .font(FragmentaTypography.sectionTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    ForEach(detail.highlights) { highlight in
                        HighlightCardView(highlight: highlight)
                    }
                }
            }
        }
    }
}

private struct BookDetailHeroView: View {
    let detail: BookDetail

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                Text(detail.book.title)
                    .font(FragmentaTypography.display)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(detail.book.displayAuthor)
                    .font(FragmentaTypography.subheadline)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            if let synopsis = detail.book.synopsis, synopsis.isBlank == false {
                Text(synopsis)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            HStack(spacing: FragmentaSpacing.medium) {
                metric(value: "\(detail.stats.highlightCount)", label: "highlights")
                metric(value: "\(detail.stats.noteCount)", label: "notes")

                if let lastImportedAt = detail.stats.lastImportedAt {
                    metric(value: lastImportedAt.fragmentaDayMonthYearString(), label: "imported")
                }
            }
        }
        .journalCardStyle()
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

#if DEBUG
struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BookDetailView(bookID: PreviewFixtures.books[0].id, booksService: PreviewBooksService())
        }
    }
}
#endif
