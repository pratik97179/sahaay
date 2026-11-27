import 'dart:io';

import '../application/photo_capture.dart';

/// Debug only: stands in for the camera on the iOS simulator, which has
/// none. Hands back the photos already in [directory] in turn, so the add
/// flow can be tried end to end. Enabled with
/// `--dart-define=SAHAAY_SAMPLE_CAMERA=true` in debug builds; never used in
/// release.
final class SamplePhotoCapture implements PhotoCapture {
  SamplePhotoCapture(this._directory);

  final Directory _directory;
  int _next = 0;

  @override
  Future<String?> capture() async {
    final photos =
        _directory
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.jpg'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    if (photos.isEmpty) return null;
    // Copy it, as a camera would hand over a new file.
    final photo = photos[_next++ % photos.length];
    final copy = File(
      '${Directory.systemTemp.path}/sample-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    return (await photo.copy(copy.path)).path;
  }
}
