import 'app_database.dart';

/// Runs work atomically across repositories that share the local database.
abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}

final class DriftTransactionRunner implements TransactionRunner {
  const DriftTransactionRunner(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
