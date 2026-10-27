import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/services/invoicing/billing_profile_api.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/utils/address/spain_postal_code_autofill.dart';
import 'package:hexora/presentation/utils/validation/email_validator.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
    extends State<BillingProfileInlineEditor>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

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
  String? _logoPreviewSourceUrl;
  String? _logoPreviewUrl;
  bool _hasChanges = false;
  int _completionPercent = 0;

  static const _currencies = [
    ('EUR', 'Euro (€)'),
    ('USD', 'Dólar (US\$)'),
    ('GBP', 'Libra (£)'),
    ('MXN', 'Peso mexicano'),
    ('COP', 'Peso colombiano'),
    ('ARS', 'Peso argentino'),
    ('CLP', 'Peso chileno'),
    ('PEN', 'Sol peruano'),
    ('BRL', 'Real brasileño'),
  ];

  static const _languages = [
    ('es', 'Español'),
    ('en', 'English'),
    ('ca', 'Català'),
    ('gl', 'Galego'),
    ('eu', 'Euskara'),
    ('fr', 'Français'),
    ('de', 'Deutsch'),
    ('pt', 'Português'),
    ('it', 'Italiano'),
  ];

  void _applyPostalAutofill() {
    final autofill = inferSpainPostalAutofill(
      postalCode: _postal.text,
      currentCountry: _country.text,
    );
    if (autofill == null) return;
    if (_province.text.trim() != autofill.province) {
      _province.text = autofill.province;
    }
    if (_country.text.trim().isEmpty) {
      _country.text = autofill.country;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final p = widget.initial;
    _legalName = TextEditingController(text: p?.legalName ?? '');
    _taxId = TextEditingController(text: p?.taxId ?? '');
    _logoUrl = TextEditingController(text: p?.logoUrl ?? '');
    _logoPreviewSourceUrl = p?.logoUrl;
    _logoPreviewUrl = p?.logoPreviewUrl;
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
      _legalName, _taxId, _logoUrl, _street, _extra, _city,
      _province, _postal, _country, _email, _website, _iban,
      _currency, _vatRate, _language,
    ]) {
      c.addListener(_recomputeDirty);
    }
    _postal.addListener(_applyPostalAutofill);
    _applyPostalAutofill();
    _recomputeDirty();
  }

  void _resetFields() {
    final p = widget.initial;
    _legalName.text = p?.legalName ?? '';
    _taxId.text = p?.taxId ?? '';
    _logoUrl.text = p?.logoUrl ?? '';
    _logoPreviewSourceUrl = p?.logoUrl;
    _logoPreviewUrl = p?.logoPreviewUrl;
    _street.text = p?.addressStreet ?? '';
    _extra.text = p?.addressExtra ?? '';
    _city.text = p?.addressCity ?? '';
    _province.text = p?.addressProvince ?? '';
    _postal.text = p?.addressPostalCode ?? '';
    _country.text = p?.addressCountry ?? '';
    _email.text = p?.email ?? '';
    _website.text = p?.website ?? '';
    _iban.text = p?.iban ?? '';
    _currency.text = p?.currency ?? 'EUR';
    _vatRate.text = (p?.vatRate ?? 21).toString();
    _language.text = p?.language ?? '';
    _applyPostalAutofill();
    _recomputeDirty();
  }

  int _calculateCompletionPercent() {
    final checks = <bool>[
      _legalName.text.trim().isNotEmpty,
      _taxId.text.trim().isNotEmpty,
      _street.text.trim().isNotEmpty,
      _city.text.trim().isNotEmpty,
      _postal.text.trim().isNotEmpty,
      _country.text.trim().isNotEmpty,
      _email.text.trim().isNotEmpty,
      _iban.text.trim().isNotEmpty,
      _currency.text.trim().isNotEmpty,
      _vatRate.text.trim().isNotEmpty,
      _language.text.trim().isNotEmpty,
      _logoUrl.text.trim().isNotEmpty,
    ];
    final completed = checks.where((ok) => ok).length;
    return ((completed / checks.length) * 100).round();
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
            _legalName.text, _taxId.text, _logoUrl.text, _street.text,
            _extra.text, _city.text, _province.text, _postal.text,
            _country.text, _email.text, _website.text, _iban.text,
            _currency.text, _vatRate.text, _language.text,
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
            _parsedVatRate() == initial.vatRate &&
            sameNullable(initial.language, _language.text));

    final nextCompletion = _calculateCompletionPercent();
    if (!mounted) return;
    setState(() {
      _hasChanges = next;
      _completionPercent = nextCompletion;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _legalName.dispose();
    _taxId.dispose();
    _logoUrl.dispose();
    _street.dispose();
    _extra.dispose();
    _city.dispose();
    _province.dispose();
    _postal.removeListener(_applyPostalAutofill);
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

  // ── Logo ──

  void _showLogoDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 520, maxHeight: 400),
                  child: Image.network(url, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported_outlined, size: 64)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(_).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final l = AppLocalizations.of(context)!;
    if (!mounted || widget.initial == null) return;

    final picked = await showDialog<PlatformFile>(
      context: context,
      builder: (context) {
        PlatformFile? selected;
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFile() async {
              setDialogState(() => error = null);
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                withData: true,
                type: FileType.custom,
                allowedExtensions: ['png', 'jpg', 'jpeg'],
              );
              final file = result?.files.single;
              if (file == null) return;
              final ext =
                  (file.extension?.toLowerCase().trim().isNotEmpty == true
                          ? file.extension!
                          : file.name.split('.').last)
                      .toLowerCase()
                      .trim();
              final validType = const ['png', 'jpg', 'jpeg'].contains(ext);
              final tooLarge = file.size > 15 * 1024 * 1024;
              setDialogState(() {
                if (!validType || tooLarge) {
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
                      child: Text(selected!.name,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
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
    if (picked == null || !mounted) return;
    if (picked.bytes == null || picked.bytes!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.billingLogoUploadError)));
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
      _logoPreviewSourceUrl = updated.logoUrl;
      _logoPreviewUrl = updated.logoPreviewUrl;
      _logoUrl.text = updated.logoUrl ?? '';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.billingLogoUploadSuccess)));
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[BillingProfileInlineEditor] logo upload failed '
          'groupId=${widget.groupId} error=$e\n$st');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.billingLogoUploadError)));
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  // ── Save ──

  num? _parsedVatRate() =>
      num.tryParse(_vatRate.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final vat = _parsedVatRate()!;

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
        currency:
            _currency.text.trim().isEmpty ? 'EUR' : _currency.text.trim(),
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

  // ── Shared builders ──

  InputDecoration _dec(
    BuildContext context, {
    required String label,
    IconData? icon,
    Widget? suffix,
    String? helper,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fieldColor = isLight
        ? Colors.white
        : cs.surfaceContainerHighest.withValues(alpha: 0.22);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
    );
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon, size: 16),
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: fieldColor,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  Widget _textField({
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
    final t = AppTypography.of(context);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: style ?? t.bodySmall,
      decoration: _dec(context,
          label: label, icon: icon, suffix: suffix, helper: helper),
      validator: validator,
    );
  }

  Widget _copySuffix(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: MaterialLocalizations.of(context).copyButtonLabel,
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: v));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.copiedToClipboard)));
      },
      icon: const Icon(Icons.content_copy_outlined, size: 16),
    );
  }

  Widget _sectionLabel(String title, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
          ],
          Text(title,
              style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── Tab contents ──

  Widget _buildGeneralTab(bool wide) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _sectionLabel(l.billingDetails, icon: Icons.apartment_outlined),
        _textField(
          controller: _legalName,
          label: l.billingLegalName,
          icon: Icons.badge_outlined,
          suffix: _copySuffix(_legalName),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        ),
        const SizedBox(height: 10),
        _textField(
          controller: _taxId,
          label: l.billingTaxId,
          icon: Icons.numbers_outlined,
          style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: 0.2),
          suffix: _copySuffix(_taxId),
          helper: l.billingTaxIdHelper,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        ),
        const SizedBox(height: 18),
        _sectionLabel(l.billingAddress, icon: Icons.place_outlined),
        _textField(
          controller: _street,
          label: l.addressStreet,
          icon: Icons.home_outlined,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        ),
        const SizedBox(height: 10),
        _textField(controller: _extra, label: l.addressExtra),
        const SizedBox(height: 10),
        if (wide)
          Row(children: [
            Expanded(
                child: _textField(
                    controller: _city,
                    label: l.addressCity,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null)),
            const SizedBox(width: 10),
            Expanded(
                child: _textField(
                    controller: _province,
                    label: l.addressProvince,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null)),
          ])
        else ...[
          _textField(
              controller: _city,
              label: l.addressCity,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null),
          const SizedBox(height: 10),
          _textField(
              controller: _province,
              label: l.addressProvince,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null),
        ],
        const SizedBox(height: 10),
        if (wide)
          Row(children: [
            Expanded(
                child: _textField(
                    controller: _postal,
                    label: l.addressPostalCode,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null)),
            const SizedBox(width: 10),
            Expanded(
                child: _textField(
                    controller: _country,
                    label: l.addressCountry,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null)),
          ])
        else ...[
          _textField(
              controller: _postal,
              label: l.addressPostalCode,
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null),
          const SizedBox(height: 10),
          _textField(
              controller: _country,
              label: l.addressCountry,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l.fieldIsRequired
                  : null),
        ],
      ],
    );
  }

  Widget _buildContactoTab() {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _sectionLabel(l.billingEmailLabel, icon: Icons.email_outlined),
        _textField(
          controller: _email,
          label: l.billingEmailLabel,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          suffix: _copySuffix(_email),
          validator: (v) {
            final txt = (v ?? '').trim();
            if (txt.isEmpty) return null;
            return isLikelyValidEmail(txt) ? null : l.invalidEmail;
          },
        ),
        const SizedBox(height: 18),
        _sectionLabel(l.billingWebsite, icon: Icons.language_outlined),
        _textField(
          controller: _website,
          label: l.billingWebsite,
          icon: Icons.language_outlined,
          keyboardType: TextInputType.url,
          suffix: _copySuffix(_website),
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
    );
  }

  Widget _buildFacturasTab() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subtleTint =
        isLight ? cs.primary.withValues(alpha: 0.035) : cs.primaryContainer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Logo section
        _sectionLabel(l.invoiceLogoTitle, icon: Icons.image_outlined),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _logoUrl,
          builder: (_, v, __) {
            final url = v.text.trim();
            final displayUrl = url == _logoPreviewSourceUrl
                ? (_logoPreviewUrl ?? url)
                : url;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: url.isEmpty
                      ? (_logoBusy || widget.initial == null
                          ? null
                          : _pickLogo)
                      : () => _showLogoDialog(displayUrl),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: url.isEmpty
                          ? cs.surfaceContainerHighest
                              .withValues(alpha: isLight ? 0.38 : 0.18)
                          : subtleTint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: url.isEmpty
                            ? cs.outlineVariant.withValues(alpha: 0.55)
                            : cs.primary.withValues(alpha: 0.32),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: url.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 28,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.45)),
                                const SizedBox(height: 4),
                                Text(
                                    widget.initial == null
                                        ? 'Guarda el perfil para subir un logo'
                                        : 'Toca para subir logo',
                                    style: t.caption.copyWith(
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.55))),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.network(displayUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        size: 28,
                                        color: cs.onSurfaceVariant))),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    HexoraButton(
                      onPressed: _logoBusy ? null : _pickLogo,
                      label: l.invoiceLogoUploadCta,
                      icon: Icons.cloud_upload_outlined,
                      loading: _logoBusy,
                      size: HexoraButtonSize.compact,
                    ),
                    if (url.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      HexoraButton.iconOnly(
                        onPressed: () => _showLogoDialog(displayUrl),
                        icon: Icons.open_in_full_rounded,
                        tooltip: 'Ver a tamaño completo',
                        size: HexoraButtonSize.compact,
                      ),
                      const SizedBox(width: 4),
                      HexoraButton.iconOnly(
                        onPressed: _saving ? null : () => _logoUrl.text = '',
                        icon: Icons.delete_outline_rounded,
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        variant: HexoraButtonVariant.danger,
                        size: HexoraButtonSize.compact,
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        // IBAN
        _sectionLabel('Banca', icon: Icons.account_balance_outlined),
        _textField(
          controller: _iban,
          label: l.billingIban,
          icon: Icons.account_balance_outlined,
          style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800, letterSpacing: 0.2),
          suffix: _copySuffix(_iban),
          helper: l.billingIbanHelper,
        ),

        const SizedBox(height: 18),

        // VAT
        _sectionLabel('Impuestos', icon: Icons.percent_rounded),
        Row(
          children: [
            IconButton(
              onPressed: _saving
                  ? null
                  : () {
                      final current = _parsedVatRate() ?? 21;
                      _vatRate.text =
                          (current - 1).clamp(0, 100).toString();
                    },
              icon: const Icon(Icons.remove_circle_outline, size: 20),
            ),
            Expanded(
              child: _textField(
                controller: _vatRate,
                label: '${l.billingTaxRate} %',
                icon: Icons.percent,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                helper: l.billingTaxRateHelper,
                validator: (_) {
                  final vat = _parsedVatRate();
                  return vat == null ||
                          !vat.isFinite ||
                          vat < 0 ||
                          vat > 100
                      ? 'Introduce un IVA entre 0 y 100'
                      : null;
                },
              ),
            ),
            IconButton(
              onPressed: _saving
                  ? null
                  : () {
                      final current = _parsedVatRate() ?? 21;
                      _vatRate.text =
                          (current + 1).clamp(0, 100).toString();
                    },
              icon: const Icon(Icons.add_circle_outline, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegionTab() {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    final currencyValue = _currency.text.trim().isEmpty
        ? 'EUR'
        : _currency.text.trim();
    final currencyKnown =
        _currencies.any((c) => c.$1 == currencyValue);

    final langValue = _language.text.trim();
    final langKnown =
        _languages.any((l) => l.$1 == langValue);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _sectionLabel(l.billingCurrency,
            icon: Icons.currency_exchange_outlined),
        if (currencyKnown)
          DropdownButtonFormField<String>(
            initialValue: currencyValue,
            isDense: true,
            style: t.bodySmall,
            decoration: _dec(context,
                label: l.billingCurrency,
                helper: l.billingCurrencyHelper),
            items: [
              for (final c in _currencies)
                DropdownMenuItem(value: c.$1, child: Text(c.$2)),
            ],
            onChanged: (v) {
              if (v != null) _currency.text = v;
            },
          )
        else
          _textField(
            controller: _currency,
            label: l.billingCurrency,
            icon: Icons.currency_exchange_outlined,
            helper: l.billingCurrencyHelper,
          ),

        const SizedBox(height: 18),

        _sectionLabel(l.billingLanguage, icon: Icons.translate_outlined),
        if (langKnown || langValue.isEmpty)
          DropdownButtonFormField<String>(
            initialValue: langKnown ? langValue : null,
            isDense: true,
            style: t.bodySmall,
            decoration: _dec(context,
                label: l.billingLanguage,
                helper: l.billingLanguageHelper),
            items: [
              for (final lang in _languages)
                DropdownMenuItem(value: lang.$1, child: Text(lang.$2)),
            ],
            onChanged: (v) {
              if (v != null) _language.text = v;
            },
          )
        else
          _textField(
            controller: _language,
            label: l.billingLanguage,
            icon: Icons.translate_outlined,
            helper: l.billingLanguageHelper,
          ),
      ],
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final subtleTint =
        isLight ? cs.primary.withValues(alpha: 0.035) : cs.primaryContainer;
    final es = l.localeName.startsWith('es');

    final complete = _completionPercent >= 100;

    final formContent = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // ── Compact header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.business_rounded,
                    size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _legalName.text.trim().isEmpty
                        ? 'Empresa sin nombre'
                        : _legalName.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: complete
                        ? Colors.green.withValues(alpha: 0.10)
                        : cs.primaryContainer.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: (complete ? Colors.green : cs.primary)
                            .withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        complete
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                        size: 14,
                        color: complete
                            ? Colors.green.shade700
                            : cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_completionPercent%',
                        style: t.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: complete
                              ? Colors.green.shade700
                              : cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Tabs ──
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: t.bodySmall,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: cs.outlineVariant.withValues(alpha: 0.25),
            tabs: const [
              Tab(text: 'General'),
              Tab(text: 'Contacto'),
              Tab(text: 'Facturas'),
              Tab(text: 'Región'),
            ],
          ),

          // ── Tab content ──
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(wide),
                    _buildContactoTab(),
                    _buildFacturasTab(),
                    _buildRegionTab(),
                  ],
                );
              },
            ),
          ),

          // ── Sticky footer ──
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: subtleTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: cs.primary.withValues(alpha: .16)),
              ),
              child: Row(
                children: [
                  Icon(
                      _hasChanges
                          ? Icons.edit_note
                          : Icons.check_circle,
                      size: 20,
                      color: _hasChanges
                          ? cs.primary
                          : Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasChanges
                          ? (es
                              ? 'Hay cambios pendientes'
                              : 'Unsaved changes')
                          : (es
                              ? 'Perfil actualizado'
                              : 'Profile up to date'),
                      style: t.caption,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HexoraButton(
                    onPressed: (!_hasChanges || _saving)
                        ? null
                        : _resetFields,
                    label: es ? 'Descartar' : 'Discard',
                    icon: Icons.undo,
                    variant: HexoraButtonVariant.secondary,
                    size: HexoraButtonSize.compact,
                  ),
                  const SizedBox(width: 8),
                  HexoraButton(
                    key: const ValueKey('billing-profile-save'),
                    onPressed:
                        (!_hasChanges || _saving) ? null : _save,
                    label: _saving ? l.saving : l.saveChanges,
                    icon: Icons.check,
                    loading: _saving,
                    size: HexoraButtonSize.compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showFolder) return formContent;

    return FolderPanel(
      title: l.billingProfileTitle,
      showTab: true,
      child: formContent,
    );
  }
}
