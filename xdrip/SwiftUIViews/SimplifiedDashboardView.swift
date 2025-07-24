//
//  SimplifiedDashboardView.swift
//  xdrip
//
//  Created by AI Assistant on 24/07/2024.
//  Copyright © 2024 Johan Degraeve. All rights reserved.
//

import SwiftUI
import Charts

struct SimplifiedDashboardView: View {
    
    @ObservedObject var viewModel: SimplifiedDashboardViewModel
    @StateObject private var errorManager = ErrorManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Error banner (if any)
                    if let error = errorManager.currentError {
                        ErrorBanner(error: error) {
                            errorManager.clearError()
                        }
                    }
                    
                    // Connectivity status
                    ConnectivityStatusCard(status: viewModel.connectivityStatus)
                    
                    // Current Reading Card
                    CurrentReadingCard(
                        currentValue: viewModel.currentGlucoseValue,
                        trend: viewModel.currentTrend,
                        unit: viewModel.glucoseUnit,
                        timeAgo: viewModel.timeAgo
                    )
                    
                    // Glucose Chart
                    GlucoseChartCard(
                        bgReadingValues: viewModel.bgReadingValues,
                        bgReadingDates: viewModel.bgReadingDates,
                        isMgDl: viewModel.isMgDl,
                        urgentLowLimit: viewModel.urgentLowLimit,
                        lowLimit: viewModel.lowLimit,
                        highLimit: viewModel.highLimit,
                        urgentHighLimit: viewModel.urgentHighLimit
                    )
                    
                    // Key Metrics Row
                    KeyMetricsRow(
                        averageValue: viewModel.averageGlucose,
                        timeInRange: viewModel.timeInRange,
                        unit: viewModel.glucoseUnit
                    )
                    
                    // Active Alerts (if any)
                    if !viewModel.activeAlerts.isEmpty {
                        AlertsCard(alerts: viewModel.activeAlerts)
                    }
                    
                    Spacer(minLength: 100) // Space for any floating elements
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Glucose")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            viewModel.startRealTimeUpdates()
            viewModel.setErrorManager(errorManager)
        }
        .onDisappear {
            viewModel.stopRealTimeUpdates()
        }
    }
}

// MARK: - Current Reading Card

struct CurrentReadingCard: View {
    let currentValue: String
    let trend: GlucoseTrend
    let unit: String
    let timeAgo: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Reading")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(currentValue)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(glucoseColor)
                        
                        Text(unit)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: trend.iconName)
                            .font(.title)
                            .foregroundColor(trend.color)
                    }
                    
                    Text(timeAgo)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var glucoseColor: Color {
        // This would be calculated based on glucose ranges
        return .primary
    }
}

// MARK: - Glucose Chart Card

struct GlucoseChartCard: View {
    let bgReadingValues: [Double]
    let bgReadingDates: [Date]
    let isMgDl: Bool
    let urgentLowLimit: Double
    let lowLimit: Double
    let highLimit: Double
    let urgentHighLimit: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("6-Hour Glucose Chart")
                    .font(.headline)
                
                Spacer()
                
                Text("Last 6h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Use the existing GlucoseChartView
            GlucoseChartView(
                glucoseChartType: .simplifiedDashboard,
                bgReadingValues: bgReadingValues.isEmpty ? nil : bgReadingValues,
                bgReadingDates: bgReadingDates.isEmpty ? nil : bgReadingDates,
                isMgDl: isMgDl,
                urgentLowLimitInMgDl: urgentLowLimit,
                lowLimitInMgDl: lowLimit,
                highLimitInMgDl: highLimit,
                urgentHighLimitInMgDl: urgentHighLimit,
                liveActivityType: .normal,
                hoursToShowScalingHours: 6.0,
                glucoseCircleDiameterScalingHours: nil,
                overrideChartHeight: 200,
                overrideChartWidth: nil,
                highContrast: false
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Key Metrics Row

struct KeyMetricsRow: View {
    let averageValue: String
    let timeInRange: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: "Average",
                value: averageValue,
                unit: unit,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            MetricCard(
                title: "Time in Range",
                value: timeInRange,
                unit: "%",
                icon: "target"
            )
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Alerts Card

struct AlertsCard: View {
    let alerts: [GlucoseAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Alerts")
                .font(.headline)
            
            ForEach(alerts, id: \.id) { alert in
                HStack {
                    Image(systemName: alert.iconName)
                        .foregroundColor(alert.color)
                    
                    Text(alert.message)
                        .font(.callout)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(UIColor.systemYellow).opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.systemYellow), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Types

enum GlucoseTrend {
    case rising, stable, falling, rapidRising, rapidFalling
    
    var iconName: String {
        switch self {
        case .rising:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .falling:
            return "arrow.down.right"
        case .rapidRising:
            return "arrow.up"
        case .rapidFalling:
            return "arrow.down"
        }
    }
    
    var color: Color {
        switch self {
        case .rising, .rapidRising:
            return .orange
        case .stable:
            return .primary
        case .falling, .rapidFalling:
            return .red
        }
    }
}

struct GlucoseAlert {
    let id = UUID()
    let message: String
    let type: AlertType
    
    var iconName: String {
        switch type {
        case .high:
            return "exclamationmark.triangle.fill"
        case .low:
            return "exclamationmark.triangle.fill"
        case .urgentHigh:
            return "exclamationmark.octagon.fill"
        case .urgentLow:
            return "exclamationmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .high, .urgentHigh:
            return .red
        case .low, .urgentLow:
            return .orange
        }
    }
    
    enum AlertType {
        case high, low, urgentHigh, urgentLow
    }
}

// MARK: - GlucoseChartType Extension

extension GlucoseChartType {
    static let simplifiedDashboard = GlucoseChartType.liveActivity
}

#Preview {
    SimplifiedDashboardView(viewModel: SimplifiedDashboardViewModel())
}

// MARK: - Connectivity Status Card

struct ConnectivityStatusCard: View {
    let status: ConnectivityStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: status.iconName)
                .foregroundColor(status.color)
                .imageScale(.medium)
            
            Text(status.description)
                .font(.callout)
                .foregroundColor(status.color)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}