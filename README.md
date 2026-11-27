# Sahaay

A medication reminder app. Add your medicines with a photo, set one or more independent reminders for each, and get a notification when a reminder is due. All data stays on your device.

Sahaay is a reminder tool only: it does not give medical advice or calculate doses.

## Documentation

- [Architecture](docs/architecture.md)
- [Design system](docs/design-system.md)
- [Technology decisions](docs/adr/0001-technology-choices.md)

## Getting Started

**Prerequisites:** Flutter SDK, Dart SDK, Android Studio or Xcode. Only Android and iOS are supported.

```bash
git clone <repository-url>
cd sahaay
flutter pub get
dart run build_runner build
flutter run
```

## Development

Generated files (`*.g.dart`) are not committed; rerun `dart run build_runner build` after changing database tables.

```bash
dart format .
flutter analyze
flutter test
```
