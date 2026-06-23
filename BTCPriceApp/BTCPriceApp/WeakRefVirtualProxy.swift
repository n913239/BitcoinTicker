//
//  WeakRefVirtualProxy.swift
//  BTCPriceApp
//
//  Created by mike on 2026/6/23.
//

import BTCPrice

final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: BTCPriceView where T: BTCPriceView {
    func display(_ viewModel: BTCPriceViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: BTCPriceLoadingView where T: BTCPriceLoadingView {
    func display(_ viewModel: BTCPriceLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: BTCPriceErrorView where T: BTCPriceErrorView {
    func display(_ viewModel: BTCPriceErrorViewModel) {
        object?.display(viewModel)
    }
}
