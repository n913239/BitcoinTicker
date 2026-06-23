//
//  BTCPriceUIComposer.swift
//  BTCPriceApp
//
//  Created by mike on 2026/6/23.
//

import UIKit
import BTCPrice

@MainActor
enum BTCPriceUIComposer {
    static func compose(
        httpClient: HTTPClient,
        scheduler: Scheduler,
        period: TimeInterval = 1.0
    ) -> BTCPriceViewController {
        let loader = BTCPriceLoaderFactory.makeBTCPriceLoader(httpClient: httpClient)
        let poller = BTCPricePoller(loader: loader, scheduler: scheduler, period: period)
        let viewController = BTCPriceViewController()
        let proxy = WeakRefVirtualProxy(viewController)
        let presenter = BTCPricePresenter(
            priceView: proxy,
            loadingView: proxy,
            errorView: proxy
        )
        let adapter = BTCPricePresentationAdapter(poller: poller)
        adapter.presenter = presenter
        
        viewController.onAppear = { [adapter] in adapter.start() }
        viewController.onDisappear = { [adapter] in adapter.stop() }
        return viewController
    }
}
