//
//  BTCPriceAcceptanceTests.swift
//  BTCPriceAppTests
//
//  Created by mike on 2026/6/23.
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
        
        await tickAndWaitForUI(scheduler: scheduler)
        
        XCTAssertEqual(viewController.priceLabelText, "$72,615.55", "Expected formatted price from Binance loader after first tick")
        XCTAssertTrue(viewController.isErrorMessageHidden, "Expected no error message on successful load")
    }
    
    func test_onLaunch_displaysFallbackBTCPriceWhenPrimaryLoaderFails() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(httpClient: .onlinePrimaryFailureFallbackSucceeds(response), scheduler: scheduler)
        
        await tickAndWaitForUI(scheduler: scheduler)
        
        XCTAssertEqual(viewController.priceLabelText, "$73,000.00", "Expected formatted price from Coinbase fallback loader after primary failure")
        XCTAssertTrue(viewController.isErrorMessageHidden, "Expected no error message on fallback success")
    }
    
    func test_onLaunch_displaysErrorWhenAllLoadersFail() async throws {
        let scheduler = ManualScheduler()
        let viewController = try launch(httpClient: .offline, scheduler: scheduler)
        
        await tickAndWaitForUI(scheduler: scheduler)
        
        XCTAssertFalse(viewController.isErrorMessageHidden, "Expected error message when all loaders fail")
        XCTAssertEqual(viewController.errorLabelText, BTCPricePresenter.loadError)
    }
    
    // MARK: - Helpers
    
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
    
    private func tickAndWaitForUI(scheduler: ManualScheduler) async {
        scheduler.tick()
        // Allow Poller's detached Task to call the loader, and Adapter's MainActor Task to update the view.
        for _ in 0..<30 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
    
}

// MARK: - Stub responses（檔案層級 → @Sendable，不捕獲 test-case 狀態）

@Sendable private func response(for url: URL) -> (Data, HTTPURLResponse) {
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    return (data(for: url), response)
}

@Sendable private func data(for url: URL) -> Data {
    switch url.host {
    case "api.binance.com":
        return try! JSONSerialization.data(withJSONObject: ["symbol": "BTCUSDT", "price": "72615.55"])
    case "api.coinbase.com":
        return try! JSONSerialization.data(withJSONObject: ["data": ["amount": "73000.00", "base": "BTC", "currency": "USD"]])
    default:
        return Data()
    }
}

// MARK: - HTTPClientStub

extension BTCPriceAcceptanceTests {
    
    final class HTTPClientStub: HTTPClient {
        private let stub: @Sendable (URL) -> Result<(Data, HTTPURLResponse), Error>
        
        init(stub: @escaping @Sendable (URL) -> Result<(Data, HTTPURLResponse), Error>) {
            self.stub = stub
        }
        
        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            try stub(url).get()
        }
        
        static var offline: HTTPClientStub {
            HTTPClientStub { _ in .failure(NSError(domain: "offline", code: 0)) }
        }
        
        static func online(_ response: @escaping @Sendable (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            HTTPClientStub { url in .success(response(url)) }
        }
        
        static func onlinePrimaryFailureFallbackSucceeds(_ response: @escaping @Sendable (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            HTTPClientStub { url in
                if url.host == "api.binance.com" {
                    return .failure(NSError(domain: "binance-failure", code: 0))
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
