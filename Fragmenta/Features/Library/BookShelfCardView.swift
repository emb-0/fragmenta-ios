import SwiftUI

struct BookShelfCardView: View {
    let book: Book
    var emphasized = false

    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                    if book.isRecentlyImported {
                        Text("RECENTLY IMPORTED")
                            .font(FragmentaTypography.eyebrow)
                            .foregroundStyle(FragmentaColor.accentSoft)
                            .tracking(1.3)
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

                Text(book.source.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(FragmentaTypography.eyebrow)
                    .foregroundStyle(FragmentaColor.textTertiary)
                    .tracking(1.2)
                    .chipSurfaceStyle()
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
                Label(book.highlightCountLabel, systemImage: "quote.opening")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)

                if let noteCountLabel = book.noteCountLabel {
                    Text(noteCountLabel)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                Spacer()

                if let lastImportedAt = book.lastImportedAt {
                    Label(lastImportedAt.fragmentaDayMonthYearString(), systemImage: "clock")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textTertiary)
                }
            }
        }

        if emphasized {
            cardContent.paperGlassCardStyle(tint: FragmentaColor.accent.opacity(0.14))
        } else {
            cardContent.journalCardStyle()
        }
    }
}

struct BookShelfCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 120, height: 12)

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
