import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns the current wall-clock time.
typedef Clock = DateTime Function();

/// The single source of "now", overridden in tests so dates and validation
/// stay deterministic.
final clockProvider = Provider<Clock>((ref) => DateTime.now);
