import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/account_repository.dart';
import '../widgets/account_widgets.dart';

/// Personal Info: photo + name, then name / email / phone rows. EDIT opens
/// the edit form.
class PersonalInfoPage extends ConsumerWidget {
  const PersonalInfoPage({super.key});

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
                PageHeader(
                  title: l.personalInfo,
                  trailing: TextButton(
                    onPressed: () => context.push('/account/edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      l.edit.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                AsyncBody(
                  value: profile,
                  onRetry: () => ref.invalidate(profileProvider),
                  builder: (p) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: Row(
                          children: [
                            Avatar(url: p.avatarUrl, name: p.fullName),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SettingsGroup(
                        children: [
                          SettingsTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFFFB6F3D),
                            label: l.fullName,
                            value: p.fullName.isEmpty ? '—' : p.fullName,
                          ),
                          SettingsTile(
                            icon: Icons.mail_outline_rounded,
                            iconColor: const Color(0xFF413DFB),
                            label: l.email,
                            value: p.email,
                          ),
                          SettingsTile(
                            icon: Icons.phone_outlined,
                            iconColor: const Color(0xFF369BFF),
                            label: l.phone,
                            value: p.phone ?? '—',
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
      ),
    );
  }
}
