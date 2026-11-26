import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahaay_design/sahaay_design.dart';

import 'app/app.dart';
import 'core/storage/app_directories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerSahaayDesignLicenses();
  final documents = await getApplicationDocumentsDirectory();
  runApp(
    ProviderScope(
      overrides: [appDocumentsDirectoryProvider.overrideWithValue(documents)],
      child: const SahaayApp(),
    ),
  );
}
