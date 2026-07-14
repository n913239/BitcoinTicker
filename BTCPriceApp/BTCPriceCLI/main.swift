//
//  main.swift
//  BTCPriceCLI
//
//  Created by mike on 2026/7/13.
//

import Foundation
import BTCPrice

setvbuf(stdout, nil, _IOLBF, 0)

let httpClient = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
let scheduler = DispatchSourceTimerScheduler()

let poller = MainActor.assumeIsolated {
    BTCPriceCLIComposer.compose(httpClient: httpClient, scheduler: scheduler)
}

withExtendedLifetime(poller) {
    RunLoop.main.run()
}
