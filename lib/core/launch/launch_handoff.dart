import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One straight mark, in global coordinates: a tick or the needle.
@immutable
final class LaunchLine {
  const LaunchLine({
    required this.x,
    required this.top,
    required this.bottom,
    required this.width,
    this.alpha = 1,
  });

  final double x;
  final double top;
  final double bottom;
  final double width;
  final double alpha;
}

/// Where the launch screen's needle lands (docs/design-system.md §3).
@immutable
final class LaunchLanding {
  /// On Today's ruler: its needle and the nearest ticks on each side,
  /// nearest first.
  const LaunchLanding.ruler({
    required LaunchLine this.needle,
    required this.left,
    required this.right,
  });

  /// Nowhere: the launch screen just fades, such as on an empty day.
  const LaunchLanding.none() : needle = null, left = const [], right = const [];

  final LaunchLine? needle;
  final List<LaunchLine> left;
  final List<LaunchLine> right;
}

/// Passes the first screen's needle to the launch curtain, once.
final class LaunchHandoff {
  final landing = ValueNotifier<LaunchLanding?>(null);

  /// How much of Today's own ruler shows (0–1). The curtain starts it at 0,
  /// brings it up faintly while its marks move into place, then fully as
  /// they land; with no curtain it stays 1.
  final reveal = ValueNotifier<double>(1);

  /// Only the first landing counts.
  void land(LaunchLanding to) => landing.value ??= to;
}

final launchHandoffProvider = Provider<LaunchHandoff>((ref) => LaunchHandoff());
