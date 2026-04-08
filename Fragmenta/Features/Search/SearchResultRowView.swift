import SwiftUI

struct SearchResultRowView: View {
    let result: HighlightSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                Text(result.book.title)
                    .font(FragmentaTypography.cardTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(result.book.displayAuthor)
                    .font(FragmentaTypography.subheadline)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            Text("“\(result.highlight.text.trimmed)”")
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textPrimary.opacity(0.9))
                .lineLimit(4)

            HStack(spacing: FragmentaSpacing.small) {
                if let locationLabel = result.highlight.locationLabel {
                    Text(locationLabel)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                Spacer()

                if result.matchedTerms.isEmpty == false {
                    Text(result.matchedTerms.joined(separator: " · "))
                        .font(FragmentaTypography.caption)
                        .foregroundStyle(FragmentaColor.textTertiary)
                }
            }
        }
        .sectionSurfaceStyle()
    }
}

#if DEBUG
struct SearchResultRowView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            SearchResultRowView(result: PreviewFixtures.searchResults[0])
                .padding(FragmentaSpacing.large)
        }
    }
}
#endif
