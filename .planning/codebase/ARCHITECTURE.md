# Architecture

## Pattern
The application follows a standard Flutter **Model-View-ViewModel (MVVM) / Provider-driven** architectural pattern.

## Core Layers

### 1. Presentation Layer (`lib/screens`, `lib/widgets`)
- Pure UI components built using Flutter.
- Receives data and trigger commands through Providers.
- Relies heavily on `Consumer` widgets and `context.read/watch`.

### 2. State & Business Logic Layer (`lib/providers`)
- Contains the application's business rules and state handlers extending `ChangeNotifier`.
- Handles external service calls (Firebase, Gemini API, Geolocator) and updates UI state accordingly.

### 3. Data & Entity Layer (`lib/models`)
- Defines structured Dart classes representing domain objects (e.g., `UserModel`, `HealthRecord`).
- Typically contains `fromJson` and `toJson` methods for Firestore serialization/deserialization.

### 4. Shared Utilities (`lib/theme`, `lib/utils`)
- Theming constants and reusable configuration.
