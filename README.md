<p align="center">
  <img src="assets/app_icon_transparent.png" alt="Protega Logo" width="120"/>
</p>

<h1 align="center">Protega — SOS Alert & Health Monitoring App</h1>

<p align="center">
  A real-time emergency response and health monitoring system built with Flutter, Firebase, and ESP32 IoT hardware.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/ESP32-IoT%20Hardware-E7352C?logo=espressif" alt="ESP32"/>
  <img src="https://img.shields.io/badge/Gemini%20AI-Powered-4285F4?logo=google" alt="Gemini AI"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Android"/>
</p>

---

## 🔭 Overview

**Protega** is a comprehensive safety application that combines a Flutter mobile app with ESP32 wearable hardware to deliver:

- **SOS Emergency Alerts** — triggered via the app (hold-to-activate) or physical hardware button
- **Real-time Vitals Monitoring** — heart rate, fall detection, GPS location, and battery level streamed from ESP32
- **Guardian Network** — friends and family receive live alerts and can track the user in real time
- **AI Safety Assistant** — powered by Google Gemini for intelligent safety guidance
- **Background Protection** — foreground service with alarm audio, even when the app is minimized

---

## 📁 Project Structure

```
protega/
├── lib/
│   ├── main.dart                          # App entry, Firebase init, provider setup
│   ├── firebase_options.dart              # Firebase config (git-ignored)
│   ├── models/
│   │   └── models.dart                    # Data models (User, Alert, Chat, Message)
│   ├── providers/
│   │   ├── auth_provider.dart             # Authentication & user session
│   │   ├── emergency_provider.dart        # SOS alerts, alarm audio, alert lifecycle
│   │   ├── hardware_provider.dart         # ESP32 connection, vitals, fall detection
│   │   └── social_provider.dart           # Friends, chat, AI assistant, requests
│   ├── screens/
│   │   ├── auth_screen.dart               # Login & multi-step signup wizard
│   │   ├── chat_screen.dart               # Real-time messaging interface
│   │   ├── guardian_dashboard.dart         # Monitor connected patients
│   │   ├── history_screen.dart            # Alert & event timeline
│   │   ├── home_shell.dart                # Main app shell with bottom navigation
│   │   ├── patient_dashboard.dart         # Vitals display & SOS trigger
│   │   ├── permissions_setup_screen.dart  # Runtime permission onboarding
│   │   ├── settings_screen.dart           # Profile, contacts, fall config, privacy
│   │   └── social_screen.dart             # Friend list & friend requests
│   ├── services/
│   │   └── background_service.dart        # Foreground service for SOS & monitoring
│   ├── theme/
│   │   └── theme.dart                     # Colors, gradients, text styles
│   └── widgets/
│       ├── animated_background.dart       # Animated gradient blob background
│       ├── bottom_nav.dart                # Glassmorphism bottom navigation bar
│       ├── glass_card.dart                # Frosted glass card component
│       ├── glass_chip.dart                # Frosted glass chip/tag component
│       └── sos_button.dart                # Hold-to-activate SOS button
│
├── android/
│   └── app/src/main/kotlin/com/example/protega/
│       ├── MainActivity.kt                # Flutter activity with method channels
│       ├── BackgroundGestureService.kt    # Accessibility service for hardware SOS
│       └── SosBroadcastReceiver.kt        # Broadcast receiver for native SOS triggers
│
├── esp32_firmware/
│   └── esp32_firmware.ino                 # Arduino firmware for ESP32 wearable
│
├── assets/
│   ├── app_icon_transparent.png           # App launcher icon
│   ├── fonts/                             # Inter & Outfit font families
│   └── sounds/                            # SOS alarm audio
│
├── firestore.rules                        # Cloud Firestore security rules
├── firebase.json                          # Firebase project config
├── pubspec.yaml                           # Flutter dependencies
├── .env                                   # API keys (git-ignored)
└── .gitignore
```

---

## ✨ Features

