import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../cart/cart_controller.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/account_repository.dart';
import '../widgets/account_widgets.dart';

/// Profile menu: photo, name, email, then grouped rows.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                PageHeader(title: l.profile),
                AsyncBody(
                  value: profile,
                  onRetry: () => ref.invalidate(profileProvider),
                  builder: (p) => Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: Row(
                      children: [
                        Avatar(url: p.avatarUrl, name: p.fullName),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.email,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFA0A5BA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFFFB6F3D),
                      label: l.personalInfo,
                      onTap: () => context.push('/account/personal'),
                    ),
                    SettingsTile(
                      icon: Icons.map_outlined,
                      iconColor: const Color(0xFF413DFB),
                      label: l.addresses,
                      onTap: () => context.push('/account/addresses'),
                    ),
                  ],
                ),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFFFF7622),
                      label: l.myOrders,
                      onTap: () => context.push('/orders'),
                    ),
                    SettingsTile(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: const Color(0xFF369BFF),
                      label: l.cart,
                      onTap: () => context.push('/cart'),
                    ),
                    SettingsTile(
                      icon: Icons.translate_rounded,
                      iconColor: const Color(0xFF2AE1E1),
                      label: l.language,
                      trailing: const LanguageSwitch(),
                    ),
                  ],
                ),
                SettingsGroup(
                  children: [
                    SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xFFFB4A59),
                      label: l.logOut,
                      onTap: () async {
                        ref.read(cartProvider.notifier).clear();
                        await signOutAndStopPush(ref);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
