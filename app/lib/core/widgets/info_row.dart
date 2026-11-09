import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The "⭐ 4.7   🚚 Free   🕒 20 min" row. Each entry is an orange outline
/// icon followed by a short label.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.items});

  final List<InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 34,
      runSpacing: 8,
      children: [
        for (final it in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(it.icon, color: it.color ?? AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                it.label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: it.bold ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class InfoItem {
  const InfoItem(this.icon, this.label, {this.bold = false, this.color});
  final IconData icon;
  final String label;
  final bool bold;
  final Color? color;
}
