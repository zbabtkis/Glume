# Glume UX Redesign - Integration Guide

## Overview

This document outlines the UX redesign implementation for Glume, providing a more minimalistic and user-friendly design. The redesign includes a complete onboarding process and a simplified dashboard view.

## Implementation Summary

### 1. Onboarding Process

**New Files:**
- `xdrip/SwiftUIViews/Onboarding/OnboardingView.swift`
- `xdrip/SwiftUIViews/Onboarding/OnboardingViewModel.swift`
- `xdrip/View Controllers/OnboardingHostingController.swift`

**Key Features:**
- 5-step wizard: Welcome → CGM Selection → Setup → Testing → Completion
- Support for all existing CGM transmitter types
- Bluetooth scanning simulation and connectivity testing
- Integration with existing UserDefaults and BluetoothPeripheralManager

**Integration Points:**
- `RootViewController` checks `UserDefaults.standard.onboardingCompleted`
- Onboarding is automatically presented on first app launch
- Saves selected CGM type and marks onboarding as complete

### 2. Simplified Dashboard

**New Files:**
- `xdrip/SwiftUIViews/SimplifiedDashboardView.swift`
- `xdrip/SwiftUIViews/SimplifiedDashboardViewModel.swift`
- `xdrip/View Controllers/SimplifiedDashboardHostingController.swift`

**Key Features:**
- Current glucose reading with trend arrows
- 6-hour glucose chart using existing `GlucoseChartView`
- Key metrics: average glucose and time in range
- Active alerts display for high/low values
- Real-time updates every 30 seconds

**Integration Points:**
- Uses existing `BgReadingsAccessor` for data
- Integrates with existing `GlucoseChartView` component
- Respects existing UserDefaults for glucose units and limits

### 3. Performance Optimizations

**Modified Files:**
- `xdrip/Core Data/accessors/BgReadingsAccessor.swift`

**New Methods:**
- `getLatestBgReadingsForDashboard(hours:forSensor:)` - Optimized 6-hour data fetch
- `getMostRecentValidBgReading(forSensor:)` - Current reading optimization

**Improvements:**
- Efficient Core Data predicates for non-zero calculated values
- Proper fetch limits based on expected reading intervals
- Time-based filtering for better performance

### 4. Error Handling

**New Files:**
- `xdrip/Utilities/ErrorHandling.swift`

**Key Components:**
- `GlumeError` enum with user-friendly messages
- `ErrorView` and `ErrorBanner` SwiftUI components
- `ErrorManager` for centralized error handling
- `ConnectivityStatus` tracking and display

**Error Types Covered:**
- Bluetooth unavailable/unauthorized
- Device not found/unsupported
- Connection timeout
- Data read errors
- Network unavailable
- CGM not configured

### 5. Testing Infrastructure

**New Files:**
- `Tests/OnboardingTests/OnboardingViewModelTests.swift`
- `Tests/DashboardTests/SimplifiedDashboardViewModelTests.swift`

**Test Coverage:**
- Onboarding flow navigation and state management
- CGM type selection and validation
- Error handling and recovery
- Dashboard data processing and trend calculation
- Alert generation based on glucose values

## Integration Steps

### Step 1: Update Project Configuration

1. Ensure all new SwiftUI files are added to the Xcode project
2. Verify that SwiftUI framework is linked
3. Update build settings if necessary for SwiftUI support

### Step 2: Enable Onboarding Flow

The onboarding flow is already integrated into `RootViewController`. To customize:

```swift
// In RootViewController.swift
private func checkAndShowOnboardingIfNeeded() {
    // Modify conditions as needed
    guard !UserDefaults.standard.onboardingCompleted && presentedViewController == nil else {
        return
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.showOnboarding()
    }
}
```

### Step 3: Replace Main Dashboard (Optional)

To use the simplified dashboard as the main view:

```swift
// In your tab bar controller or main view setup
let simplifiedDashboard = SimplifiedDashboardHostingController()
simplifiedDashboard.setBgReadingsAccessor(bgReadingsAccessor)

// Replace existing dashboard tab
tabBarController.viewControllers = [simplifiedDashboard, /* other tabs */]
```

### Step 4: Configure CGM Integration

Update the onboarding to work with actual CGM setup:

```swift
// In OnboardingViewModel.swift
func setBluetoothPeripheralManager(_ manager: BluetoothPeripheralManager) {
    self.bluetoothPeripheralManager = manager
    // Add actual device scanning and setup logic
}
```

### Step 5: Customize Error Messages

Modify error messages in `ErrorHandling.swift` to match your app's tone:

```swift
// In GlumeError enum
case deviceNotFound:
    return "Your preferred device name for device not found"
```

## Configuration Options

### UserDefaults Keys

- `onboardingCompleted`: Boolean indicating if onboarding is complete
- Existing keys: `bloodGlucoseUnitIsMgDl`, `urgentLowMarkValue`, etc.

### Customizable Settings

- Update interval for dashboard (currently 30 seconds)
- Chart time range (currently 6 hours)
- Error retry timeouts
- CGM type availability

## Performance Considerations

### Core Data Optimizations

- Use `getLatestBgReadingsForDashboard()` for dashboard data
- Fetch limits prevent excessive memory usage
- Predicates filter out invalid readings

### Real-time Updates

- Timer-based updates balance performance and freshness
- Updates stop when view is not visible
- Error handling prevents crash loops

## Testing

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme xdrip -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suites
xcodebuild test -scheme xdrip -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OnboardingViewModelTests
```

### Mock Data for Testing

Use the provided `MockBgReading` class for unit tests:

```swift
let mockReading = MockBgReading(value: 120, timestamp: Date())
viewModel.updateCurrentReading(mockReading)
```

## Deployment

### TestFlight Deployment

The existing Fastlane configuration supports the new features:

```bash
# Build and deploy
fastlane build_xdrip4ios
fastlane release
```

### Version Notes

Include in your release notes:
- New user onboarding experience
- Simplified, clean dashboard design
- Improved performance and error handling
- Enhanced CGM setup process

## Future Enhancements

### Potential Improvements

1. **Advanced Onboarding**
   - Video tutorials for each CGM type
   - Real-time device detection feedback
   - Troubleshooting guides

2. **Dashboard Enhancements**
   - Customizable time ranges
   - Additional metrics (standard deviation, etc.)
   - Dark mode optimization

3. **Error Recovery**
   - Automatic retry mechanisms
   - Detailed diagnostic information
   - Support contact integration

4. **Testing Expansion**
   - UI tests for SwiftUI views
   - Integration tests with Core Data
   - Performance benchmarking

## Troubleshooting

### Common Issues

1. **Onboarding not showing**: Check `UserDefaults.standard.onboardingCompleted`
2. **Dashboard data not loading**: Verify `BgReadingsAccessor` is properly set
3. **Errors not displaying**: Ensure `ErrorManager` is connected to views
4. **Performance issues**: Check Core Data fetch limits and predicates

### Debug Mode

Enable debug logging by setting:
```swift
// In your debug configuration
UserDefaults.standard.set(true, forKey: "debugMode")
```

This will provide additional console output for troubleshooting.

## Support

For questions or issues with the UX redesign implementation:

1. Check the unit tests for usage examples
2. Review the SwiftUI view implementations
3. Verify integration points with existing code
4. Test error scenarios using the provided error types

The implementation follows iOS design guidelines and maintains compatibility with the existing xdrip codebase while providing a modern, user-friendly experience.