import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "Food" wordmark with the orange cloche (Figma asset, 121×59).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 121.125});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Food',
      image: true,
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        width: width,
        height: width * 58.882 / 121.125,
      ),
    );
  }
}
