//
//  BTCPricePoller.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

public final class BTCPricePoller {
    private let loader: BTCPriceLoader
    private let scheduler: Scheduler
    private let period: TimeInterval
    
    private let lock = NSLock()
    private var cancellable: ScheduleCancellable?
    private var onStart: (() -> Void)?
    private var onPrice: ((BTCPriceItem) -> Void)?
    private var onError: ((Error) -> Void)?
    private var latestLoadID = 0
    
    public init(loader: BTCPriceLoader, scheduler: Scheduler, period: TimeInterval = 1.0) {
        self.loader = loader
        self.scheduler = scheduler
        self.period = period
    }
    
    public func start(
        onStart: @escaping () -> Void,
        onPrice: @escaping (BTCPriceItem) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        lock.withLock {
            self.onStart = onStart
            self.onPrice = onPrice
            self.onError = onError
        }
        
        let scheduled = scheduler.schedule(every: period) { [weak self] in
            self?.load()
        }
        lock.withLock { cancellable = scheduled }
    }
    
    public func stop() {
        let scheduled: ScheduleCancellable? = lock.withLock {
            let current = cancellable
            cancellable = nil
            onStart = nil
            onPrice = nil
            onError = nil
            latestLoadID += 1
            return current
        }
        scheduled?.cancel()
    }
    
    deinit {
        cancellable?.cancel()
    }
    
    private func load() {
        let (loadID, start) = lock.withLock { () -> (Int, (() -> Void)?) in
            latestLoadID += 1
            return (latestLoadID, onStart)
        }
        start?()
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let item = try await loader.load()
                priceHandler(for: loadID)?(item)
            } catch {
                errorHandler(for: loadID)?(error)
            }
        }
    }
    
    private func priceHandler(for loadID: Int) -> ((BTCPriceItem) -> Void)? {
        lock.withLock { loadID == latestLoadID ? onPrice : nil }
    }
    
    private func errorHandler(for loadID: Int) -> ((Error) -> Void)? {
        lock.withLock { loadID == latestLoadID ? onError : nil }
    }
}
