import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_image.dart';

/// Menu item card from "Restaurant View": image overhanging a white card
/// with soft shadow, name, subtitle, price and an orange "+" button.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.onAdd,
    this.unavailableLabel,
  });

  final String name;
  final String? subtitle;

  /// Already formatted price, e.g. "1 250 DA".
  final String price;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  /// When non-null the item is shown greyed out with this label.
  final String? unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final disabled = unavailableLabel != null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Stack(
          clipBehavior: Clip.none,
          // Lets the card body stretch to the row height in ProductGrid.
          fit: StackFit.passthrough,
          children: [
            // Card body, starting 40px below the image top.
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsetsDirectional.fromSTEB(12, 72, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F96969A),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: text.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unavailableLabel ?? price,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (!disabled) _AddButton(onPressed: onAdd),
                    ],
                  ),
                ],
              ),
            ),
            // Image overhanging the card.
            PositionedDirectional(
              start: 20,
              end: 20,
              top: 0,
              child: AppImage(url: imageUrl, height: 100, radius: AppRadius.lg),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const SizedBox.square(
          dimension: 30,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

/// Two-column grid of [ProductCard]s where both cards in a row share the
/// height of the taller one (names can wrap to two lines).
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.children, this.spacing = 21});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
