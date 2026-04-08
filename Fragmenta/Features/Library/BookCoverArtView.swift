import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum BookCoverPresentation {
    case list
    case bookshelf
    case hero

    var maxPixelSize: CGFloat {
        switch self {
        case .list:
            return 320
        case .bookshelf:
            return 480
        case .hero:
            return 720
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .list:
            return FragmentaRadius.medium
        case .bookshelf:
            return FragmentaRadius.large
        case .hero:
            return FragmentaRadius.hero
        }
    }
}

struct BookCoverArtView: View {
    let book: Book
    let presentation: BookCoverPresentation

    @StateObject private var loader: BookCoverImageLoader

    init(book: Book, presentation: BookCoverPresentation) {
        self.book = book
        self.presentation = presentation
        _loader = StateObject(
            wrappedValue: BookCoverImageLoader(
                url: {
                    switch presentation {
                    case .list, .bookshelf:
                        return book.coverThumbnailURL ?? book.coverURL
                    case .hero:
                        return book.coverURL ?? book.coverThumbnailURL
                    }
                }(),
                maxPixelSize: presentation.maxPixelSize
            )
        )
    }

    var body: some View {
        ZStack {
            BookCoverFallbackView(book: book, presentation: presentation)

            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.animation(.easeOut(duration: 0.18)))
            } else if loader.isLoading {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.04),
                        Color.white.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: presentation.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: presentation.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: FragmentaColor.shadow.opacity(0.18), radius: 12, x: 0, y: 8)
        .task {
            loader.loadIfNeeded()
        }
    }
}

@MainActor
final class BookCoverImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false

    private let url: URL?
    private let maxPixelSize: CGFloat
    private let pipeline: CoverImagePipeline
    private var task: Task<Void, Never>?

    init(
        url: URL?,
        maxPixelSize: CGFloat,
        pipeline: CoverImagePipeline = .shared
    ) {
        self.url = url
        self.maxPixelSize = maxPixelSize
        self.pipeline = pipeline
    }

    deinit {
        task?.cancel()
    }

    func loadIfNeeded() {
        guard image == nil, isLoading == false, let url else {
            return
        }

        isLoading = true
        task = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            defer { isLoading = false }

            do {
                image = try await pipeline.image(for: url, maxPixelSize: maxPixelSize)
            } catch is CancellationError {
                return
            } catch {
                image = nil
            }
        }
    }
}

private struct BookCoverFallbackView: View {
    let book: Book
    let presentation: BookCoverPresentation

    private var palette: [Color] {
        if
            let backgroundHex = book.cover?.backgroundHex,
            let background = Color(fragmentaHexString: backgroundHex)
        {
            let foreground = book.cover?.foregroundHex.flatMap { Color(fragmentaHexString: $0) } ?? FragmentaColor.textPrimary
            return [background.opacity(0.98), background.opacity(0.82), foreground.opacity(0.2)]
        }

        let palettes: [[Color]] = [
            [FragmentaColor.surfaceQuaternary, FragmentaColor.accent.opacity(0.72), FragmentaColor.surfaceMuted],
            [FragmentaColor.surfaceSecondary, FragmentaColor.accentSoft.opacity(0.78), FragmentaColor.surfaceMuted],
            [FragmentaColor.surfacePrimary, FragmentaColor.success.opacity(0.64), FragmentaColor.surfaceMuted],
            [FragmentaColor.surfaceSecondary, FragmentaColor.warning.opacity(0.68), FragmentaColor.surfaceMuted]
        ]

        let index = abs(book.id.hashValue) % palettes.count
        return palettes[index]
    }

    private var monogram: String {
        let letters = book.title
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()

        return letters.isEmpty ? "BK" : letters.uppercased()
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: palette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                Text(monogram)
                    .font(presentation == .hero ? FragmentaTypography.display : FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary.opacity(0.94))

                Spacer(minLength: 0)

                Text(book.title)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textPrimary.opacity(0.9))
                    .lineLimit(presentation == .hero ? 3 : 2)

                if presentation != .hero {
                    Text(book.displayAuthor)
                        .font(FragmentaTypography.caption)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(presentation == .hero ? FragmentaSpacing.large : FragmentaSpacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .overlay(alignment: .topTrailing) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, presentation == .hero ? FragmentaSpacing.large : FragmentaSpacing.medium)
                .padding(.trailing, presentation == .hero ? FragmentaSpacing.medium : FragmentaSpacing.small)
        }
    }
}

#if DEBUG
struct BookCoverArtView_Previews: PreviewProvider {
    static var previews: some View {
        FragmentaScreenBackground {
            HStack(alignment: .top, spacing: FragmentaSpacing.large) {
                BookCoverArtView(book: PreviewFixtures.books[0], presentation: .bookshelf)
                    .frame(width: 148)
                    .aspectRatio(CGFloat(PreviewFixtures.books[0].resolvedCoverAspectRatio), contentMode: .fit)

                BookCoverArtView(book: PreviewFixtures.books[1], presentation: .hero)
                    .frame(width: 140)
                    .aspectRatio(CGFloat(PreviewFixtures.books[1].resolvedCoverAspectRatio), contentMode: .fit)
            }
            .padding(FragmentaSpacing.large)
        }
    }
}
#endif
