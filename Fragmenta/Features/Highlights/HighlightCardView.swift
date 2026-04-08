import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct HighlightCardView: View {
    let highlight: Highlight
    let citation: HighlightCitation?
    var isFocused = false

    @State private var copyFeedback: CopyFeedback?

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            header
            quoteBlock

            if let note = highlight.note, note.isBlank == false {
                noteBlock(note)
            }

            footer
            actionRow
        }
        .paperGlassCardStyle(
            tint: isFocused
                ? FragmentaColor.accentSoft.opacity(0.2)
                : (highlight.note?.isBlank == false ? FragmentaColor.accentSoft.opacity(0.14) : FragmentaColor.accent.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                .stroke(isFocused ? FragmentaColor.accentSoft.opacity(0.35) : Color.clear, lineWidth: 1.2)
        )
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: FragmentaSpacing.xSmall) {
                if isFocused {
                    chip("Focused", foreground: FragmentaColor.textPrimary)
                }

                if let locationLabel = highlight.locationLabel {
                    chip(locationLabel, foreground: FragmentaColor.textSecondary)
                }
            }

            Spacer()

            if let highlightedAt = highlight.highlightedAt ?? highlight.createdAt {
                Text(highlightedAt.fragmentaDayMonthYearString())
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textTertiary)
            }
        }
    }

    private var quoteBlock: some View {
        HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
            Text("“")
                .font(.system(size: 52, weight: .regular, design: .serif))
                .foregroundStyle(isFocused ? FragmentaColor.accentSoft : FragmentaColor.accent)
                .padding(.top, -6)

            Text(highlight.text.trimmed)
                .font(isFocused ? FragmentaTypography.quoteEmphasized : FragmentaTypography.quote)
                .foregroundStyle(FragmentaColor.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func noteBlock(_ note: String) -> some View {
        HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
            Rectangle()
                .fill(FragmentaColor.accentSoft.opacity(0.45))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                Text("NOTE")
                    .font(FragmentaTypography.eyebrow)
                    .foregroundStyle(FragmentaColor.textTertiary)
                    .tracking(1.3)

                Text(note)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, FragmentaSpacing.small)
        .padding(.horizontal, FragmentaSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                .fill(FragmentaColor.surfaceTertiary.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        HStack(spacing: FragmentaSpacing.small) {
            if let chapter = highlight.chapter, chapter.isBlank == false {
                chip(chapter, foreground: FragmentaColor.textSecondary)
            }

            if let colorName = highlight.colorName, colorName.isBlank == false {
                chip(colorName.capitalized, foreground: FragmentaColor.textTertiary)
            }

            Spacer()
        }
    }

    private var actionRow: some View {
        HStack(spacing: FragmentaSpacing.small) {
            Button(copyFeedback == .plain ? "Copied" : "Copy") {
                copyToPasteboard(highlight.shareBody, feedback: .plain)
            }
            .font(FragmentaTypography.metadata)
            .foregroundStyle(copyFeedback == .plain ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
            .chipSurfaceStyle()

            if citation != nil {
                Button(copyFeedback == .citation ? "Copied Citation" : "Copy Citation") {
                    copyToPasteboard(highlight.copyBodyWithCitation(citation: citation), feedback: .citation)
                }
                .font(FragmentaTypography.metadata)
                .foregroundStyle(copyFeedback == .citation ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                .chipSurfaceStyle()
            }

            ShareLink(item: highlight.shareBody(citation: citation)) {
                Text("Share")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .chipSurfaceStyle()
            }
        }
    }

    private func chip(_ text: String, foreground: Color) -> some View {
        Text(text)
            .font(FragmentaTypography.chip)
            .foregroundStyle(foreground)
            .chipSurfaceStyle()
    }

    private func copyToPasteboard(_ value: String, feedback: CopyFeedback) {
#if canImport(UIKit)
        UIPasteboard.general.string = value
#endif
        HapticFeedback.selectionChanged()
        copyFeedback = feedback

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if copyFeedback == feedback {
                copyFeedback = nil
            }
        }
    }
}

private enum CopyFeedback {
    case plain
    case citation
}

struct HighlightCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(width: 140, height: 18)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 132)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FragmentaColor.surfaceOverlay)
                .frame(height: 64)
        }
        .redacted(reason: .placeholder)
        .paperGlassCardStyle()
    }
}

#if DEBUG
struct HighlightCardView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            HighlightCardView(
                highlight: PreviewFixtures.highlights[0],
                citation: HighlightCitation(
                    bookTitle: PreviewFixtures.bookDetail.book.title,
                    author: PreviewFixtures.bookDetail.book.author,
                    chapter: PreviewFixtures.highlights[0].chapter,
                    locationLabel: PreviewFixtures.highlights[0].locationLabel
                ),
                isFocused: true
            )
                .padding(FragmentaSpacing.large)
        }
    }
}
#endif