### 🚨 SOS Emergency System
- **Hold-to-activate** SOS button with 3-second progress ring and haptic feedback
- **Loud alarm audio** plays on the device during an active alert
- **Real-time alert broadcasting** to all connected guardians/friends via Firestore
- **Background foreground service** keeps SOS active even when the app is minimized
- **Native SOS trigger** via Android accessibility service and broadcast receiver
- **Hardware SOS button** on ESP32 wearable for physical panic trigger

### 📡 ESP32 Hardware Integration
- **ADXL345 accelerometer** for fall detection with configurable sensitivity
- **NEO-6M GPS module** for real-time location tracking
- **Battery level monitoring** via analog pin
- **Firebase Realtime Database** streaming for low-latency vitals updates
- **WiFiManager** for easy WiFi provisioning on the device
- **Physical SOS button** on GPIO pin 4

### 🔐 Authentication & Roles
- Firebase Authentication (email/password)
- Multi-step signup wizard with role selection
- **Medical use** roles: Patient, Guardian, Caretaker, Safety Officer
- **Personal use** roles: Self (User), Guardian
- Persistent session with auto-login

### 👥 Guardian Dashboard
- Monitor multiple patients simultaneously
- Real-time health status cards with vitals
- Live location tracking
- Direct call and message actions
- Active alert notifications

### 💬 Social & Chat
- Friend search by unique User ID
- Friend request system (send, accept, decline)
- Real-time messaging via Firestore
- **AI Safety Assistant** powered by Google Gemini
- Online/offline status indicators

### 📊 History & Analytics
- Alert history timeline with severity indicators
- System event logging
- Filterable event categories
- Timestamp tracking

### ⚙️ Settings
- Profile management (name, photo, medical info)
- Emergency contacts management
- Fall detection sensitivity (Low / Medium / High)
- Notification preferences
- Privacy settings
- Hardware connection management

### 🎨 UI/UX
- **Glassmorphism** design language throughout
- **Animated gradient backgrounds** with ambient blobs
- **Dark theme** with curated color palette
- Smooth animations via `flutter_animate`
- Health data charts via `fl_chart`
- Custom fonts (Inter, Outfit)
- Haptic feedback on key interactions

---

