import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_image.dart';

/// Row from "Running Orders": square image, orange tag line, bold title,
/// muted id line, price and action buttons. Reused by restaurant, driver
/// and admin lists.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.title,
    this.tag,
    this.subtitle,
    this.amount,
    this.imageUrl,
    this.leading,
    this.actions = const [],
    this.onTap,
    this.extra,
  });

  final String title;

  /// Orange line above the title ("#Breakfast" in the design; we use status
  /// or time).
  final String? tag;

  /// Muted line ("ID: 32053").
  final String? subtitle;

  /// Formatted price.
  final String? amount;
  final String? imageUrl;

  /// Replaces the image (e.g. an icon or distance badge for drivers).
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onTap;

  /// Optional extra content under the subtitle (address, item list…).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                AppImage(url: imageUrl, width: 102, height: 102, radius: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag != null)
                    Text(
                      tag!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (extra != null) ...[const SizedBox(height: 6), extra!],
                  if (amount != null || actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // Price at the start, buttons at the end (as in the
                    // design); buttons wrap under the price when longer
                    // translations don't fit on one line.
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          amount ?? '',
                          style: TextStyle(fontSize: 17, color: AppColors.ink),
                        ),
                        if (actions.isNotEmpty)
                          Wrap(spacing: 12, runSpacing: 8, children: actions),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
