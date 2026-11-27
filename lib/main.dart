import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/storage/app_directories.dart';
import 'features/medicines/data/sample_photo_capture.dart';
import 'features/medicines/medicines_providers.dart';

/// Debug only: use sample photos instead of the camera (the iOS simulator
/// has none).
const _sampleCamera = bool.fromEnvironment('SAHAAY_SAMPLE_CAMERA');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final documents = await getApplicationDocumentsDirectory();
  runApp(
    ProviderScope(
      overrides: [
        appDocumentsDirectoryProvider.overrideWithValue(documents),
        if (kDebugMode && _sampleCamera)
          photoCaptureProvider.overrideWithValue(
            SamplePhotoCapture(Directory('${documents.path}/medicine_photos')),
          ),
      ],
      child: const SahaayApp(),
    ),
  );
}
