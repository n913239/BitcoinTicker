//
//  SceneDelegateTests.swift
//  BTCPriceAppTests
//
//  Created by mike on 2026/6/23.
//

import XCTest
import BTCPrice
@testable import BTCPriceApp

@MainActor
final class SceneDelegateTests: XCTestCase {
    
    func test_configureWindow_setsWindowAsKeyAndVisible() throws {
        let sut = makeSUT()
        
        let window = try UIWindowSpy.make()
        sut.window = window
        
        sut.configureWindow()
        
        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
    }
    
    func test_configureWindow_configuresRootViewController() throws {
        let sut = makeSUT()
        sut.window = try UIWindowSpy.make()
        
        sut.configureWindow()
        
        let root = sut.window?.rootViewController
        XCTAssertTrue(root is BTCPriceViewController, "Expected a BTCPriceViewController as root, got \(String(describing: root)) instead")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> SceneDelegate {
        let sut = SceneDelegate(httpClient: HTTPClientStub(), scheduler: InertScheduler())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private final class UIWindowSpy: UIWindow {
        var makeKeyAndVisibleCallCount = 0
        
        static func make() throws -> UIWindowSpy {
            let dummyScene = try XCTUnwrap((UIWindowScene.self as NSObject.Type).init() as? UIWindowScene)
            return UIWindowSpy(windowScene: dummyScene)
        }
        
        override func makeKeyAndVisible() {
            makeKeyAndVisibleCallCount += 1
        }
    }
    
    private final class HTTPClientStub: HTTPClient {
        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            try await Task.sleep(for: .seconds(60 * 60))
            throw NSError(domain: "never", code: 0)
        }
    }
    
    private final class InertScheduler: Scheduler {
        func schedule(every interval: TimeInterval, action: @escaping () -> Void) -> ScheduleCancellable {
            NoopCancellable()
        }
        
        private struct NoopCancellable: ScheduleCancellable {
            func cancel() {}
        }
    }
}
