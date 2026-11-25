import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sahaay/core/database/app_database.dart';

AppDatabase openTestDatabase([QueryExecutor? executor]) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(executor ?? NativeDatabase.memory());
}
