Project in development.

Documentation available on https://xdrip4ios.readthedocs.io/en/latest/

for info, send an email to xdrip@proximus.be

Current Status :

## New UX Features (v2024.1)

- **Onboarding Experience**: New user wizard for easy CGM setup
  - Step-by-step guide for device selection and configuration
  - Automated connectivity testing
  - Support for all CGM transmitter types
  
- **Simplified Dashboard**: Clean, minimal interface focusing on essential data
  - Current glucose reading with trend indicators
  - 6-hour glucose chart
  - Key metrics (average, time in range)
  - Real-time alerts for high/low values

- **Enhanced Error Handling**: User-friendly error messages with recovery suggestions
  - Bluetooth connectivity issues
  - Device setup problems
  - Data synchronization errors

- **Performance Optimizations**: Improved Core Data queries for faster dashboard loading
  - Optimized glucose data fetching
  - Efficient chart rendering
  - Background data refresh

## Core Features

- Supported transmitters :
    - Dexcom G4 with xBridge       
    - Dexcom G5 and G6
    - MiaoMiao 1 and 2
    - Blucon
    - Bubble
    - Droplet 1
    - Atom
    - Libre 2
- 6 hour graph with readings
- Alerting
- Upload to Nightscout
- Follower mode, with NightScout
- Store readings in HealthKit
- Speak readings
- upload to Dexcom share servers
- Bluetooth Connection to M5Stack, the M5Stack software to be used can be found here : https://github.com/JohanDegraeve/M5_NightscoutMon
- Bluetooth Connection to M5StickC, the M5Stickc software to be used can be found here : https://github.com/JohanDegraeve/M5_StickC_xdrip_iOS
- Connection to Watlaa :
    
    

- create events in Calendar when new glucose reading is received. This to support AppleWatch. More info : https://github.com/JohanDegraeve/xdripswift/wiki/Calendar-Events---Apple-Watch

For developers : please go to the Wiki : https://github.com/JohanDegraeve/xdripswift/wiki
