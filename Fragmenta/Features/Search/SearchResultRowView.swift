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

            Text("“\(result.displaySnippet)”")
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textPrimary.opacity(0.9))
                .lineLimit(5)

            HStack(spacing: FragmentaSpacing.small) {
                if let locationLabel = result.highlight.locationLabel {
                    Text(locationLabel)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                if result.matchedInNote == true {
                    Text("Note match")
                        .font(FragmentaTypography.caption)
                        .foregroundStyle(FragmentaColor.accentSoft)
                        .chipSurfaceStyle()
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

struct SearchResultRowSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 180, height: 20)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 120, height: 16)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 68)
        }
        .redacted(reason: .placeholder)
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
