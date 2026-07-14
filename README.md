# BitcoinTicker

Purple Belt Challenge #1 — a small **iOS app + command-line tool** that polls the Bitcoin spot price every second, falls back through a chain of price sources when one fails, enforces the spec's one-second update budget, and renders the result through a presenter-driven, platform-agnostic view layer shared by both apps.

## Data sources

The spec names **Binance** as the primary source and **CryptoCompare** as the fallback. Both are wired exactly as specified:

| Order | Source | Status |
| --- | --- | --- |
| 1 (primary) | `api.binance.com/api/v3/ticker/price?symbol=BTCUSDT` | working |
| 2 (fallback) | `min-api.cryptocompare.com/data/generateAvg?fsym=BTC&tsym=USD&e=coinbase` | **returns `401 API key required`** since the CoinDesk migration |
| 3 (extra fallback) | `api.coinbase.com/v2/prices/BTC-USD/spot` | working, keyless |

CryptoCompare is kept in the chain because the spec asks for it, and it fails over automatically. Coinbase is added as a third tier under the spec's own escape clause — *"If any of the links are not working, use any other BTC/USD conversion API you can find online."* — so the app keeps working today without pretending CryptoCompare is dead code we never tried.

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
| `BTCPriceAPIEndToEndTests/` | E2E | Real-network tests: Binance, Coinbase, and the whole fallback chain. Excluded from CI; run on demand |

## Schemes & test plan

| Scheme (shared) | Purpose |
| --- | --- |
| `CI_iOS` | Drives CI via `CI_iOS.xctestplan` (random ordering, code coverage on production targets) |
| `BTCPriceApp` | Build / run the iOS app |
| `BTCPrice` | Build the framework on its own |
| `BTCPriceCLI` | Build / run the command-line tool |
| `BTCPriceAPIEndToEnd` | Run the network E2E tests locally |

`CI_iOS.xctestplan` runs `BTCPriceTests` + `BTCPriceAppTests` + `BTCPriceiOSTests` (E2E intentionally excluded), with `testExecutionOrdering: random` and code coverage scoped to `BTCPrice` + `BTCPriceApp`.

## CI / CD

**CI** (`.github/workflows/CI-iOS.yml`, GitHub Actions, `macos-15` / Xcode 16.4) on every push & PR to `main`:
1. builds + tests the iOS scheme `CI_iOS` on an iPhone 16 simulator with **ThreadSanitizer** and **code coverage** enabled;
2. builds the `BTCPriceCLI` executable for macOS (so the CLI deliverable can never silently break).

**CD** (`.github/workflows/CD.yml`) runs automatically after a green CI run on `main` (`workflow_run`), so nothing is ever delivered from a red build. It produces two downloadable artifacts:

| Artifact | What it is |
| --- | --- |
| `BTCPriceCLI-macos` | The **runnable** command-line tool plus the `BTCPrice.framework` it loads at `@loader_path`. Download, unzip, run — it prints the live price once a second. |
| `BTCPriceApp-xcarchive` | An unsigned `xcarchive` of the iOS app, ready to be exported once a signing identity exists. |

The CLI needs no code signing, so its delivery is complete: the artifact is the product. The iOS leg stops one step short — `xcodebuild -exportArchive` and the TestFlight upload need an Apple Developer signing identity, which isn't available for this challenge repo. That final step is the only part that is **documented rather than executed**; everything before it runs on every green build.

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

