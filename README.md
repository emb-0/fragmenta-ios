# Fragmenta iOS

Fragmenta iOS is the standalone native SwiftUI client for `fragmenta-core`, the separate Next.js backend that parses Kindle `.txt` exports into books, highlights, notes, imports, and exports.

This repository is intentionally:

- a real native iOS codebase in Swift and SwiftUI
- not a web wrapper
- not React Native
- not Expo
- not a cross-platform scaffold

Sprint 4 is a tight runtime-readiness sprint. It builds on the polished Sprint 3 shell and focuses on the native behaviors that matter most when the app first meets Xcode and real device workflows: direct file ingest, share-sheet handoff structure, citation-aware actions, book-level export hooks, and cleaner diagnostics.

## Sprint 4 snapshot

Sprint 4 adds:

- app-level incoming file handling through `onOpenURL`
- document-type registration for plain-text Kindle exports
- a shared import-draft pipeline used by Files open-in-place, document picker ingest, and future share-extension handoff
- a real share-extension scaffold that stages shared text or files into an app-group-backed pending import draft
- stronger import preview, warnings, duplicate, and result presentation
- citation-aware highlight copy/share actions
- book-level markdown export hooks in Book Detail
- better load-more recovery on the reading screen
- sharper search result snippet emphasis and retry behavior
- more useful Settings diagnostics for backend, app group, and last import state

## Git state audit

Sprint 4 started by verifying repository state before any feature work.

Initial audit found:

- `git status --short --branch` showed `main...origin/main`
- `git branch -vv` showed `main` tracking `origin/main`
- `git remote -v` showed `origin` as `git@github.com:emb-0/fragmenta-ios.git`
- there were no pending local changes before Sprint 4 work began

Sprint 4 ends by committing the new work and pushing `main` back to the same remote.

Current expected repo state after Sprint 4:

- branch: `main`
- upstream: `origin/main`
- remote: `git@github.com:emb-0/fragmenta-ios.git`
- push status: Sprint 4 commits pushed to GitHub on `main`

## Important tree changes

```text
fragmenta-ios/
├── Config/
│   ├── Base.xcconfig
│   ├── Fragmenta.entitlements
│   ├── FragmentaShareExtension.entitlements
│   ├── Info.plist
│   └── ShareExtension-Info.plist
├── Fragmenta/
│   ├── App/
│   ├── Core/
│   │   └── ImportIntake/
│   ├── Features/
│   │   ├── Highlights/
│   │   ├── Import/
│   │   ├── Search/
│   │   └── Settings/
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── FragmentaShareExtension/
│   └── ShareViewController.swift
├── Fragmenta.xcodeproj
├── project.yml
└── README.md
```

Key new Sprint 4 files:

- `Fragmenta/Core/ImportIntake/IncomingImportDraft.swift`
- `Fragmenta/Core/ImportIntake/TextImportLoader.swift`
- `Fragmenta/Core/ImportIntake/SharedImportStore.swift`
- `FragmentaShareExtension/ShareViewController.swift`
- `Config/Fragmenta.entitlements`
- `Config/FragmentaShareExtension.entitlements`
- `Config/ShareExtension-Info.plist`

## Sprint 4 implementation notes

### Runtime readiness

- `AppState` now owns pending incoming import drafts and incoming file error messaging.
- `FragmentaApp` refreshes pending shared drafts on launch and when the scene becomes active.
- `Info.plist` now declares plain-text document support and opening-in-place support.
- version defaults were advanced to Sprint 4 values:
  - `MARKETING_VERSION = 0.4.0`
  - `CURRENT_PROJECT_VERSION = 4`

### Native ingest

- Files-based `.txt` ingest still uses `UIDocumentPicker`, but now routes through a shared `TextImportLoader`.
- direct open-from-Files is scaffolded through `onOpenURL`
- pending shared import drafts can be written into an app group and then picked up inside the app
- the Import screen now understands incoming drafts from:
  - pasted text
  - document picker
  - Files app
  - share extension

### Share extension

Sprint 4 includes a real share-extension scaffold:

- target declared in `project.yml`
- `ShareViewController` extracts shared text or file URLs
- the extension stores a pending import draft into the configured app group
- the main app reads that draft and routes the user to Import for preview/commit

This still needs Xcode/device validation, but the project structure, plist, entitlements, source files, and handoff path are now in place.

### Export, copy, and share

- `ExportService` now supports:
  - library-wide export
  - book-level export via `book_id`
- Book Detail now exposes a book-level markdown export/share affordance
- highlight cards now support:
  - plain copy
  - copy with citation
  - share with citation
- search results now offer copy actions from a context menu

### Reading and search polish

- Book Detail now has load-more retry handling
- long quotes and notes are explicitly text-selectable
- search results now emphasize matched terms inside the snippet
- search failures now offer a retry path

