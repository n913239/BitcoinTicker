//
//  main.swift
//  BTCPriceCLI
//
//  Created by mike on 2026/6/22.
//

import Foundation
import BTCPrice

let httpClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
let scheduler = DispatchSourceTimerScheduler()
// Top-level binding keeps the poller alive for the lifetime of the process.
let poller = MainActor.assumeIsolated {
    BTCPriceCLIComposer.compose(httpClient: httpClient, scheduler: scheduler)
}
_ = poller

RunLoop.main.run()
