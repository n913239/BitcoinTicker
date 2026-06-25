//
//  BTCPricePollerTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/6/22.
//

import XCTest
import BTCPrice

final class BTCPricePollerTests: XCTestCase {
    
    func test_init_doesNotScheduleAction() {
        let (_, scheduler, loader) = makeSUT()
        
        XCTAssertEqual(scheduler.scheduledActionCount, 0)
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_start_schedulesActionAtConfiguredPeriod() {
        let (sut, scheduler, _) = makeSUT(period: 2.5)
        
        sut.start(onPrice: { _ in }, onError: { _ in })
        
        XCTAssertEqual(scheduler.scheduledIntervals, [2.5])
    }
    
    func test_tick_loadsFromLoader() {
        let (sut, scheduler, loader) = makeSUT()
        let exp = expectation(description: "Wait for load")
        loader.onLoad = { exp.fulfill() }
        
        sut.start(onPrice: { _ in }, onError: { _ in })
        scheduler.tick()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_tick_deliversLoadedPriceToOnPrice() {
        let (sut, scheduler, loader) = makeSUT()
        let item = BTCPriceItem(price: 72615.55)
        loader.stub(result: .success(item))
        
        let exp = expectation(description: "Wait for onPrice")
        let received = ResultBox<BTCPriceItem>()
        sut.start(
            onPrice: {
                received.value = $0
                exp.fulfill()
            },
            onError: { _ in }
        )
        
        scheduler.tick()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(received.value?.price, item.price)
    }
    
    func test_tick_deliversFailureToOnError() {
        let (sut, scheduler, loader) = makeSUT()
        let expectedError = NSError(domain: "any", code: 1)
        loader.stub(result: .failure(expectedError))
        
        let exp = expectation(description: "Wait for onError")
        let received = ResultBox<NSError>()
        sut.start(
            onPrice: { _ in },
            onError: {
                received.value = $0 as NSError
                exp.fulfill()
            }
        )
        
        scheduler.tick()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(received.value?.domain, expectedError.domain)
        XCTAssertEqual(received.value?.code, expectedError.code)
    }
    
    func test_stop_cancelsSchedule_andDoesNotTriggerLoaderOnFurtherTicks() async {
        let (sut, scheduler, loader) = makeSUT()
        sut.start(onPrice: { _ in }, onError: { _ in })
        
        sut.stop()
        scheduler.tick()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_tick_skipsNewLoadWhilePreviousLoadIsInFlight() async {
        let (sut, scheduler, loader) = makeSUT()
        
        let firstLoadStarted = expectation(description: "first load started")
        loader.onLoad = { firstLoadStarted.fulfill() }
        loader.enableBlocking()
        
        let loadFinished = expectation(description: "first load finished")
        sut.start(onPrice: { _ in loadFinished.fulfill() }, onError: { _ in })
        
        scheduler.tick()
        await fulfillment(of: [firstLoadStarted], timeout: 1.0)

        scheduler.tick()

        XCTAssertEqual(loader.loadCallCount, 1, "Second tick must be skipped while a load is in flight")

        loader.release()
        await fulfillment(of: [loadFinished], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        period: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (BTCPricePoller, ManualScheduler, LoaderSpy) {
        let scheduler = ManualScheduler()
        let loader = LoaderSpy()
        let sut = BTCPricePoller(loader: loader, scheduler: scheduler, period: period)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(scheduler, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (sut, scheduler, loader)
    }
    
    private final class LoaderSpy: BTCPriceLoader, @unchecked Sendable {
        private let queue = DispatchQueue(label: "LoaderSpy")
        private var _loadCallCount = 0
        private var stubbedResult: Result<BTCPriceItem, Error> = .success(BTCPriceItem(price: 0))
        private var _onLoad: (() -> Void)?
        private var _shouldBlock = false
        private var _gate: CheckedContinuation<Void, Never>?
        
        var loadCallCount: Int {
            queue.sync { _loadCallCount }
        }
        
        var onLoad: (() -> Void)? {
            get { queue.sync { _onLoad } }
            set { queue.sync { _onLoad = newValue } }
        }
        
        func stub(result: Result<BTCPriceItem, Error>) {
            queue.sync { stubbedResult = result }
        }
        
        func enableBlocking() {
            queue.sync { _shouldBlock = true }
        }
        
        func release() {
            let gate: CheckedContinuation<Void, Never>? = queue.sync {
                let g = _gate
                _gate = nil
                return g
            }
            gate?.resume()
        }
        
        func load() async throws -> BTCPriceItem {
            let (result, shouldBlock): (Result<BTCPriceItem, Error>, Bool) = queue.sync {
                _loadCallCount += 1
                _onLoad?()
                return (stubbedResult, _shouldBlock)
            }
            if shouldBlock {
                await withCheckedContinuation { continuation in
                    queue.sync { _gate = continuation }
                }
            }
            switch result {
            case .success(let item): return item
            case .failure(let error): throw error
            }
        }
    }
    
    private final class ResultBox<T>: @unchecked Sendable {
        private let queue = DispatchQueue(label: "ResultBox")
        private var _value: T?
        var value: T? {
            get { queue.sync { _value } }
            set { queue.sync { _value = newValue } }
        }
    }
}
