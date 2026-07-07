# File Structure

## Core Structure
- `lib/main.dart` - Entry point, Firebase and Material App initialization.
- `lib/models/` - Data structures and mapping (e.g. `user_model.dart`).
- `lib/providers/` - Centralized business logic and external service abstraction.
- `lib/screens/` - Modular UI screens (Dashboard, Auth, Maps/Geolocation specific pages).
- `lib/theme/` - TextStyles, colors, and layout constraints.
- `lib/widgets/` - Reusable cross-screen UI components (cards, specialized buttons, map overlays).

## Assets
- App Icons and animations. (Flutter Animate utilities commonly exist directly in UI widgets or shared styles).
