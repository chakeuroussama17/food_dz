import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Horizontally scrolling category chips ("Burger", "Sandwich", "Pizza").
/// Selected: filled accent orange, white text. Others: white with grey border.
class PillChips<T> extends StatelessWidget {
  const PillChips({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.xl),
    this.filledUnselected = false,
  });

  final List<T> items;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  /// "Home / Work / Other" style on Add New Address: grey fill, no border.
  final bool filledUnselected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSel = item == selected;
          return Material(
            color: isSel
                ? AppColors.accent
                : filledUnselected
                ? AppColors.field
                : Colors.white,
            shape: StadiumBorder(
              side: isSel || filledUnselected
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.border, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    labelOf(item),
                    style: TextStyle(
                      fontSize: 16,
                      color: isSel ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
