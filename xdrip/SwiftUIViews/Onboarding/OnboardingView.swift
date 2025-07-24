//
//  OnboardingView.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // Progress indicator
                ProgressView(value: viewModel.progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                    .padding(.top)
                
                // Content based on current step
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeStepView(viewModel: viewModel)
                    case .cgmSelection:
                        CGMSelectionStepView(viewModel: viewModel)
                    case .cgmSetup:
                        CGMSetupStepView(viewModel: viewModel)
                    case .testing:
                        TestingStepView(viewModel: viewModel)
                    case .completion:
                        CompletionStepView(viewModel: viewModel)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation buttons
                HStack {
                    if viewModel.canGoBack {
                        Button("Back") {
                            viewModel.goBack()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(viewModel.nextButtonTitle) {
                        viewModel.goNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canGoNext)
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { 
                    viewModel.clearError()
                }
                if viewModel.currentError == .deviceNotFound {
                    Button("Try Again") {
                        viewModel.clearError()
                        viewModel.startScanning()
                    }
                }
            } message: {
                if let error = viewModel.currentError {
                    VStack(alignment: .leading) {
                        Text(error.errorDescription ?? "Unknown error")
                        if let recoverySuggestion = error.recoverySuggestion {
                            Text(recoverySuggestion)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Welcome to Glume")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Let's set up your continuous glucose monitor to get started with real-time glucose tracking.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - CGM Selection Step

struct CGMSelectionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Select Your CGM Device")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose the continuous glucose monitor you'll be using with Glume.")
                .font(.body)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.availableCGMTypes, id: \.self) { cgmType in
                        CGMTypeCard(
                            cgmType: cgmType,
                            isSelected: viewModel.selectedCGMType == cgmType
                        ) {
                            viewModel.selectCGMType(cgmType)
                        }
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct CGMTypeCard: View {
    let cgmType: CGMTransmitterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(cgmType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch cgmType {
        case .dexcom, .dexcomG4, .dexcomG7:
            return "sensor.tag.radiowaves.forward"
        case .miaomiao:
            return "dot.radiowaves.up.forward"
        case .Blucon:
            return "antenna.radiowaves.left.and.right"
        case .Bubble:
            return "circle.grid.3x3"
        case .Libre2:
            return "circle.and.line.horizontal"
        default:
            return "sensor"
        }
    }
}

// MARK: - CGM Setup Step

struct CGMSetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Setup \(viewModel.selectedCGMType?.rawValue ?? "CGM")")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Follow these steps to connect your CGM device:")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 16) {
                SetupStepRow(
                    stepNumber: 1,
                    title: "Enable Bluetooth",
                    description: "Make sure Bluetooth is enabled on your device"
                )
                
                SetupStepRow(
                    stepNumber: 2,
                    title: "Turn on your CGM",
                    description: "Ensure your CGM device is powered on and in range"
                )
                
                SetupStepRow(
                    stepNumber: 3,
                    title: "Start scanning",
                    description: "Tap 'Start Scanning' to search for your device"
                )
            }
            .padding(.top)
            
            Spacer()
            
            if viewModel.isScanning {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Scanning for devices...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
            } else {
                Button("Start Scanning") {
                    viewModel.startScanning()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct SetupStepRow: View {
    let stepNumber: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(stepNumber)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.accentColor))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Testing Step

struct TestingStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            
            Spacer()
            
            if viewModel.isTestingConnection {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2.0)
                    
                    Text("Testing Connection")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Verifying your CGM device connection...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if viewModel.connectionTestPassed {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Connection Successful!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your CGM device is connected and ready to use.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Connection Issue")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("We couldn't establish a connection with your CGM device. Please check your device and try again.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        viewModel.testConnection()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Completion Step

struct CompletionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Setup Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Your CGM is now configured and ready to monitor your glucose levels. You'll start seeing readings on your dashboard shortly.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}