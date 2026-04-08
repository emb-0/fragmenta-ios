import SwiftUI

struct BookShelfCardView: View {
    let book: Book
    var emphasized = false

    var body: some View {
        let cardContent = HStack(alignment: .top, spacing: FragmentaSpacing.large) {
            BookCoverArtView(book: book, presentation: .list)
                .frame(width: 82, height: emphasized ? 132 : 118)

            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                HStack(alignment: .top, spacing: FragmentaSpacing.small) {
                    VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                        HStack(spacing: FragmentaSpacing.xSmall) {
                            if book.isRecentlyImported {
                                Text("RECENTLY IMPORTED")
                                    .font(FragmentaTypography.eyebrow)
                                    .foregroundStyle(FragmentaColor.accentSoft)
                                    .tracking(1.3)
                            }

                            if let noteCountLabel = book.noteCountLabel {
                                Text(noteCountLabel.uppercased())
                                    .font(FragmentaTypography.eyebrow)
                                    .foregroundStyle(FragmentaColor.textTertiary)
                                    .tracking(1.1)
                            }
                        }

                        Text(book.title)
                            .font(FragmentaTypography.cardTitle)
                            .foregroundStyle(FragmentaColor.textPrimary)
                            .multilineTextAlignment(.leading)

                        Text(book.displayAuthor)
                            .font(FragmentaTypography.subheadline)
                            .foregroundStyle(FragmentaColor.textSecondary)
                    }

                    Spacer(minLength: FragmentaSpacing.medium)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .padding(FragmentaSpacing.small)
                        .background(
                            Circle()
                                .fill(FragmentaColor.surfaceOverlay)
                        )
                }

                if let synopsis = book.synopsis, synopsis.isBlank == false {
                    Text(synopsis)
                        .font(FragmentaTypography.narrative)
                        .foregroundStyle(FragmentaColor.textPrimary.opacity(0.9))
                        .lineLimit(emphasized ? 4 : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Rectangle()
                    .fill(FragmentaColor.divider)
                    .frame(height: 1)

                HStack(spacing: FragmentaSpacing.small) {
                    metadataChip(book.highlightCountLabel, systemImage: "quote.opening")
                    metadataChip(sourceLabel, systemImage: "books.vertical")

                    Spacer()

                    if let lastImportedAt = book.lastImportedAt {
                        metadataChip(lastImportedAt.fragmentaDayMonthYearString(), systemImage: "clock")
                    }
                }
            }
        }

        if emphasized {
            cardContent.paperGlassCardStyle(tint: FragmentaColor.accent.opacity(0.14))
        } else {
            cardContent.journalCardStyle()
        }
    }

    private var sourceLabel: String {
        book.source.rawValue
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func metadataChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(FragmentaTypography.metadata)
            .foregroundStyle(FragmentaColor.textSecondary)
            .chipSurfaceStyle()
    }
}

struct BookShelfCardSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: FragmentaSpacing.large) {
            RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 82, height: 118)

            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(width: 140, height: 12)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(height: 24)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(width: 160, height: 18)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(height: 74)

                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(FragmentaColor.divider)
                    .frame(height: 1)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(FragmentaColor.surfaceOverlay)
                    .frame(height: 18)
            }
        }
        .redacted(reason: .placeholder)
        .journalCardStyle()
    }
}

#if DEBUG
struct BookShelfCardView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            VStack(spacing: FragmentaSpacing.large) {
                BookShelfCardView(book: PreviewFixtures.books[0], emphasized: true)
                BookShelfCardView(book: PreviewFixtures.books[1])
            }
            .padding(FragmentaSpacing.large)
        }
    }
}
#endif
