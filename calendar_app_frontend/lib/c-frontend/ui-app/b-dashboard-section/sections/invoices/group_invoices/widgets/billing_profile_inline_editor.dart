import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/utils/address/spain_postal_code_autofill.dart';
import 'package:hexora/c-frontend/utils/validation/email_validator.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  int _completionPercent = 0;

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
    _postal.addListener(_applyPostalAutofill);
    _applyPostalAutofill();
    _recomputeDirty();
  }

  void _resetFields() {
    final p = widget.initial;
    _legalName.text = p?.legalName ?? '';
    _taxId.text = p?.taxId ?? '';
    _logoUrl.text = p?.logoUrl ?? '';
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

    final nextCompletion = _calculateCompletionPercent();
    if (!mounted) return;
    setState(() {
      _hasChanges = next;
      _completionPercent = nextCompletion;
    });
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

  void _showLogoDialog(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    maxHeight: 400,
                  ),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
    if (!mounted) return;

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
              // Temporary debug logging
              debugPrint(
                '[logo-upload] name: ${file.name} | ext: ${file.extension} | size: ${file.size}',
              );
              // Extension-based type check (PlatformFile has no MIME type property)
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : cs.surfaceContainerHighest;
    final fieldColor = isLight
        ? Colors.white
        : cs.surfaceContainerHighest.withValues(alpha: 0.22);
    final subtleTint =
        isLight ? cs.primary.withValues(alpha: 0.035) : cs.primaryContainer;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
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
        fillColor: fieldColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 10),
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
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    Widget sectionCard({required Widget child, bool featured = false}) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: featured
                ? subtleTint
                : cardColor.withValues(alpha: isLight ? 1 : 0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: featured
                  ? cs.primary.withValues(alpha: 0.34)
                  : cs.outlineVariant.withValues(alpha: 0.38),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.045 : 0.16),
                blurRadius: isLight ? 18 : 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: child,
        ),
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

    String displayOrMissing(String value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
      return 'Pendiente';
    }

    Widget summaryMetric({
      required IconData icon,
      required String label,
      required String value,
    }) {
      final missing = value.trim().isEmpty;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: missing
              ? cs.errorContainer.withValues(alpha: isLight ? 0.28 : 0.16)
              : cs.surfaceContainerHighest
                  .withValues(alpha: isLight ? 0.5 : 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: missing
                ? cs.error.withValues(alpha: 0.22)
                : cs.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: missing ? cs.error : cs.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayOrMissing(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      color: missing ? cs.error : cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget completionPill() {
      final complete = _completionPercent >= 100;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: complete
              ? cs.tertiaryContainer.withValues(alpha: 0.55)
              : cs.primaryContainer.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                (complete ? cs.tertiary : cs.primary).withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              complete ? Icons.verified_rounded : Icons.pending_actions_rounded,
              size: 16,
              color: complete ? cs.tertiary : cs.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '$_completionPercent% completado',
              style: t.bodySmall.copyWith(
                color: complete ? cs.onTertiaryContainer : cs.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    Widget companySummaryCard(bool wide) {
      return sectionCard(
        featured: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(Icons.business_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _legalName.text.trim().isEmpty
                            ? 'Empresa sin nombre'
                            : _legalName.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Datos usados como emisor en facturas y PDFs.',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                completionPill(),
              ],
            ),
            const SizedBox(height: 14),
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: summaryMetric(
                      icon: Icons.badge_outlined,
                      label: l.billingTaxId,
                      value: _taxId.text,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: summaryMetric(
                      icon: Icons.email_outlined,
                      label: l.billingEmailLabel,
                      value: _email.text,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: summaryMetric(
                      icon: Icons.language_outlined,
                      label: l.billingWebsite,
                      value: _website.text,
                    ),
                  ),
                ],
              )
            else ...[
              summaryMetric(
                icon: Icons.badge_outlined,
                label: l.billingTaxId,
                value: _taxId.text,
              ),
              const SizedBox(height: 8),
              summaryMetric(
                icon: Icons.email_outlined,
                label: l.billingEmailLabel,
                value: _email.text,
              ),
              const SizedBox(height: 8),
              summaryMetric(
                icon: Icons.language_outlined,
                label: l.billingWebsite,
                value: _website.text,
              ),
            ],
          ],
        ),
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
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _logoUrl,
              builder: (_, v, __) {
                final url = v.text.trim();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Preview area ─────────────────────────────────────
                    GestureDetector(
                      onTap: url.isEmpty
                          ? (_logoBusy ? null : _pickLogo)
                          : () => _showLogoDialog(url),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 128,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: url.isEmpty
                              ? cs.surfaceContainerHighest
                                  .withValues(alpha: isLight ? 0.38 : 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: url.isEmpty
                                ? cs.outlineVariant.withValues(alpha: 0.55)
                                : cs.primary.withValues(alpha: 0.32),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: url.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 34,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Toca para subir logo',
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  CustomPaint(painter: _CheckerPainter()),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 36,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.52),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.open_in_full_rounded,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ver',
                                            style: t.bodySmall.copyWith(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ── Action buttons ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _logoBusy ? null : _pickLogo,
                            icon: _logoBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 17,
                                  ),
                            label: Text(l.invoiceLogoUploadCta),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        if (url.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Ver a tamaño completo',
                            child: IconButton.outlined(
                              onPressed: () => _showLogoDialog(url),
                              icon: const Icon(
                                Icons.open_in_full_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                            child: IconButton.outlined(
                              onPressed:
                                  _saving ? null : () => _logoUrl.text = '',
                              style: IconButton.styleFrom(
                                  foregroundColor: cs.error),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            ),
            const SizedBox(height: 10),
            textField(
              controller: _taxId,
              label: l.billingTaxId,
              icon: Icons.numbers_outlined,
              style: codeStyle,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
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
                final ok = isLikelyValidEmail(txt);
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.fieldIsRequired
                          : null,
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
              ),
            ],
          ],
        ),
      );
    }

    Widget bankingSection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(
              'Banca',
              subtitle: 'Cuenta usada para mostrar datos de pago en facturas.',
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),
            textField(
              controller: _iban,
              label: l.billingIban,
              icon: Icons.account_balance_outlined,
              style: codeStyle,
              suffix: copySuffix(_iban),
              helper: l.billingIbanHelper,
            ),
          ],
        ),
      );
    }

    Widget taxSettingsSection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(
              'Impuestos',
              subtitle: 'Valores por defecto aplicados al crear documentos.',
              icon: Icons.percent_rounded,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
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
          ],
        ),
      );
    }

    Widget regionalSettingsSection() {
      return sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(
              'Región',
              subtitle: 'Moneda e idioma para documentos emitidos.',
              icon: Icons.public_rounded,
            ),
            const SizedBox(height: 10),
            textField(
              controller: _currency,
              label: l.billingCurrency,
              icon: Icons.currency_exchange_outlined,
              helper: l.billingCurrencyHelper,
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
                    companySummaryCard(wide),
                    const SizedBox(height: 12),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                companySection(),
                                const SizedBox(height: 12),
                                contactSection(),
                                const SizedBox(height: 12),
                                addressSection(wide),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                logoSection(),
                                const SizedBox(height: 12),
                                bankingSection(),
                                const SizedBox(height: 12),
                                taxSettingsSection(),
                                const SizedBox(height: 12),
                                regionalSettingsSection(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          companySection(),
                          const SizedBox(height: 12),
                          contactSection(),
                          const SizedBox(height: 12),
                          addressSection(false),
                          const SizedBox(height: 12),
                          logoSection(),
                          const SizedBox(height: 12),
                          bankingSection(),
                          const SizedBox(height: 12),
                          taxSettingsSection(),
                          const SizedBox(height: 12),
                          regionalSettingsSection(),
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
                  color: cs.surface.withValues(alpha: 0.94),
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _completionPercent / 100),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 3,
                        backgroundColor:
                            cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        color: _completionPercent >= 100
                            ? Colors.green
                            : _completionPercent >= 60
                                ? cs.primary
                                : cs.error.withValues(alpha: 0.7),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _hasChanges
                                      ? Icons.edit_note_outlined
                                      : Icons.check_circle_outline,
                                  size: 18,
                                  color: _hasChanges
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _hasChanges
                                        ? 'Hay cambios pendientes'
                                        : 'Perfil actualizado',
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            flex: 0,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: (!_hasChanges || _saving)
                                      ? null
                                      : _resetFields,
                                  icon: const Icon(Icons.undo_rounded),
                                  label: Text(
                                    'Descartar cambios',
                                    style: t.bodySmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed:
                                      (!_hasChanges || _saving) ? null : _save,
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _saving ? l.saving : l.saveChanges,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
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
              ),
            ),
          )
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

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const sq = 8.0;
    final light = Paint()..color = const Color(0xFFE8E8E8);
    final dark = Paint()..color = const Color(0xFFF8F8F8);
    final cols = (size.width / sq).ceil() + 1;
    final rows = (size.height / sq).ceil() + 1;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * sq, r * sq, sq, sq),
          (r + c).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter _) => false;
}
