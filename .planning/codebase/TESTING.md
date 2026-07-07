# Testing Strategy

## Current Coverage
- The project depends lightly on `flutter_test`. 
- Deeply nested testing of Cloud Firestore operations or Geolocator streams is not thoroughly mocked out of the box in `dev_dependencies`.

## Priorities
1. Setting up mock Provider contexts to properly unit-test individual business logic paths (e.g. testing `AppProvider` in isolation).
2. Implementing Widget testing for the Auth flow and chat screens to prevent UI regression during architecture upgrades.
