import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded network image with the kit's grey placeholder (#98A8B8) while
/// loading, on error, or when there is no URL.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppRadius.lg,
    this.borderRadius,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: AppColors.placeholder,
    );
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? placeholder
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              // Decode at display size to save memory on low-end phones.
              cacheWidth: width == null || !width!.isFinite
                  ? null
                  : (width! * MediaQuery.devicePixelRatioOf(context)).round(),
              frameBuilder: (context, child, frame, sync) =>
                  sync || frame != null ? child : placeholder,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
