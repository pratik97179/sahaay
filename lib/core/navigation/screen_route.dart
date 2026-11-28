import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'destination.dart';

/// Registers one [Destination] type as a screen: where it sits under its
/// parent, how its values travel in the location, and what it shows.
///
/// Each feature lists its screens in `<feature>_screens.dart`; the app
/// composes those lists once. The screen table checks every list when the
/// app starts, so a wrong path, a missing parent or a value with no
/// placeholder fails at launch instead of on some later tap.
final class ScreenRoute<D extends Destination> {
  ScreenRoute({
    required this.path,
    required this.parent,
    required this._decode,
    required this._build,
    this._encode,
  });

  /// `/` for the one root screen; otherwise this screen's own part of the
  /// location, under its parent's: `medicines`, `:id`, `reminders/new`.
  /// `:name` is a value, filled from [encode] and read back by [decode].
  final String path;

  /// The destination type beneath this screen: where back goes, and what a
  /// cold open (a notification) puts underneath. `null` only for the root.
  final Type? parent;

  /// Builds the destination from its location's values.
  final D Function(Map<String, String> values) _decode;

  /// The page that shows a destination.
  final Widget Function(D destination) _build;

  /// A destination's values by placeholder name; leave out when it has none.
  final Map<String, String> Function(D destination)? _encode;

  /// The destination type this screen shows.
  Type get type => D;

  /// [destination]'s values by placeholder name, for its location.
  Map<String, String> valuesOf(Destination destination) =>
      _encode?.call(destination as D) ?? const {};

  /// This screen as a go_router route, with [children] nested under it.
  GoRoute toGoRoute(List<RouteBase> children) => GoRoute(
    path: path,
    pageBuilder: (context, state) => MaterialPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: _build(_decode(state.pathParameters)),
    ),
    routes: children,
  );
}

/// Every screen of the app, built from the features' lists: the route tree
/// for go_router, and the location of any [Destination].
final class ScreenTable {
  ScreenTable(List<ScreenRoute> screens)
    : _byType = _index(screens),
      _patterns = {},
      _names = {} {
    for (final screen in screens) {
      final chain = _chainOf(screen);
      final parts = [
        for (final s in chain.reversed)
          if (s.path != '/') s.path,
      ];
      final pattern = '/${parts.join('/')}';
      final names = [
        for (final m in _placeholder.allMatches(pattern)) m.group(1)!,
      ];
      if (names.toSet().length != names.length) {
        throw StateError(
          'Screen ${screen.type}: a value name is used twice in $pattern.',
        );
      }
      _patterns[screen.type] = pattern;
      _names[screen.type] = names.toSet();
    }
    root = _build(screens.singleWhere((s) => s.parent == null), screens);
  }

  static final _placeholder = RegExp(r':(\w+)');

  final Map<Type, ScreenRoute> _byType;
  final Map<Type, String> _patterns;
  final Map<Type, Set<String>> _names;

  /// The route tree, rooted at `/`.
  late final GoRoute root;

  /// The location that shows [to], such as `/medicines/abc`.
  String locationOf(Destination to) {
    final screen = _byType[to.runtimeType];
    if (screen == null) {
      throw StateError(
        '${to.runtimeType} has no screen. Add it to its feature\'s '
        '*_screens.dart list.',
      );
    }
    final values = screen.valuesOf(to);
    final names = _names[screen.type]!;
    if (values.length != names.length || !names.every(values.containsKey)) {
      throw StateError(
        '${screen.type} gives the values ${values.keys.toList()}, but its '
        'location ${_patterns[screen.type]} needs ${names.toList()}.',
      );
    }
    return _patterns[screen.type]!.replaceAllMapped(_placeholder, (m) {
      final value = values[m.group(1)]!;
      if (value.isEmpty) {
        throw StateError('${screen.type}: the value ${m.group(1)} is empty.');
      }
      return Uri.encodeComponent(value);
    });
  }

  static Map<Type, ScreenRoute> _index(List<ScreenRoute> screens) {
    final byType = <Type, ScreenRoute>{};
    for (final s in screens) {
      if (byType.containsKey(s.type)) {
        throw StateError('${s.type} is registered as a screen twice.');
      }
      final root = s.parent == null;
      if (root != (s.path == '/')) {
        throw StateError(
          'Screen ${s.type}: only the root screen has no parent, and only it '
          'has the path "/".',
        );
      }
      if (!root && (s.path.startsWith('/') || s.path.endsWith('/'))) {
        throw StateError(
          'Screen ${s.type}: "${s.path}" is relative to its parent, so it '
          'neither starts nor ends with "/".',
        );
      }
      byType[s.type] = s;
    }
    if (byType.values.where((s) => s.parent == null).length != 1) {
      throw StateError('Exactly one screen is the root, with no parent.');
    }
    for (final s in screens) {
      if (s.parent != null && !byType.containsKey(s.parent)) {
        throw StateError(
          'Screen ${s.type}: its parent ${s.parent} has no screen.',
        );
      }
    }
    return byType;
  }

  /// [screen], its parent, its parent's parent… up to the root.
  List<ScreenRoute> _chainOf(ScreenRoute screen) {
    final chain = <ScreenRoute>[screen];
    while (chain.last.parent != null) {
      if (chain.length > _byType.length) {
        throw StateError('Screen ${screen.type}: its parents form a loop.');
      }
      chain.add(_byType[chain.last.parent]!);
    }
    return chain;
  }

  /// [screen]'s route with its children nested. Fixed paths come before
  /// values among siblings, so `medicines/new` is never read as an id.
  static GoRoute _build(ScreenRoute screen, List<ScreenRoute> screens) {
    final children = screens.where((s) => s.parent == screen.type).toList();
    final seen = <String>{};
    for (final c in children) {
      if (!seen.add(c.path)) {
        throw StateError('Two screens under ${screen.type} use "${c.path}".');
      }
    }
    final fixed = [
      for (final c in children)
        if (!c.path.startsWith(':')) c,
    ];
    final valued = [
      for (final c in children)
        if (c.path.startsWith(':')) c,
    ];
    return screen.toGoRoute([
      for (final c in [...fixed, ...valued]) _build(c, screens),
    ]);
  }
}
