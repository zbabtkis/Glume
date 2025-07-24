//
//  SimplifiedDashboardViewModelTests.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import XCTest
@testable import xdrip

class SimplifiedDashboardViewModelTests: XCTestCase {
    
    var viewModel: SimplifiedDashboardViewModel!
    
    override func setUpWithTearDown() throws {
        super.setUp()
        viewModel = SimplifiedDashboardViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Test that the view model starts with default values
        XCTAssertEqual(viewModel.currentGlucoseValue, "--")
        XCTAssertEqual(viewModel.currentTrend, .stable)
        XCTAssertEqual(viewModel.timeAgo, "--")
        XCTAssertTrue(viewModel.bgReadingValues.isEmpty)
        XCTAssertTrue(viewModel.bgReadingDates.isEmpty)
        XCTAssertEqual(viewModel.averageGlucose, "--")
        XCTAssertEqual(viewModel.timeInRange, "--")
        XCTAssertTrue(viewModel.activeAlerts.isEmpty)
        XCTAssertEqual(viewModel.connectivityStatus.description, "Disconnected")
    }
    
    func testGlucoseUnitCalculation() {
        // Test glucose unit based on user defaults
        
        // Mock user defaults for testing
        UserDefaults.standard.set(false, forKey: "bloodGlucoseUnit") // true for mgDl
        XCTAssertEqual(viewModel.glucoseUnit, "mg/dL")
        
        UserDefaults.standard.set(true, forKey: "bloodGlucoseUnit") // false for mgDl 
        XCTAssertEqual(viewModel.glucoseUnit, "mmol/L")
    }
    
    func testGlucoseLimits() {
        // Test that glucose limits are properly retrieved
        XCTAssertGreaterThan(viewModel.urgentLowLimit, 0)
        XCTAssertGreaterThan(viewModel.lowLimit, 0)
        XCTAssertGreaterThan(viewModel.highLimit, 0)
        XCTAssertGreaterThan(viewModel.urgentHighLimit, 0)
        
        // Test logical order
        XCTAssertLessThan(viewModel.urgentLowLimit, viewModel.lowLimit)
        XCTAssertLessThan(viewModel.lowLimit, viewModel.highLimit)
        XCTAssertLessThan(viewModel.highLimit, viewModel.urgentHighLimit)
    }
    
    func testTimeAgoFormatting() {
        // Test time ago formatting with different intervals
        
        // Test current time (0 seconds)
        let now = viewModel.formatTimeAgo(0)
        XCTAssertEqual(now, "Now")
        
        // Test 1 minute
        let oneMinute = viewModel.formatTimeAgo(60)
        XCTAssertEqual(oneMinute, "1 min ago")
        
        // Test multiple minutes
        let fiveMinutes = viewModel.formatTimeAgo(300)
        XCTAssertEqual(fiveMinutes, "5 mins ago")
        
        // Test 1 hour
        let oneHour = viewModel.formatTimeAgo(3600)
        XCTAssertEqual(oneHour, "1h ago")
        
        // Test 1 hour 30 minutes
        let oneHourThirty = viewModel.formatTimeAgo(5400)
        XCTAssertEqual(oneHourThirty, "1h 30m ago")
        
        // Test multiple hours
        let threeHours = viewModel.formatTimeAgo(10800)
        XCTAssertEqual(threeHours, "3h ago")
    }
    
    func testTrendCalculation() {
        // Test glucose trend calculation
        
        // Create mock BgReading objects for testing
        let currentTime = Date()
        let previousTime = Date(timeInterval: -300, since: currentTime) // 5 minutes ago
        
        let currentReading = MockBgReading(value: 120, timestamp: currentTime)
        let previousReading = MockBgReading(value: 110, timestamp: previousTime)
        
        // Test rising trend
        let risingTrend = viewModel.calculateTrend(current: currentReading, previous: previousReading)
        XCTAssertEqual(risingTrend, .rising)
        
        // Test stable trend
        let stableCurrentReading = MockBgReading(value: 115, timestamp: currentTime)
        let stableTrend = viewModel.calculateTrend(current: stableCurrentReading, previous: previousReading)
        XCTAssertEqual(stableTrend, .stable)
        
        // Test falling trend
        let fallingCurrentReading = MockBgReading(value: 100, timestamp: currentTime)
        let fallingTrend = viewModel.calculateTrend(current: fallingCurrentReading, previous: previousReading)
        XCTAssertEqual(fallingTrend, .falling)
    }
    
    func testConnectivityStatusUpdates() {
        // Test connectivity status changes
        viewModel.connectivityStatus = .connecting
        XCTAssertEqual(viewModel.connectivityStatus.description, "Connecting...")
        XCTAssertEqual(viewModel.connectivityStatus.color, .orange)
        
        viewModel.connectivityStatus = .connected
        XCTAssertEqual(viewModel.connectivityStatus.description, "Connected")
        XCTAssertEqual(viewModel.connectivityStatus.color, .green)
        
        viewModel.connectivityStatus = .disconnected
        XCTAssertEqual(viewModel.connectivityStatus.description, "Disconnected")
        XCTAssertEqual(viewModel.connectivityStatus.color, .gray)
        
        viewModel.connectivityStatus = .error(.deviceNotFound)
        XCTAssertEqual(viewModel.connectivityStatus.description, "Device not found")
        XCTAssertEqual(viewModel.connectivityStatus.color, .red)
    }
    
    func testAlertGeneration() {
        // Test alert generation based on glucose values
        let highReading = MockBgReading(value: 200, timestamp: Date())
        let lowReading = MockBgReading(value: 60, timestamp: Date())
        let normalReading = MockBgReading(value: 120, timestamp: Date())
        
        // Test high glucose alert
        viewModel.updateAlerts(highReading)
        XCTAssertFalse(viewModel.activeAlerts.isEmpty)
        XCTAssertEqual(viewModel.activeAlerts.first?.type, .high)
        
        // Test low glucose alert
        viewModel.updateAlerts(lowReading)
        XCTAssertFalse(viewModel.activeAlerts.isEmpty)
        XCTAssertEqual(viewModel.activeAlerts.first?.type, .low)
        
        // Test normal glucose (no alerts)
        viewModel.updateAlerts(normalReading)
        XCTAssertTrue(viewModel.activeAlerts.isEmpty)
    }
}

// MARK: - Mock Objects for Testing

class MockBgReading: BgReading {
    private let mockValue: Double
    private let mockTimestamp: Date
    
    init(value: Double, timestamp: Date) {
        self.mockValue = value
        self.mockTimestamp = timestamp
        super.init()
    }
    
    override var calculatedValue: Double {
        return mockValue
    }
    
    override var timeStamp: Date {
        return mockTimestamp
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}