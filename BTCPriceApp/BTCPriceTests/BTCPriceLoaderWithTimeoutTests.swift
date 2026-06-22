//
//  BTCPriceLoaderWithTimeoutTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/6/22.
//

import XCTest
@testable import BTCPrice

final class BTCPriceLoaderWithTimeoutTests: XCTestCase {
    
    func test_load_deliversItemWhenLoaderCompletesBeforeTimeout() async throws {
        let item = makeItem(price: 72000.0)
        let (sut, _) = makeSUT(result: .success(item), loaderDelay: 0.0, timeout: 1.0, sleepDuration: 1.0)
        
        let result = try await sut.load()
        
        XCTAssertEqual(result.price, item.price)
    }
    
    func test_load_throwsTimeoutErrorWhenLoaderExceedsTimeout() async {
        let (sut, _) = makeSUT(
            result: .success(makeItem(price: 72000.0)),
            loaderDelay: 5.0,
            timeout: 0.1,
            sleepDuration: 0.1
        )
        
        await assertThrows(BTCPriceLoaderWithTimeout.Error.timeout) {
            _ = try await sut.load()
        }
    }
    
    func test_load_throwsTimeoutWhenSleepCompletesFirst_usingInjectedSleep() async {
        // The injected sleep finishes immediately; the loader sleeps "forever" with respect to the
        // injected clock so the timeout always wins, giving us a deterministic timeout race.
        let (sut, _) = makeSUT(
            result: .success(makeItem(price: 72000.0)),
            loaderDelay: 60.0,
            timeout: 1.0,
            sleepDuration: 0.0
        )
        
        await assertThrows(BTCPriceLoaderWithTimeout.Error.timeout) {
            _ = try await sut.load()
        }
    }
    
    func test_load_propagatesLoaderErrorWhenLoaderFailsBeforeTimeout() async {
        let loaderError = NSError(domain: "loader-failure", code: 0)
        let (sut, _) = makeSUT(
            result: .failure(loaderError),
            loaderDelay: 0.0,
            timeout: 1.0,
            sleepDuration: 1.0
        )
        
        do {
            _ = try await sut.load()
            XCTFail("Expected loader error to propagate")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, loaderError.domain)
            XCTAssertEqual(error.code, loaderError.code)
        }
    }
    
    func test_load_deliversItemWhenLoaderJustBeatsTimeout() async throws {
        // Boundary: 0.5s loader vs 1.0s timeout. Loader wins, we get the item.
        let item = makeItem(price: 72615.55)
        let (sut, _) = makeSUT(
            result: .success(item),
            loaderDelay: 0.5,
            timeout: 1.0,
            sleepDuration: 1.0
        )
        
        let result = try await sut.load()
        
        XCTAssertEqual(result.price, item.price)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        result: Result<BTCPriceItem, Error>,
        loaderDelay: TimeInterval,
        timeout: TimeInterval,
        sleepDuration: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: BTCPriceLoaderWithTimeout, loader: BTCPriceLoaderStub) {
        let loader = BTCPriceLoaderStub(result: result, delay: loaderDelay)
        let sleep: BTCPriceLoaderWithTimeout.Sleep = { _ in
            if sleepDuration > 0 {
                try await Task.sleep(for: .seconds(sleepDuration))
            }
        }
        let sut = BTCPriceLoaderWithTimeout(loader: loader, timeout: timeout, sleep: sleep)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func makeItem(price: Double) -> BTCPriceItem {
        BTCPriceItem(price: price)
    }
    
    private func assertThrows<E: Error & Equatable>(
        _ expectedError: E,
        file: StaticString = #filePath,
        line: UInt = #line,
        when block: () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("Expected \(expectedError), got success", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected \(expectedError), got \(error)", file: file, line: line)
        }
    }
}

// MARK: - Stub

private class BTCPriceLoaderStub: BTCPriceLoader, @unchecked Sendable {
    private let result: Result<BTCPriceItem, Error>
    private let delay: TimeInterval
    
    init(result: Result<BTCPriceItem, Error>, delay: TimeInterval) {
        self.result = result
        self.delay = delay
    }
    
    func load() async throws -> BTCPriceItem {
        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }
        return try result.get()
    }
}
