import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/picture.dart';

/// Shows a shoe photo, or a tidy box icon when there isn't one.
///
/// [url] is whatever the API stored in `pictureUrl`: base64 text (the normal case now),
/// a `data:` URI, or an http(s) link from an older record.
///
/// Base64 is decoded once and kept, not on every rebuild, so lists stay smooth and
/// images don't flicker when the screen refreshes.
class ShoePhoto extends StatefulWidget {
  const ShoePhoto({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.iconSize = 36,
    this.cacheWidth = 800,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;

  /// Decode the bitmap no wider than this (pixels) when [width] isn't a fixed size.
  /// Keeps memory down on long lists.
  final int cacheWidth;

  @override
  State<ShoePhoto> createState() => _ShoePhotoState();
}

class _ShoePhotoState extends State<ShoePhoto> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = decodePicture(widget.url);
  }

  @override
  void didUpdateWidget(ShoePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = decodePicture(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.paper2,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined,
          size: widget.iconSize, color: AppColors.placeholder),
    );

    final width = widget.width;
    final fixedWidth = width != null && width.isFinite;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final cacheWidth = fixedWidth ? (width * dpr).ceil() : widget.cacheWidth;

    final Widget content;
    if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: width ?? double.infinity,
        height: widget.height,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => placeholder,
      );
    } else if (isRemotePicture(widget.url)) {
      content = Image.network(
        widget.url!.trim(),
        fit: BoxFit.cover,
        width: width ?? double.infinity,
        height: widget.height,
        errorBuilder: (context, error, stack) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    } else {
      content = placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(width: width, height: widget.height, child: content),
    );
  }
}
