import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/widgets.dart';
import '../../features/auth/data/auth_providers.dart';
import '../../features/restaurant_owner/data/owner_repository.dart';
import '../../features/restaurant_owner/widgets/owner_widgets.dart'
    show roleLabel;
import '../../l10n/app_localizations.dart';
import '../portal_state.dart';
import '../widgets/portal_widgets.dart';

const _roles = ['owner', 'manager', 'staff'];

String _teamError(AppLocalizations l, TeamFailure f) => switch (f) {
  TeamFailure.userNotFound => l.errUserNotFound,
  TeamFailure.otherRole => l.errOtherRole,
  TeamFailure.alreadyMember => l.errAlreadyMember,
  TeamFailure.lastOwner => l.errLastOwner,
  TeamFailure.notAllowed => l.onlyOwnersTeam,
  TeamFailure.network => l.errNetwork,
};

/// The team of one outlet: who has access and with which role.
class PortalTeamPage extends ConsumerStatefulWidget {
  const PortalTeamPage({super.key});

  @override
  ConsumerState<PortalTeamPage> createState() => _PortalTeamPageState();
}

class _PortalTeamPageState extends ConsumerState<PortalTeamPage> {
  String? get _outlet => ref.read(portalOutletProvider).value?.id;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final l = AppLocalizations.of(context);
    try {
      await action();
      if (done != null && mounted) showAppSnack(context, done);
    } on TeamError catch (e) {
      if (mounted) showAppSnack(context, _teamError(l, e.failure), error: true);
    } finally {
      if (_outlet != null) ref.invalidate(teamProvider(_outlet!));
      ref.invalidate(myRestaurantsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final outlet = ref.watch(portalOutletProvider).value;
    if (outlet == null) return const SizedBox.shrink();
    final team = ref.watch(teamProvider(outlet.id));
    final me = ref.watch(currentUserIdProvider).value;
    final repo = ref.read(ownerRepositoryProvider);

    return PortalPage(
      title: l.navTeam,
      subtitle: l.teamSubtitle,
      actions: [
        const SingleOutletPicker(),
        if (outlet.isOwner)
          FilledButton.icon(
            onPressed: () async {
              final added = await showDialog<(String, String)>(
                context: context,
                builder: (_) => const _AddMemberDialog(),
              );
              if (added == null) return;
              await _run(
                () => repo.addMember(outlet.id, added.$1, added.$2),
                done: l.memberAdded,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l.addMember),
          ),
      ],
      children: [
        ResponsiveRow(
          breakpoint: 900,
          children: [
            for (final (role, desc, icon) in [
              ('owner', l.roleOwnerDesc, Icons.workspace_premium_outlined),
              ('manager', l.roleManagerDesc, Icons.manage_accounts_outlined),
              ('staff', l.roleStaffDesc, Icons.badge_outlined),
            ])
              PCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roleLabel(l, role),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!outlet.isOwner)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.onlyOwnersTeam,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        team.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(teamProvider(outlet.id)),
              child: Text(l.retry),
            ),
          ),
          data: (members) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 60,
                    horizontalMargin: 20,
                    columns: [
                      DataColumn(label: Text(l.colName)),
                      DataColumn(label: Text(l.colEmail)),
                      DataColumn(label: Text(l.colRole)),
                      DataColumn(label: Text(l.colSince)),
                      const DataColumn(label: SizedBox()),
                    ],
                    rows: [
                      for (final m in members)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                m.name.isEmpty ? '—' : m.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            DataCell(Text(m.email)),
                            DataCell(
                              outlet.isOwner
                                  ? DropdownButton<String>(
                                      value: m.role,
                                      underline: const SizedBox(),
                                      items: [
                                        for (final r in _roles)
                                          DropdownMenuItem(
                                            value: r,
                                            child: Text(roleLabel(l, r)),
                                          ),
                                      ],
                                      onChanged: (r) => r == null || r == m.role
                                          ? null
                                          : _run(
                                              () => repo.setMemberRole(
                                                outlet.id,
                                                m.userId,
                                                r,
                                              ),
                                            ),
                                    )
                                  : Text(roleLabel(l, m.role)),
                            ),
                            DataCell(
                              Text(
                                m.since == null
                                    ? '—'
                                    : DateFormat('dd/MM/yyyy').format(m.since!),
                              ),
                            ),
                            DataCell(
                              outlet.isOwner || m.userId == me
                                  ? TextButton(
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            content: Text(
                                              l.removeMemberConfirm(
                                                m.name.isEmpty
                                                    ? m.email
                                                    : m.name,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: Text(l.back),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: Text(
                                                  l.removeMember,
                                                  style: const TextStyle(
                                                    color: AppColors.danger,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await _run(
                                            () => repo.removeMember(
                                              outlet.id,
                                              m.userId,
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        l.removeMember,
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Email + role. Returns (email, role).
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  String _role = 'staff';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.addMember),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: l.memberEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    isValidEmail(v ?? '') ? null : l.errEmailInvalid,
              ),
              const SizedBox(height: 6),
              Text(
                l.memberEmailHint,
                style: TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              RadioGroup<String>(
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v ?? _role),
                child: Column(
                  children: [
                    for (final (r, desc) in [
                      ('staff', l.roleStaffDesc),
                      ('manager', l.roleManagerDesc),
                      ('owner', l.roleOwnerDesc),
                    ])
                      RadioListTile<String>(
                        value: r,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(roleLabel(l, r)),
                        subtitle: Text(desc),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.back, style: TextStyle(color: AppColors.body)),
        ),
        AppButton(
          label: l.addMember,
          variant: AppButtonVariant.small,
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (_email.text.trim(), _role));
            }
          },
        ),
      ],
    );
  }
}
