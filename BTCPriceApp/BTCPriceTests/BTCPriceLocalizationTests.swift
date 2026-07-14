//
//  BTCPriceLocalizationTests.swift
//  BTCPriceTests
//
//  Created by mike on 2026/7/14.
//

import XCTest
import BTCPrice

@MainActor
final class BTCPriceLocalizationTests: XCTestCase {
    
    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        let table = "BTCPrice"
        let bundle = Bundle(for: BTCPricePresenter.self)
        
        assertLocalizedKeyAndValuesExist(in: bundle, table)
    }
    
}
