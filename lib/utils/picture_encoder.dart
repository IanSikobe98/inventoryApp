import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// How small a photo is made before it is stored. Tune here.
///
/// The photo is saved *inside the database row* as base64 and is sent with every
/// inventory list, so smaller is better. 800 px at quality 75 is typically 40-120 KB,
/// which looks sharp on a phone card. The API refuses anything over 750,000 base64
/// characters (about 560 KB), so [maxBytes] keeps us comfortably below that.
class PictureLimits {
  /// Longest edge, in pixels.
  static const int maxSide = 800;

  /// JPEG quality, 1-100.
  static const int quality = 75;

  /// If the first attempt is still bigger than this, retry smaller (see the ladder).
  static const int maxBytes = 400 * 1024;
}

/// A problem with the chosen photo, worded for the user.
class PictureException implements Exception {
  PictureException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A photo ready to store: [base64] is what goes into `pictureUrl`.
class EncodedPicture {
  const EncodedPicture({
    required this.base64,
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// Plain base64 of a JPEG (no `data:` prefix, no line breaks).
  final String base64;

  /// Size of the JPEG in bytes (before base64 adds about a third).
  final int bytes;
  final int width;
  final int height;
}

/// Shrinks [raw] (any JPEG/PNG/GIF/WebP/BMP) to a small JPEG and base64-encodes it.
/// The work runs in a background isolate so the screen stays smooth.
///
/// Also fixes phone-camera rotation, flattens transparency onto white, and drops
/// metadata such as GPS location (re-encoding discards it).
Future<EncodedPicture> encodePicture(Uint8List raw) async {
  if (raw.isEmpty) {
    throw PictureException('That file is empty.');
  }
  final result = await compute(_encodeJob, raw);
  if (result == null) {
    throw PictureException(
        "Couldn't read that image. Please choose a JPEG, PNG, GIF or WebP photo.");
  }
  if (result.bytes > PictureLimits.maxBytes) {
    throw PictureException(
        'That photo is too detailed to shrink small enough. Please try a different one.');
  }
  return result;
}

// Each step trades a little sharpness for a smaller file; we stop at the first one that fits.
const List<(int, int)> _ladder = [
  (PictureLimits.maxSide, PictureLimits.quality),
  (640, 65),
  (480, 55),
];

/// Runs in a background isolate. Returns null if the bytes are not a readable image.
EncodedPicture? _encodeJob(Uint8List raw) {
  try {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return null;

    var image = img.bakeOrientation(decoded);
    if (image.hasPalette) {
      image = image.convert(numChannels: 4);
    }
    if (image.numChannels == 4) {
      image = _flattenOnWhite(image);
    }

    EncodedPicture? best;
    for (final (side, quality) in _ladder) {
      final resized = _fit(image, side);
      final jpg = img.encodeJpg(resized, quality: quality);
      best = EncodedPicture(
        base64: base64Encode(jpg),
        bytes: jpg.length,
        width: resized.width,
        height: resized.height,
      );
      if (jpg.length <= PictureLimits.maxBytes) break;
    }
    return best;
  } catch (_) {
    return null;
  }
}

/// Scales down so the longest edge is at most [side]. Never scales up.
img.Image _fit(img.Image image, int side) {
  if (math.max(image.width, image.height) <= side) return image;
  return image.width >= image.height
      ? img.copyResize(image, width: side, interpolation: img.Interpolation.average)
      : img.copyResize(image, height: side, interpolation: img.Interpolation.average);
}

/// JPEG has no transparency, so paint the image onto white (otherwise transparent
/// areas of a PNG turn black).
img.Image _flattenOnWhite(img.Image src) {
  final canvas = img.Image(width: src.width, height: src.height, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, src);
  return canvas;
}
