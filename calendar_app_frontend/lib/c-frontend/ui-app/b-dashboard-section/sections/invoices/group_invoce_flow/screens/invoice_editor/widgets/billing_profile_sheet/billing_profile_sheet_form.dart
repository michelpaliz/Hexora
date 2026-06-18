import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/c-frontend/utils/validation/email_validator.dart';
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

    // ── Shared styles ─────────────────────────────────────────────────────────
    final mono = t.bodyMedium.copyWith(
      fontFamily: 'monospace',
      letterSpacing: 0.5,
      fontWeight: FontWeight.w700,
    );

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    InputDecoration dec({
      required String label,
      IconData? icon,
      Widget? suffix,
      String? helper,
    }) =>
        InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          prefixIcon: icon == null
              ? null
              : Icon(icon, size: 18, color: cs.onSurfaceVariant),
          suffixIcon: suffix,
          isDense: true,
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          enabledBorder: border(cs.outlineVariant.withValues(alpha: 0.5)),
          focusedBorder: border(cs.primary, width: 1.5),
          errorBorder: border(cs.error),
          focusedErrorBorder: border(cs.error, width: 1.5),
          disabledBorder: border(cs.outlineVariant.withValues(alpha: 0.25)),
        );

    Widget field({
      required TextEditingController controller,
      required String label,
      IconData? icon,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
      TextStyle? style,
      Widget? suffix,
      String? helper,
      bool enabled = true,
    }) {
      return TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: style ?? t.bodyMedium,
        decoration:
            dec(label: label, icon: icon, suffix: suffix, helper: helper),
        validator: validator,
      );
    }

    Future<void> copy(String value) async {
      await Clipboard.setData(ClipboardData(text: value));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.copiedToClipboard)));
    }

    Widget copyBtn(TextEditingController c) {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: c,
        builder: (_, v, __) {
          final val = v.text.trim();
          if (val.isEmpty) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.content_copy_outlined, size: 15),
            tooltip: MaterialLocalizations.of(context).copyButtonLabel,
            visualDensity: VisualDensity.compact,
            onPressed: () => copy(val),
          );
        },
      );
    }

    // ── Section card ──────────────────────────────────────────────────────────
    Widget sectionCard({
      required IconData icon,
      required String title,
      String? subtitle,
      Color? accent,
      required List<Widget> children,
    }) {
      final color = accent ?? cs.primary;
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: t.bodyMedium
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Logo section ──────────────────────────────────────────────────────────
    Widget logoSection() {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: controllers.logoUrl,
        builder: (_, v, __) {
          final url = v.text.trim();
          return sectionCard(
            icon: Icons.image_outlined,
            title: l.invoiceLogoTitle,
            subtitle: l.invoiceLogoSubtitle,
            accent: cs.tertiary,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: url.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: cs.onSurfaceVariant,
                                size: 26,
                              ),
                            )
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: cs.error,
                                  size: 22,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          url.isEmpty ? l.invoiceLogoEmpty : url,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall
                              .copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: logoBusy ? null : onPickLogo,
                              icon: logoBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 15,
                                    ),
                              label: Text(
                                l.invoiceLogoUploadCta,
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                              ),
                            ),
                            if (url.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: saving
                                    ? null
                                    : () => controllers.logoUrl.text = '',
                                icon: const Icon(Icons.delete_outline,
                                    size: 15),
                                label: Text(
                                  MaterialLocalizations.of(context)
                                      .deleteButtonTooltip,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  foregroundColor: cs.error,
                                  side: BorderSide(
                                    color: cs.error.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              field(
                controller: controllers.logoUrl,
                label: l.invoiceLogoUrlLabel,
                icon: Icons.link_outlined,
                keyboardType: TextInputType.url,
                suffix: copyBtn(controllers.logoUrl),
              ),
            ],
          );
        },
      );
    }

    // ── Billing details section ───────────────────────────────────────────────
    Widget billingSection() {
      return sectionCard(
        icon: Icons.apartment_outlined,
        title: l.billingDetails,
        subtitle: l.billingDetailsSubtitle,
        accent: cs.primary,
        children: [
          field(
            controller: controllers.legalName,
            label: l.billingLegalName,
            icon: Icons.badge_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
          ),
          field(
            controller: controllers.taxId,
            label: l.billingTaxId,
            icon: Icons.numbers_outlined,
            style: mono,
            suffix: copyBtn(controllers.taxId),
            helper: l.billingTaxIdHelper,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
          ),
        ],
      );
    }

    // ── Contact section ───────────────────────────────────────────────────────
    Widget contactSection() {
      return sectionCard(
        icon: Icons.contact_mail_outlined,
        title: l.contact,
        accent: cs.secondary,
        children: [
          field(
            controller: controllers.email,
            label: l.billingEmailLabel,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            suffix: copyBtn(controllers.email),
            validator: (v) {
              final txt = (v ?? '').trim();
              if (txt.isEmpty) return null;
              return isLikelyValidEmail(txt) ? null : l.invalidEmail;
            },
          ),
          field(
            controller: controllers.website,
            label: l.billingWebsite,
            icon: Icons.language_outlined,
            keyboardType: TextInputType.url,
            suffix: copyBtn(controllers.website),
            validator: (v) {
              final txt = (v ?? '').trim();
              if (txt.isEmpty) return null;
              final uri = Uri.tryParse(txt);
              final ok = (uri != null &&
                      (uri.hasScheme || uri.host.isNotEmpty)) ||
                  txt.contains('.');
              return ok ? null : l.invalidUrl;
            },
          ),
        ],
      );
    }

    // ── Address section ───────────────────────────────────────────────────────
    Widget addressSection() {
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final wide = constraints.maxWidth >= 440;
          return sectionCard(
            icon: Icons.place_outlined,
            title: l.billingAddress,
            children: [
              field(
                controller: controllers.street,
                label: l.addressStreet,
                icon: Icons.home_outlined,
              ),
              field(
                controller: controllers.extra,
                label: l.addressExtra,
              ),
              if (wide) ...[
                Row(children: [
                  Expanded(
                    child: field(
                        controller: controllers.city,
                        label: l.addressCity),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: field(
                        controller: controllers.province,
                        label: l.addressProvince),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    child: field(
                      controller: controllers.postal,
                      label: l.addressPostalCode,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: field(
                      controller: controllers.country,
                      label: l.addressCountry,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.fieldIsRequired
                          : null,
                    ),
                  ),
                ]),
              ] else ...[
                field(
                    controller: controllers.city, label: l.addressCity),
                field(
                    controller: controllers.province,
                    label: l.addressProvince),
                field(
                  controller: controllers.postal,
                  label: l.addressPostalCode,
                  keyboardType: TextInputType.number,
                ),
                field(
                  controller: controllers.country,
                  label: l.addressCountry,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fieldIsRequired
                      : null,
                ),
              ],
            ],
          );
        },
      );
    }

    // ── Preferences section ───────────────────────────────────────────────────
    Widget preferencesSection() {
      return sectionCard(
        icon: Icons.tune_outlined,
        title: l.preferencesSectionTitle,
        children: [
          field(
            controller: controllers.iban,
            label: l.billingIban,
            icon: Icons.account_balance_outlined,
            style: mono,
            suffix: copyBtn(controllers.iban),
            helper: l.billingIbanHelper,
          ),
          // Currency + VAT stepper
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: field(
                  controller: controllers.currency,
                  label: l.billingCurrency,
                  icon: Icons.currency_exchange_outlined,
                  helper: l.billingCurrencyHelper,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            visualDensity: VisualDensity.compact,
                            onPressed: saving
                                ? null
                                : () {
                                    final cur = num.tryParse(
                                            controllers.vatRate.text
                                                .trim()) ??
                                        21;
                                    controllers.vatRate.text =
                                        (cur - 1).clamp(0, 100).toString();
                                  },
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: controllers.vatRate,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              style: t.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                labelText: l.billingTaxRate,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                filled: false,
                                prefixIcon: Icon(Icons.percent,
                                    size: 14,
                                    color: cs.onSurfaceVariant),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 13),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            visualDensity: VisualDensity.compact,
                            onPressed: saving
                                ? null
                                : () {
                                    final cur = num.tryParse(
                                            controllers.vatRate.text
                                                .trim()) ??
                                        21;
                                    controllers.vatRate.text =
                                        (cur + 1).clamp(0, 100).toString();
                                  },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        l.billingTaxRateHelper,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          field(
            controller: controllers.language,
            label: l.billingLanguage,
            icon: Icons.translate_outlined,
            helper: l.billingLanguageHelper,
          ),
        ],
      );
    }

    // ── Responsive body ───────────────────────────────────────────────────────
    Widget buildBody() {
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final wide = constraints.maxWidth >= 620;
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                logoSection(),
                const SizedBox(height: 12),
                billingSection(),
                const SizedBox(height: 12),
                contactSection(),
                const SizedBox(height: 12),
                addressSection(),
                const SizedBox(height: 12),
                preferencesSection(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    logoSection(),
                    const SizedBox(height: 12),
                    billingSection(),
                    const SizedBox(height: 12),
                    addressSection(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    contactSection(),
                    const SizedBox(height: 12),
                    preferencesSection(),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    // ── Root ──────────────────────────────────────────────────────────────────
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.billingProfileTitle,
                        style: t.titleLarge
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                buildBody(),
              ],
            ),
          ),

          // ── Sticky save bar ────────────────────────────────────────────────
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
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: hasChanges
                          ? Row(
                              key: const ValueKey('dirty'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l.saveChanges,
                                  style: t.bodySmall.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(key: ValueKey('clean')),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: FilledButton.icon(
                        onPressed:
                            (!hasChanges || saving) ? null : onSave,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 16),
                        label: Text(saving ? l.saving : l.saveChanges),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
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
