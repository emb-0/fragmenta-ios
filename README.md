# Fragmenta iOS

Fragmenta iOS is the native SwiftUI client for `fragmenta-core`, the separate backend that ingests Kindle exports into books, highlights, notes, collections, insights, exports, discovery surfaces, and share artifacts.

Sprint 1 through Sprint 8 are complete. Sprint 9 makes the production Vercel backend the default runtime path so the app can be tested immediately on Simulator and physical iPhone without pointing at localhost first.

## Sprint 9 focus

- make `https://fragmenta-core.vercel.app` the bundled Debug and Release default
- keep local Mac mini backend testing available only as an explicit override
- show the resolved backend target clearly in Settings
- keep `/api/health` probing visible so production reachability is obvious during runtime checks

## Current project shape

- app target: `Fragmenta`
- share extension target: `FragmentaShareExtension`
- generated project: `Fragmenta.xcodeproj`
- source of truth for generation: `project.yml`
- config files:
  - `Config/Base.xcconfig`
  - `Config/Debug.xcconfig`
  - `Config/Release.xcconfig`
  - optional local override: `Config/Local.xcconfig`

`Config/Local.xcconfig` is intentionally gitignored. Use `Config/Local.xcconfig.example` as the starting point on each machine.

## Quick start on this Mac

1. Regenerate the Xcode project after any `project.yml` or source-layout change:

```sh
xcodegen generate
```

2. Open `Fragmenta.xcodeproj` in Xcode.
3. In Xcode, confirm signing for both targets:
   - `Fragmenta`
   - `FragmentaShareExtension`
4. In Signing & Capabilities for both targets, verify:
   - the Team matches `DEVELOPMENT_TEAM`
   - the bundle identifiers match your local config
   - App Groups is enabled on both targets
   - both targets use the exact same App Group identifier
5. Build `Fragmenta`.
6. Launch the app.
7. Open Settings and confirm the backend target reads `Production backend`.
8. Run the backend check.

## Default production testing setup

The bundled default is now production in both tracked configs:

- `Config/Debug.xcconfig`
- `Config/Release.xcconfig`

Both now set:

- `FRAGMENTA_API_BASE_URL = https:$(FORWARD_SLASH)$(FORWARD_SLASH)fragmenta-core.vercel.app`

You only need `Config/Local.xcconfig` if you want machine-local overrides such as signing values, bundle IDs, App Group values, or a temporary local/LAN backend.

Create it only when needed:

```sh
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

## Required xcconfig values

If you do create `Config/Local.xcconfig` on this Mac mini, use:

- `DEVELOPMENT_TEAM = YOURTEAMID`
- `PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.fragmenta`
- `FRAGMENTA_SHARE_EXTENSION_BUNDLE_IDENTIFIER = com.yourcompany.fragmenta.share`
- `FRAGMENTA_APP_GROUP_IDENTIFIER = group.com.yourcompany.fragmenta.shared`
- `FRAGMENTA_API_BASE_URL = https:$(FORWARD_SLASH)$(FORWARD_SLASH)fragmenta-core.vercel.app`

Important notes:

- `Config/Debug.xcconfig` now defaults to the Vercel production backend.
- `Config/Release.xcconfig` also defaults to the same production backend.
- `Config/Local.xcconfig` is included last, so your local machine values win cleanly.
- in `.xcconfig`, keep the `http:$(FORWARD_SLASH)$(FORWARD_SLASH)...` or `https:$(FORWARD_SLASH)$(FORWARD_SLASH)...` style; raw `//` can be mangled by Xcode build setting expansion

## API base URL guidance

Use `FRAGMENTA_API_BASE_URL` based on where `fragmenta-core` is running:

- default Simulator or device path on this Mac:
  `https:$(FORWARD_SLASH)$(FORWARD_SLASH)fragmenta-core.vercel.app`
- iOS Simulator against a local backend on this Mac:
  `http:$(FORWARD_SLASH)$(FORWARD_SLASH)127.0.0.1:3000`
- physical iPhone against a local backend on this Mac:
  `http:$(FORWARD_SLASH)$(FORWARD_SLASH)<mac-mini-lan-ip>:3000`

Runtime rules:

- production is now the default bundled path for Debug and Release
- `127.0.0.1` and `localhost` only work for the Simulator
- a real iPhone cannot reach your Mac mini through `127.0.0.1`
- for device testing against local backend, use the Mac mini LAN IP
- Debug builds still expose an in-app base URL override in Settings
- malformed overrides are now rejected with explicit validation instead of being silently accepted

## ATS and local networking

`Config/Info.plist` now includes:

- `NSAppTransportSecurity`
  - `NSAllowsLocalNetworking = true`

That is enough for local plain-HTTP development against `127.0.0.1`, `localhost`, or a LAN IP without disabling ATS globally.

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

The app and share extension must use the same App Group or shared ingest will not work.

## Sprint 8 runtime decisions

Layout and ergonomics:

- phone spacing and typography were retuned away from the earlier wide-preview bias
- repeated outer shells and card padding were reduced so content uses more of the iPhone width
- bookshelf cards, summary grids, and the bookshelf cover grid now read larger on phone
- cramped hero sections in book detail and collection detail now fall back more gracefully on narrow widths
- filter bars and action rows that were too eager to stay horizontal now use horizontal scroll or `ViewThatFits`

Navigation and bottom bar:

