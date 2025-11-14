import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AddClientSheet extends StatefulWidget {
  final String groupId; // used on create
  final ClientsApi api;
  final GroupClient? client; // null = create, non-null = edit

  const AddClientSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.client,
  });

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _active = true;
  bool _saving = false;

  bool get _isEdit => widget.client != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final c = widget.client!;
      _name.text = c.name;
      _phone.text = c.phone ?? '';
      _email.text = c.email ?? '';
      _active = c.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        // ---- EDIT (PATCH) ----
        final patch = <String, dynamic>{
          'name': _name.text.trim(),
          'isActive': _active,
          'contact': {
            'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
          },
        };
        final updated = await widget.api.updateFields(widget.client!.id, patch);
        if (!mounted) return;
        Navigator.of(context).pop<GroupClient>(updated);
      } else {
        // ---- CREATE ----
        final created = await widget.api.create(
          GroupClient(
            id: '',
            name: _name.text.trim(),
            groupId: widget.groupId,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            isActive: _active,
            createdAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop<GroupClient>(created);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l.failedWithReason(e.toString()), style: typo.bodySmall)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, pad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isEdit
                        ? Icons.edit_note_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? l.editClient : l.createClient,
                    style: typo.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
            const SizedBox(height: 14),

            // Name
            TextFormField(
              controller: _name,
              style: typo.bodyMedium,
              decoration: InputDecoration(
                labelText: '${l.nameLabel} *',
                labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                hintText: l.e_gJohnDoe,
                hintStyle: typo.bodySmall
                    .copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.person_outline),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                errorBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.error),
                ),
                focusedErrorBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.error, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.nameIsRequired : null,
            ),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: _phone,
              style: typo.bodyMedium,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.phoneLabel,
                labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                hintText: l.e_gPhone,
                hintStyle: typo.bodySmall
                    .copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.phone_outlined),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              controller: _email,
              style: typo.bodyMedium,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l.emailLabel,
                labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                hintText: l.e_gEmail,
                hintStyle: typo.bodySmall
                    .copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.alternate_email),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                return ok ? null : l.invalidEmail;
              },
            ),

            const SizedBox(height: 6),

            // Active switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text(l.active,
                  style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _active ? l.clientWillBeActive : l.clientWillBeInactive,
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 12),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? l.saving : (_isEdit ? l.saveChanges : l.saveClient),
                  style: typo.bodySmall.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
