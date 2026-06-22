//
//  DispatchSourceTimerSchedulerTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/6/22.
//

import XCTest
import BTCPrice

final class DispatchSourceTimerSchedulerTests: XCTestCase {
    
    func test_schedule_invokesActionAtLeastOnceWithinTimeout() {
        let sut = makeSUT()
        let expectation = expectation(description: "Wait for scheduled action")
        expectation.assertForOverFulfill = false
        
        let cancellable = sut.schedule(every: 0.2) {
            expectation.fulfill()
        }
        
        // 真實計時器整合測試：CI 開 ThreadSanitizer + 低優先佇列偶會 starve，timeout 放寬到 5.0
        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }
    
    func test_schedule_invokesActionRepeatedly() {
        let sut = makeSUT()
        let expectation = expectation(description: "Wait for repeated invocations")
        expectation.expectedFulfillmentCount = 3
        expectation.assertForOverFulfill = false
        
        let cancellable = sut.schedule(every: 0.2) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        cancellable.cancel()
    }
    
    func test_cancel_stopsFurtherInvocations() {
        let sut = makeSUT()
        let firstTick = expectation(description: "Wait for first invocation")
        let counter = Counter()
        
        let cancellable = sut.schedule(every: 0.1) {
            counter.increment()
            firstTick.fulfill()
        }
        
        wait(for: [firstTick], timeout: 5.0)
        cancellable.cancel()
        
        let countAfterCancel = counter.value
        let waitForPotentialExtraTicks = expectation(description: "Settle after cancel")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            waitForPotentialExtraTicks.fulfill()
        }
        wait(for: [waitForPotentialExtraTicks], timeout: 1.0)
        
        XCTAssertEqual(counter.value, countAfterCancel, "Action must not fire after cancel")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> DispatchSourceTimerScheduler {
        let sut = DispatchSourceTimerScheduler()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private final class Counter: @unchecked Sendable {
        private let queue = DispatchQueue(label: "counter")
        private var _value = 0
        
        func increment() {
            queue.sync { _value += 1 }
        }
        
        var value: Int {
            queue.sync { _value }
        }
    }
}
