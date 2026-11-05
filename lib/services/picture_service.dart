import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../utils/picture_encoder.dart';

enum PictureSource { camera, gallery }

/// Lets the user choose a photo and turns it into base64 ready for `pictureUrl`.
///
/// Wrapped in a class (and provided through Provider) so widget tests can swap in a fake
/// instead of opening a real camera or file dialog.
class PictureService {
  PictureService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// The camera is only offered on phones/tablets. Desktop and web use the file chooser.
  bool get cameraAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Opens the camera or gallery, then shrinks and base64-encodes the chosen photo.
  /// Returns null if the user cancelled. Throws [PictureException] with a readable
  /// message if something went wrong.
  Future<EncodedPicture?> pickAndEncode(PictureSource source) async {
    XFile? file;
    try {
      // The picker pre-shrinks huge camera photos natively, so the Dart step below
      // never has to decode a 12-megapixel image.
      file = await _picker.pickImage(
        source: source == PictureSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } on PlatformException catch (e) {
      throw PictureException(_friendly(source, e));
    } on UnsupportedError {
      throw PictureException(source == PictureSource.camera
          ? "This device can't use the camera here. Choose from the gallery instead."
          : "This device can't open the photo chooser.");
    }
    if (file == null) return null; // cancelled

    final bytes = await file.readAsBytes();
    return encodePicture(bytes);
  }

  String _friendly(PictureSource source, PlatformException e) {
    switch (e.code) {
      case 'camera_access_denied':
        return 'Camera permission was denied. Allow it in your phone settings, or choose from the gallery.';
      case 'photo_access_denied':
        return 'Photo access was denied. Allow it in your phone settings and try again.';
      default:
        final what = source == PictureSource.camera ? 'the camera' : 'your photos';
        return 'Could not open $what${e.message == null ? '' : ': ${e.message}'}';
    }
  }
}