- native `TabView` remains the navigation model
- the tab shell was not replaced with a custom overlay
- iOS 26 tab bar styling now favors the native glass/minimization path instead of forcing a heavy explicit background
- the Import screen bottom action bar now adapts horizontally or vertically and sits more cleanly above the tab area

Backend diagnostics:

- Settings now shows the resolved backend URL, whether it is production or local, its source, and reachability guidance
- invalid default or override URLs are surfaced as configuration issues
- Debug override input now validates before applying
- Settings can run a backend check from inside the app
- the check probes `/api/health` first and falls back to `/api/stats/overview` if the health endpoint is not implemented
- transport errors now distinguish:
  - malformed base URL
  - unresolved host
  - connection refused / nothing listening
  - timeout
  - decoding mismatch
  - server-returned error

## Backend contract notes

Sprint 8 kept the earlier Sprint 7 route/decode tightening and added more runtime-oriented reconciliation against the checked `fragmenta-core` source.

Validated or tightened:

- books still tolerate current backend book field variants and apply local filtering/sorting because the checked books route remains server-light
- insights continue to fall back to `/api/stats/overview`, `/api/stats/activity`, and `/api/stats/books` when `/api/insights/reading` is unavailable
- collection membership still falls back when `/api/books/{id}/collections` is unavailable
- discovery still degrades cleanly when related-highlights or AI summary routes are missing or AI is unconfigured
- share cards still fall back to `/api/share/highlight/{id}?download=1`
- search now maps client sort choices onto the backend search sort the server actually understands
- search now applies local refinement for author filtering and `Oldest` ordering because the checked backend search route does not honor those semantics directly

Current backend caveats:

- the deployed production backend at `fragmenta-core.vercel.app` now exposes `/api/health`
- the checked local `fragmenta-core` repo may still lag that production health route, so the stats fallback remains useful for local development
- semantic search still depends on backend support; if the backend ignores `mode=semantic`, the UI still works but behaves like exact search
- discovery cannot show real related highlights until the backend adds a dedicated route
- the local collection-membership fallback is more network-chatty than a dedicated book-scoped endpoint

## Runtime validation completed in Sprint 9

Validated in this environment:

- `git fetch origin --prune`
- `xcodebuild -project Fragmenta.xcodeproj -scheme Fragmenta -configuration Debug -showBuildSettings`
- confirmed `FRAGMENTA_API_BASE_URL = https://fragmenta-core.vercel.app` in Debug build settings
- `xcodegen generate`
- app build:

```sh
xcodebuild -project Fragmenta.xcodeproj -scheme Fragmenta -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/fragmenta-ios-sprint9-build CODE_SIGNING_ALLOWED=NO build
```

- result: `** BUILD SUCCEEDED **`
- production backend probe:
  `curl -sS -D - https://fragmenta-core.vercel.app/api/health`
- production health result: `HTTP/2 200` with `{"ok":true,"environment":"production","version":"6887a4f"}`
- simulator launch:
  `xcrun simctl launch 97B7595A-C7B4-4B04-A2E2-E61BB4964BE0 com.fragmenta.ios`
- simulator launch result: `com.fragmenta.ios: 42455`

Runtime constraints observed during validation:

- this Sprint 9 pass validates production-default config and production endpoint reachability, not deeper UI runtime behavior
- no new simulator screenshot or real-device proof is claimed here

What is honestly claimed:

- the bundled default Debug and Release URL is now the production Vercel backend
- Debug build settings resolve that URL correctly
- project generation succeeded
- the app compiles for the iOS Simulator
- the production backend endpoint was probed directly from this Mac and returned a healthy production response
- the production-default build installed and launched on the iPhone 16e simulator

What is not claimed:

- no share-extension ingest runtime validation
- no real device validation from this Sprint 9 pass
- no end-to-end in-app production data walkthrough was claimed from this config-only sprint

## Tonight's runtime checklist

After setting the local team, bundle IDs, and App Group:

1. Build `Fragmenta`.
2. Launch the app on Simulator.
3. Open Settings and confirm:
   - resolved base URL
   - source is correct
   - backend check returns the status you expect
4. Verify the Library screen no longer feels underscaled on phone.
5. Switch Journal / Bookshelf and confirm the shelf uses the screen width more naturally.
6. Open a book detail screen and confirm the hero layout and action strip feel readable on phone.
7. Open Insights and confirm the layout reads comfortably on phone width.
8. Run search and verify the filter row is usable on phone.
9. Open Collections and verify collection detail plus membership sheet remain readable on phone.
10. Open Import and verify the bottom action bar does not fight the tab bar.
11. Test cover loading on shelf and detail screens.
12. Test collection CRUD and membership.
13. Test search, including semantic mode if the backend supports it.
14. Test share-card preview/share.
15. Test import preview and import commit.
16. Test Files ingest.
17. Test share-extension ingest.
18. Test cache clear and rerun the backend check.

## Remaining blockers before Sprint 9

- start `fragmenta-core` locally on this Mac or set a reachable production URL before deeper runtime testing
- validate the Sprint 8 layout/nav changes on a real physical iPhone, not just Simulator launch
- validate share-extension ingest and App Group handoff on real runtime
- confirm semantic-search and discovery behavior against the actual backend instance you plan to use
- the `CoverImagePipeline` async `NSLock` warnings are still present under the newer toolchain and should be cleaned up soon, though they did not block Sprint 8 compile/runtime readiness
