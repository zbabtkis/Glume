//
//  ErrorHandling.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Error Types

enum GlumeError: LocalizedError, Identifiable {
    case bluetoothUnavailable
    case bluetoothUnauthorized
    case deviceNotFound
    case connectionTimeout
    case deviceUnsupported(deviceName: String)
    case dataReadError
    case unknownDevice
    case cgmNotConfigured
    case networkUnavailable
    case calibrationRequired
    case sensorExpired
    
    var id: String {
        return errorDescription ?? "unknown_error"
    }
    
    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Bluetooth is not available"
        case .bluetoothUnauthorized:
            return "Bluetooth permission denied"
        case .deviceNotFound:
            return "Device not found"
        case .connectionTimeout:
            return "Connection timeout"
        case .deviceUnsupported(let deviceName):
            return "Device '\(deviceName)' is not supported"
        case .dataReadError:
            return "Failed to read glucose data"
        case .unknownDevice:
            return "Unknown device detected"
        case .cgmNotConfigured:
            return "CGM not configured"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .calibrationRequired:
            return "Sensor calibration required"
        case .sensorExpired:
            return "Sensor has expired"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .bluetoothUnavailable:
            return "Please enable Bluetooth in your device settings and try again."
        case .bluetoothUnauthorized:
            return "Please allow Bluetooth access for Glume in your device settings."
        case .deviceNotFound:
            return "Make sure your CGM device is turned on and in range, then try scanning again."
        case .connectionTimeout:
            return "Check that your CGM device is nearby and try connecting again."
        case .deviceUnsupported:
            return "This device is not currently supported by Glume. Please check for app updates or contact support."
        case .dataReadError:
            return "Please check your CGM device connection and try again."
        case .unknownDevice:
            return "An unknown device was detected. Please ensure you're connecting to the correct CGM."
        case .cgmNotConfigured:
            return "Please complete the CGM setup process to start receiving glucose readings."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .calibrationRequired:
            return "Your sensor requires calibration. Please follow the calibration instructions."
        case .sensorExpired:
            return "Please replace your sensor with a new one to continue receiving readings."
        }
    }
    
    var iconName: String {
        switch self {
        case .bluetoothUnavailable, .bluetoothUnauthorized:
            return "bluetooth.slash"
        case .deviceNotFound, .unknownDevice:
            return "magnifyingglass"
        case .connectionTimeout:
            return "clock.badge.exclamationmark"
        case .deviceUnsupported:
            return "exclamationmark.triangle"
        case .dataReadError:
            return "exclamationmark.circle"
        case .cgmNotConfigured:
            return "gearshape"
        case .networkUnavailable:
            return "wifi.slash"
        case .calibrationRequired:
            return "calibration"
        case .sensorExpired:
            return "clock.badge"
        }
    }
    
    var color: Color {
        switch self {
        case .bluetoothUnavailable, .bluetoothUnauthorized, .deviceNotFound, .connectionTimeout, .dataReadError, .networkUnavailable:
            return .orange
        case .deviceUnsupported, .unknownDevice, .sensorExpired:
            return .red
        case .cgmNotConfigured, .calibrationRequired:
            return .blue
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: GlumeError
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?
    
    init(error: GlumeError, retryAction: (() -> Void)? = nil, dismissAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            Image(systemName: error.iconName)
                .font(.system(size: 60))
                .foregroundColor(error.color)
            
            VStack(spacing: 8) {
                Text(error.errorDescription ?? "Unknown Error")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            HStack(spacing: 16) {
                if let dismissAction = dismissAction {
                    Button("Dismiss") {
                        dismissAction()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let retryAction = retryAction {
                    Button("Try Again") {
                        retryAction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let error: GlumeError
    let dismissAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.iconName)
                .foregroundColor(error.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "Error")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: dismissAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(error.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(error.color, lineWidth: 1)
        )
    }
}

// MARK: - Error Manager

class ErrorManager: ObservableObject {
    @Published var currentError: GlumeError?
    @Published var showingError: Bool = false
    
    func showError(_ error: GlumeError) {
        currentError = error
        showingError = true
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
    
    func handleBluetoothError(_ error: Error) {
        // Convert CBError or other bluetooth errors to GlumeError
        if let description = error.localizedDescription.lowercased() {
            if description.contains("unauthorized") {
                showError(.bluetoothUnauthorized)
            } else if description.contains("unavailable") {
                showError(.bluetoothUnavailable)
            } else if description.contains("timeout") {
                showError(.connectionTimeout)
            } else {
                showError(.deviceNotFound)
            }
        } else {
            showError(.deviceNotFound)
        }
    }
    
    func handleDataError(_ error: Error) {
        showError(.dataReadError)
    }
    
    func handleNetworkError(_ error: Error) {
        showError(.networkUnavailable)
    }
}

// MARK: - Connectivity Status

enum ConnectivityStatus {
    case connected
    case disconnected
    case connecting
    case error(GlumeError)
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .error(let error):
            return error.errorDescription ?? "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .connected:
            return .green
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .error:
            return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .connected:
            return "checkmark.circle.fill"
        case .disconnected:
            return "circle"
        case .connecting:
            return "arrow.clockwise"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ErrorView(
            error: .deviceNotFound,
            retryAction: { },
            dismissAction: { }
        )
        
        ErrorBanner(
            error: .bluetoothUnavailable,
            dismissAction: { }
        )
    }
    .padding()
}