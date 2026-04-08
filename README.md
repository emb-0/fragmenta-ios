# Fragmenta iOS

Fragmenta iOS is the native SwiftUI client for `fragmenta-core`, the separate Next.js backend that ingests Kindle exports into books, highlights, notes, collections, insights, exports, discovery surfaces, and share artifacts.

Sprint 1 through Sprint 6 are complete. Sprint 7 is the stabilization pass that makes this repo compile cleanly, configure cleanly, and validate with less friction on a fresh Mac.

## Sprint 7 focus

- tighten Xcode and xcconfig setup
- reduce signing and App Group confusion
- align the iOS client with the backend routes and payloads currently present in `fragmenta-core`
- build the app target and share extension target cleanly
- document the exact setup and validation flow for tonight

## Current project shape

- native app target: `Fragmenta`
- share extension target: `FragmentaShareExtension`
- generated project: `Fragmenta.xcodeproj`
- source of truth for generation: `project.yml`
- config files: `Config/Base.xcconfig`, `Config/Debug.xcconfig`, `Config/Release.xcconfig`
- optional local override: `Config/Local.xcconfig`

`Config/Local.xcconfig` is intentionally gitignored. Use `Config/Local.xcconfig.example` as the starting point on each machine.

## Quick start on this Mac mini

1. Copy the local config template:

```sh
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

2. Set the required values in `Config/Local.xcconfig`.
3. Regenerate the project after any `project.yml` change:

```sh
xcodegen generate
```

4. Open `Fragmenta.xcodeproj` in Xcode.
5. In Xcode, confirm signing for both targets:
   - `Fragmenta`
   - `FragmentaShareExtension`
6. In Xcode, open Signing & Capabilities for both targets and verify:
   - the Team matches `DEVELOPMENT_TEAM`
   - the bundle identifiers match your local config
   - App Groups is enabled on both targets
   - both targets use the exact same App Group identifier
7. Build `Fragmenta`.
8. Build `FragmentaShareExtension`.
9. Launch the app and walk through the validation checklist below.

## Required xcconfig values

Set these values in `Config/Local.xcconfig` for this Mac:

- `DEVELOPMENT_TEAM = YOURTEAMID`
- `PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.fragmenta`
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER = $(PRODUCT_BUNDLE_IDENTIFIER).share`
- `FRAGMENTA_APP_GROUP_IDENTIFIER = group.$(PRODUCT_BUNDLE_IDENTIFIER).shared`
- `FRAGMENTA_API_BASE_URL = http:$(FORWARD_SLASH)$(FORWARD_SLASH)127.0.0.1:3000`

Notes:

