import SwiftUI

struct BookShelfCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
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
            }

            if let synopsis = book.synopsis, synopsis.isBlank == false {
                Text(synopsis)
                    .font(FragmentaTypography.narrative)
                    .foregroundStyle(FragmentaColor.textPrimary.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Rectangle()
                .fill(FragmentaColor.divider)
                .frame(height: 1)

            HStack(spacing: FragmentaSpacing.small) {
                Label(book.highlightCountLabel, systemImage: "quote.opening")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)

                Spacer()

                if let lastImportedAt = book.lastImportedAt {
                    Label(lastImportedAt.fragmentaDayMonthYearString(), systemImage: "clock")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textTertiary)
                }
            }
        }
        .journalCardStyle()
    }
}

#if DEBUG
struct BookShelfCardView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            BookShelfCardView(book: PreviewFixtures.books[0])
                .padding(FragmentaSpacing.large)
        }
    }
}
#endif
