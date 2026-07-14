# 🚀 Quick Setup Guide — Protega

Get the Protega app running on your device in minutes.

---

## Step 1: Prerequisites

| Requirement | Version |
|---|---|
| Flutter SDK | ≥ 3.0.0 |
| Dart SDK | ≥ 3.0.0 |
| Android Studio / VS Code | Latest with Flutter extension |
| Firebase project | [Create one here](https://console.firebase.google.com) |

### Verify Flutter installation
```bash
flutter doctor
```

---

## Step 2: Clone & Install

```bash
git clone https://github.com/Sohaib1256/Protega-sos-alert-app.git
cd Protega-sos-alert-app
flutter pub get
```

---

## Step 3: Firebase Configuration

### 3a. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Enable the following services:
   - **Authentication** → Email/Password sign-in method
   - **Cloud Firestore** → Create database in production mode
   - **Realtime Database** → Create database (for ESP32 vitals)

### 3b. Add Android App to Firebase
1. In Firebase Console → Project Settings → Add App → Android
2. Package name: `com.example.protega`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### 3c. Generate Firebase Options
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This creates `lib/firebase_options.dart` automatically.

### 3d. Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```
Or copy rules from `firestore.rules` into the Firebase Console Rules editor.

---

## Step 4: Environment Variables

Create a `.env` file in the project root:

```env
GEMINI_API_KEY=your_google_gemini_api_key
```

Get a Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey).

---

## Step 5: Run the App

### On Android emulator or device
```bash
flutter run
```

### On a specific device
```bash
flutter devices          # List available devices
flutter run -d <device_id>
```

---

## Step 6: Create an Account

1. Launch the app
2. Tap **Sign Up**
3. Choose your purpose: **Medical** or **Personal**
4. Select your role:
   - Medical → Patient, Guardian, Caretaker, Safety Officer
   - Personal → Self (User), Guardian
5. Fill in your profile details
6. Start using Protega!

---

## 🔌 ESP32 Hardware Setup (Optional)

If you have an ESP32 wearable device:

### Required Hardware
- ESP32 development board
- ADXL345 accelerometer (I2C)
- NEO-6M GPS module (Serial)
- Push button (SOS trigger)
- Battery + voltage divider for monitoring

### Wiring

| Component | ESP32 Pin |
|---|---|
| SOS Button | GPIO 4 |
| GPS TX | GPIO 16 |
| GPS RX | GPIO 17 |
| ADXL345 SDA | GPIO 21 |
| ADXL345 SCL | GPIO 22 |
| Battery (analog) | GPIO 34 |

### Flashing Firmware

1. Install [Arduino IDE](https://www.arduino.cc/en/software) with ESP32 board support
2. Install libraries: `WiFiManager`, `Firebase ESP Client`, `Adafruit ADXL345`, `TinyGPSPlus`
3. Open `esp32_firmware/esp32_firmware.ino`
4. Update the Firebase API key and database URL
5. Upload to ESP32

### First Boot
- The ESP32 starts a WiFi access point for provisioning
- Connect to it from your phone and enter your WiFi credentials
- The device will begin streaming vitals to Firebase Realtime Database

---

## 📱 Features to Try

1. **SOS Alert** — Hold the SOS button for 3 seconds on the patient dashboard
2. **Add Friends** — Search by User ID on the Social tab
3. **Chat** — Message friends or talk to the AI Safety Assistant
4. **Guardian View** — Log in as a Guardian to monitor connected patients
5. **Settings** — Configure fall detection sensitivity, add emergency contacts
6. **History** — View past alerts and system events
7. **Permissions** — The app will guide you through required permissions on first launch

---

## 🔧 Troubleshooting

### `flutter: command not found`
Add Flutter to your system PATH, or restart your terminal.

### Build errors on Android
Run `flutter doctor` and install any missing Android SDK components.

### Firebase authentication failing
- Verify `google-services.json` is in `android/app/`
- Make sure Email/Password auth is enabled in Firebase Console

### Background service not starting
- Exempt the app from battery optimization in your device settings
- Grant all requested permissions (location, notifications, phone)

### Dependencies error
```bash
flutter clean
flutter pub get
```

### ESP32 not connecting to Firebase
- Verify WiFi credentials (use WiFiManager AP to reconfigure)
- Check the Firebase API key and database URL in the firmware
- Ensure Realtime Database rules allow write access for the device

---

## 🏗️ Build for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (macOS + Xcode required)
```bash
flutter build ios --release
```

---

## 💡 Tips

- **Hot reload**: Press `r` in the terminal while the app is running
- **Hot restart**: Press `R` in the terminal
- **Debug mode**: `flutter run --debug` (default)
- **Profile mode**: `flutter run --profile`
- **Check logs**: `flutter logs` for device logs

---

Enjoy building with **Protega**! 🛡️
