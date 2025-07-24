//
//  OnboardingViewModel.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case cgmSelection = 1
    case cgmSetup = 2
    case testing = 3
    case completion = 4
    
    var progress: Double {
        return Double(self.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

class OnboardingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedCGMType: CGMTransmitterType?
    @Published var isScanning: Bool = false
    @Published var isTestingConnection: Bool = false
    @Published var connectionTestPassed: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Computed Properties
    
    var progress: Double {
        return currentStep.progress
    }
    
    var canGoBack: Bool {
        return currentStep.rawValue > 0
    }
    
    var canGoNext: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .cgmSelection:
            return selectedCGMType != nil
        case .cgmSetup:
            return !isScanning
        case .testing:
            return connectionTestPassed || !isTestingConnection
        case .completion:
            return true
        }
    }
    
    var nextButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .cgmSelection:
            return "Continue"
        case .cgmSetup:
            return "Test Connection"
        case .testing:
            return connectionTestPassed ? "Finish" : "Skip"
        case .completion:
            return "Done"
        }
    }
    
    var availableCGMTypes: [CGMTransmitterType] {
        return CGMTransmitterType.allCases
    }
    
    // MARK: - Private Properties
    
    private var bluetoothPeripheralManager: BluetoothPeripheralManager?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // We'll inject the BluetoothPeripheralManager when available
    }
    
    // MARK: - Public Methods
    
    func setBluetoothPeripheralManager(_ manager: BluetoothPeripheralManager) {
        self.bluetoothPeripheralManager = manager
    }
    
    func goNext() {
        switch currentStep {
        case .welcome:
            currentStep = .cgmSelection
            
        case .cgmSelection:
            currentStep = .cgmSetup
            
        case .cgmSetup:
            currentStep = .testing
            startConnectionTest()
            
        case .testing:
            if connectionTestPassed {
                currentStep = .completion
                saveOnboardingSettings()
            } else {
                // Skip to completion even if test failed
                currentStep = .completion
                saveOnboardingSettings()
            }
            
        case .completion:
            completeOnboarding()
        }
    }
    
    func goBack() {
        guard canGoBack else { return }
        
        let previousStepIndex = currentStep.rawValue - 1
        if let previousStep = OnboardingStep(rawValue: previousStepIndex) {
            currentStep = previousStep
        }
    }
    
    func selectCGMType(_ cgmType: CGMTransmitterType) {
        selectedCGMType = cgmType
    }
    
    func startScanning() {
        guard let selectedCGMType = selectedCGMType else { return }
        
        isScanning = true
        
        // Simulate scanning process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isScanning = false
            // For now, we'll assume scanning was successful
            // In a real implementation, this would interface with BluetoothPeripheralManager
        }
    }
    
    func testConnection() {
        startConnectionTest()
    }
    
    // MARK: - Private Methods
    
    private func startConnectionTest() {
        isTestingConnection = true
        connectionTestPassed = false
        
        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isTestingConnection = false
            // For now, we'll simulate a successful connection
            // In a real implementation, this would test actual device connectivity
            self.connectionTestPassed = true
        }
    }
    
    private func saveOnboardingSettings() {
        guard let selectedCGMType = selectedCGMType else { return }
        
        // Save the selected CGM type to UserDefaults
        // Note: This is a simplified implementation
        // In the real app, this would involve more complex peripheral setup
        
        UserDefaults.standard.set(true, forKey: UserDefaults.Key.isMaster.rawValue)
        
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        
        // Store the selected CGM type for future reference
        UserDefaults.standard.set(selectedCGMType.rawValue, forKey: "selectedCGMType")
    }
    
    private func completeOnboarding() {
        // This will be handled by the presenting view controller
        // to dismiss the onboarding and show the main app
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}