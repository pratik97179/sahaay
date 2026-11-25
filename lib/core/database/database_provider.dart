import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The single on-device database, closed when the app's scope is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.local();
  ref.onDispose(db.close);
  return db;
});
