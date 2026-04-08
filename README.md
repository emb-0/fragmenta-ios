# Fragmenta iOS

Fragmenta iOS is the standalone native SwiftUI client for `fragmenta-core`, the separate Next.js backend that stores books, highlights, notes, imports, and exports derived from Kindle `.txt` exports.

This repository is intentionally:

- a real native iOS codebase in Swift and SwiftUI
- not a web wrapper
- not React Native
- not Expo
- not a cross-platform scaffold

Sprint 3 builds on the connected Sprint 2 shell and turns the app into a much more cohesive, premium reading product surface while also fixing the repository’s GitHub sync state.

## Sprint 3 snapshot

Sprint 3 adds:

- a stronger, more publication-minded visual system
- calmer typography and spacing hierarchy
- more tactile paper/glass surface rhythm
- more refined library cards and curated shelf sections
- a more notebook-like book detail experience
- sharper search composer and result presentation
- a more trustworthy, manuscript-like import workflow
- a more composed Settings screen
- verified GitHub remote setup and push status

## Git audit and GitHub sync

Sprint 3 started with a repository audit because the GitHub repo was not showing any project files.

### What was found

At the start of Sprint 3:

- `git status --short --branch` showed a clean local `main`
- `git branch -vv` showed `main` with no upstream tracking
- `git remote -v` returned nothing
- `git remote get-url origin` failed because `origin` did not exist
- local Sprint 1 and Sprint 2 commits existed only in the local checkout
- `gh api repos/emb-0/fragmenta-ios` confirmed the GitHub repository exists
- `git ls-remote --heads origin` returned no heads once `origin` was added, which meant the GitHub repo was effectively empty

### What was fixed

Sprint 3 fixed the repo state by:

1. adding `origin` as `git@github.com:emb-0/fragmenta-ios.git`
2. pushing local `main` to GitHub with upstream tracking
3. confirming that `main` now tracks `origin/main`

### Current repo state

Current expected state after Sprint 3:

- branch: `main`
- upstream: `origin/main`
- remote: `git@github.com:emb-0/fragmenta-ios.git`
- local history: pushed to GitHub

If you run:

```bash
git status --short --branch
git branch -vv
git remote -v
```

you should now see `main...origin/main` and the configured `origin` remote.

## Sprint 3 design direction

The iOS app now serves as the visual source of truth for Fragmenta.

Design decisions in Sprint 3:

- stronger serif emphasis for reading and quote surfaces
- rounded system typography retained for navigation and chrome
- restrained material use: glass where it adds tactility, not novelty
- richer section spacing so screens feel paced rather than dense
- cards that feel closer to bound paper and editorial objects than generic rounded panels
- more explicit visual hierarchy in search, import, and settings

The app should now read as:

- premium Apple-native
- literary
- reflective
- tactile
- restrained

## Architecture

### App shell

- `Fragmenta/App/FragmentaApp.swift`
- `Fragmenta/App/RootView.swift`
- `Fragmenta/Core/AppState.swift`
- `Fragmenta/Core/AppContainer.swift`

### Core infrastructure

- `Fragmenta/Core/AppPreferencesStore.swift`
- `Fragmenta/Core/DiagnosticsStore.swift`
- `Fragmenta/Core/FragmentaCacheStore.swift`

### Services

- `Fragmenta/Services/BooksService.swift`
- `Fragmenta/Services/SearchService.swift`
- `Fragmenta/Services/ImportService.swift`
- `Fragmenta/Services/ExportService.swift`
- `Fragmenta/Services/API/APIClient.swift`
- `Fragmenta/Services/API/APIEndpoint.swift`

### Feature areas

- `Fragmenta/Features/Library`
- `Fragmenta/Features/Highlights`
- `Fragmenta/Features/Search`
- `Fragmenta/Features/Import`
- `Fragmenta/Features/Settings`

## Important file tree

```text
fragmenta-ios/
├── Config/
│   ├── Base.xcconfig
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   └── Info.plist
├── Fragmenta/
│   ├── App/
│   ├── Core/
│   ├── DesignSystem/
│   ├── Features/
│   │   ├── Highlights/
│   │   ├── Import/
│   │   ├── Library/
│   │   ├── Search/
│   │   └── Settings/
│   ├── Models/
│   ├── Services/
│   │   └── API/
│   └── Utilities/
│       └── PreviewSupport/
├── Fragmenta.xcodeproj
├── project.yml
└── README.md
```

## Sprint 3 feature changes

### Library

