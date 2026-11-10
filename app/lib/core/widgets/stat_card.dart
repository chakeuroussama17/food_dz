import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "20 RUNNING ORDERS" tile from Seller Dashboard Home.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
    this.highlight = false,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  /// Orange value text, e.g. new requests waiting.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 52,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.primary : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
