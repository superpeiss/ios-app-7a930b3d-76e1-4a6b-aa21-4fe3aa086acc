# Industrial Configurator iOS App

A production-ready iOS application for configuring industrial components with real-time 3D preview, compatibility validation, and quote generation.

## Features

- **Multi-Step Configuration Process**: Guide users through selecting compatible industrial components
- **Dynamic Compatibility Filtering**: Real-time filtering based on product database rules
- **Live 3D Preview**: SceneKit-powered visualization of assembled products
- **Bill of Materials**: Automatic BOM generation with complex pricing logic
- **Quote Generation**: Formal quotes with validity periods and user account management
- **User Account Management**: Save configurations and quotes to user accounts

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Separation of concerns with ViewModels
- **Combine**: Reactive state management
- **SceneKit**: 3D rendering and visualization
- **XcodeGen**: Project file generation for maintainability

## Project Structure

```
IndustrialConfigurator/
├── Models/              # Data models (Component, Configuration, Quote, etc.)
├── Views/               # SwiftUI views
├── ViewModels/          # View models (managed by services)
├── Services/            # Business logic services
│   ├── ProductDatabaseService.swift
│   ├── ConfigurationManager.swift
│   ├── BOMService.swift
│   └── UserManager.swift
├── Utilities/           # Helper utilities
└── Resources/           # Assets and resources
```

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository:
```bash
git clone https://github.com/superpeiss/ios-app-7a930b3d-76e1-4a6b-aa21-4fe3aa086acc.git
cd ios-app-7a930b3d-76e1-4a6b-aa21-4fe3aa086acc
```

2. Run the setup script:
```bash
./setup.sh
```

This will install XcodeGen (if needed) and generate the Xcode project.

3. Open the project:
```bash
open IndustrialConfigurator.xcodeproj
```

## Building

### Using Xcode
Open `IndustrialConfigurator.xcodeproj` and press Cmd+B

### Using Command Line
```bash
xcodebuild -scheme IndustrialConfigurator \
  -destination 'generic/platform=iOS' \
  clean build
```

## Testing

Run tests using:
```bash
xcodebuild -scheme IndustrialConfigurator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

## Components

### Product Database
- 24+ pre-configured industrial components across 8 categories
- Compatibility rules engine
- Pricing rules with discounts and surcharges

### Configuration Manager
- Multi-step configuration workflow
- Real-time compatibility validation
- Configuration persistence

### 3D Visualization
- Real-time SceneKit rendering
- Interactive camera controls
- Component stacking and assembly preview

### BOM & Pricing
- Line item generation
- Complex pricing rules (discounts, surcharges, bundles)
- Quote generation with validity periods

## CI/CD

GitHub Actions workflow automatically builds and tests the app on every push.

## License

Copyright © 2024. All rights reserved.
