/// Captures a medicine photo with the device camera.
///
/// Kept behind a contract so screens can be tested without the camera plugin.
abstract interface class PhotoCapture {
  /// Opens the camera and returns the path of the captured photo, or `null`
  /// when the user cancels.
  Future<String?> capture();
}
