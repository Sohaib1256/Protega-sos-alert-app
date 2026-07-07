# Protega - Health Monitoring & Emergency Response App

A comprehensive Flutter application for health monitoring and emergency response with real-time vitals tracking, SOS functionality, and AI-powered safety assistance.

## 📁 Project Structure

```
lib/
├── main.dart                       # App entry point
├── models/
│   └── models.dart                 # Data models (User, Alert, Chat, etc.)
├── providers/
│   └── app_provider.dart           # State management with Provider
├── screens/
│   ├── auth_screen.dart            # Login & signup with wizard
│   ├── chat_screen.dart            # Real-time chat interface
│   ├── guardian_dashboard.dart     # Guardian view to monitor patients
│   ├── history_screen.dart         # Activity and alert history
│   ├── home_shell.dart             # Main app shell with navigation
│   ├── patient_dashboard.dart      # Patient vitals & SOS button
│   ├── settings_screen.dart        # User settings & preferences
│   └── social_screen.dart          # Friends list & social features
├── theme/
│   └── theme.dart                  # App theme & color constants
└── widgets/
    ├── animated_background.dart    # Animated gradient background
    ├── bottom_nav.dart             # Bottom navigation bar
    ├── glass_card.dart             # Glassmorphism UI component
    └── sos_button.dart             # Emergency SOS button widget
```

## ✨ Features

### 🔐 Authentication
- Multi-step signup wizard
- Role-based access (Patient, Guardian, Caretaker, Safety Officer)
- Purpose selection (Medical, Personal)
- Form validation with user-friendly error messages

### 🚨 Patient Dashboard
- **SOS Emergency Button**: Hold-to-activate emergency alert
- **Real-time Vitals**: Heart rate, battery level tracking
- **Fall Detection**: Configurable sensitivity settings
- **Location Sharing**: GPS tracking for safety
- **Quick Actions**: Direct access to emergency contacts

### 👥 Guardian Dashboard
- Monitor multiple patients simultaneously
- Real-time health status updates
- Location tracking on maps
- Direct communication (call/message)
- Alert notifications

### 💬 Social & Chat
- Friend search by User ID
- Real-time messaging
- AI Safety Assistant with intelligent responses
- Online/offline status indicators
- Friend request system

### 📊 History & Analytics
- Alert history timeline
- System event logging
- Timestamp tracking
- Event categorization

### ⚙️ Settings
- Profile management
- Fall detection configuration
- Emergency contacts management
- Privacy settings
- Notification preferences

## 🎨 UI/UX Features

- **Glassmorphism Design**: Frosted glass effects throughout
- **Smooth Animations**: Flutter Animate for fluid transitions
- **Dark Theme**: Eye-friendly color scheme
- **Gradient Backgrounds**: Animated ambient blobs
- **Haptic Feedback**: Tactile responses for actions
- **Charts**: Health data visualization with FL Chart

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone or download the project**
   ```bash
   cd protega
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
```bash
flutter run -d android
```

#### iOS
```bash
flutter run -d ios
```

#### Web
```bash
flutter run -d chrome
```

## 📱 Demo Credentials

The app includes demo authentication:

**Patient Account:**
- Email: `john@example.com`
- Password: `password`

**Guardian Account:**
- Email: `jane@example.com`
- Password: `password`

Or create a new account via signup!

## 🔧 Configuration

### Fall Detection
Adjust sensitivity in Settings:
- Low: Less sensitive, fewer false alarms
- Medium: Balanced detection
- High: Most sensitive, maximum protection

### Emergency Contacts
Add emergency contacts in Settings for quick access during alerts.

## 📦 Dependencies

- **provider**: State management
- **flutter_animate**: Smooth animations
- **fl_chart**: Data visualization
- **uuid**: Unique ID generation
- **url_launcher**: Phone calls & links

## 🏗️ Architecture

### State Management
- Provider pattern for reactive state management
- Centralized `AppProvider` for global app state
- ChangeNotifier for UI updates

### Code Organization
- **Models**: Data structures and business logic
- **Providers**: State management layer
- **Screens**: Full-page views
- **Widgets**: Reusable UI components
- **Theme**: Centralized styling

## 🎯 Key Components

### SOS Button
Hold-to-activate emergency button with:
- 3-second hold timer
- Progress ring indicator
- Ripple animation effect
- Haptic feedback

### Glass Card
Reusable glassmorphism component:
```dart
GlassCard(
  child: YourWidget(),
  padding: EdgeInsets.all(16),
  onTap: () {},
)
```

### Animated Background
Dynamic gradient background with moving blobs:
```dart
AnimatedBackground(
  child: YourContent(),
  isAlert: false,
)
```

## 🔐 Security Note

This is a demo application. For production use:
- Implement proper authentication with JWT/OAuth
- Add backend API integration
- Enable HTTPS for all communications
- Encrypt sensitive data
- Add biometric authentication
- Implement proper session management

## 🐛 Troubleshooting

### Issue: Dependencies not installing
**Solution**: Run `flutter clean` then `flutter pub get`

### Issue: Build fails
**Solution**: Check Flutter version with `flutter doctor`

### Issue: Hot reload not working
**Solution**: Stop and restart the app

## 🚀 Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS App
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📞 Support

For issues or questions:
1. Check the documentation above
2. Review Flutter documentation: https://docs.flutter.dev/
3. Open an issue in the repository

## 🎉 Enjoy!

Start the app and explore all the features. Perfect for:
- Health monitoring applications
- Emergency response systems
- Patient care management
- Family safety tracking

---

**Note**: This app uses demo data and simulated responses. For production use, integrate with real backend services and sensor data.
