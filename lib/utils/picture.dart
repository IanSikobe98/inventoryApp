import 'dart:convert';
import 'dart:typed_data';

/// Helpers for the value stored in `pictureUrl`.
///
/// New photos are stored as base64 text (a small JPEG). Older records may still hold an
/// http(s) link, and a `data:image/...;base64,` prefix is tolerated, so every shape
/// that can come back from the API still displays.

String? _clean(String? value) {
  final t = value?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// True when there is any picture value at all.
bool hasPicture(String? value) => _clean(value) != null;

/// True for an http(s) link (an older, pre-base64 record).
bool isRemotePicture(String? value) {
  final t = _clean(value)?.toLowerCase();
  return t != null && (t.startsWith('http://') || t.startsWith('https://'));
}

/// Turns a stored picture into image bytes, or null when there is none, it is a link,
/// or it is not valid base64. Accepts raw base64 or a `data:` URI; ignores whitespace
/// and missing `=` padding.
Uint8List? decodePicture(String? value) {
  final t = _clean(value);
  if (t == null || isRemotePicture(t)) return null;

  var b64 = t;
  if (t.toLowerCase().startsWith('data:')) {
    final comma = t.indexOf(',');
    if (comma < 0) return null;
    b64 = t.substring(comma + 1);
  }
  b64 = b64.replaceAll(RegExp(r'\s'), '');
  if (b64.isEmpty) return null;

  try {
    return base64.decode(base64.normalize(b64));
  } on FormatException {
    return null;
  }
}

/// Approximate size of a stored base64 picture in bytes (no decoding needed).
int pictureSizeBytes(String? value) {
  final t = _clean(value);
  if (t == null || isRemotePicture(t)) return 0;
  var len = t.length;
  if (t.toLowerCase().startsWith('data:')) {
    final comma = t.indexOf(',');
    if (comma >= 0) len = t.length - comma - 1;
  }
  return len * 3 ~/ 4;
}

/// "48 KB" / "1.2 MB"
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
