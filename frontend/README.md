## Food Info Flutter App

A simple Flutter client that searches foods and shows key nutrients using a FastAPI backend proxy.

## Project structure

```
frontend/
  pubspec.yaml
  lib/
    main.dart
    food_provider.dart
    search_screen.dart
    detail_screen.dart
```

## Prerequisites

* Flutter SDK (latest stable)
* A running backend on your machine, default `http://127.0.0.1:8000`

## Configure the backend URL

Open `lib/food_provider.dart` and set `ApiConfig.baseUrl` to match your target device.
* Android emulator: `http://10.0.2.2:8000`
* iOS simulator, macOS desktop, Flutter web on Chrome: `http://127.0.0.1:8000`
* Physical device: `http://<your-computer-LAN-IP>:8000` and run the backend with `--host 0.0.0.0`

## Platform notes

### macOS desktop

* Ensure `macos/Runner/DebugProfile.entitlements` includes:

  ```xml
  <key>com.apple.security.network.client</key><true/>
  ```
* If HTTP is blocked, add ATS exceptions to `macos/Runner/Info.plist` similar to iOS

## Install dependencies

```bash
cd frontend
flutter pub get
```

## Run the app

Start the backend first, then:

```bash
flutter run -d macos
# or choose your device:
# flutter run -d ios
# flutter run -d chrome
# flutter run -d emulator-id
```

## App flow

- [Home page](../assets/images/home.png)

1. Enter a food name and search
3. See a scrollable list of results
4. Tap a result to open the details screen
5. View key nutrients in a simple table

## Features included

* Search by food name
* View specific nutrition information
* Provider state management
* Loading and error states

- [Search Loading](../assets/images/search_load.png)
- [Details Loading](../assets/images/detail_load.png)

## Versions used in development

* Flutter stable channel
* Dart stable SDK
* Provider 6
* http
