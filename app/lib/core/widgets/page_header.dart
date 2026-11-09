import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circle_icon_button.dart';

/// Header row from "Restaurant View", "Details", "Add New Items":
/// round back button, title, optional trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.darkBack = false,
    this.trailing,
  });

  final String title;
  final bool showBack;
  final bool darkBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.lg,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            CircleIconButton.back(context, dark: darkBack),
            const SizedBox(width: 17),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
