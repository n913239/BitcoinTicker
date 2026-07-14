//
//  BTCPricePresentationAdapter.swift
//  BTCPriceApp
//
//  Created by mike on 2026/7/14.
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
            onStart: { [weak self] in
                Task { @MainActor in
                    self?.presenter?.didStartLoading()
                }
            },
            onPrice: { [weak self] item in
                Task { @MainActor in
                    self?.presenter?.didFinishLoading(with: item)
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
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
