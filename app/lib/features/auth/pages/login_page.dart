import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  late bool _remember = ref.read(appSessionProvider).rememberMe;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    final session = ref.read(appSessionProvider);
    try {
      await session.setRememberMe(_remember);
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      // Router redirect sends the user home once the session arrives.
    } on AuthError catch (e) {
      if (!mounted) return;
      if (e.failure == AuthFailure.emailNotConfirmed) {
        // Account exists but was never confirmed: send a fresh code.
        await ref
            .read(authRepositoryProvider)
            .resendSignupCode(_email.text)
            .catchError((_) {});
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
      } else {
        showAppSnack(context, authErrorText(l, e), error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.logInTitle,
      subtitle: l.logInSubtitleLong,
      showBack: false,
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 24),
              PasswordField(
                label: l.password,
                controller: _password,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => (v ?? '').isEmpty ? l.errPasswordShort : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: RememberCheckbox(
                      value: _remember,
                      label: l.rememberMe,
                      onChanged: (v) => setState(() => _remember = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      l.forgotPassword,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(label: l.logIn, loading: _loading, onPressed: _submit),
              const SizedBox(height: 26),
              AuthLinkRow(
                text: l.noAccount,
                action: l.signUp,
                onTap: () => context.push('/signup'),
              ),
              AuthLinkRow(
                text: l.ownRestaurant,
                action: l.registerIt,
                onTap: () => context.push('/restaurant/register'),
              ),
              AuthLinkRow(
                text: l.deliverWithUs,
                action: l.joinAsDriver,
                onTap: () => context.push('/driver/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
