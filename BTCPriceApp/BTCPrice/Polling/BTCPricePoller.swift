//
//  BTCPricePoller.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

import Foundation

public final class BTCPricePoller {
    private let loader: BTCPriceLoader
    private let scheduler: Scheduler
    private let period: TimeInterval
    
    private var cancellable: ScheduleCancellable?
    private var onPrice: ((BTCPriceItem) -> Void)?
    private var onError: ((Error) -> Void)?
    
    public init(loader: BTCPriceLoader, scheduler: Scheduler, period: TimeInterval = 1.0) {
        self.loader = loader
        self.scheduler = scheduler
        self.period = period
    }
    
    public func start(onPrice: @escaping (BTCPriceItem) -> Void, onError: @escaping (Error) -> Void) {
        self.onPrice = onPrice
        self.onError = onError
        
        cancellable = scheduler.schedule(every: period) { [weak self] in
            self?.load()
        }
    }
    
    public func stop() {
        cancellable?.cancel()
        cancellable = nil
        onPrice = nil
        onError = nil
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    private func load() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let item = try await self.loader.load()
                self.onPrice?(item)
            } catch {
                self.onError?(error)
            }
        }
    }
}
