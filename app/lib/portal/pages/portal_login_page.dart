import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/theme_switch.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../l10n/app_localizations.dart';

/// Split screen: orange brand panel, sign-in form.
class PortalLoginPage extends ConsumerStatefulWidget {
  const PortalLoginPage({super.key});

  @override
  ConsumerState<PortalLoginPage> createState() => _PortalLoginPageState();
}

class _PortalLoginPageState extends ConsumerState<PortalLoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hide = true;

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
    try {
      await ref.read(appSessionProvider).setRememberMe(true);
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
    } on AuthError catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    } catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    LanguageSwitch(),
                    SizedBox(width: 8),
                    ThemeSwitch(),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  l.portalLoginTitle,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 28),
                LabeledField(
                  label: l.email,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: (v) =>
                      isValidEmail(v ?? '') ? null : l.errEmailInvalid,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: l.password,
                  controller: _password,
                  obscureText: _hide,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () => setState(() => _hide = !_hide),
                    icon: Icon(
                      _hide
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').isEmpty ? l.errPasswordShort : null,
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: l.logIn,
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 900
            ? form
            : Row(
                children: [
                  Expanded(child: _BrandPanel(tagline: l.portalTagline)),
                  Expanded(child: form),
                ],
              ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.tagline});
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandLogo(width: 260, stacked: false, inverse: true),
          const SizedBox(height: 36),
          Text(
            l.portalTitle,
            style: const TextStyle(
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tagline,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Color(0xEEFFFFFF),
            ),
          ),
          const SizedBox(height: 36),
          for (final (icon, text) in [
            (Icons.receipt_long_rounded, l.ordersSubtitle),
            (Icons.insights_rounded, l.reportsSubtitle),
            (Icons.group_rounded, l.teamSubtitle),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Signed in with a customer, driver or admin account.
class PortalNotPartnerPage extends ConsumerWidget {
  const PortalNotPartnerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(width: 150),
                const SizedBox(height: 24),
                Text(
                  l.portalNotPartner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.body,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: l.logOut,
                  variant: AppButtonVariant.outline,
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
