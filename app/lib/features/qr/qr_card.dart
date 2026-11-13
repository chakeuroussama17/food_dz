import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

/// A restaurant's QR code as printed: the fennec in the middle and the
/// restaurant's name below. Always on white (a QR code needs contrast),
/// also in dark mode.
class RestaurantQrCard extends StatelessWidget {
  const RestaurantQrCard({
    super.key,
    required this.link,
    required this.name,
    required this.caption,
    this.size = 240,
  });

  final String link;
  final String name;

  /// "Scan to order".
  final String caption;

  /// Size of the code itself.
  final double size;

  static const _ink = Color(0xFF121223);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        size * 0.12,
        size * 0.1,
        size * 0.12,
        size * 0.1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14121223),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandLogo(width: size * 0.55, stacked: false),
          SizedBox(height: size * 0.08),
          Semantics(
            label: link,
            image: true,
            child: QrImageView(
              key: const Key('restaurant-qr'),
              data: link,
              size: size,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: _ink,
              ),
              embeddedImage: const AssetImage('assets/brand/mark.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: Size.square(size * 0.22),
              ),
            ),
          ),
          SizedBox(height: size * 0.08),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size * 0.095,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          SizedBox(height: size * 0.025),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size * 0.058,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
