import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

/// Not in the Figma file; built from the same auth components.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _retype = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _retype.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      ref.read(appSessionProvider).recoveringPassword = false;
      if (!mounted) return;
      showAppSnack(context, l.passwordUpdated);
      context.go('/home');
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
      title: l.newPasswordTitle,
      subtitle: l.newPasswordSubtitle,
      showBack: false,
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                label: l.newPassword,
                controller: _password,
                newPassword: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    isValidPassword(v ?? '') ? null : l.errPasswordShort,
              ),
              const SizedBox(height: 24),
              PasswordField(
                label: l.retypePassword,
                controller: _retype,
                newPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) =>
                    v == _password.text ? null : l.errPasswordMismatch,
              ),
              const SizedBox(height: 30),
              AppButton(label: l.save, loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
