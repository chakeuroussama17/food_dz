import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 45px round button: grey back / "…" on Restaurant View, dark on Track Order,
/// white when placed over a photo.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.background,
    this.foreground,
    this.size = 45,
    this.tooltip,
  });

  /// Back chevron; points left in LTR and right in RTL.
  factory CircleIconButton.back(
    BuildContext context, {
    VoidCallback? onPressed,
    bool dark = false,
    bool onImage = false,
  }) {
    return CircleIconButton(
      // chevron_left is flagged matchTextDirection, so Flutter mirrors it
      // automatically in RTL.
      icon: Icons.chevron_left_rounded,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      background: dark
          ? AppColors.pill
          : onImage
          ? AppColors.surface
          : AppColors.field,
      foreground: dark ? Colors.white : AppColors.ink,
    );
  }

  final IconData icon;
  final VoidCallback? onPressed;

  /// Default: the input fill colour.
  final Color? background;

  /// Default: the main text colour.
  final Color? foreground;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background ?? AppColors.field,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            icon,
            color: foreground ?? AppColors.ink,
            size: size * 0.6,
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
