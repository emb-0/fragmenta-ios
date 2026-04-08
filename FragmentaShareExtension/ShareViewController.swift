import Foundation
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private enum ShareError: LocalizedError {
        case unsupportedContent

        var errorDescription: String? {
            switch self {
            case .unsupportedContent:
                return "Share plain text or a `.txt` file to send it into Fragmenta."
            }
        }
    }

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private lazy var sharedImportStore = SharedImportStore(
        appGroupIdentifier: (Bundle.main.object(forInfoDictionaryKey: "FragmentaAppGroupIdentifier") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    )

    private var hasProcessedSharedItems = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewHierarchy()
        updatePresentation(
            title: "Preparing import",
            detail: "Fragmenta is reading the shared Kindle export and saving it for preview in the app.",
            showsActivity: true,
            actionTitle: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard hasProcessedSharedItems == false else {
            return
        }

        hasProcessedSharedItems = true

        Task { @MainActor in
            await processIncomingShare()
        }
    }

    private func configureViewHierarchy() {
        view.backgroundColor = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)

        let stackView = UIStackView(arrangedSubviews: [
            activityIndicator,
            titleLabel,
            detailLabel,
            actionButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        detailLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        detailLabel.textColor = UIColor(white: 0.82, alpha: 1)
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        actionButton.configuration = .borderedTinted()
        actionButton.addTarget(self, action: #selector(handleActionButtonTap), for: .touchUpInside)
        actionButton.isHidden = true

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @MainActor
    private func processIncomingShare() async {
        do {
            let draft = try await resolveIncomingDraft()
            try await sharedImportStore.save(draft)

            updatePresentation(
                title: "Saved for Fragmenta",
                detail: "Open Fragmenta to preview the backend parse and confirm the import.",
                showsActivity: false,
                actionTitle: "Done"
            )

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            completeExtensionRequest()
        } catch is CancellationError {
            completeExtensionRequest()
        } catch {
            let detail = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            updatePresentation(
                title: "Share failed",
                detail: detail,
                showsActivity: false,
                actionTitle: "Close"
            )
        }
    }

    private func resolveIncomingDraft() async throws -> IncomingImportDraft {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }

        for provider in providers {
            if let draft = try await draftFromFileProvider(provider) {
                return draft
            }

            if let draft = try await draftFromTextProvider(provider) {
                return draft
            }
        }

        throw ShareError.unsupportedContent
    }

    private func draftFromFileProvider(_ provider: NSItemProvider) async throws -> IncomingImportDraft? {
        let supportedTypes = [UTType.fileURL.identifier, UTType.plainText.identifier, UTType.text.identifier]

        for typeIdentifier in supportedTypes where provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
            guard let item = try await loadItem(from: provider, typeIdentifier: typeIdentifier) else {
                continue
            }

            if let url = item as? URL {
                return try TextImportLoader.draft(from: url, source: .shareExtension, accessSecurityScopedResource: false)
            }

            if let url = item as? NSURL {
                return try TextImportLoader.draft(from: url as URL, source: .shareExtension, accessSecurityScopedResource: false)
            }

            if
                let data = item as? Data,
                let path = String(data: data, encoding: .utf8),
                let url = URL(string: path),
                url.isFileURL
            {
                return try TextImportLoader.draft(from: url, source: .shareExtension, accessSecurityScopedResource: false)
            }

            if
                let path = item as? String,
                let url = URL(string: path),
                url.isFileURL
            {
                return try TextImportLoader.draft(from: url, source: .shareExtension, accessSecurityScopedResource: false)
            }
        }

        return nil
    }

    private func draftFromTextProvider(_ provider: NSItemProvider) async throws -> IncomingImportDraft? {
        let supportedTypes = [UTType.plainText.identifier, UTType.text.identifier]

        for typeIdentifier in supportedTypes where provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
            guard let item = try await loadItem(from: provider, typeIdentifier: typeIdentifier) else {
                continue
            }

            if let string = item as? String {
                return try TextImportLoader.draft(from: string, source: .shareExtension)
            }

            if let attributedString = item as? NSAttributedString {
                return try TextImportLoader.draft(from: attributedString.string, source: .shareExtension)
            }

            if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                return try TextImportLoader.draft(from: text, source: .shareExtension)
            }
        }

        return nil
    }

    private func loadItem(
        from provider: NSItemProvider,
        typeIdentifier: String
    ) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: item)
                }
            }
        }
    }

    @MainActor
    private func updatePresentation(
        title: String,
        detail: String,
        showsActivity: Bool,
        actionTitle: String?
    ) {
        titleLabel.text = title
        detailLabel.text = detail
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil

        if showsActivity {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    @objc
    private func handleActionButtonTap() {
        completeExtensionRequest()
    }

    private func completeExtensionRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
