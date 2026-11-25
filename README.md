# Sahaay

A medication reminder app. Add your medicines with a photo, set one or more independent reminders for each, and get a notification when a reminder is due. All data stays on your device.

Sahaay is a reminder tool only: it does not give medical advice or calculate doses.

See the [product requirements](docs/sahaay_prd.md) and [v1 technical notes](docs/sahaay_v1_technical_notes.md).

## Getting Started

**Prerequisites:** Flutter SDK, Dart SDK, Android Studio or Xcode.

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
