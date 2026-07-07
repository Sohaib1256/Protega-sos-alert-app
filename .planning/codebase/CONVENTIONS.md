# Coding Conventions

## Framework Standards
- Strictly adheres to the Flutter Lint rules defined by `flutter_lints: ^6.0.0`. Do not violate the standard `flutter analyze` constraints.
- Prefer `const` constructors everywhere for optimization.

## Naming & Style
- **Classes/Enums:** PascalCase
- **Variables/Methods:** camelCase
- **Files/Folders:** snake_case
- **Extracting Widgets:** When a build method exceeds ~150 lines, extract local UI clumps into private stateless widgets in the same file or a reusable public widget in `lib/widgets`.