- **Composition Root.** `BTCPriceUIComposer` (iOS) and `BTCPriceCLIComposer` (CLI) own all wiring: `HTTPClient → RemoteBTCPriceLoader (Binance → CryptoCompare → Coinbase) → BTCPriceLoaderWithFallback → BTCPriceLoaderWithTimeout → BTCPricePoller → presentation adapter → BTCPricePresenter`. View controllers and the CLI entry point contain no construction logic.
- **Drift-free polling, first value immediately.** `BTCPricePoller` depends on a `Scheduler` protocol — production uses `DispatchSourceTimerScheduler` (a repeating `DispatchSourceTimer`, no accumulating drift). The timer fires **immediately** and then every second, so the app never shows a blank screen for the first second. Tests inject `ManualScheduler` to advance time deterministically.
- **Two-level timeout budget.** The spec requires an error *"if it fails to update within a second"*, so the whole chain is wrapped in a **1.0s** timeout. But a hanging primary would then leave the fallbacks nothing to work with, so Binance additionally gets a **0.5s** budget of its own. The fallbacks therefore always get a real chance to answer, and the total update still never exceeds the one second the spec allows.
- **No dropped ticks.** Every tick starts a load and notifies `onStart`. If a previous load is still in flight, the new one still runs; results carry a load ID and a **superseded result is discarded**, so a slow response can never overwrite a newer price. (An earlier design skipped the tick entirely, which silently produced neither a value nor an error for that second.)
- **The error stays until a success.** The spec says to *"hide the error once the value is updated successfully"* — so only `didFinishLoading(with: item)` clears it. `didStartLoading()` deliberately does **not**, otherwise a persistent outage would make the error blink once per second. For the same reason the loading indicator is shown only while there is no price on screen yet.
- **Typed errors.** `RemoteBTCPriceLoader.Error` is `connectivity` / `invalidData`; `URLSessionHTTPClient` throws its own `UnexpectedValuesRepresentation` rather than leaking `URLError`.
- **Timeout via labelled task-group race.** `BTCPriceLoaderWithTimeout` races the loader against an injectable sleep in a `withThrowingTaskGroup`, tagging each child with an enum so the winner is unambiguous; the loser is cancelled in a `defer`.
- **MVP presentation.** `BTCPricePresenter` has a 3-segment API (`didStartLoading` / `didFinishLoading(with: item)` / `didFinishLoading(with: error)`) emitting three platform-agnostic view models through three view protocols, implemented by both the iOS `BTCPriceViewController` and the CLI `ConsolePriceView`.
- **Localization.** User-facing strings come from `BTCPrice.strings` via `NSLocalizedString`, guarded by `BTCPriceLocalizationTests` (every referenced key resolves in every supported localization). Dates/numbers format through an injected `Locale` / `Calendar`.
- **Weak proxy.** `WeakRefVirtualProxy` lets the presenter hold the view weakly; the Composition Root inserts it so the view controller is released normally.
- **Test seams without leaking encapsulation.** UI labels stay private; tests query the hierarchy by `accessibilityIdentifier`.
- **Snapshot tests compare colour exactly.** `SnapshotConfiguration` fixes size / safe area / traits (injected with `traitOverrides`, since overriding the `traitCollection` getter no longer propagates to subviews); `SnapshotWindow` renders without becoming the key window, so it doesn't retain the VC between tests. The assertion encodes the freshly rendered image to PNG and decodes it back **before** comparing, so both sides have been through the same colour-space conversion — without that, a wide-gamut (P3) render is compared against an sRGB-decoded reference and every dark-mode and error snapshot mismatches on colour alone.

  What remains is text reflow: on a different machine the error message breaks one word earlier, even though the font (12.0), the label width (342.0) and the simulator runtime (18.5, build 22F77) are all verified identical. That moves ~0.6% of the pixels. So the assertion allows **at most 1% of pixels to differ, with zero per-channel colour tolerance** — a compared pixel must match exactly. A failure reports the measured difference and attaches both images. (The earlier `precision 0.98` / `perChannelTolerance 32` was far weaker: it would have passed a 12% colour shift across the entire screen.)

  Leak tracking is applied to the presenter but not to the view controller there: UIKit retains the VC through the snapshot window's scene, so the check would always fail. VC lifetime is covered by the acceptance tests instead.
- **Line-buffered CLI output.** `main.swift` sets `_IOLBF` on `stdout`. Without it, a piped or redirected CLI shows nothing at all — C stdio block-buffers a non-TTY stream, and a one-line-per-second ticker never fills the 4 KB buffer.
- **E2E tests are excluded from CI on purpose.** They hit the real Binance / CryptoCompare / Coinbase endpoints, so they depend on third-party uptime and would make CI red for reasons unrelated to the code. They are run on demand via the `BTCPriceAPIEndToEnd` scheme. One of them loads through the **whole fallback chain**, which is what proves the app still delivers a price while CryptoCompare is returning 401.

## Non-goals (explicitly deferred)

- **Signed CD upload / TestFlight** — CD runs and publishes a runnable CLI and an unsigned iOS archive on every green build; only `-exportArchive` + upload are deferred until signing credentials exist. See CI / CD above.
- **`MainQueueDispatchDecorator`** — threading is handled by `@MainActor` on the presenter/adapter, functionally equivalent here.
- **Sync closure-based domain loader** — the domain `BTCPriceLoader` stays `async throws`; bridging to sync callbacks adds ceremony with no user benefit.
