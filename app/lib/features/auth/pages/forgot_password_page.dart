import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      // Supabase answers the same whether or not the email exists, so this
      // page never reveals which emails have accounts.
      await ref.read(authRepositoryProvider).sendRecoveryCode(_email.text);
      if (!mounted) return;
      context.push(
        Uri(
          path: '/verify',
          queryParameters: {'email': _email.text.trim(), 'purpose': 'recovery'},
        ).toString(),
      );
    } catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.forgotPasswordTitle,
      subtitle: l.forgotPasswordSubtitle,
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
              textInputAction: TextInputAction.done,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submit(),
              validator: (v) =>
                  isValidEmail(v ?? '') ? null : l.errEmailInvalid,
            ),
            const SizedBox(height: 30),
            AppButton(label: l.sendCode, loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
