import SwiftUI

struct ImportView: View {
    @StateObject private var viewModel: ImportViewModel

    init(highlightService: HighlightServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ImportViewModel(highlightService: highlightService))
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Import",
                        title: "Paste a Kindle export",
                        subtitle: "Sprint 1 is prepared for raw text submission now, with document picker and share-sheet flows ready to layer in later."
                    )

                    importComposer
                    statusCard
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    private var importComposer: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Kindle export text")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                    .fill(FragmentaColor.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )

                if viewModel.rawText.isBlank {
                    Text("Paste the full Kindle highlights export here.")
                        .font(FragmentaTypography.body)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .padding(FragmentaSpacing.medium)
                }

                TextEditor(text: $viewModel.rawText)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(FragmentaColor.textPrimary)
                    .frame(minHeight: 260)
                    .padding(FragmentaSpacing.small)
                    .background(Color.clear)
            }
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        switch viewModel.state {
        case .idle:
            ImportStatusCard(
                title: "Ready for ingestion",
                message: "Fragmenta will POST the raw export to `/api/imports/kindle` as JSON, keeping parsing and persistence inside fragmenta-core."
            )

        case .editing:
            ImportStatusCard(
                title: "Draft prepared",
                message: "The request body is ready. When submitted, the app will send the raw text and wait for an import response from fragmenta-core."
            )

        case .importing:
            VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
                ProgressView()
                    .tint(FragmentaColor.textPrimary)

                Text("Importing from Kindle export...")
                    .font(FragmentaTypography.subheadline)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionSurfaceStyle()

        case .success(let response):
            ImportStatusCard(
                title: "Import accepted",
                message: response.message ?? response.summaryLine
            )

        case .failure(let message):
            ImportStatusCard(
                title: "Import failed",
                message: message
            )
        }
    }

    private var actionBar: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            Button("Clear") {
                viewModel.reset()
            }
            .fragmentaAdaptiveGlassButton()

            Button {
                Task {
                    await viewModel.submit()
                }
            } label: {
                if case .importing = viewModel.state {
                    ProgressView()
                        .tint(FragmentaColor.textPrimary)
                } else {
                    Text("Send to Fragmenta")
                }
            }
            .disabled(viewModel.rawText.trimmed.isEmpty || isImporting)
            .fragmentaAdaptiveGlassButton(prominent: true)
        }
        .padding(.horizontal, FragmentaSpacing.large)
        .padding(.vertical, FragmentaSpacing.medium)
        .background(
            Rectangle()
                .fill(FragmentaColor.background.opacity(0.92))
                .ignoresSafeArea()
        )
    }

    private var isImporting: Bool {
        if case .importing = viewModel.state {
            return true
        }

        return false
    }
}

private struct ImportStatusCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

#if DEBUG
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ImportView(highlightService: PreviewHighlightService())
        }
    }
}
#endif
