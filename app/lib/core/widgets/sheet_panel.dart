import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// White panel with large top radius and a small grey handle, as on
/// "Track Order" and "Running Orders". Also the light-grey footer on Food
/// Details when [tinted] is true.
class SheetPanel extends StatelessWidget {
  const SheetPanel({
    super.key,
    required this.child,
    this.showHandle = true,
    this.tinted = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.xl,
      AppSpace.md,
      AppSpace.xl,
      AppSpace.xl,
    ),
  });

  final Widget child;
  final bool showHandle;
  final bool tinted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tinted ? AppColors.field : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: padding,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle)
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpace.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC1C7D0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
