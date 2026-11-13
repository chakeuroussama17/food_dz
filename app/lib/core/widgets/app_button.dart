import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppButtonVariant {
  /// Full-width orange, uppercase, 62px tall ("ADD TO CART", "LOG IN").
  primary,

  /// Small filled orange ("Done" on Running Orders).
  small,

  /// Small red outline ("Cancel" on Running Orders).
  dangerOutline,

  /// Small neutral outline.
  outline,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final enabled = onPressed != null && !loading;

    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.small => (
        AppColors.primary,
        Colors.white,
        BorderSide.none,
      ),
      AppButtonVariant.dangerOutline => (
        AppColors.surface,
        AppColors.danger,
        const BorderSide(color: AppColors.danger),
      ),
      AppButtonVariant.outline => (
        AppColors.surface,
        AppColors.ink,
        BorderSide(color: AppColors.border),
      ),
    };

    final text = Text(
      isPrimary ? label.toUpperCase() : label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: isPrimary ? 0.6 : 0,
        color: fg,
      ),
    );

    final Widget child;
    if (loading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
      );
    } else if (icon == null) {
      child = text;
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(child: text),
        ],
      );
    }

    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: SizedBox(
        width: isPrimary ? double.infinity : null,
        height: isPrimary ? 62 : 36,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isPrimary ? AppRadius.md : 8),
            side: side,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isPrimary ? 24 : 16),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
