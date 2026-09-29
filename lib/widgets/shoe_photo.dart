import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows a shoe photo from a URL, or a tidy box icon when there isn't one
/// (or it fails to load).
class ShoePhoto extends StatelessWidget {
  const ShoePhoto({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.iconSize = 36,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.paper2,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined,
          size: iconSize, color: AppColors.placeholder),
    );

    final hasUrl = url != null && url!.trim().isNotEmpty;
    final Widget content = hasUrl
        ? Image.network(
            url!.trim(),
            fit: BoxFit.cover,
            width: width ?? double.infinity,
            height: height,
            errorBuilder: (context, error, stack) => placeholder,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
          )
        : placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: content),
    );
  }
}
