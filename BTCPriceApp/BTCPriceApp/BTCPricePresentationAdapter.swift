//
//  BTCPricePresentationAdapter.swift
//  BTCPriceApp
//
//  Created by mike on 2026/6/23.
//

import Foundation
import BTCPrice

@MainActor
final class BTCPricePresentationAdapter {
    private let poller: BTCPricePoller
    var presenter: BTCPricePresenter?
    
    init(poller: BTCPricePoller) {
        self.poller = poller
    }
    
    func start() {
        poller.start(
            onPrice: { [weak self] item in
                Task { @MainActor in
                    self?.presenter?.didStartLoading()
                    self?.presenter?.didFinishLoading(with: item)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.presenter?.didStartLoading()
                    self?.presenter?.didFinishLoading(with: error)
                }
            }
        )
    }
    
    func stop() {
        poller.stop()
    }
    
    deinit {
        poller.stop()
    }
}
