import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dark pill "(−) 2 (+)" from Food Details.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, int next, String label) =>
        Semantics(
          button: true,
          label: label,
          child: InkResponse(
            onTap: enabled ? () => onChanged(next) : null,
            radius: 20,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: enabled ? 0.2 : 0.08),
              ),
              child: Icon(
                icon,
                size: 16,
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ),
          ),
        );

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.pill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, value > min, value - 1, '-'),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          btn(Icons.add_rounded, value < max, value + 1, '+'),
        ],
      ),
    );
  }
}
