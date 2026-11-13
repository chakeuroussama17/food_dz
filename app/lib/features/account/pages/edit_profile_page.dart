import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/snack.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/widgets/browse_widgets.dart';
import '../widgets/details_fields.dart';
import '../data/account_repository.dart';
import '../widgets/account_widgets.dart';

/// Edit Profile: photo with an edit badge, full name, email (read-only),
/// phone, SAVE.
class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                PageHeader(title: l.editProfile),
                Expanded(
                  child: AsyncBody(
                    value: profile,
                    onRetry: () => ref.invalidate(profileProvider),
                    builder: (p) => _Form(profile: p),
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

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _email = TextEditingController(text: widget.profile.email);
  late String? _avatarUrl = widget.profile.avatarUrl;
  late final _commune = TextEditingController(
    text: widget.profile.commune ?? '',
  );
  late int? _wilaya = widget.profile.wilaya;
  late DateTime? _birth = widget.profile.birthDate;
  late String? _gender = widget.profile.gender;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _commune.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        throw StateError('too large');
      }
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final url = await ref
          .read(accountRepositoryProvider)
          .uploadAvatar(bytes, ext);
      setState(() => _avatarUrl = url);
      ref.invalidate(profileProvider);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final phone = _phone.text.trim().isEmpty
          ? null
          : normalizeDzPhone(_phone.text);
      await ref
          .read(accountRepositoryProvider)
          .updateProfile(fullName: _name.text, phone: phone);
      final commune = _commune.text.trim();
      await ref
          .read(accountRepositoryProvider)
          .updateDetails(
            ProfileDetails(
              birthDate: _birth,
              gender: _gender,
              wilaya: _wilaya,
              commune: commune.isEmpty ? null : commune,
            ),
          );
      ref.invalidate(profileProvider);
      if (!mounted) return;
      showAppSnack(context, l.saved);
      if (context.canPop()) context.pop();
    } catch (_) {
      if (mounted) showAppSnack(context, l.errGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(
            child: Stack(
              children: [
                Avatar(url: _avatarUrl, name: _name.text, size: 130),
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Tooltip(
                    message: l.changePhoto,
                    child: Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : _pickPhoto,
                        child: SizedBox.square(
                          dimension: 41,
                          child: _uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          LabeledField(
            label: l.fullName,
            controller: _name,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => isValidName(v ?? '') ? null : l.errNameRequired,
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: l.email,
            controller: _email,
            enabled: false,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: l.phone,
            controller: _phone,
            hint: l.phoneOptionalHint,
            optionalLabel: l.optional,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              return normalizeDzPhone(t) == null ? l.errPhoneInvalid : null;
            },
          ),
          const SizedBox(height: 24),
          WilayaField(
            value: _wilaya,
            required: false,
            onChanged: (v) => setState(() => _wilaya = v),
          ),
          const SizedBox(height: 24),
          LabeledField(
            label: l.commune,
            controller: _commune,
            hint: l.communeHint,
            maxLength: 80,
          ),
          const SizedBox(height: 24),
          BirthDateField(
            value: _birth,
            onChanged: (d) => setState(() => _birth = d),
          ),
          const SizedBox(height: 24),
          FieldLabel(l.gender),
          ChoiceChips(
            options: genderOptions(l),
            value: _gender,
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
          const SizedBox(height: 40),
          AppButton(label: l.save, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
