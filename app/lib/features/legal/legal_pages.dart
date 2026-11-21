import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/data/auth_providers.dart';
import 'consent_repository.dart';
import 'legal_texts.dart';

IconData legalIcon(String id) => switch (id) {
  'privacy' => Icons.privacy_tip_outlined,
  'partner' => Icons.storefront_outlined,
  'rider' => Icons.delivery_dining_outlined,
  _ => Icons.gavel_rounded,
};

/// /terms: the list of documents (public, no account needed).
class LegalHubPage extends StatelessWidget {
  const LegalHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                PageHeader(title: l.termsTitle),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    children: [
                      for (final id in legalDocIds)
                        Card(
                          color: AppColors.surface,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            key: Key('legal:$id'),
                            leading: Icon(
                              legalIcon(id),
                              color: AppColors.primary,
                            ),
                            title: Text(
                              legalDoc(id, lang).title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push('/legal/$id'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        l.legalVersion(kLegalVersion),
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
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

/// /legal/:id: one document (public). Also the privacy policy address
/// asked by Google, Facebook, Apple and the stores.
class LegalDocPage extends StatelessWidget {
  const LegalDocPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final doc = legalDoc(id, lang);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                PageHeader(title: doc.title),
                Expanded(child: LegalDocBody(doc: doc)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LegalDocBody extends StatelessWidget {
  const LegalDocBody({super.key, required this.doc});
  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text(
          l.legalVersion(kLegalVersion),
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Text(
          doc.intro,
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 20),
        for (final (title, body) in doc.sections) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(fontSize: 15, height: 1.55, color: AppColors.body),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// Wraps the app: a signed-in person who hasn't accepted the current
/// documents for their role (customer: terms + privacy; restaurant: +
/// partner terms; rider: + rider terms) must accept before going on.
/// Covers social logins (no sign-up form) and new versions of the texts.
class ConsentGate extends ConsumerWidget {
  const ConsentGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appSessionProvider.select((s) => s.role));
    final accepted = ref.watch(myConsentsProvider).value;
    if (role == null || accepted == null) return child;
    final missing = requiredDocs(
      role,
    ).where((d) => !accepted.contains(d)).toList();
    if (missing.isEmpty) return child;
    return Stack(
      children: [
        Offstage(child: child),
        AcceptTermsScreen(documents: missing),
      ],
    );
  }
}

class AcceptTermsScreen extends ConsumerStatefulWidget {
  const AcceptTermsScreen({super.key, required this.documents});
  final List<String> documents;

  @override
  ConsumerState<AcceptTermsScreen> createState() => _AcceptTermsScreenState();
}

class _AcceptTermsScreenState extends ConsumerState<AcceptTermsScreen> {
  final _ticked = <String>{};
  String? _reading;
  bool _saving = false;

  Future<void> _accept() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(consentRepositoryProvider)
          .accept(widget.documents, kLegalVersion);
      ref.invalidate(myConsentsProvider);
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
    if (_reading != null) {
      final doc = legalDoc(_reading!, lang);
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const BackButtonIcon(),
            onPressed: () => setState(() => _reading = null),
          ),
          title: Text(doc.title),
        ),
        body: LegalDocBody(doc: doc),
      );
    }
    final all = _ticked.length == widget.documents.length;
    return Scaffold(
      key: const Key('accept-terms'),
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 16),
                const Center(child: BrandLogo(width: 170, stacked: false)),
                const SizedBox(height: 28),
                Text(
                  l.acceptTermsTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.acceptTermsBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: AppColors.body),
                ),
                const SizedBox(height: 22),
                for (final id in widget.documents)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          key: Key('accept:$id'),
                          value: _ticked.contains(id),
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(
                            () => v == true
                                ? _ticked.add(id)
                                : _ticked.remove(id),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l.iAcceptDoc(legalDoc(id, lang).title),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _reading = id),
                          child: Text(l.readDoc),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                AppButton(
                  label: l.acceptAndContinue,
                  loading: _saving,
                  onPressed: all ? _accept : null,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => signOutAndStopPush(ref),
                  child: Text(
                    l.logOut,
                    style: TextStyle(color: AppColors.muted),
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
