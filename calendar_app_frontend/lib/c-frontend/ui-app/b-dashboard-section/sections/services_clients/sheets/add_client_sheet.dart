import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
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
  final _billingLegalName = TextEditingController();
  final _billingTaxId = TextEditingController();
  final _billingStreet = TextEditingController();
  final _billingExtra = TextEditingController();
  final _billingCity = TextEditingController();
  final _billingProvince = TextEditingController();
  final _billingPostal = TextEditingController();
  final _billingCountry = TextEditingController();
  final _billingEmail = TextEditingController();
  final _billingPhone = TextEditingController();
  bool _active = true;
  bool _billingExpanded = false;
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
      final b = c.billing;
      if (b != null) {
        _billingLegalName.text = b.legalName ?? c.name;
        _billingTaxId.text = b.taxId ?? '';
        _billingStreet.text = b.addressStreet ?? '';
        _billingExtra.text = b.addressExtra ?? '';
        _billingCity.text = b.addressCity ?? '';
        _billingProvince.text = b.addressProvince ?? '';
        _billingPostal.text = b.addressPostalCode ?? '';
        _billingCountry.text = b.addressCountry ?? '';
        _billingEmail.text = b.email ?? (c.email ?? '');
        _billingPhone.text = b.phone ?? (c.phone ?? '');
        _billingExpanded = b.hasData;
      } else {
        // Nudge users to reuse contact details
        _billingLegalName.text = c.name;
        _billingEmail.text = c.email ?? '';
        _billingPhone.text = c.phone ?? '';
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _billingLegalName.dispose();
    _billingTaxId.dispose();
    _billingStreet.dispose();
    _billingExtra.dispose();
    _billingCity.dispose();
    _billingProvince.dispose();
    _billingPostal.dispose();
    _billingCountry.dispose();
    _billingEmail.dispose();
    _billingPhone.dispose();
    super.dispose();
  }

  ClientBilling? _billingFromInputs({bool includeNulls = false}) {
    final billing = ClientBilling(
      legalName: _billingLegalName.text,
      taxId: _billingTaxId.text,
      addressStreet: _billingStreet.text,
      addressExtra: _billingExtra.text,
      addressCity: _billingCity.text,
      addressProvince: _billingProvince.text,
      addressPostalCode: _billingPostal.text,
      addressCountry: _billingCountry.text,
      email: _billingEmail.text,
      phone: _billingPhone.text,
    );
    final payload = billing.toPayload(includeNulls: includeNulls);
    return payload == null ? null : billing;
  }

  Map<String, dynamic>? _billingPayload({bool includeNulls = false}) =>
      _billingFromInputs(includeNulls: includeNulls)
          ?.toPayload(includeNulls: includeNulls);

  bool get _hasBillingData =>
      _billingFromInputs(includeNulls: false)?.hasData ?? false;

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final billingPatch =
        _billingPayload(includeNulls: _isEdit); // allow clearing on edit
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
        if (billingPatch != null) patch['billing'] = billingPatch;
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
            billing: _billingFromInputs(),
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
        child: SingleChildScrollView(
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
                  labelStyle:
                      typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
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
                  labelStyle:
                      typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
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
                  labelStyle:
                      typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
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

              // Billing details
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                child: ExpansionTile(
                  initiallyExpanded: _billingExpanded || _hasBillingData,
                  onExpansionChanged: (v) =>
                      setState(() => _billingExpanded = v),
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.billingDetails,
                          style: typo.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (widget.client?.billing?.isComplete ?? false)
                              ? cs.secondaryContainer
                              : cs.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: cs.outlineVariant.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.client?.billing?.isComplete ?? false
                              ? l.billingComplete
                              : l.billingMissing,
                          style: typo.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: (widget.client?.billing?.isComplete ?? false)
                                ? cs.onSecondaryContainer
                                : cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    l.billingDetailsSubtitle,
                    style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _billingLegalName,
                      style: typo.bodyMedium,
                      decoration: InputDecoration(
                        labelText: l.billingLegalName,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _billingTaxId,
                      style: typo.bodyMedium,
                      decoration: InputDecoration(
                        labelText: l.billingTaxId,
                        prefixIcon: const Icon(Icons.numbers),
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _billingStreet,
                      style: typo.bodyMedium,
                      decoration: InputDecoration(
                        labelText: l.addressStreet,
                        prefixIcon: const Icon(Icons.home_outlined),
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _billingExtra,
                      style: typo.bodyMedium,
                      decoration: InputDecoration(
                        labelText: l.addressExtra,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _billingCity,
                            style: typo.bodyMedium,
                            decoration: InputDecoration(
                              labelText: l.addressCity,
                              prefixIcon:
                                  const Icon(Icons.location_city_rounded),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _billingProvince,
                            style: typo.bodyMedium,
                            decoration: InputDecoration(
                              labelText: l.addressProvince,
                              prefixIcon: const Icon(Icons.map_outlined),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _billingPostal,
                            style: typo.bodyMedium,
                            decoration: InputDecoration(
                              labelText: l.addressPostalCode,
                              prefixIcon:
                                  const Icon(Icons.local_post_office_outlined),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _billingCountry,
                            style: typo.bodyMedium,
                            decoration: InputDecoration(
                              labelText: l.addressCountry,
                              prefixIcon: const Icon(Icons.public),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _billingEmail,
                            style: typo.bodyMedium,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: l.billingEmailLabel,
                              prefixIcon:
                                  const Icon(Icons.alternate_email_rounded),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v);
                              return ok ? null : l.invalidEmail;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _billingPhone,
                            style: typo.bodyMedium,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: l.billingPhoneLabel,
                              prefixIcon: const Icon(Icons.phone_in_talk),
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder.copyWith(
                                borderSide:
                                    BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Active switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: Text(l.active,
                    style:
                        typo.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
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
                    _saving
                        ? l.saving
                        : (_isEdit ? l.saveChanges : l.saveClient),
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
      ),
    );
  }
}