## 🔧 Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) |
| **State Management** | Provider (multi-provider architecture) |
| **Auth** | Firebase Authentication |
| **Database** | Cloud Firestore (chat, users, alerts) |
| **Realtime Data** | Firebase Realtime Database (ESP32 vitals) |
| **AI** | Google Gemini API |
| **Background Service** | `flutter_background_service` + Android foreground service |
| **Native Android** | Kotlin (accessibility service, broadcast receiver, method channels) |
| **IoT Hardware** | ESP32 + ADXL345 + NEO-6M GPS |
| **Fonts** | Google Fonts (Inter, Outfit) |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio or VS Code with Flutter extensions
- A Firebase project (see [Firebase Setup](#firebase-setup))
- *(Optional)* ESP32 board with ADXL345 and NEO-6M GPS

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Sohaib1256/Protega-sos-alert-app.git
   cd Protega-sos-alert-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**

   Create a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password)
3. Enable **Cloud Firestore** and deploy the security rules from `firestore.rules`
4. Enable **Realtime Database** (for ESP32 vitals streaming)
5. Add your Android app and download `google-services.json` to `android/app/`
6. Generate `firebase_options.dart` using FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### ESP32 Hardware Setup (Optional)

1. Open `esp32_firmware/esp32_firmware.ino` in Arduino IDE
2. Install required libraries:
   - `WiFiManager`
   - `Firebase ESP Client`
   - `Adafruit ADXL345`
   - `TinyGPSPlus`
3. Update the Firebase API key and database URL in the firmware
4. Wire the hardware:
   - **SOS Button** → GPIO 4
   - **GPS (NEO-6M)** → TX=GPIO 16, RX=GPIO 17
   - **ADXL345** → SDA=GPIO 21, SCL=GPIO 22
   - **Battery** → GPIO 34 (analog)
5. Flash the firmware to your ESP32

---

## 🏗️ Architecture

### Multi-Provider State Management

The app uses a **domain-separated provider architecture** instead of a single monolithic provider:

```
┌─────────────────────────────────────────────────┐
│                    main.dart                      │
│            MultiProvider (4 providers)            │
├──────────┬──────────┬───────────┬────────────────┤
│  Auth    │ Emergency│ Hardware  │    Social       │
│ Provider │ Provider │ Provider  │   Provider      │
├──────────┼──────────┼───────────┼────────────────┤
│ Firebase │ Firestore│ Realtime  │  Firestore      │
│   Auth   │ + Audio  │    DB     │  + Gemini AI    │
└──────────┴──────────┴───────────┴────────────────┘
```

- **AuthProvider** — Sign in, sign up, session persistence, user profile
- **EmergencyProvider** — SOS trigger, alarm playback, alert CRUD, alert listeners
- **HardwareProvider** — ESP32 connection, vitals streaming, fall detection config
- **SocialProvider** — Friends, requests, chat messages, AI assistant

### Background Services

- **`BackgroundService`** — Dart isolate-based foreground service for continuous monitoring
- **`BackgroundGestureService.kt`** — Android accessibility service for detecting hardware SOS gestures
- **`SosBroadcastReceiver.kt`** — Android broadcast receiver that bridges native SOS triggers to Flutter

### Firestore Data Model

```
users/{userId}         → profile, role, vitals, emergency contacts, friends[]
alerts/{alertId}       → SOS alerts with sender, location, severity, timestamps
chats/{chatId}         → participant list, last message
  └── messages/{msgId} → individual chat messages
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Email/password authentication |
| `cloud_firestore` | Users, alerts, chats database |
| `firebase_database` | Real-time ESP32 vitals streaming |
| `flutter_animate` | Smooth UI animations |
| `fl_chart` | Health data visualization |
| `google_generative_ai` | Gemini AI safety assistant |
| `geolocator` | GPS location services |
| `flutter_background_service` | Foreground service for SOS |
| `flutter_local_notifications` | Alert notifications |
| `audioplayers` | SOS alarm audio playback |
| `permission_handler` | Runtime permission management |
| `shared_preferences` | Local key-value storage |
| `flutter_dotenv` | Environment variable loading |
| `flutter_phone_direct_caller` | Direct phone call actions |
| `image_picker` | Profile photo selection |
| `google_fonts` | Inter & Outfit font families |
| `uuid` | Unique ID generation |
| `url_launcher` | Open URLs, phone calls, SMS |
| `path_provider` | File system paths |
| `http` | HTTP networking |

---

## 🔐 Security Notes

- Firebase security rules enforce user-scoped read/write access
- Friends can only add/remove their own UID from other users' arrays
- Alerts are readable only by the sender and their friends
- Chat access is restricted to participants
- API keys are stored in `.env` (git-ignored)
- `firebase_options.dart` and `google-services.json` are git-ignored

---

## 🐛 Troubleshooting

| Issue | Solution |
|---|---|
| Dependencies not installing | Run `flutter clean` then `flutter pub get` |
| Build fails | Check `flutter doctor` for missing SDKs |
| Firebase errors | Verify `google-services.json` is in `android/app/` |
| Background service not starting | Grant battery optimization exemption in device settings |
| Location not updating | Ensure location permissions are granted (including background) |
| ESP32 not connecting | Check WiFi credentials and Firebase database URL in firmware |
| Alarm not playing | Ensure `assets/sounds/alarm.mp3` exists and is listed in `pubspec.yaml` |

---

## 🚀 Building for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (requires macOS + Xcode)
```bash
flutter build ios --release
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## 📄 License

This project is provided as-is for educational and demonstration purposes.

---

## 📞 Support

For issues or questions:
1. Open an issue in the [GitHub repository](https://github.com/Sohaib1256/Protega-sos-alert-app/issues)
2. Review Flutter documentation: [docs.flutter.dev](https://docs.flutter.dev/)
3. Review Firebase documentation: [firebase.google.com/docs](https://firebase.google.com/docs)

---

## 🔗 Let's Connect
[![LinkedIn](https://img.shields.io/badge/LinkedIn-%230077B5.svg?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/sohaib-sheikh-388a9036a/)
