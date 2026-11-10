import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/widgets/auth_fields.dart';
import '../../auth/widgets/auth_scaffold.dart';
import '../data/driver_repository.dart';
import '../widgets/driver_widgets.dart';

/// "Become a driver": account (if signed out) + phone + vehicle. The driver
/// can't go online until the admin approves the account.
class DriverRegisterPage extends ConsumerStatefulWidget {
  const DriverRegisterPage({super.key});

  @override
  ConsumerState<DriverRegisterPage> createState() => _DriverRegisterPageState();
}

class _DriverRegisterPageState extends ConsumerState<DriverRegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  Vehicle _vehicle = Vehicle.moto;
  bool _loading = false;

  late final bool _needsAccount = !ref.read(appSessionProvider).signedIn;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final session = ref.read(appSessionProvider);
    setState(() => _loading = true);
    // Keeps the router from moving us while the account is being set up.
    session.setRegisteringRestaurant(true);
    try {
      if (_needsAccount) {
        final signedIn = await ref
            .read(authRepositoryProvider)
            .signUp(
              name: _name.text,
              email: _email.text,
              password: _password.text,
              phone: normalizeDzPhone(_phone.text),
            );
        if (!signedIn) {
          session.setRegisteringRestaurant(false);
          if (mounted) {
            context.push(
              Uri(
                path: '/verify',
                queryParameters: {
                  'email': _email.text.trim(),
                  'purpose': 'signup',
                },
              ).toString(),
            );
          }
          return;
        }
      }
      await ref
          .read(driverRepositoryProvider)
          .register(phone: normalizeDzPhone(_phone.text)!, vehicle: _vehicle);
      await session.refreshRole();
      ref.invalidate(myDriverProvider);
      if (mounted) showAppSnack(context, l.driverRegistered);
    } on AuthError catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    } on DriverError catch (e) {
      if (mounted) {
        showAppSnack(context, driverErrorText(l, e.failure), error: true);
      }
    } finally {
      // The router now sends the new driver to /driver.
      session.setRegisteringRestaurant(false);
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.registerDriverTitle,
      subtitle: l.registerDriverSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_needsAccount) ...[
                _section(l.yourAccount),
                LabeledField(
                  label: l.name,
                  controller: _name,
                  hint: l.namePlaceholder,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      isValidName(v ?? '') ? null : l.errNameRequired,
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: l.email,
                  controller: _email,
                  hint: l.emailPlaceholder,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) =>
                      isValidEmail(v ?? '') ? null : l.errEmailInvalid,
                ),
                const SizedBox(height: 20),
                PasswordField(
                  label: l.password,
                  controller: _password,
                  newPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      isValidPassword(v ?? '') ? null : l.errPasswordShort,
                ),
                const SizedBox(height: 32),
              ],
              _section(l.driverSection),
              LabeledField(
                label: l.driverPhone,
                controller: _phone,
                hint: '0550 12 34 56',
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                maxLength: 20,
                validator: (v) => normalizeDzPhone(v ?? '') == null
                    ? l.errPhoneInvalid
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                l.vehicle.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              PillChips<Vehicle>(
                items: Vehicle.values,
                selected: _vehicle,
                padding: EdgeInsets.zero,
                filledUnselected: true,
                labelOf: (v) => vehicleLabel(l, v),
                onSelected: (v) => setState(() => _vehicle = v),
              ),
              const SizedBox(height: 36),
              AppButton(label: l.signUp, loading: _loading, onPressed: _submit),
              if (_needsAccount) ...[
                const SizedBox(height: 16),
                AuthLinkRow(
                  text: l.haveAccount,
                  action: l.logIn,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