- `Config/Debug.xcconfig` defaults to local backend on the same Mac via `127.0.0.1:3000`.
- `Config/Release.xcconfig` defaults to `https://fragmenta-core.example.com` and should be overridden for real release testing.
- `Config/Local.xcconfig` is included last, so your local values override the repo defaults cleanly.
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER` and `FRAGMENTA_APP_GROUP_IDENTIFIER` can stay derived from `PRODUCT_BUNDLE_IDENTIFIER` if you prefer that convention.

## API base URL guidance

Use `FRAGMENTA_API_BASE_URL` based on where `fragmenta-core` is running:

- iOS Simulator against local backend on this Mac:
  `http:$(FORWARD_SLASH)$(FORWARD_SLASH)127.0.0.1:3000`
- Physical iPhone against local backend on this Mac:
  `http:$(FORWARD_SLASH)$(FORWARD_SLASH)<mac-mini-lan-ip>:3000`
- Simulator or device against deployed backend:
  `https:$(FORWARD_SLASH)$(FORWARD_SLASH)<your-production-host>`

Important:

- `localhost` and `127.0.0.1` work for the Simulator because it runs on the same Mac.
- a physical device cannot use `127.0.0.1` for your Mac mini's backend
- use the Mac mini LAN IP or a deployed URL for device testing
- Debug builds also expose an in-app base URL override in Settings for quick local switching

## Signing and App Group setup

Both targets already point at entitlements files:

- app: `Config/Fragmenta.entitlements`
- extension: `Config/FragmentaShareExtension.entitlements`

Both entitlements files expect:

- `com.apple.security.application-groups = $(FRAGMENTA_APP_GROUP_IDENTIFIER)`

To finish setup in Xcode:

1. Select `Fragmenta`.
2. Open Signing & Capabilities.
3. Confirm the bundle identifier matches `PRODUCT_BUNDLE_IDENTIFIER`.
4. Confirm the Team matches `DEVELOPMENT_TEAM`.
5. Add or verify the App Groups capability.
6. Add the exact `FRAGMENTA_APP_GROUP_IDENTIFIER` value.
7. Repeat the same steps for `FragmentaShareExtension`.
8. Confirm the extension bundle identifier matches `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER`.

The share extension and app must use the same App Group or shared ingest will not work.

## Backend contract notes

Sprint 7 aligned the client with the backend routes and payloads currently present in the local `fragmenta-core` checkout.

Validated or tightened:

- books decode `canonical_title`, `canonical_author`, `thumbnail_url`, `cover_url`, and current source variants
- book detail now tolerates both bare book payloads and nested `{ book, stats }` payloads
- highlights decode `note_text`, nested `book`, and `source_location`
- book highlights and search now use `limit` plus `offset` pagination
- search results decode backend `{ highlight, book }` payloads without requiring snippet metadata
- import preview and import commit now send `text` in the request body, matching the current backend routes
- import preview, import response, and import history now tolerate `import_summary`, `parse_status`, `books_found`, `books_existing`, `highlights_found`, and related backend fields
- insights now fall back to `/api/stats/overview`, `/api/stats/activity`, and `/api/stats/books` when `/api/insights/reading` is unavailable
- share cards now fall back to `/api/share/highlight/{id}?download=1` when `/api/highlights/{id}/share-card` is unavailable
- collection membership now falls back to collection detail checks when `/api/books/{id}/collections` is unavailable
- discovery now degrades cleanly when related highlights or AI summary routes are missing or AI is unconfigured

Current known backend caveats:

- semantic search still depends on backend support; if the backend ignores `mode=semantic`, the UI still works but behaves like exact search
- the stats fallback cannot populate "top passages" without a dedicated backend route
- collection membership fallback is more network-chatty than a dedicated book-scoped collections endpoint

## Build validation completed in Sprint 7

Validated in this environment:

- `git fetch origin --prune`
- clean local branch state before work
- `xcodegen generate`
- resolved build settings show the full Debug API URL instead of the broken truncated value
- app scheme build:

```sh
xcodebuild -project Fragmenta.xcodeproj -scheme Fragmenta -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/fragmenta-ios-sprint7-build CODE_SIGNING_ALLOWED=NO build
```

- share extension scheme build:

```sh
xcodebuild -project Fragmenta.xcodeproj -scheme FragmentaShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/fragmenta-ios-sprint7-build CODE_SIGNING_ALLOWED=NO build
```

Validated as compile-only:

- both builds succeeded for the iOS Simulator
- no device signing validation is claimed here
- no simulator launch validation is claimed here
- no runtime share extension validation is claimed here

## Tonight's validation checklist

Walk through this in Xcode after setting your local team, bundle IDs, App Group, and API base URL:

1. Build `Fragmenta`.
2. Build `FragmentaShareExtension`.
3. Launch the app.
4. Verify the Journal and Bookshelf toggle both render real data.
5. Verify cover loading on the shelf and in book detail.
6. Open Insights and verify the screen loads without decode failures.
7. Open Collections, then validate collection detail plus add/remove membership from book detail.
8. Run search, then test semantic mode if the backend supports it.
9. Open a highlight and validate share-card preview and native share handoff.
10. Test import preview and import commit from pasted text.
11. Test Files-based ingest from a `.txt` export.
12. Test share-extension ingest from another app into Fragmenta.
13. Open Settings and validate diagnostics plus cache clear.

## Remaining blockers before Sprint 8

- set final local signing values in `Config/Local.xcconfig`
- enable App Groups in Xcode for both targets with the exact same identifier
- run simulator and, if needed, device validation against the real backend URL you plan to use tonight
- confirm share-extension handoff on real runtime, not just compile
- confirm semantic search and AI discovery behavior against the backend instance you actually plan to use

Once those are complete, Sprint 8 can stay focused on product work instead of setup churn.
