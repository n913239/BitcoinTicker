//
//  ManualSchedulerTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
import BTCPrice

final class ManualSchedulerTests: XCTestCase {
    
    func test_schedule_doesNotInvokeActionBeforeTick() {
        let sut = ManualScheduler()
        var callCount = 0
        
        _ = sut.schedule(every: 1.0) { callCount += 1 }
        
        XCTAssertEqual(callCount, 0)
    }
    
    func test_tick_invokesScheduledAction() {
        let sut = ManualScheduler()
        var callCount = 0
        
        _ = sut.schedule(every: 1.0) { callCount += 1 }
        
        sut.tick()
        XCTAssertEqual(callCount, 1)
        
        sut.tick()
        XCTAssertEqual(callCount, 2)
    }
    
    func test_cancel_preventsFurtherInvocations() {
        let sut = ManualScheduler()
        var callCount = 0
        
        let cancellable = sut.schedule(every: 1.0) { callCount += 1 }
        sut.tick()
        XCTAssertEqual(callCount, 1)
        
        cancellable.cancel()
        sut.tick()
        XCTAssertEqual(callCount, 1, "Action must not fire after cancel")
    }
    
    func test_schedule_recordsRequestedInterval() {
        let sut = ManualScheduler()
        
        _ = sut.schedule(every: 1.5) {}
        _ = sut.schedule(every: 0.5) {}
        
        XCTAssertEqual(sut.scheduledIntervals, [1.5, 0.5])
    }
    
    func test_tick_invokesAllScheduledActions() {
        let sut = ManualScheduler()
        var firstCount = 0
        var secondCount = 0
        
        _ = sut.schedule(every: 1.0) { firstCount += 1 }
        _ = sut.schedule(every: 1.0) { secondCount += 1 }
        
        sut.tick()
        
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 1)
    }
}
