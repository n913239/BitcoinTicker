//
//  ManualScheduler.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import Foundation
import BTCPrice

final class ManualScheduler: Scheduler {
    private(set) var scheduledIntervals: [TimeInterval] = []
    private var actions: [UUID: () -> Void] = [:]
    
    func schedule(every interval: TimeInterval, action: @escaping () -> Void) -> ScheduleCancellable {
        scheduledIntervals.append(interval)
        let id = UUID()
        actions[id] = action
        return Cancellable { [weak self] in
            self?.actions.removeValue(forKey: id)
        }
    }
    
    func tick() {
        for action in actions.values {
            action()
        }
    }
    
    var scheduledActionCount: Int { actions.count }
    
    private final class Cancellable: ScheduleCancellable {
        private let onCancel: () -> Void
        private var cancelled = false
        
        init(onCancel: @escaping () -> Void) {
            self.onCancel = onCancel
        }
        
        func cancel() {
            guard !cancelled else { return }
            cancelled = true
            onCancel()
        }
    }
}
