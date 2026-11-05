import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/picture_service.dart';
import '../theme/app_theme.dart';
import '../utils/picture.dart';
import '../utils/picture_encoder.dart';
import 'shoe_photo.dart';

/// The photo box in the add/edit-batch form: the dashed "add a photo" area from the
/// design. Tap it to take a photo or pick one from the gallery. The photo is shrunk and
/// base64-encoded right away, and [onChanged] receives the string to store in
/// `pictureUrl` (or null when the photo is removed).
class PictureField extends StatefulWidget {
  const PictureField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// Current `pictureUrl` value: base64, a link, or null.
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  State<PictureField> createState() => _PictureFieldState();
}

class _PictureFieldState extends State<PictureField> {
  static const double _boxHeight = 176;

  bool _busy = false;
  String? _error;
  EncodedPicture? _last;

  Future<void> _open() async {
    if (_busy || !widget.enabled) return;
    final service = context.read<PictureService>();

    if (!service.cameraAvailable) {
      await _pick(PictureSource.gallery);
      return;
    }

    final choice = await showModalBottomSheet<PictureSource>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, PictureSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, PictureSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice != null && mounted) await _pick(choice);
  }

  Future<void> _pick(PictureSource source) async {
    final service = context.read<PictureService>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final encoded = await service.pickAndEncode(source);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (encoded != null) _last = encoded;
      });
      if (encoded != null) widget.onChanged(encoded.base64);
    } on PictureException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  void _remove() {
    setState(() {
      _last = null;
      _error = null;
    });
    widget.onChanged(null);
  }

  String? _info() {
    final last = _last;
    if (last != null) {
      return '${formatBytes(last.bytes)} · ${last.width}×${last.height}px';
    }
    if (isRemotePicture(widget.value)) return 'Photo from a link';
    if (hasPicture(widget.value)) return 'Photo · ${formatBytes(pictureSizeBytes(widget.value))}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final has = hasPicture(widget.value);
    final info = _info();

    final Widget box;
    if (_busy) {
      box = _DashedBox(
        height: _boxHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.rust)),
            const SizedBox(height: 12),
            Text('Preparing photo…',
                style: AppText.body(size: 13, color: AppColors.inkSoft)),
          ],
        ),
      );
    } else if (has) {
      box = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            ShoePhoto(
              url: widget.value,
              width: double.infinity,
              height: _boxHeight,
              iconSize: 52,
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xCC201811),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Change photo',
                        style: AppText.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      box = _DashedBox(
        height: _boxHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                size: 34, color: AppColors.placeholder),
            const SizedBox(height: 10),
            Text('Add a photo of the box',
                style: AppText.body(weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Tap to choose a picture. It is shrunk automatically.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 12, color: AppColors.inkSoft)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photo of the shoes in this box',
            style: AppText.body(
                size: 12, weight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('pictureBox'),
            borderRadius: BorderRadius.circular(12),
            onTap: widget.enabled && !_busy ? _open : null,
            child: box,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!,
                style: AppText.body(size: 12.5, color: AppColors.alert)),
          ),
        if (info != null || has)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (info != null)
                  Expanded(
                    child: Text(info,
                        style: AppText.body(size: 12, color: AppColors.inkSoft)),
                  )
                else
                  const Spacer(),
                if (has)
                  TextButton.icon(
                    key: const Key('removePicture'),
                    onPressed: widget.enabled && !_busy ? _remove : null,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.alert,
                        visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove photo'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A rounded box with a dashed outline, like the upload area in the design.
class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // foreground, so the dashes are drawn on top of the box's fill
      foregroundPainter: _DashedRRectPainter(color: AppColors.placeholder),
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    this.radius = 12,
    this.dash = 7,
    this.gap = 5,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
            Offset.zero & size, Radius.circular(radius))
        .deflate(strokeWidth / 2);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap ||
      old.strokeWidth != strokeWidth;
}
