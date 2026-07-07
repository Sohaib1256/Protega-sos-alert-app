# 🚀 Quick Setup Guide

## Step 1: Install Flutter

If you don't have Flutter installed:

### macOS
```bash
brew install flutter
```

### Windows
Download from: https://docs.flutter.dev/get-started/install/windows

### Linux
Download from: https://docs.flutter.dev/get-started/install/linux

## Step 2: Verify Installation

```bash
flutter doctor
```

This will show you what needs to be installed.

## Step 3: Navigate to Project

```bash
cd protega_organized
```

## Step 4: Install Dependencies

```bash
flutter pub get
```

## Step 5: Run the App

### On Android/iOS Emulator
```bash
flutter run
```

### On Chrome (Web)
```bash
flutter run -d chrome
```

### On Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

## 📱 Demo Login

Use these credentials to test the app:

**Patient Account:**
- Email: `john@example.com`
- Password: `password`

**Guardian Account:**
- Email: `jane@example.com`
- Password: `password`

Or create your own account!

## 📂 Project Structure Matches Image

```
lib/
├── models/
│   └── models.dart              ✅
├── providers/
│   └── app_provider.dart        ✅
├── screens/
│   ├── auth_screen.dart         ✅
│   ├── chat_screen.dart         ✅
│   ├── guardian_dashboard.dart  ✅
│   ├── history_screen.dart      ✅
│   ├── home_shell.dart          ✅
│   ├── patient_dashboard.dart   ✅
│   ├── settings_screen.dart     ✅
│   └── social_screen.dart       ✅
├── theme/
│   └── theme.dart               ✅
└── widgets/
    ├── animated_background.dart ✅
    ├── bottom_nav.dart          ✅
    ├── glass_card.dart          ✅
    └── sos_button.dart          ✅
```

## ✨ Features to Try

1. **Login**: Use demo credentials or create account
2. **SOS Button**: Hold for 3 seconds on patient dashboard
3. **Chat**: Message AI assistant or friends
4. **Guardian View**: Switch to guardian account to monitor patients
5. **Settings**: Configure fall detection, add emergency contacts
6. **History**: View past alerts and events

## 🔧 Troubleshooting

### "flutter: command not found"
Add Flutter to your PATH or restart terminal after installation.

### Build errors on Android
Run: `flutter doctor` and install any missing Android SDK components.

### iOS build fails
Make sure Xcode is installed: `xcode-select --install`

### Dependencies error
Run: `flutter clean` then `flutter pub get`

## 📱 Build for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS App
```bash
flutter build ios --release
```
Then archive in Xcode.

### Web
```bash
flutter build web --release
```
Output: `build/web/`

## 🎯 Next Steps

1. Explore all screens and features
2. Customize theme colors in `lib/theme/theme.dart`
3. Add backend API integration
4. Implement real sensor data
5. Add push notifications
6. Deploy to app stores

## 💡 Tips

- Use hot reload: Press `r` in terminal while app is running
- Hot restart: Press `R` in terminal
- Debug mode: Run with `flutter run --debug`
- Profile mode: Run with `flutter run --profile`

Enjoy building with Protega! 🚀
