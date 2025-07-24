//
//  OnboardingViewModelTests.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import XCTest
@testable import xdrip

class OnboardingViewModelTests: XCTestCase {
    
    var viewModel: OnboardingViewModel!
    
    override func setUpWithTearDown() throws {
        super.setUp()
        viewModel = OnboardingViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Test that the view model starts in the correct initial state
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertNil(viewModel.selectedCGMType)
        XCTAssertFalse(viewModel.isScanning)
        XCTAssertFalse(viewModel.isTestingConnection)
        XCTAssertFalse(viewModel.connectionTestPassed)
        XCTAssertFalse(viewModel.showingError)
    }
    
    func testProgressCalculation() {
        // Test that progress is calculated correctly for each step
        viewModel.currentStep = .welcome
        XCTAssertEqual(viewModel.progress, 0.0)
        
        viewModel.currentStep = .cgmSelection
        XCTAssertEqual(viewModel.progress, 0.25)
        
        viewModel.currentStep = .cgmSetup
        XCTAssertEqual(viewModel.progress, 0.5)
        
        viewModel.currentStep = .testing
        XCTAssertEqual(viewModel.progress, 0.75)
        
        viewModel.currentStep = .completion
        XCTAssertEqual(viewModel.progress, 1.0)
    }
    
    func testCGMTypeSelection() {
        // Test CGM type selection
        let testCGMType = CGMTransmitterType.dexcom
        viewModel.selectCGMType(testCGMType)
        
        XCTAssertEqual(viewModel.selectedCGMType, testCGMType)
    }
    
    func testCanGoNext() {
        // Test navigation logic
        
        // Welcome step - should always be able to go next
        viewModel.currentStep = .welcome
        XCTAssertTrue(viewModel.canGoNext)
        
        // CGM selection - should only be able to go next if CGM is selected
        viewModel.currentStep = .cgmSelection
        XCTAssertFalse(viewModel.canGoNext)
        
        viewModel.selectCGMType(.dexcom)
        XCTAssertTrue(viewModel.canGoNext)
        
        // Setup step - should be able to go next when not scanning
        viewModel.currentStep = .cgmSetup
        XCTAssertTrue(viewModel.canGoNext)
        
        viewModel.isScanning = true
        XCTAssertFalse(viewModel.canGoNext)
        
        // Testing step - should be able to go next when connection passed or not testing
        viewModel.currentStep = .testing
        viewModel.isTestingConnection = false
        viewModel.connectionTestPassed = true
        XCTAssertTrue(viewModel.canGoNext)
        
        viewModel.connectionTestPassed = false
        XCTAssertTrue(viewModel.canGoNext) // Can skip
        
        viewModel.isTestingConnection = true
        XCTAssertFalse(viewModel.canGoNext)
    }
    
    func testCanGoBack() {
        // Test back navigation logic
        viewModel.currentStep = .welcome
        XCTAssertFalse(viewModel.canGoBack)
        
        viewModel.currentStep = .cgmSelection
        XCTAssertTrue(viewModel.canGoBack)
        
        viewModel.currentStep = .completion
        XCTAssertTrue(viewModel.canGoBack)
    }
    
    func testNextButtonTitle() {
        // Test that button titles are correct for each step
        viewModel.currentStep = .welcome
        XCTAssertEqual(viewModel.nextButtonTitle, "Get Started")
        
        viewModel.currentStep = .cgmSelection
        XCTAssertEqual(viewModel.nextButtonTitle, "Continue")
        
        viewModel.currentStep = .cgmSetup
        XCTAssertEqual(viewModel.nextButtonTitle, "Test Connection")
        
        viewModel.currentStep = .testing
        viewModel.connectionTestPassed = true
        XCTAssertEqual(viewModel.nextButtonTitle, "Finish")
        
        viewModel.connectionTestPassed = false
        XCTAssertEqual(viewModel.nextButtonTitle, "Skip")
        
        viewModel.currentStep = .completion
        XCTAssertEqual(viewModel.nextButtonTitle, "Done")
    }
    
    func testAvailableCGMTypes() {
        // Test that all CGM types are available
        let availableTypes = viewModel.availableCGMTypes
        XCTAssertEqual(availableTypes.count, CGMTransmitterType.allCases.count)
        XCTAssertTrue(availableTypes.contains(.dexcom))
        XCTAssertTrue(availableTypes.contains(.miaomiao))
        XCTAssertTrue(availableTypes.contains(.Blucon))
    }
    
    func testErrorHandling() {
        // Test error handling
        let testError = GlumeError.deviceNotFound
        viewModel.showError(testError)
        
        XCTAssertEqual(viewModel.currentError, testError)
        XCTAssertTrue(viewModel.showingError)
        
        viewModel.clearError()
        XCTAssertNil(viewModel.currentError)
        XCTAssertFalse(viewModel.showingError)
    }
}