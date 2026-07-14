//
//  BTCPriceCLIComposer.swift
//  BTCPriceCLI
//
//  Created by mike on 2026/7/14.
//

import Foundation
import BTCPrice

@MainActor
enum BTCPriceCLIComposer {
    static func compose(
        httpClient: HTTPClient,
        scheduler: Scheduler,
        period: TimeInterval = 1.0,
        output: @escaping (String) -> Void = { print($0) }
    ) -> BTCPricePoller {
        let loader = BTCPriceLoaderFactory.makeBTCPriceLoader(httpClient: httpClient)
        let poller = BTCPricePoller(loader: loader, scheduler: scheduler, period: period)
        let consoleView = ConsolePriceView(output: output)
        let presenter = BTCPricePresenter(
            priceView: consoleView,
            loadingView: consoleView,
            errorView: consoleView
        )
        let adapter = ConsolePresentationAdapter(poller: poller, presenter: presenter)
        adapter.start()
        return poller
    }
}

@MainActor
private final class ConsolePresentationAdapter {
    private let poller: BTCPricePoller
    private let presenter: BTCPricePresenter
    
    init(poller: BTCPricePoller, presenter: BTCPricePresenter) {
        self.poller = poller
        self.presenter = presenter
    }
    
    func start() {
        poller.start(
            onStart: { [presenter] in
                Task { @MainActor in
                    presenter.didStartLoading()
                }
            },
            onPrice: { [presenter] item in
                Task { @MainActor in
                    presenter.didFinishLoading(with: item)
                }
            },
            onError: { [presenter] error in
                Task { @MainActor in
                    presenter.didFinishLoading(with: error)
                }
            }
        )
    }
}
