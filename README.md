
# Personal Finance Tracker

## Overview
An advanced Flutter mobile application for comprehensive personal finance management with real-time synchronization, analytical insights, and secure multi-device access.

## Architecture
Implements clean, layered architecture separating UI, business logic, and data layers, following SOLID principles and reactive programming patterns.

## Core Technologies
- **Frontend**: Flutter/Dart with Material Design
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **State Management**: Provider pattern with reactive streams
- **Security**: End-to-end encryption for financial data

## Key Features
- **Intelligent Transaction Management**: ML-assisted categorization
- **Dynamic Analytics**: Interactive data visualization with drill-down capabilities
- **Budget Control**: Real-time monitoring with threshold notifications
- **Multi-currency Support**: Live conversion rates
- **Credit Instruments Management**: Comprehensive tracking of credit facilities

## Technical Implementation
- Dependency injection for modular architecture
- Comprehensive test coverage (unit, widget, integration)
- Offline-first design with seamless synchronization
- GDPR and financial regulation compliance

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter plugins
- Firebase account

### Installation
```bash
# Clone the repository
git clone https://github.com/Ngogaserge/FinSight.git

# Navigate to project directory
cd FinSight

# Install dependencies
flutter pub get

# Configure Firebase
# 1. Create a Firebase project at firebase.google.com
# 2. Add Android and iOS apps to your Firebase project
# 3. Download and add the google-services.json and GoogleService-Info.plist files

# Run the application
flutter run
```

### Development
- Run tests: `flutter test`
- Build release: `flutter build apk --release` or `flutter build ios --release`
