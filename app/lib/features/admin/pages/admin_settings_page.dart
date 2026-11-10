import 'package:flutter/material.dart';

import '../../../core/widgets/theme_switch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/widgets/account_widgets.dart';
import '../../auth/data/auth_providers.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

/// Delivery fee, default commission, business details printed on
/// receipts; customers list; language; log out.
class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cfg = ref.watch(adminConfigProvider);
    return AdminScaffold(
      section: AdminSection.settings,
      title: l.settings,
      body: AsyncBody(
        value: cfg,
        onRetry: () => ref.invalidate(adminConfigProvider),
        builder: (c) => _SettingsForm(config: c),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.config});
  final AdminConfig config;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _form = GlobalKey<FormState>();
  late final c = widget.config;
  late final _fee = TextEditingController(text: '${c.deliveryFee}');
  late final _rate = TextEditingController(
    text: (c.defaultCommissionRate * 100)
        .toStringAsFixed(1)
        .replaceAll('.0', ''),
  );
  late final _name = TextEditingController(text: c.businessName);
  late final _phone = TextEditingController(text: c.businessPhone);
  late final _email = TextEditingController(text: c.businessEmail);
  late final _address = TextEditingController(text: c.businessAddress);
  late final _tax = TextEditingController(text: c.businessTaxId);
  late final _hours = TextEditingController(text: '${c.cashHandoverHours}');
  late final _autoReject = TextEditingController(
    text: '${c.autoRejectMinutes}',
  );
  bool _saving = false;

  @override
  void dispose() {
    for (final x in [
      _fee,
      _rate,
      _name,
      _phone,
      _email,
      _address,
      _tax,
      _hours,
      _autoReject,
    ]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateConfig(
            AdminConfig(
              deliveryFee: int.parse(_fee.text.trim()),
              defaultCommissionRate:
                  double.parse(_rate.text.trim().replaceAll(',', '.')) / 100,
              businessName: _name.text,
              businessPhone: _phone.text,
              businessEmail: _email.text,
              businessAddress: _address.text,
              businessTaxId: _tax.text,
              cashHandoverHours: int.parse(_hours.text.trim()),
              autoRejectMinutes: int.parse(_autoReject.text.trim()),
            ),
          );
      ref.invalidate(adminConfigProvider);
      ref.invalidate(adminRestaurantsProvider);
      if (mounted) showAppSnack(context, l.saved);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: l.deliveryFeeDa,
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  hint: formatDzd(200, lang),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 0 || n > 5000
                        ? l.errDeliveryFee
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.defaultCommission,
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    final n = double.tryParse(
                      (v ?? '').trim().replaceAll(',', '.'),
                    );
                    return n == null || n < 0 || n > 50 ? l.errRate : null;
                  },
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.cashHoursSetting,
                  controller: _hours,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 1 || n > 168
                        ? l.errCashHours
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.autoRejectSetting,
                  controller: _autoReject,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 3 || n > 60
                        ? l.errAutoReject
                        : null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.businessInfo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: l.businessName,
                  controller: _name,
                  maxLength: 80,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.errNameRequired : null,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: l.businessPhone,
                  controller: _phone,
                  maxLength: 30,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: l.businessEmail,
                  controller: _email,
                  maxLength: 254,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: l.businessAddress,
                  controller: _address,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: l.businessTaxId,
                  controller: _tax,
                  maxLength: 40,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(label: l.save, loading: _saving, onPressed: _save),
          const SizedBox(height: 24),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.view_carousel_outlined,
                iconColor: AppColors.primary,
                label: l.homeBanners,
                onTap: () => context.push('/admin/banners'),
              ),
              SettingsTile(
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF413DFB),
                label: l.customers,
                onTap: () => context.push('/admin/customers'),
              ),
              SettingsTile(
                icon: Icons.translate_rounded,
                iconColor: const Color(0xFF2AE1E1),
                label: l.language,
                trailing: const LanguageSwitch(),
              ),
              SettingsTile(
                icon: Icons.dark_mode_outlined,
                iconColor: const Color(0xFF7C6FD6),
                label: l.appearance,
                trailing: const ThemeSwitch(),
              ),
              SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFFB4A59),
                label: l.logOut,
                onTap: () => signOutAndStopPush(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Customers with search.
class AdminCustomersPage extends ConsumerStatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  ConsumerState<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends ConsumerState<AdminCustomersPage> {
  String _search = '';
  late Future<List<AdminCustomer>> _future = _load();

  Future<List<AdminCustomer>> _load() =>
      ref.read(adminRepositoryProvider).customers(search: _search);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                PageHeader(title: l.customers),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l.searchCustomers,
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: AppColors.surface,
                    ),
                    onSubmitted: (v) => setState(() {
                      _search = v;
                      _future = _load();
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<AdminCustomer>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return AsyncBody<void>(
                          value: AsyncError(snap.error!, StackTrace.empty),
                          builder: (_) => const SizedBox.shrink(),
                          onRetry: () => setState(() => _future = _load()),
                        );
                      }
                      final list = snap.data!;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        children: [
                          AdminCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final c in list)
                                  ListTile(
                                    title: Text(
                                      c.fullName.isEmpty ? c.email : c.fullName,
                                    ),
                                    subtitle: Text(
                                      [
                                        c.email,
                                        c.phone ?? '',
                                      ].where((x) => x.isNotEmpty).join(' · '),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(l.ordersCount(c.ordersCount)),
                                        Text(
                                          formatDzd(c.spent, lang),
                                          style: TextStyle(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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
