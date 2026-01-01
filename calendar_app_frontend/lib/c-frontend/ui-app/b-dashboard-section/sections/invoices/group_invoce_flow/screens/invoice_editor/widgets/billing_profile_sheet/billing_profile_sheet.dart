import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/billing_profile_sheet/billing_profile_sheet_form.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class BillingProfileSheet extends StatefulWidget {
  final BillingProfile? initial;
  final String groupId;
  final BillingProfileApi api;
  const BillingProfileSheet({
    super.key,
    required this.initial,
    required this.groupId,
    required this.api,
  });

  @override
  State<BillingProfileSheet> createState() => _BillingProfileSheetState();
}

class _BillingProfileSheetState extends State<BillingProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _legalName;
  late final TextEditingController _taxId;
  late final TextEditingController _logoUrl;
  late final TextEditingController _street;
  late final TextEditingController _extra;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postal;
  late final TextEditingController _country;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _iban;
  late final TextEditingController _currency;
  late final TextEditingController _vatRate;
  late final TextEditingController _language;
  bool _saving = false;
  bool _logoBusy = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _legalName = TextEditingController(text: p?.legalName ?? '');
    _taxId = TextEditingController(text: p?.taxId ?? '');
    _logoUrl = TextEditingController(text: p?.logoUrl ?? '');
    _street = TextEditingController(text: p?.addressStreet ?? '');
    _extra = TextEditingController(text: p?.addressExtra ?? '');
    _city = TextEditingController(text: p?.addressCity ?? '');
    _province = TextEditingController(text: p?.addressProvince ?? '');
    _postal = TextEditingController(text: p?.addressPostalCode ?? '');
    _country = TextEditingController(text: p?.addressCountry ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _website = TextEditingController(text: p?.website ?? '');
    _iban = TextEditingController(text: p?.iban ?? '');
    _currency = TextEditingController(text: p?.currency ?? 'EUR');
    _vatRate = TextEditingController(text: (p?.vatRate ?? 21).toString());
    _language = TextEditingController(text: p?.language ?? '');

    for (final c in [
      _legalName,
      _taxId,
      _logoUrl,
      _street,
      _extra,
      _city,
      _province,
      _postal,
      _country,
      _email,
      _website,
      _iban,
      _currency,
      _vatRate,
      _language,
    ]) {
      c.addListener(_recomputeDirty);
    }
    _recomputeDirty();
  }

  void _recomputeDirty() {
    String? normNullable(String? s) {
      final v = s?.trim() ?? '';
      return v.isEmpty ? null : v;
    }

    bool sameNullable(String? a, String? b) =>
        normNullable(a) == normNullable(b);

    final initial = widget.initial;
    final bool next = initial == null
        ? [
            _legalName.text,
            _taxId.text,
            _logoUrl.text,
            _street.text,
            _extra.text,
            _city.text,
            _province.text,
            _postal.text,
            _country.text,
            _email.text,
            _website.text,
            _iban.text,
            _currency.text,
            _vatRate.text,
            _language.text,
          ].any((e) => e.trim().isNotEmpty)
        : !(_legalName.text.trim() == initial.legalName &&
            _taxId.text.trim() == initial.taxId &&
            sameNullable(initial.logoUrl, _logoUrl.text) &&
            sameNullable(initial.addressStreet, _street.text) &&
            sameNullable(initial.addressExtra, _extra.text) &&
            sameNullable(initial.addressCity, _city.text) &&
            sameNullable(initial.addressProvince, _province.text) &&
            sameNullable(initial.addressPostalCode, _postal.text) &&
            sameNullable(initial.addressCountry, _country.text) &&
            sameNullable(initial.email, _email.text) &&
            sameNullable(initial.website, _website.text) &&
            sameNullable(initial.iban, _iban.text) &&
            (normNullable(_currency.text) ?? 'EUR') == initial.currency &&
            (num.tryParse(_vatRate.text.trim()) ?? 21) == initial.vatRate &&
            sameNullable(initial.language, _language.text));

    if (!mounted) return;
    if (_hasChanges == next) return;
    setState(() => _hasChanges = next);
  }

  @override
  void dispose() {
    _legalName.dispose();
    _taxId.dispose();
    _logoUrl.dispose();
    _street.dispose();
    _extra.dispose();
    _city.dispose();
    _province.dispose();
    _postal.dispose();
    _country.dispose();
    _email.dispose();
    _website.dispose();
    _iban.dispose();
    _currency.dispose();
    _vatRate.dispose();
    _language.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final l = AppLocalizations.of(context)!;
    final token = await TokenService.loadToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.notAuthenticatedOrUserMissing)),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _logoBusy = true);
    try {
      final bytes = kIsWeb ? await picked.readAsBytes() : null;
      final result = await uploadImageToAzure(
        scope: 'groups',
        resourceId: widget.groupId,
        file: kIsWeb ? null : File(picked.path),
        bytes: bytes,
        accessToken: token,
      );
      if (!mounted) return;

      _logoUrl.text = result.photoUrl;
      final updated = await widget.api.updateLogo(
        groupId: widget.groupId,
        logoUrl: result.photoUrl,
      );
      if (!mounted) return;

      _logoUrl.text = updated.logoUrl ?? result.photoUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLogoUpdated)),
      );
    } catch (e, st) {
      if (!mounted) return;
      final reason = e.toString().replaceFirst('Exception: ', '');
      final blobError = e is BlobUploadException ? e : null;
      debugPrint('[BillingProfileSheet] logo upload failed groupId='
          '${widget.groupId} error=$e\n$st');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.failedWithReason(reason)),
          action: SnackBarAction(
            label: l.details,
            onPressed: () {
              if (!mounted) return;
              showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.details),
                  content: SelectableText(
                    [
                      'groupId: ${widget.groupId}',
                      'baseUrl: ${ApiConstants.baseUrl}',
                      'cdnBaseUrl: ${ApiConstants.cdnBaseUrl}',
                      'hasToken: ${token.isNotEmpty}',
                      'tokenLength: ${token.length}',
                      'pickedPath: ${picked.path}',
                      if (blobError != null) ...[
                        'stage: ${blobError.stage}',
                        'request: ${blobError.method} ${blobError.url}',
                        if (blobError.statusCode != null)
                          'statusCode: ${blobError.statusCode}',
                        if (blobError.responseHeaders != null)
                          'responseHeaders: ${blobError.responseHeaders}',
                        if (blobError.responseBody != null)
                          'responseBody: ${blobError.responseBody}',
                        if (blobError.innerError != null)
                          'innerError: ${blobError.innerError}',
                      ],
                      'error: ${e.toString()}',
                      'stackTrace:\n$st',
                      if (kDebugMode)
                        'hint: If this fails at "get-upload-sas", check backend /blob/.../upload-sas route, auth, and group permissions.',
                    ].join('\n'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final vat = num.tryParse(_vatRate.text.trim()) ?? 21;

      String? normNullable(String? s) {
        final v = s?.trim() ?? '';
        return v.isEmpty ? null : v;
      }

      bool sameNullable(String? a, String? b) =>
          normNullable(a) == normNullable(b);

      final initial = widget.initial;
      final websiteOnlyChange = initial != null &&
          !sameNullable(initial.website, _website.text) &&
          _legalName.text.trim() == (initial.legalName) &&
          _taxId.text.trim() == (initial.taxId) &&
          sameNullable(initial.logoUrl, _logoUrl.text) &&
          sameNullable(initial.addressStreet, _street.text) &&
          sameNullable(initial.addressExtra, _extra.text) &&
          sameNullable(initial.addressCity, _city.text) &&
          sameNullable(initial.addressProvince, _province.text) &&
          sameNullable(initial.addressPostalCode, _postal.text) &&
          sameNullable(initial.addressCountry, _country.text) &&
          sameNullable(initial.email, _email.text) &&
          sameNullable(initial.iban, _iban.text) &&
          (_currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim()) ==
              initial.currency &&
          vat == (initial.vatRate) &&
          sameNullable(initial.language, _language.text);

      if (websiteOnlyChange) {
        final updated = await widget.api.updateWebsite(
          groupId: widget.groupId,
          website: normNullable(_website.text) ?? '',
        );
        if (!mounted) return;
        Navigator.of(context).pop<BillingProfile>(updated);
        return;
      }

      final profile = BillingProfile(
        id: widget.initial?.id,
        groupId: widget.groupId,
        legalName: _legalName.text.trim(),
        taxId: _taxId.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
        addressStreet: _street.text.trim().isEmpty ? null : _street.text.trim(),
        addressExtra: _extra.text.trim().isEmpty ? null : _extra.text.trim(),
        addressCity: _city.text.trim().isEmpty ? null : _city.text.trim(),
        addressProvince:
            _province.text.trim().isEmpty ? null : _province.text.trim(),
        addressPostalCode:
            _postal.text.trim().isEmpty ? null : _postal.text.trim(),
        addressCountry:
            _country.text.trim().isEmpty ? null : _country.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
        iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
        currency: _currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim(),
        vatRate: vat,
        language: _language.text.trim().isEmpty ? null : _language.text.trim(),
      );
      final saved = await widget.api.upsert(profile);
      if (!mounted) return;
      Navigator.of(context).pop<BillingProfile>(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.failedWithReason(e.toString()))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, pad),
      child: BillingProfileSheetForm(
        formKey: _formKey,
        controllers: BillingProfileControllers(
          legalName: _legalName,
          taxId: _taxId,
          logoUrl: _logoUrl,
          street: _street,
          extra: _extra,
          city: _city,
          province: _province,
          postal: _postal,
          country: _country,
          email: _email,
          website: _website,
          iban: _iban,
          currency: _currency,
          vatRate: _vatRate,
          language: _language,
        ),
        saving: _saving,
        hasChanges: _hasChanges,
        onSave: _save,
        onPickLogo: _pickLogo,
        logoBusy: _logoBusy,
      ),
    );
  }
}
