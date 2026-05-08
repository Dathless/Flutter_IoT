# IoT App

A Flutter application for IoT device management and monitoring.

## Description

This is a Flutter-based IoT application designed to connect, control, and monitor Internet of Things devices. It provides a user-friendly interface for interacting with various IoT sensors and actuators, allowing users to view real-time data, send commands, and manage device configurations.

## Packages/Dependencies

The following packages are used in this project:

- **flutter**: The Flutter SDK for building the UI.
- **cupertino_icons**: Provides Cupertino-style icons for iOS-style interfaces.
- **http**: A composable, Future-based library for making HTTP requests.
- **dio**: A powerful HTTP client for Dart, which supports Interceptors, FormData, Request Cancellation, File Downloading, Timeout, etc.
- **record**: A Flutter plugin for recording audio.
- **shared_preferences**: Wraps platform-specific persistent storage for simple data.
- **intl**: Provides internationalization and localization facilities.

### Installation

To install the dependencies, run the following command in the project root directory:

```bash
flutter pub get
```

This will download and install all the required packages listed in `pubspec.yaml`.

## Simple Workflow

1. **Clone the Repository**: Clone this project to your local machine.
2. **Install Dependencies**: Run `flutter pub get` to install all necessary packages.
3. **Set Up Devices**: Ensure your IoT devices are connected and configured.
4. **Run the App**: Use Flutter commands to run the app on your desired platform.
5. **Develop and Test**: Make changes to the code, test on emulators/devices, and iterate.

## How to Run

### Prerequisites

- Flutter SDK installed (version ^3.10.8)
- Dart SDK
- For Android: Android Studio or VS Code with Flutter extension
- For iOS: Xcode (macOS only)
- For Web: A web browser
- For Desktop: Appropriate desktop environment

### Android

#### Real Device

1. Enable Developer Options and USB Debugging on your Android device.
2. Connect your device via USB.
3. Run the following command:

```bash
flutter run
```

Flutter will detect the connected device and install the app.

#### Emulator

1. Set up an Android Virtual Device (AVD) in Android Studio.
2. Start the emulator.
3. Run:

```bash
flutter run
```

### Web

1. Ensure you have a web browser installed (Chrome recommended).
2. Run the app on the web:

```bash
flutter run -d chrome
```

This will launch the app in Chrome.

### Desktop App

#### Windows

```bash
flutter run -d windows
```

#### Linux

```bash
flutter run -d linux
```

#### macOS

```bash
flutter run -d macos
```

Note: For desktop platforms, ensure the necessary build tools are installed as per Flutter's desktop setup documentation.

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/)
- [Flutter IoT Development Guide](https://docs.flutter.dev/development/platform-integration/platform-channels)
