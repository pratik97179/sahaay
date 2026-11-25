import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'transaction_runner.dart';

/// The single on-device database, closed when the app's scope is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.local();
  ref.onDispose(db.close);
  return db;
});

/// Runs work atomically across repositories that share [appDatabaseProvider].
final transactionRunnerProvider = Provider<TransactionRunner>(
  (ref) => DriftTransactionRunner(ref.watch(appDatabaseProvider)),
);
