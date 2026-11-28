/// A screen to go to, with the values it needs (`docs/architecture.md`,
/// Navigation).
///
/// Each feature owns its destinations, in `<feature>_destinations.dart`.
/// That file is the feature's navigation contract: another feature that
/// opens one of its screens imports only that file. A destination is plain
/// data, with no path and no widget; where it sits in the app and what it
/// shows are registered once, in the feature's `<feature>_screens.dart`.
///
/// Declare subclasses `final`: a destination is matched to its screen by
/// its exact type.
abstract class Destination {
  const Destination();
}
