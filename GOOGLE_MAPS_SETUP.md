# Google Maps Integration Setup

This guide will help you set up Google Maps in your Flutter application.

## Prerequisites

1. A Google Cloud Platform (GCP) account
2. Billing enabled on your GCP project (Google Maps requires a billing account, but offers a free tier)

## Setup Instructions

### 1. Get a Google Maps API Key

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
   - Directions API
4. Go to "Credentials" and create a new API key
5. Restrict the API key to only be used by your app

### 2. Android Setup

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add your API key in the `local.properties` file (create it if it doesn't exist):
   ```
   MAPS_API_KEY=YOUR_ANDROID_API_KEY
   ```
3. Make sure your package name in `android/app/build.gradle` matches the one in your Google Cloud Console

### 3. iOS Setup

1. Open `ios/Runner/Info.plist`
2. Replace `YOUR_IOS_GOOGLE_MAPS_API_KEY` with your iOS API key
3. Make sure your bundle identifier in Xcode matches the one in your Google Cloud Console

### 4. Update Dependencies

Run the following command to update your dependencies:

```bash
flutter pub get
```

### 5. For iOS Additional Setup

1. Navigate to your iOS directory:
   ```bash
   cd ios
   ```
2. Install pods:
   ```bash
   pod install
   ```
3. Open the Xcode workspace (not the project):
   ```bash
   open Runner.xcworkspace
   ```
4. In Xcode, go to the "Signing & Capabilities" tab and enable "Background Modes" with "Location updates"

## Usage

You can now use the `GoogleMapScreen` widget in your app. Here's a basic example:

```dart
import 'package:bikex/screens/user_pages/tracking_pages/google_map_screen.dart';

// In your widget:
GoogleMapScreen(
  initialPosition: LatLng(37.7749, -122.4194), // Optional initial position
  restaurantLocation: LatLng(37.7858, -122.4064), // Optional restaurant location
  onMapCreated: (LatLng position) {
    // Called when the map is created
  },
)
```

## Troubleshooting

- If you see a blank screen, make sure you've:
  - Added the API key correctly
  - Enabled the required APIs in Google Cloud Console
  - Set the correct package name/bundle ID
  - Run `flutter clean` and rebuild the app

- For iOS, if you get build errors, try:
  ```bash
  cd ios
  pod deintegrate
  pod cache clean --all
  pod install
  ```

## Security Note

Never commit your API keys directly in version control. Use environment variables or a secrets management solution in production.
