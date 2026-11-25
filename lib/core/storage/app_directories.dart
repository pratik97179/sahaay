import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's private documents directory.
///
/// Resolved once at start-up (it needs an async platform call) and supplied
/// by overriding this provider in `main`.
final appDocumentsDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError(
    'appDocumentsDirectoryProvider must be overridden at start-up.',
  ),
);
