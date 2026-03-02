import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';

class BillingProfileInlineEditor extends StatefulWidget {
  final BillingProfile? initial;
  final String groupId;
  final BillingProfileApi api;
  final ValueChanged<BillingProfile> onSaved;
  final bool showFolder;

  const BillingProfileInlineEditor({
    super.key,
    required this.initial,
    required this.groupId,
    required this.api,
    required this.onSaved,
    this.showFolder = true,
  });

  @override
  State<BillingProfileInlineEditor> createState() =>
      _BillingProfileInlineEditorState();
}

class _BillingProfileInlineEditorState
    extends State<BillingProfileInlineEditor> {
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
    if (!mounted) return;

    final picked = await showDialog<PlatformFile>(
      context: context,
      builder: (context) {
        PlatformFile? selected;
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFile() async {
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                withData: true,
                type: FileType.custom,
                allowedExtensions: ['png', 'jpg', 'jpeg'],
              );
              final file = result?.files.single;
              if (file == null) return;
              final tooLarge = file.size > 5 * 1024 * 1024;
              setDialogState(() {
                if (tooLarge) {
                  error = l.billingLogoUploadError;
                  selected = null;
                } else {
                  error = null;
                  selected = file;
                }
              });
            }

            return AlertDialog(
              title: Text(l.billingLogoUploadTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.billingLogoUploadBody),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(l.billingLogoUploadSelectFile),
                  ),
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        selected!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(context).pop(selected),
                  child: Text(l.billingLogoUploadCta),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null) return;
    if (!mounted) return;
    if (picked.bytes == null || picked.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.billingLogoUploadError)),
      );
      return;
    }

    setState(() => _logoBusy = true);
    try {
      final updated = await widget.api.uploadLogo(
        groupId: widget.groupId,
        filename: picked.name,
        bytes: picked.bytes!,
      );
      if (!mounted) return;
      _logoUrl.text = updated.logoUrl ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.billingLogoUploadSuccess)),
      );
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[BillingProfileInlineEditor] logo upload failed groupId='
          '${widget.groupId} error=$e\n$st');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.billingLogoUploadError)),
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

      String? normalizeWebsite(String? raw) {
        final txt = (raw ?? '').trim();
        if (txt.isEmpty) return null;
        final uri = Uri.tryParse(txt);
        if (uri != null && uri.hasScheme) return txt;
        if (txt.contains('.')) return 'https://$txt';
        return txt;
      }

      final initial = widget.initial;
      final initialWebsite = normalizeWebsite(initial?.website);
      final updatedWebsite = normalizeWebsite(_website.text);
      final websiteOnlyChange = initial != null &&
          initialWebsite != updatedWebsite &&
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
          website: updatedWebsite ?? '',
        );
        if (!mounted) return;
        widget.onSaved(updated);
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
        website: updatedWebsite,
        iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
        currency: _currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim(),
        vatRate: vat,
        language: _language.text.trim().isEmpty ? null : _language.text.trim(),
      );
      final saved = await widget.api.upsert(profile);
      if (!mounted) return;
      widget.onSaved(saved);
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
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
    );

    InputDecoration dec({
      required String label,
      IconData? icon,
      Widget? suffix,
      String? helper,
    }) {
      return InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        isDense: true,
        filled: true,
        fillColor: cs.surface,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    Widget textField({
      required TextEditingController controller,
      required String label,
      IconData? icon,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
      TextStyle? style,
      Widget? suffix,
      String? helper,
      bool enabled = true,
      int? maxLines = 1,
    }) {
      return TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: style ?? t.bodyMedium,
        decoration: dec(
          label: label,
          icon: icon,
          suffix: suffix,
          helper: helper,
        ),
        validator: validator,
      );
    }

    Future<void> copyToClipboard(String value) async {
      await Clipboard.setData(ClipboardData(text: value));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.copiedToClipboard)));
    }

    Widget sectionHeader(String title, {String? subtitle, IconData? icon}) {
      return Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    Widget sectionCard({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      );
    }

    final codeStyle = t.bodyMedium.copyWith(
      fontFamily: 'monospace',
      letterSpacing: 0.2,
      fontWeight: FontWeight.w800,
    );

    Widget copySuffix(TextEditingController c) {
      final v = c.text.trim();
      if (v.isEmpty) return const SizedBox.shrink();
      return IconButton(
        tooltip: MaterialLocalizations.of(context).copyButtonLabel,
        onPressed: () => copyToClipboard(v),
        icon: const Icon(Icons.content_copy_outlined),
      );
    }

    Widget logoSection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(
              l.invoiceLogoTitle,
              subtitle: l.invoiceLogoSubtitle,
              icon: Icons.image_outlined,
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _logoUrl,
              builder: (_, v, __) {
                final url = v.text.trim();
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: url.isEmpty
                              ? Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: cs.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          url.isEmpty ? l.invoiceLogoEmpty : url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: _logoBusy ? null : _pickLogo,
                        icon: _logoBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(l.invoiceLogoUploadCta),
                      ),
                      if (url.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : () => _logoUrl.text = '',
                          icon: const Icon(Icons.close),
                          label: Text(
                            MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            textField(
              controller: _logoUrl,
              label: l.invoiceLogoUrlLabel,
              icon: Icons.link_outlined,
              keyboardType: TextInputType.url,
              suffix: copySuffix(_logoUrl),
            ),
          ],
        ),
      );
    }

    Widget companySection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(
              l.billingDetails,
              subtitle: l.billingDetailsSubtitle,
              icon: Icons.apartment_outlined,
            ),
            const SizedBox(height: 10),
            textField(
              controller: _legalName,
              label: l.billingLegalName,
              icon: Icons.badge_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null,
            ),
            const SizedBox(height: 10),
            textField(
              controller: _taxId,
              label: l.billingTaxId,
              icon: Icons.numbers_outlined,
              style: codeStyle,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null,
              suffix: copySuffix(_taxId),
              helper: l.billingTaxIdHelper,
            ),
          ],
        ),
      );
    }

    Widget contactSection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(l.contact, icon: Icons.contact_mail_outlined),
            const SizedBox(height: 10),
            textField(
              controller: _email,
              label: l.billingEmailLabel,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              suffix: copySuffix(_email),
              validator: (v) {
                final txt = (v ?? '').trim();
                if (txt.isEmpty) return null;
                final ok =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(txt);
                return ok ? null : l.invalidEmail;
              },
            ),
            const SizedBox(height: 10),
            textField(
              controller: _website,
              label: l.billingWebsite,
              icon: Icons.language_outlined,
              keyboardType: TextInputType.url,
              suffix: copySuffix(_website),
              validator: (v) {
                final txt = (v ?? '').trim();
                if (txt.isEmpty) return null;
                final uri = Uri.tryParse(txt);
                final ok =
                    (uri != null && (uri.hasScheme || uri.host.isNotEmpty)) ||
                        txt.contains('.');
                return ok ? null : l.invalidUrl;
              },
            ),
          ],
        ),
      );
    }

    Widget addressSection(bool wide) {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(l.billingAddress, icon: Icons.place_outlined),
            const SizedBox(height: 10),
            textField(
              controller: _street,
              label: l.addressStreet,
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 10),
            textField(
              controller: _extra,
              label: l.addressExtra,
            ),
            const SizedBox(height: 10),
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: textField(
                      controller: _city,
                      label: l.addressCity,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: textField(
                      controller: _province,
                      label: l.addressProvince,
                    ),
                  ),
                ],
              )
            else ...[
              textField(
                controller: _city,
                label: l.addressCity,
              ),
              const SizedBox(height: 10),
              textField(
                controller: _province,
                label: l.addressProvince,
              ),
            ],
            const SizedBox(height: 10),
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: textField(
                      controller: _postal,
                      label: l.addressPostalCode,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: textField(
                      controller: _country,
                      label: l.addressCountry,
                    ),
                  ),
                ],
              )
            else ...[
              textField(
                controller: _postal,
                label: l.addressPostalCode,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              textField(
                controller: _country,
                label: l.addressCountry,
              ),
            ],
          ],
        ),
      );
    }

    Widget preferencesSection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(l.preferencesSectionTitle, icon: Icons.tune_outlined),
            const SizedBox(height: 10),
            textField(
              controller: _iban,
              label: l.billingIban,
              icon: Icons.account_balance_outlined,
              style: codeStyle,
              suffix: copySuffix(_iban),
              helper: l.billingIbanHelper,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: textField(
                    controller: _currency,
                    label: l.billingCurrency,
                    icon: Icons.currency_exchange_outlined,
                    helper: l.billingCurrencyHelper,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () {
                                final current =
                                    num.tryParse(_vatRate.text.trim()) ?? 21;
                                final next = (current - 1).clamp(0, 100);
                                _vatRate.text = next.toString();
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: textField(
                          controller: _vatRate,
                          label: l.billingTaxRate,
                          icon: Icons.percent,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          helper: l.billingTaxRateHelper,
                        ),
                      ),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () {
                                final current =
                                    num.tryParse(_vatRate.text.trim()) ?? 21;
                                final next = (current + 1).clamp(0, 100);
                                _vatRate.text = next.toString();
                              },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            textField(
              controller: _language,
              label: l.billingLanguage,
              icon: Icons.translate_outlined,
              helper: l.billingLanguageHelper,
            ),
          ],
        ),
      );
    }

    final formContent = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                logoSection(),
                                const SizedBox(height: 12),
                                companySection(),
                                const SizedBox(height: 12),
                                addressSection(wide),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                contactSection(),
                                const SizedBox(height: 12),
                                preferencesSection(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          logoSection(),
                          const SizedBox(height: 12),
                          companySection(),
                          const SizedBox(height: 12),
                          contactSection(),
                          const SizedBox(height: 12),
                          addressSection(false),
                          const SizedBox(height: 12),
                          preferencesSection(),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hasChanges ? l.saveChanges : l.saveChanges,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (!_hasChanges || _saving) ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? l.saving : l.saveChanges,
                            style: t.bodySmall.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showFolder) {
      return formContent;
    }

    return FolderPanel(
      title: l.billingProfileTitle,
      showTab: true,
      child: formContent,
    );
  }
}
