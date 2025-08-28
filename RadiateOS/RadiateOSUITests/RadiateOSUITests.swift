//
//  RadiateOSUITests.swift
//  RadiateOSUITests
//
//  Created by Mostafa Nasr on 27/08/2025.
//

import XCTest

final class RadiateOSUITests: XCTestCase {

    @MainActor
    func testLaunch() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
    }
}
