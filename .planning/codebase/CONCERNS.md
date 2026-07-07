# Areas of Concern

## Fragility & Technical Debt
1. **Gemini AI Integration:** Previous release issues (AI assistant non-responsive in Release APK vs Debug) point to potential ProGuard/R8 obfuscation issues or missing Internet permissions in the Android Manifest.
2. **Geolocator Permissions:** Real-time geolocation often causes crashes or silent failures if active permission requesting flows or fallback handlers are not maintained precisely.
3. **Provider Bloat:** Large centralized `AppProvider` files might become bottlenecks. Needs vigilant monitoring to avoid god-classes.
