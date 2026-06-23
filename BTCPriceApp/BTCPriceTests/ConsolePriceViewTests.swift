//
//  ConsolePriceViewTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/6/23.
//

import XCTest
import BTCPrice

@MainActor
final class ConsolePriceViewTests: XCTestCase {
    
    func test_displayPrice_outputsFormattedLine() {
        var captured = [String]()
        let sut = ConsolePriceView { captured.append($0) }
        
        sut.display(BTCPriceViewModel(price: "$72,615.55"))
        
        XCTAssertEqual(captured, ["BTC/USD: $72,615.55"])
    }
    
    func test_displayError_outputsErrorLine() {
        var captured = [String]()
        let sut = ConsolePriceView { captured.append($0) }
        
        sut.display(.error(message: "Something failed"))
        
        XCTAssertEqual(captured, ["ERROR: Something failed"])
    }
    
    func test_displayNoError_outputsNothing() {
        var captured = [String]()
        let sut = ConsolePriceView { captured.append($0) }
        
        sut.display(.noError)
        
        XCTAssertEqual(captured, [])
    }
    
    func test_displayLoading_outputsNothing() {
        var captured = [String]()
        let sut = ConsolePriceView { captured.append($0) }
        
        sut.display(BTCPriceLoadingViewModel(isLoading: true))
        
        XCTAssertEqual(captured, [])
    }
}
