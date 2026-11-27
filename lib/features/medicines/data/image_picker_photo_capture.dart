import 'package:image_picker/image_picker.dart';

import '../application/photo_capture.dart';

/// Camera-only capture through `image_picker` (gallery is out of scope).
final class ImagePickerPhotoCapture implements PhotoCapture {
  ImagePickerPhotoCapture([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Photos are only used for recognising a medicine, so they are downscaled
  /// to keep local storage small.
  static const double _maxDimension = 1600;

  @override
  Future<String?> capture() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: 85,
    );
    return photo?.path;
  }
}
