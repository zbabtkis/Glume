//
//  SimplifiedDashboardViewModel.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SimplifiedDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentGlucoseValue: String = "--"
    @Published var currentTrend: GlucoseTrend = .stable
    @Published var timeAgo: String = "--"
    @Published var bgReadingValues: [Double] = []
    @Published var bgReadingDates: [Date] = []
    @Published var averageGlucose: String = "--"
    @Published var timeInRange: String = "--"
    @Published var activeAlerts: [GlucoseAlert] = []
    @Published var connectivityStatus: ConnectivityStatus = .disconnected
    
    // MARK: - Private Properties
    
    private var bgReadingsAccessor: BgReadingsAccessor?
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var errorManager: ErrorManager?
    
    // MARK: - Computed Properties
    
    var glucoseUnit: String {
        return isMgDl ? "mg/dL" : "mmol/L"
    }
    
    var isMgDl: Bool {
        return UserDefaults.standard.bloodGlucoseUnitIsMgDl
    }
    
    var urgentLowLimit: Double {
        return UserDefaults.standard.urgentLowMarkValue
    }
    
    var lowLimit: Double {
        return UserDefaults.standard.lowMarkValue
    }
    
    var highLimit: Double {
        return UserDefaults.standard.highMarkValue
    }
    
    var urgentHighLimit: Double {
        return UserDefaults.standard.urgentHighMarkValue
    }
    
    // MARK: - Private Properties
    
    private var bgReadingsAccessor: BgReadingsAccessor?
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Properties
    
    private var bgReadingsAccessor: BgReadingsAccessor?
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var errorManager: ErrorManager?
    
    // MARK: - Initialization
    
    init() {
        setupInitialData()
    }
    
    // MARK: - Public Methods
    
    func setBgReadingsAccessor(_ accessor: BgReadingsAccessor) {
        self.bgReadingsAccessor = accessor
        refreshDataSync()
    }
    
    func setErrorManager(_ manager: ErrorManager) {
        self.errorManager = manager
    }
    
    func startRealTimeUpdates() {
        // Start a timer to update data every 30 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.refreshDataSync()
        }
        
        // Initial refresh
        refreshDataSync()
    }
    
    func stopRealTimeUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @MainActor
    func refreshData() async {
        refreshDataSync()
    }
    
    // MARK: - Private Methods
    
    private func setupInitialData() {
        // Set up default values
        currentGlucoseValue = "--"
        timeAgo = "No data"
        averageGlucose = "--"
        timeInRange = "--"
    }
    
    private func refreshDataSync() {
        guard let bgReadingsAccessor = bgReadingsAccessor else { 
            connectivityStatus = .error(.cgmNotConfigured)
            errorManager?.showError(.cgmNotConfigured)
            return 
        }
        
        connectivityStatus = .connecting
        
        do {
            // Get the latest valid reading using optimized method
            if let latestReading = bgReadingsAccessor.getMostRecentValidBgReading(forSensor: nil) {
                updateCurrentReading(latestReading)
                
                // Get second latest reading for trend calculation
                let twoLatestReadings = bgReadingsAccessor.get2LatestBgReadings(minimumTimeIntervalInMinutes: 4.0)
                if twoLatestReadings.count > 1 {
                    currentTrend = calculateTrend(current: twoLatestReadings[0], previous: twoLatestReadings[1])
                }
                
                connectivityStatus = .connected
            } else {
                connectivityStatus = .disconnected
            }
            
            // Get readings for the chart (last 6 hours) using optimized method
            let chartReadings = bgReadingsAccessor.getLatestBgReadingsForDashboard(hours: 6.0, forSensor: nil)
            
            updateChartData(chartReadings)
            updateMetrics(chartReadings)
            updateAlerts(chartReadings.first)
            
        } catch {
            connectivityStatus = .error(.dataReadError)
            errorManager?.handleDataError(error)
        }
    }
    
    private func updateCurrentReading(_ reading: BgReading) {
        DispatchQueue.main.async {
            // Format the glucose value
            self.currentGlucoseValue = reading.calculatedValue.bgValueToString(mgDl: self.isMgDl)
            
            // Calculate time ago
            let timeInterval = abs(reading.timeStamp.timeIntervalSinceNow)
            self.timeAgo = self.formatTimeAgo(timeInterval)
        }
    }
    
    private func calculateTrend(current: BgReading, previous: BgReading) -> GlucoseTrend {
        let difference = current.calculatedValue - previous.calculatedValue
        let timeInterval = current.timeStamp.timeIntervalSince(previous.timeStamp) / 60.0 // Convert to minutes
        
        guard timeInterval > 0 else { return .stable }
        
        let changePerMinute = difference / timeInterval
        
        switch changePerMinute {
        case let x where x > 2:
            return .rapidRising
        case let x where x > 1:
            return .rising
        case let x where x < -2:
            return .rapidFalling
        case let x where x < -1:
            return .falling
        default:
            return .stable
        }
    }
    
    private func updateChartData(_ readings: [BgReading]) {
        DispatchQueue.main.async {
            self.bgReadingValues = readings.map { $0.calculatedValue }
            self.bgReadingDates = readings.map { $0.timeStamp }
        }
    }
    
    private func updateMetrics(_ readings: [BgReading]) {
        guard !readings.isEmpty else { return }
        
        DispatchQueue.main.async {
            // Calculate average
            let average = readings.map { $0.calculatedValue }.reduce(0, +) / Double(readings.count)
            self.averageGlucose = average.bgValueToString(mgDl: self.isMgDl)
            
            // Calculate time in range
            let inRangeCount = readings.filter { reading in
                reading.calculatedValue >= self.lowLimit && reading.calculatedValue <= self.highLimit
            }.count
            
            let timeInRangePercentage = (Double(inRangeCount) / Double(readings.count)) * 100
            self.timeInRange = String(format: "%.0f", timeInRangePercentage)
        }
    }
    
    private func updateAlerts(_ latestReading: BgReading?) {
        guard let reading = latestReading else {
            DispatchQueue.main.async {
                self.activeAlerts = []
            }
            return
        }
        
        var alerts: [GlucoseAlert] = []
        
        if reading.calculatedValue >= urgentHighLimit {
            alerts.append(GlucoseAlert(message: "Urgent High Glucose", type: .urgentHigh))
        } else if reading.calculatedValue >= highLimit {
            alerts.append(GlucoseAlert(message: "High Glucose", type: .high))
        } else if reading.calculatedValue <= urgentLowLimit {
            alerts.append(GlucoseAlert(message: "Urgent Low Glucose", type: .urgentLow))
        } else if reading.calculatedValue <= lowLimit {
            alerts.append(GlucoseAlert(message: "Low Glucose", type: .low))
        }
        
        DispatchQueue.main.async {
            self.activeAlerts = alerts
        }
    }
    
    private func formatTimeAgo(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        
        if minutes == 0 {
            return "Now"
        } else if minutes == 1 {
            return "1 min ago"
        } else if minutes < 60 {
            return "\(minutes) mins ago"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if hours == 1 {
                return remainingMinutes > 0 ? "1h \(remainingMinutes)m ago" : "1h ago"
            } else {
                return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m ago" : "\(hours)h ago"
            }
        }
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    
    var bloodGlucoseUnitIsMgDl: Bool {
        return bool(forKey: Key.bloodGlucoseUnitIsMgDl.rawValue)
    }
    
    var urgentLowMarkValue: Double {
        let value = double(forKey: Key.urgentLowMarkValue.rawValue)
        return value > 0 ? value : (bloodGlucoseUnitIsMgDl ? 55.0 : 3.1)
    }
    
    var lowMarkValue: Double {
        let value = double(forKey: Key.lowMarkValue.rawValue)
        return value > 0 ? value : (bloodGlucoseUnitIsMgDl ? 70.0 : 3.9)
    }
    
    var highMarkValue: Double {
        let value = double(forKey: Key.highMarkValue.rawValue)
        return value > 0 ? value : (bloodGlucoseUnitIsMgDl ? 180.0 : 10.0)
    }
    
    var urgentHighMarkValue: Double {
        let value = double(forKey: Key.urgentHighMarkValue.rawValue)
        return value > 0 ? value : (bloodGlucoseUnitIsMgDl ? 250.0 : 13.9)
    }
}