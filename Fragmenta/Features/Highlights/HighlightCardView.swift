import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct HighlightCardView: View {
    let highlight: Highlight
    var isFocused = false

    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            HStack(alignment: .center) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(isFocused ? FragmentaColor.accentSoft : FragmentaColor.accent)

                Spacer()

                if isFocused {
                    Text("Focused")
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.textPrimary)
                        .chipSurfaceStyle()
                }

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
                        .fixedSize(horizontal: false, vertical: true)
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

            HStack(spacing: FragmentaSpacing.small) {
                Button(didCopy ? "Copied" : "Copy") {
                    copyToPasteboard()
                }
                .font(FragmentaTypography.metadata)
                .foregroundStyle(didCopy ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                .chipSurfaceStyle()

                ShareLink(item: highlight.shareBody) {
                    Text("Share")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .chipSurfaceStyle()
                }
            }
        }
        .paperGlassCardStyle(
            tint: isFocused
                ? FragmentaColor.accentSoft.opacity(0.2)
                : (highlight.note?.isBlank == false ? FragmentaColor.accentSoft.opacity(0.16) : FragmentaColor.accent.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                .stroke(isFocused ? FragmentaColor.accentSoft.opacity(0.35) : Color.clear, lineWidth: 1.2)
        )
    }

    private func copyToPasteboard() {
#if canImport(UIKit)
        UIPasteboard.general.string = highlight.shareBody
#endif
        HapticFeedback.selectionChanged()
        didCopy = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            didCopy = false
        }
    }
}

struct HighlightCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 120, height: 18)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 120)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 52)
        }
        .redacted(reason: .placeholder)
        .paperGlassCardStyle()
    }
}

#if DEBUG
struct HighlightCardView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            HighlightCardView(highlight: PreviewFixtures.highlights[0], isFocused: true)
                .padding(FragmentaSpacing.large)
        }
    }
}
#endif
