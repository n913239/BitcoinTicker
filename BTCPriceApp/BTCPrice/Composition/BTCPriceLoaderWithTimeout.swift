//
//  BTCPriceLoaderWithTimeout.swift
//  BTCPrice
//
//  Created by mike on 2026/6/22.
//

import Foundation

public final class BTCPriceLoaderWithTimeout: BTCPriceLoader {
    public enum Error: Swift.Error, Equatable {
        case timeout
    }
    
    public typealias Sleep = @Sendable (TimeInterval) async throws -> Void
    
    private let loader: BTCPriceLoader
    private let timeout: TimeInterval
    private let sleep: Sleep
    
    public init(
        loader: BTCPriceLoader,
        timeout: TimeInterval,
        sleep: @escaping Sleep = { try await Task.sleep(for: .seconds($0)) }
    ) {
        self.loader = loader
        self.timeout = timeout
        self.sleep = sleep
    }
    
    public func load() async throws -> BTCPriceItem {
        try await withThrowingTaskGroup(of: TaskResult.self) { group in
            group.addTask { [loader] in
                let item = try await loader.load()
                try Task.checkCancellation()
                return .loaderFinished(item)
            }
            group.addTask { [sleep, timeout] in
                try await sleep(timeout)
                try Task.checkCancellation()
                return .timeoutFired
            }
            
            defer { group.cancelAll() }
            
            guard let first = try await group.next() else {
                throw Error.timeout
            }
            
            switch first {
            case .loaderFinished(let item):
                return item
            case .timeoutFired:
                throw Error.timeout
            }
        }
    }
    
    private enum TaskResult {
        case loaderFinished(BTCPriceItem)
        case timeoutFired
    }
}
