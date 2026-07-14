//
//  BTCPricePollerTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
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
        
        sut.start(onStart: {}, onPrice: { _ in }, onError: { _ in })
        
        XCTAssertEqual(scheduler.scheduledIntervals, [2.5])
    }
    
    func test_tick_loadsFromLoader() {
        let (sut, scheduler, loader) = makeSUT()
        let exp = expectation(description: "Wait for load")
        loader.onLoad = { exp.fulfill() }
        
        sut.start(onStart: {}, onPrice: { _ in }, onError: { _ in })
        scheduler.tick()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_tick_notifiesStartBeforeLoading() {
        let (sut, scheduler, loader) = makeSUT()
        let events = EventLog()
        let exp = expectation(description: "Wait for load")
        
        loader.onLoad = {
            events.append("load")
            exp.fulfill()
        }
        sut.start(
            onStart: { events.append("start") },
            onPrice: { _ in },
            onError: { _ in }
        )
        
        scheduler.tick()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(events.values, ["start", "load"])
    }
    
    func test_everyTick_notifiesStart() {
        let (sut, scheduler, _) = makeSUT()
        let events = EventLog()
        let exp = expectation(description: "Wait for three starts")
        exp.expectedFulfillmentCount = 3
        
        sut.start(
            onStart: {
                events.append("start")
                exp.fulfill()
            },
            onPrice: { _ in },
            onError: { _ in }
        )
        
        scheduler.tick()
        scheduler.tick()
        scheduler.tick()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(events.values.count, 3)
    }
    
    func test_tick_deliversLoadedPriceToOnPrice() {
        let (sut, scheduler, loader) = makeSUT()
        let item = BTCPriceItem(price: 72615.55)
        loader.stub(result: .success(item))
        
        let exp = expectation(description: "Wait for onPrice")
        let received = ResultBox<BTCPriceItem>()
        sut.start(
            onStart: {},
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
            onStart: {},
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
    
    func test_stop_cancelsSchedule_andDoesNotTriggerLoaderOnFurtherTicks() {
        let (sut, scheduler, loader) = makeSUT()
        sut.start(onStart: {}, onPrice: { _ in }, onError: { _ in })
        
        sut.stop()
        scheduler.tick()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_tickWhilePreviousLoadIsInFlight_startsAnotherLoad() async {
        let (sut, scheduler, loader) = makeSUT()
        loader.enableBlocking()
        sut.start(onStart: {}, onPrice: { _ in }, onError: { _ in })
        
        await tickAndWaitForBlockedLoad(scheduler, loader)
        await tickAndWaitForBlockedLoad(scheduler, loader)
        
        XCTAssertEqual(loader.loadCallCount, 2, "A tick must never be silently dropped")
        
        loader.releaseAll()
    }
    
    func test_supersededLoad_doesNotDeliverItsResult() async {
        let (sut, scheduler, loader) = makeSUT()
        let superseded = BTCPriceItem(price: 1)
        let latest = BTCPriceItem(price: 2)
        loader.stub(results: [.success(superseded), .success(latest)])
        loader.enableBlocking()
        
        let received = ValueLog<Double>()
        let delivered = expectation(description: "Wait for a delivered price")
        sut.start(
            onStart: {},
            onPrice: {
                received.append($0.price)
                delivered.fulfill()
            },
            onError: { _ in }
        )
        
        await tickAndWaitForBlockedLoad(scheduler, loader)
        await tickAndWaitForBlockedLoad(scheduler, loader)
        
        loader.releaseAll()
        await fulfillment(of: [delivered], timeout: 5.0)
        
        XCTAssertEqual(received.values, [latest.price], "Only the latest tick may deliver its result")
    }
    
    // MARK: - Helpers
    
    private func tickAndWaitForBlockedLoad(
        _ scheduler: ManualScheduler,
        _ loader: LoaderSpy
    ) async {
        let blocked = expectation(description: "Wait for the load to reach the loader")
        loader.onBlock = { blocked.fulfill() }
        
        scheduler.tick()
        
        await fulfillment(of: [blocked], timeout: 5.0)
    }
    
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
        private var _results: [Result<BTCPriceItem, Error>] = []
        private var _defaultResult: Result<BTCPriceItem, Error> = .success(BTCPriceItem(price: 0))
        private var _onLoad: (() -> Void)?
        private var _onBlock: (() -> Void)?
        private var _shouldBlock = false
        private var _gates: [CheckedContinuation<Void, Never>] = []
        
        var loadCallCount: Int {
            queue.sync { _loadCallCount }
        }
        
        var onLoad: (() -> Void)? {
            get { queue.sync { _onLoad } }
            set { queue.sync { _onLoad = newValue } }
        }
        
        var onBlock: (() -> Void)? {
            get { queue.sync { _onBlock } }
            set { queue.sync { _onBlock = newValue } }
        }
        
        func stub(result: Result<BTCPriceItem, Error>) {
            queue.sync { _defaultResult = result }
        }
        
        func stub(results: [Result<BTCPriceItem, Error>]) {
            queue.sync { _results = results }
        }
        
        func enableBlocking() {
            queue.sync { _shouldBlock = true }
        }
        
        func releaseAll() {
            let gates: [CheckedContinuation<Void, Never>] = queue.sync {
                _shouldBlock = false
                let pending = _gates
                _gates = []
                return pending
            }
            gates.forEach { $0.resume() }
        }
        
        func load() async throws -> BTCPriceItem {
            let (result, shouldBlock): (Result<BTCPriceItem, Error>, Bool) = queue.sync {
                let index = _loadCallCount
                _loadCallCount += 1
                _onLoad?()
                let result = index < _results.count ? _results[index] : _defaultResult
                return (result, _shouldBlock)
            }
            
            if shouldBlock {
                await withCheckedContinuation { continuation in
                    let notifyBlocked: (() -> Void)? = queue.sync {
                        _gates.append(continuation)
                        return _onBlock
                    }
                    notifyBlocked?()
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
    
    private final class ValueLog<T>: @unchecked Sendable {
        private let queue = DispatchQueue(label: "ValueLog")
        private var _values: [T] = []
        var values: [T] { queue.sync { _values } }
        func append(_ value: T) { queue.sync { _values.append(value) } }
    }
    
    private final class EventLog: @unchecked Sendable {
        private let queue = DispatchQueue(label: "EventLog")
        private var _values: [String] = []
        var values: [String] { queue.sync { _values } }
        func append(_ value: String) { queue.sync { _values.append(value) } }
    }
}
