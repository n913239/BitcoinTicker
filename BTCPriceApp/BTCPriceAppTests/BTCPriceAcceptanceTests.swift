//
//  BTCPriceAcceptanceTests.swift
//  BTCPriceAppTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
import BTCPrice
@testable import BTCPriceApp

@MainActor
final class BTCPriceAcceptanceTests: XCTestCase {
    
    func test_onLaunch_displaysRemoteBTCPriceWhenPrimaryLoaderSucceeds() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(httpClient: .online(response), scheduler: scheduler)
        
        XCTAssertEqual(viewController.priceLabelText, "", "Expected no price displayed before first tick")
        
        await tick(scheduler, until: { viewController.priceLabelText == "$72,615.55" })
        
        XCTAssertEqual(viewController.priceLabelText, "$72,615.55", "Expected formatted price from the Binance loader")
        XCTAssertTrue(viewController.isErrorMessageHidden, "Expected no error message on successful load")
    }
    
    func test_onLaunch_displaysCryptoCompareBTCPriceWhenPrimaryLoaderFails() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(httpClient: .failing(hosts: [binanceHost], otherwise: response), scheduler: scheduler)
        
        await tick(scheduler, until: { viewController.priceLabelText == "$72,900.00" })
        
        XCTAssertEqual(viewController.priceLabelText, "$72,900.00", "Expected formatted price from the CryptoCompare fallback")
        XCTAssertTrue(viewController.isErrorMessageHidden, "Expected no error message on fallback success")
    }
    
    func test_onLaunch_displaysCoinbaseBTCPriceWhenPrimaryAndFirstFallbackFail() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(
            httpClient: .failing(hosts: [binanceHost, cryptoCompareHost], otherwise: response),
            scheduler: scheduler
        )
        
        await tick(scheduler, until: { viewController.priceLabelText == "$73,000.00" })
        
        XCTAssertEqual(viewController.priceLabelText, "$73,000.00", "Expected formatted price from the Coinbase fallback")
        XCTAssertTrue(viewController.isErrorMessageHidden, "Expected no error message on fallback success")
    }
    
    func test_onLaunch_displaysErrorWhenAllLoadersFail() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(httpClient: .offline, scheduler: scheduler)
        
        await tick(scheduler, until: { !viewController.isErrorMessageHidden })
        
        XCTAssertFalse(viewController.isErrorMessageHidden, "Expected error message when all loaders fail")
        XCTAssertEqual(viewController.errorLabelText, BTCPricePresenter.loadError)
    }
    
    func test_onLaunch_displaysErrorWhenLoadDoesNotCompleteWithinOneSecond() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(httpClient: .neverResponding, scheduler: scheduler)
        
        await tick(scheduler, until: { !viewController.isErrorMessageHidden }, timeout: 10.0)
        
        XCTAssertFalse(viewController.isErrorMessageHidden, "Expected error message when the load exceeds the one-second budget")
        XCTAssertEqual(viewController.errorLabelText, BTCPricePresenter.loadError)
    }
    
    func test_onFailureAfterASuccessfulLoad_keepsShowingTheLastPriceWithAStaleMessage() async throws {
        let scheduler = ManualScheduler()
        let httpClient = HTTPClientStub.online(response)
        let viewController = try launch(httpClient: httpClient, scheduler: scheduler)
        
        await tick(scheduler, until: { viewController.priceLabelText == "$72,615.55" })
        
        httpClient.goOffline()
        await tick(scheduler, until: { !viewController.isErrorMessageHidden })
        
        XCTAssertEqual(viewController.priceLabelText, "$72,615.55", "Expected the last successful price to stay on screen")
        XCTAssertTrue(viewController.errorLabelText.hasPrefix("Failed to update value. Displaying last updated value from"))
    }
    
    // MARK: - Helpers
    
    private let binanceHost = "api.binance.com"
    private let cryptoCompareHost = "min-api.cryptocompare.com"
    
    private var heldSceneDelegate: SceneDelegate?
    
    private func launch(
        httpClient: HTTPClientStub,
        scheduler: ManualScheduler,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> BTCPriceViewController {
        let sceneDelegate = SceneDelegate(httpClient: httpClient, scheduler: scheduler)
        heldSceneDelegate = sceneDelegate
        let dummyScene = try XCTUnwrap((UIWindowScene.self as NSObject.Type).init() as? UIWindowScene)
        sceneDelegate.window = UIWindow(windowScene: dummyScene)
        sceneDelegate.window?.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        sceneDelegate.configureWindow()
        
        let vc = try XCTUnwrap(sceneDelegate.window?.rootViewController as? BTCPriceViewController, file: file, line: line)
        vc.loadViewIfNeeded()
        vc.beginAppearanceTransition(true, animated: false)
        vc.endAppearanceTransition()
        return vc
    }
    
    override func tearDown() {
        heldSceneDelegate = nil
        super.tearDown()
    }
    
    private func tick(
        _ scheduler: ManualScheduler,
        until condition: @MainActor () -> Bool,
        timeout: TimeInterval = 5.0
    ) async {
        scheduler.tick()
        
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
    
}

// MARK: - Stub responses

@Sendable private func response(for url: URL) -> (Data, HTTPURLResponse) {
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    return (data(for: url), response)
}

@Sendable private func data(for url: URL) -> Data {
    switch url.host {
    case "api.binance.com":
        return try! JSONSerialization.data(withJSONObject: ["symbol": "BTCUSDT", "price": "72615.55"])
    case "min-api.cryptocompare.com":
        return try! JSONSerialization.data(withJSONObject: ["RAW": ["FROMSYMBOL": "BTC", "TOSYMBOL": "USD", "PRICE": 72900.0]])
    case "api.coinbase.com":
        return try! JSONSerialization.data(withJSONObject: ["data": ["amount": "73000.00", "base": "BTC", "currency": "USD"]])
    default:
        return Data()
    }
}

// MARK: - HTTPClientStub

extension BTCPriceAcceptanceTests {
    
    final class HTTPClientStub: HTTPClient, @unchecked Sendable {
        private let queue = DispatchQueue(label: "HTTPClientStub")
        private var stub: @Sendable (URL) -> Result<(Data, HTTPURLResponse), Error>
        private var neverResponds = false
        
        init(stub: @escaping @Sendable (URL) -> Result<(Data, HTTPURLResponse), Error>) {
            self.stub = stub
        }
        
        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            let (stub, neverResponds) = queue.sync { (self.stub, self.neverResponds) }
            
            if neverResponds {
                try await Task.sleep(for: .seconds(60))
            }
            return try stub(url).get()
        }
        
        func goOffline() {
            queue.sync {
                stub = { _ in .failure(NSError(domain: "offline", code: 0)) }
            }
        }
        
        static var offline: HTTPClientStub {
            HTTPClientStub { _ in .failure(NSError(domain: "offline", code: 0)) }
        }
        
        static var neverResponding: HTTPClientStub {
            let stub = HTTPClientStub { _ in .failure(NSError(domain: "unreachable", code: 0)) }
            stub.queue.sync { stub.neverResponds = true }
            return stub
        }
        
        static func online(_ response: @escaping @Sendable (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            HTTPClientStub { url in .success(response(url)) }
        }
        
        static func failing(
            hosts: [String],
            otherwise response: @escaping @Sendable (URL) -> (Data, HTTPURLResponse)
        ) -> HTTPClientStub {
            HTTPClientStub { url in
                if let host = url.host, hosts.contains(host) {
                    return .failure(NSError(domain: "\(host)-failure", code: 0))
                }
                return .success(response(url))
            }
        }
    }
}

// MARK: - BTCPriceViewController test helpers

@MainActor
private extension BTCPriceViewController {
    var priceLabelText: String {
        view.findLabel(byAccessibilityIdentifier: AccessibilityIdentifier.priceLabel)?.text ?? ""
    }
    
    var errorLabelText: String {
        view.findLabel(byAccessibilityIdentifier: AccessibilityIdentifier.errorLabel)?.text ?? ""
    }
    
    var isErrorMessageHidden: Bool {
        view.findLabel(byAccessibilityIdentifier: AccessibilityIdentifier.errorLabel)?.isHidden ?? true
    }
}