- refined shelf lens controls
- curated sections such as recent, noted, and highly highlighted books
- stronger shelf cards with a more editorial treatment
- improved summary rhythm and empty states

### Book detail

- more serious book header
- more notebook-like highlight cards
- cleaner note nesting
- better quote typography
- more graceful end-of-list and loading states

### Search

- more elegant composer treatment
- clearer filter hierarchy
- stronger result rows with a more obvious reading focal point
- cleaner recent-search presentation

### Import

- better source-mode selector
- more composed manuscript editor presentation
- stronger preview and result surfaces
- more legible import history rows
- cleaner bottom action bar

### Settings

- about section
- more composed backend/environment hierarchy
- clearer export framing
- better diagnostics grouping
- more polished cache management surface

## Local persistence

Sprint 3 keeps the same lightweight persistence strategy introduced in Sprint 2:

- JSON file cache in `Caches/FragmentaCache`
- `UserDefaults` for recent searches
- `UserDefaults` for diagnostics
- `UserDefaults` for development base URL override

This is intentionally not an offline sync engine. It is a pragmatic resilience layer so the app remains useful when the network is unreliable.

## Backend assumptions

Sprint 3 keeps Sprint 2’s public, unauthenticated backend assumptions.

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

The client still assumes:

- a public API with no auth in Sprint 3
- a `data` success envelope
- an `error` object or string on failure
- `snake_case` JSON
- ISO8601 dates
- tolerant pagination payloads

## Config values

Required values:

- `FRAGMENTA_API_BASE_URL`
- `PRODUCT_BUNDLE_IDENTIFIER`
- `DEVELOPMENT_TEAM`

Current version defaults:

- `MARKETING_VERSION = 0.3.0`
- `CURRENT_PROJECT_VERSION = 3`

Current environment defaults:

- `Config/Debug.xcconfig` uses `http://127.0.0.1:3000`
- `Config/Release.xcconfig` uses `https://fragmenta-core.example.com`

## How networking works

- `AppConfig` reads `FragmentaAPIBaseURL` from `Info.plist`
- `Info.plist` resolves it from `FRAGMENTA_API_BASE_URL`
- `APIClient` builds requests from typed `APIEndpoint` values
- `PublicRequestHeadersProvider` remains the seam for future auth work
- auth is still intentionally absent in Sprint 3

In `DEBUG`, Settings includes a base URL override stored locally and applied by rebuilding the live dependency container.

## Xcode setup

### Already done in the repo

- native SwiftUI source is in place
- `Fragmenta.xcodeproj` exists
- `project.yml` exists
- xcconfig files and `Info.plist` are wired
- the repo is now connected to GitHub and pushed

### What you still need to do in Xcode

1. Open the repo folder.
2. Run `xcodegen generate` if you want to regenerate the project from `project.yml`.
3. Open `Fragmenta.xcodeproj`.
4. Select the `Fragmenta` target.
5. Set your signing team.
6. Confirm or change `PRODUCT_BUNDLE_IDENTIFIER`.
7. Set `FRAGMENTA_API_BASE_URL` for the environment you want.
8. Build and run.

### Local backend note

`Config/Debug.xcconfig` currently points to `http://127.0.0.1:3000`.

That is appropriate for a simulator on the same Mac. It will not be correct for a physical device later, because `127.0.0.1` on-device refers to the device itself rather than your Mac.

## Validation completed here

Completed in this environment:

- Git audit and GitHub sync repair
- `origin` remote setup
- push of local history to GitHub
- Sprint 3 source edits
- `xcodegen generate`
- `plutil -lint Config/Info.plist`

Not completed here:

- opening the project in Xcode
- compiling against the iOS SDK
- simulator or device execution
- visual validation of new transitions and surface rhythm on-device
- document picker validation on-device
- export share flow validation on-device
- tab bar and navigation polish validation on-device

This machine does not have Xcode installed, so those checks still need a real Xcode pass.

## What still needs Xcode or device validation

- final compile safety across all SwiftUI view changes
- tab bar presentation and navigation appearance on device
- scrolling and pagination feel in long real datasets
- share sheet behavior from export actions
- document picker behavior from Files
- clipboard and haptic behavior
- local backend reachability from simulator versus physical device

## Sprint 4 recommendations

- share sheet ingestion and app extensions
- richer book-level export actions
- stronger search snippet emphasis with real attributed matching
- cover art support and image caching if fragmenta-core exposes it
- basic UI/state tests once Xcode is available
- auth only when fragmenta-core truly requires it
