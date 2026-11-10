import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_providers.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_scaffold.dart';

enum VerifyPurpose { signup, recovery }

/// Verification: 6-digit code sent by email, with a resend countdown.
class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({super.key, required this.email, required this.purpose});

  final String email;
  final VerifyPurpose purpose;

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  static const _codeLength = 6;
  static const _resendSeconds = 60;

  final _code = TextEditingController();
  bool _loading = false;
  bool _error = false;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _code.addListener(() {
      if (_error) setState(() => _error = false);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    if (_code.text.length != _codeLength) {
      setState(() => _error = true);
      showAppSnack(context, l.errCodeIncomplete, error: true);
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(appSessionProvider);
    try {
      if (widget.purpose == VerifyPurpose.signup) {
        await repo.verifySignupCode(email: widget.email, code: _code.text);
        // Signed in now → router redirect goes to /home.
      } else {
        session.recoveringPassword = true;
        await repo.verifyRecoveryCode(email: widget.email, code: _code.text);
        if (mounted) context.go('/reset-password');
      }
    } catch (e) {
      session.recoveringPassword = false;
      if (!mounted) return;
      setState(() => _error = true);
      showAppSnack(context, authErrorText(l, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(authRepositoryProvider);
    try {
      if (widget.purpose == VerifyPurpose.signup) {
        await repo.resendSignupCode(widget.email);
      } else {
        await repo.sendRecoveryCode(widget.email);
      }
      _code.clear();
      _startTimer();
      if (mounted) showAppSnack(context, l.codeResent);
    } catch (e) {
      if (mounted) showAppSnack(context, authErrorText(l, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canResend = _secondsLeft <= 0;
    return AuthScaffold(
      title: l.verificationTitle,
      subtitle: l.codeSentTo,
      subtitleEmphasis: widget.email,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l.code.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              InkWell(
                onTap: canResend ? _resend : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.resend,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            color: canResend
                                ? AppColors.primary
                                : AppColors.inkSoft,
                          ),
                        ),
                        if (!canResend)
                          TextSpan(text: ' ${l.resendIn(_secondsLeft)}'),
                      ],
                    ),
                    style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CodeInput(
            controller: _code,
            length: _codeLength,
            hasError: _error,
            onCompleted: (_) => _verify(),
          ),
          const SizedBox(height: 30),
          AppButton(label: l.verify, loading: _loading, onPressed: _verify),
        ],
      ),
    );
  }
}
