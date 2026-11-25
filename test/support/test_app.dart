import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/app/app.dart';
import 'package:sahaay/core/database/app_database.dart';
import 'package:sahaay/core/database/database_provider.dart';
import 'package:sahaay/features/medicines/medicines_providers.dart';

import 'fakes.dart';

/// Pumps the whole app over an in-memory database and fake device services.
Future<void> pumpTestApp(
  WidgetTester tester, {
  required AppDatabase db,
  FakePhotoCapture? capture,
  FakePhotoStorage? photos,
}) async {
  // A typical phone screen (360 x 780 logical pixels).
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        photoCaptureProvider.overrideWithValue(capture ?? FakePhotoCapture()),
        medicinePhotoStorageProvider.overrideWithValue(
          photos ?? FakePhotoStorage(),
        ),
      ],
      child: const SahaayApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tears the app down so database stream timers finish inside the test.
Future<void> disposeTestApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

/// Runs real database work from a widget test, whose fake-async zone would
/// otherwise never let the query complete.
Future<T> runDb<T>(WidgetTester tester, Future<T> Function() action) async =>
    (await tester.runAsync(action)) as T;
