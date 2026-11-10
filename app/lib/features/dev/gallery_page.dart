import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Dev-only page showing every shared component, to compare against Figma
/// and check RTL. Route: /dev/gallery
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String _chip = 'Burger';
  String _label = 'Home';
  int _qty = 2;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final text = Theme.of(context).textTheme;
    String dzd(int v) => formatDzd(v, lang);

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Text(title, style: text.titleLarge),
          ),
          const SizedBox(height: AppSpace.lg),
          child,
        ],
      ),
    );

    Widget pad(Widget c) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      child: c,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                PageHeader(
                  title: l.componentGallery,
                  trailing: const LanguageSwitch(),
                ),
                // Restaurant View header block
                pad(const AppImage(url: null, height: 150, radius: 30)),
                const SizedBox(height: AppSpace.xl),
                pad(Text('Pizzeria El Bahdja', style: text.headlineSmall)),
                const SizedBox(height: AppSpace.sm),
                pad(
                  Text(
                    'Pizzas au feu de bois, sandwichs et plats traditionnels.',
                    style: text.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                pad(
                  InfoRow(
                    items: [
                      InfoItem(Icons.delivery_dining_outlined, dzd(200)),
                      InfoItem(Icons.schedule_rounded, l.minutes(20)),
                      InfoItem(
                        Icons.circle,
                        l.open,
                        color: AppColors.success,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                PillChips<String>(
                  items: const ['Burger', 'Sandwich', 'Pizza', 'Tacos'],
                  selected: _chip,
                  labelOf: (s) => s,
                  onSelected: (s) => setState(() => _chip = s),
                ),
                section(
                  '$_chip (4)',
                  pad(
                    ProductGrid(
                      children: [
                        ProductCard(
                          name: 'Burger Ferguson',
                          subtitle: 'El Bahdja',
                          price: dzd(650),
                          onAdd: () {},
                        ),
                        ProductCard(
                          name: "Rockin' Burgers",
                          subtitle: 'El Bahdja',
                          price: dzd(1250),
                          onAdd: () {},
                        ),
                        ProductCard(
                          name: 'Pizza Margherita',
                          subtitle: 'El Bahdja',
                          price: dzd(900),
                          onAdd: () {},
                        ),
                        ProductCard(
                          name: 'Tacos XL',
                          subtitle: 'El Bahdja',
                          price: dzd(700),
                          unavailableLabel: l.closed,
                        ),
                      ],
                    ),
                  ),
                ),
                section(
                  l.addToCart,
                  SheetPanel(
                    tinted: true,
                    showHandle: false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dzd(650 * _qty),
                                style: TextStyle(
                                  fontSize: 28,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            QuantityStepper(
                              value: _qty,
                              onChanged: (v) => setState(() => _qty = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xl),
                        AppButton(label: l.addToCart, onPressed: () {}),
                      ],
                    ),
                  ),
                ),
                section(
                  l.checkout,
                  pad(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledField(label: l.fullName, hint: 'Karim B.'),
                        const SizedBox(height: AppSpace.xl),
                        LabeledField(
                          label: l.phone,
                          hint: '0550 12 34 56',
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                        ),
                        const SizedBox(height: AppSpace.xl),
                        LabeledField(
                          label: l.address,
                          hint: 'Cité 200 logements, bât. 4',
                          prefixIcon: Icons.location_on_rounded,
                        ),
                        const SizedBox(height: AppSpace.xl),
                        LabeledField(
                          label: l.notes,
                          optionalLabel: l.optional,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpace.xl),
                      ],
                    ),
                  ),
                ),
                PillChips<String>(
                  items: const ['Home', 'Work', 'Other'],
                  selected: _label,
                  labelOf: (s) => s,
                  filledUnselected: true,
                  onSelected: (s) => setState(() => _label = s),
                ),
                const SizedBox(height: AppSpace.xl),
                pad(AppButton(label: l.placeOrder, onPressed: () {})),
                const SizedBox(height: AppSpace.md),
                pad(
                  AppButton(
                    label: l.placeOrder,
                    onPressed: () {},
                    loading: true,
                  ),
                ),
                section(
                  l.runningOrders,
                  Container(
                    color: AppColors.canvas,
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                value: '03',
                                label: l.runningOrders,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: StatCard(
                                value: '01',
                                label: l.orderRequests,
                                highlight: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.lg),
                        SheetPanel(
                          child: Column(
                            children: [
                              OrderCard(
                                tag: l.statusPlaced,
                                title: '2× Pizza Margherita',
                                subtitle: '#K7Q2M · 12:40',
                                amount: dzd(1800),
                                actions: [
                                  AppButton(
                                    label: l.accept,
                                    variant: AppButtonVariant.small,
                                    onPressed: () {},
                                  ),
                                  AppButton(
                                    label: l.reject,
                                    variant: AppButtonVariant.dangerOutline,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              OrderCard(
                                tag: l.statusAccepted,
                                title: '1× Tacos XL',
                                subtitle: '#B4X9P · 12:31',
                                amount: dzd(700),
                                actions: [
                                  AppButton(
                                    label: l.ready,
                                    variant: AppButtonVariant.small,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                section(
                  l.statusPickedUp,
                  pad(
                    StatusSteps(
                      currentIndex: 2,
                      steps: [
                        StatusStep(l.statusPlaced, time: '12:40'),
                        StatusStep(l.statusAccepted, time: '12:42'),
                        StatusStep(l.statusReady),
                        StatusStep(l.statusPickedUp),
                        StatusStep(l.statusDelivered),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                pad(
                  StatusSteps(
                    currentIndex: 1,
                    failedLabel: l.statusRejected,
                    steps: [StatusStep(l.statusPlaced, time: '12:40')],
                  ),
                ),
                section(
                  l.itemCount(3),
                  pad(
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        CircleIconButton.back(context, onPressed: () {}),
                        CircleIconButton.back(
                          context,
                          onPressed: () {},
                          dark: true,
                        ),
                        CircleIconButton(
                          icon: Icons.more_horiz_rounded,
                          onPressed: () {},
                        ),
                        AppButton(
                          label: l.cancel,
                          variant: AppButtonVariant.outline,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
