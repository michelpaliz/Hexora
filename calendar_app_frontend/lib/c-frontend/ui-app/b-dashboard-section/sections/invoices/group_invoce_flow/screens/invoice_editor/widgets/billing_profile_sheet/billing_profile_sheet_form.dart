import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BillingProfileControllers {
  final TextEditingController legalName;
  final TextEditingController taxId;
  final TextEditingController logoUrl;
  final TextEditingController street;
  final TextEditingController extra;
  final TextEditingController city;
  final TextEditingController province;
  final TextEditingController postal;
  final TextEditingController country;
  final TextEditingController email;
  final TextEditingController website;
  final TextEditingController iban;
  final TextEditingController currency;
  final TextEditingController vatRate;
  final TextEditingController language;

  BillingProfileControllers({
    required this.legalName,
    required this.taxId,
    required this.logoUrl,
    required this.street,
    required this.extra,
    required this.city,
    required this.province,
    required this.postal,
    required this.country,
    required this.email,
    required this.website,
    required this.iban,
    required this.currency,
    required this.vatRate,
    required this.language,
  });
}

class BillingProfileSheetForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final BillingProfileControllers controllers;
  final bool saving;
  final bool hasChanges;
  final VoidCallback onSave;
  final VoidCallback onPickLogo;
  final bool logoBusy;

  const BillingProfileSheetForm({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.saving,
    required this.hasChanges,
    required this.onSave,
    required this.onPickLogo,
    required this.logoBusy,
  });

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
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(12),
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

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 92),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.billingProfileTitle,
                        style:
                            t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Logo
                sectionCard(
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
                        valueListenable: controllers.logoUrl,
                        builder: (_, v, __) {
                          final url = v.text.trim();
                          return Container(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.35),
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
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: cs.surfaceContainerHighest,
                                              child: const Icon(
                                                Icons
                                                    .image_not_supported_outlined,
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
                                  onPressed: logoBusy ? null : onPickLogo,
                                  icon: logoBusy
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
                                    onPressed: saving
                                        ? null
                                        : () => controllers.logoUrl.text = '',
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
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 10),
                        title: Text(
                          l.details,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          textField(
                            controller: controllers.logoUrl,
                            label: l.invoiceLogoUrlLabel,
                            icon: Icons.link_outlined,
                            keyboardType: TextInputType.url,
                            suffix: copySuffix(controllers.logoUrl),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Company / billing
                sectionCard(
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
                        controller: controllers.legalName,
                        label: l.billingLegalName,
                        icon: Icons.badge_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.fieldIsRequired
                            : null,
                      ),
                      const SizedBox(height: 10),
                      textField(
                        controller: controllers.taxId,
                        label: l.billingTaxId,
                        icon: Icons.numbers_outlined,
                        style: codeStyle,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.fieldIsRequired
                            : null,
                        suffix: copySuffix(controllers.taxId),
                        helper: l.billingTaxIdHelper,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Contact
                sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionHeader(l.contact,
                          icon: Icons.contact_mail_outlined),
                      const SizedBox(height: 10),
                      textField(
                        controller: controllers.email,
                        label: l.billingEmailLabel,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        suffix: copySuffix(controllers.email),
                        validator: (v) {
                          final txt = (v ?? '').trim();
                          if (txt.isEmpty) return null;
                          final ok = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$')
                              .hasMatch(txt);
                          return ok ? null : l.invalidEmail;
                        },
                      ),
                      const SizedBox(height: 10),
                      textField(
                        controller: controllers.website,
                        label: l.billingWebsite,
                        icon: Icons.language_outlined,
                        keyboardType: TextInputType.url,
                        suffix: copySuffix(controllers.website),
                        validator: (v) {
                          final txt = (v ?? '').trim();
                          if (txt.isEmpty) return null;
                          final uri = Uri.tryParse(txt);
                          final ok = uri != null &&
                              (uri.hasScheme || uri.host.isNotEmpty);
                          return ok ? null : l.invalidUrl;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Address
                sectionCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 560;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionHeader(l.billingAddress,
                              icon: Icons.place_outlined),
                          const SizedBox(height: 10),
                          textField(
                            controller: controllers.street,
                            label: l.addressStreet,
                            icon: Icons.home_outlined,
                          ),
                          const SizedBox(height: 10),
                          textField(
                            controller: controllers.extra,
                            label: l.addressExtra,
                          ),
                          const SizedBox(height: 10),
                          if (wide)
                            Row(
                              children: [
                                Expanded(
                                  child: textField(
                                    controller: controllers.city,
                                    label: l.addressCity,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: textField(
                                    controller: controllers.province,
                                    label: l.addressProvince,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            textField(
                              controller: controllers.city,
                              label: l.addressCity,
                            ),
                            const SizedBox(height: 10),
                            textField(
                              controller: controllers.province,
                              label: l.addressProvince,
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (wide)
                            Row(
                              children: [
                                Expanded(
                                  child: textField(
                                    controller: controllers.postal,
                                    label: l.addressPostalCode,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: textField(
                                    controller: controllers.country,
                                    label: l.addressCountry,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            textField(
                              controller: controllers.postal,
                              label: l.addressPostalCode,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 10),
                            textField(
                              controller: controllers.country,
                              label: l.addressCountry,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Preferences / billing config
                sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionHeader(
                        l.preferencesSectionTitle,
                        icon: Icons.tune_outlined,
                      ),
                      const SizedBox(height: 10),
                      textField(
                        controller: controllers.iban,
                        label: l.billingIban,
                        icon: Icons.account_balance_outlined,
                        style: codeStyle,
                        suffix: copySuffix(controllers.iban),
                        helper: l.billingIbanHelper,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: textField(
                              controller: controllers.currency,
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
                                  onPressed: saving
                                      ? null
                                      : () {
                                          final current = num.tryParse(
                                                  controllers.vatRate.text
                                                      .trim()) ??
                                              21;
                                          final next =
                                              (current - 1).clamp(0, 100);
                                          controllers.vatRate.text =
                                              next.toString();
                                        },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Expanded(
                                  child: textField(
                                    controller: controllers.vatRate,
                                    label: l.billingTaxRate,
                                    icon: Icons.percent,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    helper: l.billingTaxRateHelper,
                                  ),
                                ),
                                IconButton(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          final current = num.tryParse(
                                                  controllers.vatRate.text
                                                      .trim()) ??
                                              21;
                                          final next =
                                              (current + 1).clamp(0, 100);
                                          controllers.vatRate.text =
                                              next.toString();
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
                        controller: controllers.language,
                        label: l.billingLanguage,
                        icon: Icons.translate_outlined,
                        helper: l.billingLanguageHelper,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Save
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
                        hasChanges ? l.saveChanges : l.saveChanges,
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
                          onPressed: (!hasChanges || saving) ? null : onSave,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            saving ? l.saving : l.saveChanges,
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
  }
}
