import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SearchResultRowView: View {
    let result: HighlightSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                    Text(result.book.title)
                        .font(FragmentaTypography.cardTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text(result.book.displayAuthor)
                        .font(FragmentaTypography.subheadline)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(FragmentaColor.textTertiary)
                    .padding(FragmentaSpacing.small)
                    .background(
                        Circle()
                            .fill(FragmentaColor.surfaceOverlay)
                    )
            }

            HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
                Text("“")
                    .font(.system(size: 40, weight: .regular, design: .serif))
                    .foregroundStyle(result.matchedInNote == true ? FragmentaColor.accentSoft : FragmentaColor.accent)
                    .padding(.top, -4)

                Text(highlightedSnippet)
                    .font(FragmentaTypography.narrative)
                    .foregroundStyle(FragmentaColor.textPrimary.opacity(0.92))
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, FragmentaSpacing.small)
            .padding(.horizontal, FragmentaSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                    .fill(FragmentaColor.surfaceTertiary.opacity(0.84))
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )

            HStack(spacing: FragmentaSpacing.small) {
                if let locationLabel = result.highlight.locationLabel {
                    metadataChip(locationLabel)
                }

                if result.matchedInNote == true {
                    Text("Note match")
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.accentSoft)
                        .chipSurfaceStyle()
                }

                Spacer()
            }

            if result.matchedTerms.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FragmentaSpacing.small) {
                        ForEach(Array(result.matchedTerms.prefix(4)), id: \.self) { term in
                            Text(term)
                                .font(FragmentaTypography.chip)
                                .foregroundStyle(FragmentaColor.textSecondary)
                                .chipSurfaceStyle()
                        }
                    }
                }
            }
        }
        .sectionSurfaceStyle()
        .contextMenu {
            Button("Copy Snippet") {
                copyToPasteboard(result.highlight.shareBody)
            }

            Button("Copy With Citation") {
                copyToPasteboard(result.highlight.copyBodyWithCitation(citation: citation))
            }
        }
    }

    private func metadataChip(_ title: String) -> some View {
        Text(title)
            .font(FragmentaTypography.chip)
            .foregroundStyle(FragmentaColor.textSecondary)
            .chipSurfaceStyle()
    }

    private var citation: HighlightCitation {
        HighlightCitation(
            bookTitle: result.book.title,
            author: result.book.author,
            chapter: result.highlight.chapter,
            locationLabel: result.highlight.locationLabel
        )
    }

    private var highlightedSnippet: AttributedString {
        var attributed = AttributedString(result.displaySnippet)
        let terms = result.matchedTerms
            .map(\.trimmed)
            .filter { $0.isBlank == false }
            .sorted { $0.count > $1.count }

        for term in terms {
            var searchRange = attributed.startIndex ..< attributed.endIndex

            while let range = attributed.range(of: term, options: [.caseInsensitive], range: searchRange, locale: .current) {
                attributed[range].foregroundColor = result.matchedInNote == true ? FragmentaColor.accentSoft : FragmentaColor.accent
                searchRange = range.upperBound ..< attributed.endIndex
            }
        }

        return attributed
    }

    private func copyToPasteboard(_ value: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = value
#endif
        HapticFeedback.selectionChanged()
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
                .frame(height: 94)
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
