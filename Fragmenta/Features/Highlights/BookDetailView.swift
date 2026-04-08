import SwiftUI

struct BookDetailView: View {
    @StateObject private var viewModel: BookDetailViewModel

    init(
        bookID: String,
        focusHighlightID: String? = nil,
        booksService: BooksServiceProtocol
    ) {
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
                }
            }
            .navigationTitle("Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                viewModel.loadIfNeeded()
            }
            .onChange(of: viewModel.focusedHighlightID) { focusedHighlightID in
                guard let focusedHighlightID else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.28)) {
                    proxy.scrollTo(focusedHighlightID, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        let detail = viewModel.detailState.value
        let highlights = viewModel.highlightsState.value ?? []

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
                }

                if case .failed(let message, let previous) = viewModel.detailState, previous != nil {
                    DetailStatusCard(title: "Showing saved book detail", message: message)
                }

                if case .failed(let message, let previous) = viewModel.highlightsState, previous != nil {
                    DetailStatusCard(title: "Showing saved highlights", message: message)
                }

                VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                        Text("Captured passages")
                            .font(FragmentaTypography.sectionTitle)
                            .foregroundStyle(FragmentaColor.textPrimary)

                        Text("A scrolling notebook of the lines, notes, and locations carried back from the book.")
                            .font(FragmentaTypography.metadata)
                            .foregroundStyle(FragmentaColor.textSecondary)
                    }

                    if highlights.isEmpty {
                        DetailStatusCard(
                            title: "No highlights yet",
                            message: "This book is present in the library, but fragmenta-core has not returned any saved passages yet."
                        )
                    } else {
                        ForEach(highlights) { highlight in
                            HighlightCardView(
                                highlight: highlight,
                                isFocused: highlight.id == viewModel.focusedHighlightID
                            )
                            .id(highlight.id)
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentHighlight: highlight)
                            }
                        }
                    }

                    if viewModel.isLoadingMore {
                        LoadMoreHighlightsFooter()
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
}

private struct BookDetailHeroView: View {
    let detail: BookDetail
    let isShowingFocusedContext: Bool

    var body: some View {
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
        .modifier(BookDetailHeroSurface(isShowingFocusedContext: isShowingFocusedContext))
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
    }
}
#endif