### Settings and diagnostics

- Settings now displays:
  - active backend URL
  - default backend URL
  - configured app group identifier
  - cached last import response
- cache clearing now also clears pending shared import drafts

## Local persistence

Fragmenta now uses two lightweight persistence layers:

- `Caches/FragmentaCache` for library, book detail, import history, and import/export payload caching
- `UserDefaults` for recent searches, diagnostics, and debug base URL override

Sprint 4 adds a third small persistence seam for native handoff:

- app-group-backed pending import draft storage for share-extension to main-app handoff

This is still intentionally not a full offline sync engine.

## Backend assumptions

Fragmenta still assumes a public backend with no auth in Sprint 4.

Expected endpoints:

- `GET /api/books`
- `GET /api/books/{id}`
- `GET /api/books/{id}/highlights?page=&limit=`
- `GET /api/highlights/{id}`
- `GET /api/search?q=&book_id=&author=&has_notes=&sort=&page=&limit=`
- `POST /api/imports/kindle`
- `POST /api/imports/kindle/preview`
- `GET /api/imports`
- `GET /api/imports/{id}`
- `GET /api/exports/markdown`
- `GET /api/exports/csv`

Sprint 4 also assumes book-level export can be represented cleanly as:

- `GET /api/exports/markdown?book_id={id}`
- `GET /api/exports/csv?book_id={id}` if needed later

Transport assumptions remain:

- success responses use a `data` envelope
- errors use an `error` object or string
- payloads are `snake_case`
- dates are ISO8601 strings
- pagination payloads may vary slightly, so the client remains tolerant

## Config values

Set these before running in Xcode:

- `FRAGMENTA_API_BASE_URL`
- `FRAGMENTA_APP_GROUP_IDENTIFIER`
- `PRODUCT_BUNDLE_IDENTIFIER`
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER`
- `DEVELOPMENT_TEAM`

Current defaults in `Config/Base.xcconfig`:

- `PRODUCT_BUNDLE_IDENTIFIER = com.fragmenta.ios`
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER = com.fragmenta.ios.share`
- `FRAGMENTA_APP_GROUP_IDENTIFIER = group.com.fragmenta.shared`
- `MARKETING_VERSION = 0.4.0`
- `CURRENT_PROJECT_VERSION = 4`

Environment notes:

- `Config/Debug.xcconfig` points at `http://127.0.0.1:3000`
- `Config/Release.xcconfig` points at `https://fragmenta-core.example.com`

`127.0.0.1` is correct for an iOS simulator on the same Mac. It is not correct for a physical device.

## Exact Xcode validation steps

When you return to Xcode:

1. Open `/Users/emmettbell/claude/Code/fragmenta-ios`.
2. Run `xcodegen generate` if you want to regenerate from `project.yml`.
3. Open `Fragmenta.xcodeproj`.
4. Set your signing team for both:
   - `Fragmenta`
   - `FragmentaShareExtension`
5. Confirm or replace:
   - `PRODUCT_BUNDLE_IDENTIFIER`
   - `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER`
6. Set `FRAGMENTA_API_BASE_URL`.
7. Add the App Groups capability to both targets and use the same `FRAGMENTA_APP_GROUP_IDENTIFIER`.
8. Build the app target first.
9. Validate these flows in order:
   - launch and initial library load
   - book detail pagination
   - search tap-through into focused highlight context
   - import via pasted text
   - import via document picker
   - opening a `.txt` file into Fragmenta from Files
   - book markdown export/share
   - share extension handoff from shared text or a shared `.txt` file

## Validation completed here

Completed in this environment:

- git audit of local branch, upstream, and remote
- Sprint 4 source changes
- `xcodegen generate`
- `plutil -lint Config/Info.plist`
- `plutil -lint Config/ShareExtension-Info.plist`
- `plutil -lint` for both entitlements files

Not completed here:

- compiling against the iOS SDK in Xcode
- simulator execution
- device execution
- App Groups capability setup in Xcode
- share-extension runtime validation
- document-open runtime validation from Files
- share/export runtime validation through the real system share sheet

This machine still does not have Xcode installed, so those checks remain real follow-up work.

## What still needs real device or runtime verification

- first compile across the new app target and share-extension target
- whether the configured app group resolves correctly under your signing setup
- direct `.txt` open from Files into Fragmenta
- share-extension handoff from Files, Notes, Safari, or Kindle-adjacent sources
- share sheet presentation for book markdown export
- clipboard/haptics behavior on device
- pagination feel with larger real highlight datasets

## Sprint 5 recommendations

- validate and harden the share extension on real devices
- add targeted tests around import-draft decoding and handoff state
- refine export destinations and sharing UX once runtime behavior is confirmed
- tighten any compile/runtime issues discovered during the first real Xcode pass
- consider richer reading affordances only after the ingest/share loop is fully validated
