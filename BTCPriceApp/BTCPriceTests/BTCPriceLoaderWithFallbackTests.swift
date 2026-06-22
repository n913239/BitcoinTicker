//
//  BTCPriceLoaderWithFallbackTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/6/22.
//

import XCTest
@testable import BTCPrice

final class BTCPriceLoaderWithFallbackTests: XCTestCase {
    
    func test_load_deliversPrimaryResultOnPrimarySuccess() async throws {
        let primaryItem = makeItem(price: 72000.0)
        let (sut, _, _) = makeSUT(primaryResult: .success(primaryItem), fallbackResult: .success(makeItem(price: 99000.0)))
        
        let result = try await sut.load()
        
        XCTAssertEqual(result.price, primaryItem.price)
    }
    
    func test_load_doesNotLoadFromFallbackOnPrimarySuccess() async throws {
        let (sut, _, fallbackLoader) = makeSUT(primaryResult: .success(makeItem(price: 72000.0)), fallbackResult: .success(makeItem(price: 99000.0)))
        
        _ = try await sut.load()
        
        XCTAssertEqual(fallbackLoader.loadCallCount, 0)
    }
    
    func test_load_deliversFallbackResultOnPrimaryFailure() async throws {
        let fallbackItem = makeItem(price: 99000.0)
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyError()), fallbackResult: .success(fallbackItem))
        
        let result = try await sut.load()
        
        XCTAssertEqual(result.price, fallbackItem.price)
    }
    
    func test_load_deliversErrorWhenBothPrimaryAndFallbackFail() async {
        let (sut, _, _) = makeSUT(primaryResult: .failure(anyError()), fallbackResult: .failure(anyError()))
        
        do {
            _ = try await sut.load()
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        primaryResult: Result<BTCPriceItem, Error>,
        fallbackResult: Result<BTCPriceItem, Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: BTCPriceLoaderWithFallback, primary: BTCPriceLoaderSpy, fallback: BTCPriceLoaderSpy) {
        let primaryLoader = BTCPriceLoaderSpy(result: primaryResult)
        let fallbackLoader = BTCPriceLoaderSpy(result: fallbackResult)
        let sut = BTCPriceLoaderWithFallback(primary: primaryLoader, fallback: fallbackLoader)
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, primaryLoader, fallbackLoader)
    }
    
    private func makeItem(price: Double) -> BTCPriceItem {
        BTCPriceItem(price: price)
    }
    
    private func anyError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
    
}

// MARK: - Spy

private class BTCPriceLoaderSpy: BTCPriceLoader {
    private let result: Result<BTCPriceItem, Error>
    private(set) var loadCallCount = 0
    
    init(result: Result<BTCPriceItem, Error>) {
        self.result = result
    }
    
    func load() async throws -> BTCPriceItem {
        loadCallCount += 1
        return try result.get()
    }
}
