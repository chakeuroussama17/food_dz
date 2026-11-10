import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/widgets/auth_fields.dart';
import '../../auth/widgets/auth_scaffold.dart';
import '../data/owner_repository.dart';

/// "Register your restaurant": owner account (if signed out) + restaurant
/// details. The restaurant starts inactive until the admin approves it.
class RestaurantRegisterPage extends ConsumerStatefulWidget {
  const RestaurantRegisterPage({super.key});

  @override
  ConsumerState<RestaurantRegisterPage> createState() =>
      _RestaurantRegisterPageState();
}

class _RestaurantRegisterPageState
    extends ConsumerState<RestaurantRegisterPage> {
  final _form = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  final _prep = TextEditingController(text: '20');
  bool _loading = false;

  // Decided once: a customer who is already signed in only fills the
  // restaurant part.
  late final bool _needsAccount = !ref.read(appSessionProvider).signedIn;

  @override
  void dispose() {
    for (final c in [
      _ownerName,
      _email,
      _password,
      _name,
      _phone,
      _address,
      _area,
      _prep,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final session = ref.read(appSessionProvider);
    final auth = ref.read(authRepositoryProvider);
    final owner = ref.read(ownerRepositoryProvider);
    setState(() => _loading = true);
    session.setRegisteringRestaurant(true);
    try {
      if (_needsAccount) {
        final signedIn = await auth.signUp(
          name: _ownerName.text,
          email: _email.text,
          password: _password.text,
        );
        if (!signedIn) {
          // Email confirmation is on: confirm first, then come back here.
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
      await owner.register(
        RestaurantRegistration(
          name: _name.text,
          phone: normalizeRestaurantPhone(_phone.text)!,
          address: _address.text,
          area: _area.text,
          prepMinutes: int.parse(_prep.text.trim()),
        ),
      );
      await session.refreshRole();
      ref.invalidate(myRestaurantProvider);
      if (mounted) showAppSnack(context, l.registrationDone);
    } on AuthError catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      showAppSnack(
        context,
        msg.contains('invalid phone')
            ? l.errRestaurantPhone
            : msg.contains('Failed') || msg.contains('Socket')
            ? l.errNetwork
            : l.errGeneric,
        error: true,
      );
    } finally {
      // The router now sends the new owner to /restaurant.
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
      title: l.registerRestaurantTitle,
      subtitle: l.registerRestaurantSubtitle,
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
                  controller: _ownerName,
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
              _section(l.restaurantSection),
              LabeledField(
                label: l.restaurantName,
                controller: _name,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    isValidName(v ?? '') ? null : l.errNameRequired,
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: l.restaurantPhone,
                controller: _phone,
                hint: l.phoneOptionalHint,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                validator: (v) => normalizeRestaurantPhone(v ?? '') == null
                    ? l.errRestaurantPhone
                    : null,
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: l.address,
                controller: _address,
                hint: l.addressHint,
                prefixIcon: Icons.location_on_rounded,
                maxLength: 200,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? l.errAddressRequired : null,
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: l.area,
                controller: _area,
                hint: l.areaHint,
                maxLength: 80,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: l.prepTime,
                controller: _prep,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n == null || n < 5 || n > 120 ? l.errPrepTime : null;
                },
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
