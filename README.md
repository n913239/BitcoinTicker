# BitcoinTicker

Purple Belt Challenge #1 — a small **iOS app + command-line tool** that polls the Bitcoin spot price every second from Binance, falls back to Coinbase when the primary fails, enforces a per-request timeout, and renders the result through a presenter-driven, platform-agnostic view layer shared by both apps.

> **Fallback API note.** The challenge spec suggests CryptoCompare as the fallback, but `min-api.cryptocompare.com` now requires an API key (it returns `401` for anonymous requests since the CoinDesk migration). The spec allows this — *"If any of the links are not working, use any other BTC/USD conversion API you can find online."* — so the fallback uses the keyless **Coinbase spot price API** (`/v2/prices/BTC-USD/spot`).

See **[ARCHITECTURE.md](ARCHITECTURE.md)** for the module-dependency and Composition-Root diagrams.

## Repository layout

| Folder | Target | Purpose |
| --- | --- | --- |
| `BTCPrice/` | `BTCPrice` framework | Platform-agnostic logic shared by iOS + CLI, by layer: `Domain/`, `API/`, `Polling/`, `Presentation/`, `Composition/` |
| `BTCPriceApp/` | `BTCPriceApp` iOS app | iOS host: `SceneDelegate`, `BTCPriceViewController`, `BTCPriceUIComposer`, `BTCPricePresentationAdapter`, `WeakRefVirtualProxy` |
| `BTCPriceCLI/` | `BTCPriceCLI` executable | Command-line entry point reusing the same loader chain + poller + presenter via `BTCPriceCLIComposer` |
| `BTCPriceTests/` | unit | Framework unit tests: mappers, loaders, presenter, poller, scheduler, HTTP client, localization, console view |
| `BTCPriceAppTests/` | app | Acceptance tests (primary → fallback → error flow) + `SceneDelegate` tests |
| `BTCPriceiOSTests/` | snapshot | Snapshot tests: display / loading / error × light / dark + XXXL Dynamic Type |
| `BTCPriceAPIEndToEndTests/` | E2E | Real-network tests against Binance + Coinbase. Excluded from CI; run on demand |

## Schemes & test plan

| Scheme (shared) | Purpose |
| --- | --- |
| `CI_iOS` | Drives CI via `CI_iOS.xctestplan` (random ordering, code coverage on production targets) |
| `BTCPriceCLI` | Build / run the command-line tool |
| `BTCPriceAPIEndToEnd` | Run the network E2E tests locally |

`CI_iOS.xctestplan` runs `BTCPriceTests` + `BTCPriceAppTests` + `BTCPriceiOSTests` (E2E intentionally excluded), with `testExecutionOrdering: random` and code coverage scoped to `BTCPrice` + `BTCPriceApp`.

## CI / CD

**CI** (`.github/workflows/CI-iOS.yml`, GitHub Actions, `macos-15` / Xcode 16.4) on every push & PR to `main`:
1. builds + tests the iOS scheme `CI_iOS` on an iPhone 16 simulator with **ThreadSanitizer** and **code coverage** enabled;
2. builds the `BTCPriceCLI` executable for macOS (so the CLI deliverable can never silently break).

**CD.** Continuous Delivery to TestFlight / App Store Connect requires an Apple Developer signing identity, which isn't available for this challenge repo. The delivery step is therefore **documented rather than executed**: the release path is `xcodebuild archive` → `xcodebuild -exportArchive` with a signed export options plist, wired as a manual / tag-triggered GitHub Actions job once signing credentials exist. The build is already CI-green and archivable; only the signing/upload leg is deferred.

## Running locally

```bash
# CI test suite on a simulator
xcodebuild test -project BTCPriceApp/BTCPriceApp.xcodeproj -scheme CI_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'

# Real-API end-to-end (network required)
xcodebuild test -project BTCPriceApp/BTCPriceApp.xcodeproj -scheme BTCPriceAPIEndToEnd \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'

# CLI (prints "BTC/USD: $…" every second)
xcodebuild -project BTCPriceApp/BTCPriceApp.xcodeproj -scheme BTCPriceCLI build
```

## Design decisions

- **Composition Root.** `BTCPriceUIComposer` (iOS) and `BTCPriceCLIComposer` (CLI) own all wiring: `HTTPClient → RemoteBTCPriceLoader (Binance) → BTCPriceLoaderWithFallback (Coinbase) → BTCPriceLoaderWithTimeout → BTCPricePoller → presentation adapter → BTCPricePresenter`. View controllers and the CLI entry point contain no construction logic.
- **Drift-free polling.** `BTCPricePoller` depends on a `Scheduler` protocol — production uses `DispatchSourceTimerScheduler` (a repeating `DispatchSourceTimer`, no accumulating drift); tests inject `ManualScheduler` to advance time deterministically.
- **In-flight guard.** The poller skips a tick if the previous load is still running, so a slow network never overlaps requests or renders a stale/out-of-order price.
- **Typed errors.** `RemoteBTCPriceLoader.Error` is `connectivity` / `invalidData`; `URLSessionHTTPClient` throws its own `UnexpectedValuesRepresentation` rather than leaking `URLError`.
- **Timeout via labelled task-group race.** `BTCPriceLoaderWithTimeout` races the loader against an injectable sleep in a `withThrowingTaskGroup`, tagging each child with an enum so the winner is unambiguous; the loser is cancelled in a `defer`.
- **MVP presentation.** `BTCPricePresenter` has a 3-segment API (`didStartLoading` / `didFinishLoading(with: item)` / `didFinishLoading(with: error)`) emitting three platform-agnostic view models through three view protocols, implemented by both the iOS `BTCPriceViewController` and the CLI `ConsolePriceView`.
- **Localization.** User-facing strings come from `BTCPrice.strings` via `NSLocalizedString`, guarded by `BTCPriceLocalizationTests` (every referenced key resolves in every supported localization). Dates/numbers format through an injected `Locale` / `Calendar`.
- **Weak proxy.** `WeakRefVirtualProxy` lets the presenter hold the view weakly; the Composition Root inserts it so the view controller is released normally.
- **Test seams without leaking encapsulation.** UI labels stay private; tests query the hierarchy by `accessibilityIdentifier`.
- **Snapshot tests.** `SnapshotConfiguration` fixes size / safe area / traits; `SnapshotWindow` renders without becoming the key window (so it doesn't retain the VC between tests). References were recorded on **iPhone 16 / iOS 18.5**; comparison uses a **small per-pixel tolerance** (not exact-byte) to absorb sub-pixel antialiasing differences between machines / simulator builds.

## Non-goals (explicitly deferred)

- **Signed CD upload** — see CI / CD above; deferred until signing credentials exist.
- **`MainQueueDispatchDecorator`** — threading is handled by `@MainActor` on the presenter/adapter, functionally equivalent here.
- **Sync closure-based domain loader** — the domain `BTCPriceLoader` stays `async throws`; bridging to sync callbacks adds ceremony with no user benefit.
