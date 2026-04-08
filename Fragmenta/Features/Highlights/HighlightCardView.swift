import SwiftUI

struct HighlightCardView: View {
    let highlight: Highlight

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            HStack(alignment: .center) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(FragmentaColor.accent)

                Spacer()

                if let locationLabel = highlight.locationLabel {
                    Text(locationLabel)
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .chipSurfaceStyle()
                }
            }

            Text("“\(highlight.text.trimmed)”")
                .font(FragmentaTypography.narrative)
                .foregroundStyle(FragmentaColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let note = highlight.note, note.isBlank == false {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                    Text("NOTE")
                        .font(FragmentaTypography.eyebrow)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .tracking(1.3)

                    Text(note)
                        .font(FragmentaTypography.body)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .insetSurfaceStyle()
            }

            HStack(spacing: FragmentaSpacing.small) {
                if let chapter = highlight.chapter, chapter.isBlank == false {
                    Text(chapter)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

                Spacer()

                if let highlightedAt = highlight.highlightedAt ?? highlight.createdAt {
                    Text(highlightedAt.fragmentaDayMonthYearString())
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textTertiary)
                }
            }
        }
        .paperGlassCardStyle(tint: highlight.note?.isBlank == false ? FragmentaColor.accentSoft.opacity(0.16) : FragmentaColor.accent.opacity(0.14))
    }
}

#if DEBUG
struct HighlightCardView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            HighlightCardView(highlight: PreviewFixtures.highlights[0])
                .padding(FragmentaSpacing.large)
        }
    }
}
#endif
