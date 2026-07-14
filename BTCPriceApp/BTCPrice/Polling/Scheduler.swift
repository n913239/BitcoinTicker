//
//  Scheduler.swift
//  BTCPrice
//
//  Created by mike on 2026/7/14.
//

import Foundation

public protocol Scheduler {
    func schedule(every interval: TimeInterval, action: @escaping () -> Void) -> ScheduleCancellable
}

public protocol ScheduleCancellable {
    func cancel()
}

public final class DispatchSourceTimerScheduler: Scheduler {
    private let queue: DispatchQueue
    
    public init(queue: DispatchQueue = DispatchQueue(label: "com.bscloud.BTCPrice.Scheduler", qos: .utility)) {
        self.queue = queue
    }
    
    public func schedule(every interval: TimeInterval, action: @escaping () -> Void) -> ScheduleCancellable {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(50))
        timer.setEventHandler(handler: action)
        timer.resume()
        return DispatchSourceTimerCancellable(timer: timer)
    }
}

private final class DispatchSourceTimerCancellable: ScheduleCancellable {
    private var timer: DispatchSourceTimer?
    
    init(timer: DispatchSourceTimer) {
        self.timer = timer
    }
    
    func cancel() {
        timer?.cancel()
        timer = nil
    }
    
    deinit {
        cancel()
    }
}
