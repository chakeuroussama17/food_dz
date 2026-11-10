import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';

/// Round profile photo, or the user's initial on the kit's soft orange.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.name = '', this.size = 100});

  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return AppImage(url: url, width: size, height: size, radius: size / 2);
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFBFA6),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * .4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Light grey rounded group of rows (#F6F8FA, radius 16).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

/// Row with a white round icon, a label and a chevron (or [trailing]).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor = AppColors.primary,
    this.trailing,
    this.value,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Optional second line (Personal info values).
  final String? value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value == null ? label : label.toUpperCase(),
                    style: TextStyle(
                      fontSize: value == null ? 16 : 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      value!,
                      style: TextStyle(fontSize: 14, color: AppColors.body),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    // Mirrors itself in RTL (matchTextDirection).
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      )),
          ],
        ),
      ),
    );
  }
}
