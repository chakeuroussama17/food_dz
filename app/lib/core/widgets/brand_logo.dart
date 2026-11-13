import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand name, as written in the logo.
const kBrandName = 'foodfennec';

/// The fennec tile: an orange rounded square with the white fox.
/// [inverse] gives a white tile with an orange fox, for orange backgrounds.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.inverse = false});

  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    if (!inverse) {
      return Image.asset(
        'assets/brand/mark.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.13),
      child: Image.asset(
        'assets/brand/fox_white.png',
        color: AppColors.primary,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// The "foodfennec" letters (tinted; orange by default, fine on light and
/// dark backgrounds).
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, required this.width, this.color});

  /// Width ÷ height of the letters.
  static const ratio = 1208 / 183;

  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/wordmark_white.png',
    width: width,
    height: width / ratio,
    color: color ?? AppColors.primary,
    filterQuality: FilterQuality.medium,
  );
}

/// The full logo: the fennec tile and the name. [stacked] puts the tile
/// above the name (splash), otherwise side by side (headers). [width] is
/// the width of the whole logo. [inverse] is for orange backgrounds.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width = 180,
    this.stacked = true,
    this.inverse = false,
  });

  final double width;
  final bool stacked;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final color = inverse ? Colors.white : null;
    final Widget child;
    if (stacked) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: width * 0.42, inverse: inverse),
          SizedBox(height: width * 0.07),
          BrandWordmark(width: width, color: color),
        ],
      );
    } else {
      // Tile height m; letters 0.46·m high, 0.24·m gap.
      final m = width / (1 + 0.24 + 0.46 * BrandWordmark.ratio);
      child = Row(
        // The logo reads the same way in Arabic.
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: m, inverse: inverse),
          SizedBox(width: m * 0.24),
          BrandWordmark(width: 0.46 * m * BrandWordmark.ratio, color: color),
        ],
      );
    }
    return Semantics(
      label: kBrandName,
      image: true,
      child: ExcludeSemantics(child: child),
    );
  }
}
