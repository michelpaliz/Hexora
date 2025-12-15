import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/billing_profile_sheet/billing_profile_sheet_form.dart';
import 'package:hexora/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _legalName = TextEditingController(text: p?.legalName ?? '');
    _taxId = TextEditingController(text: p?.taxId ?? '');
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
  }

  @override
  void dispose() {
    _legalName.dispose();
    _taxId.dispose();
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

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final vat = num.tryParse(_vatRate.text.trim()) ?? 21;
      final profile = BillingProfile(
        id: widget.initial?.id,
        groupId: widget.groupId,
        legalName: _legalName.text.trim(),
        taxId: _taxId.text.trim(),
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
        onSave: _save,
      ),
    );
  }
}
