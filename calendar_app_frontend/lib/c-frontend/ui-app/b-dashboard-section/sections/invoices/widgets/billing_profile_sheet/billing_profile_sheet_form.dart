import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class BillingProfileControllers {
  final TextEditingController legalName;
  final TextEditingController taxId;
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
  final VoidCallback onSave;

  const BillingProfileSheetForm({
    super.key,
    required this.formKey,
    required this.controllers,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
    );

    Widget field({
      required TextEditingController controller,
      required String label,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        ),
        validator: validator,
      );
    }

    return Form(
      key: formKey,
      child: SingleChildScrollView(
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
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            field(
              controller: controllers.legalName,
              label: l.billingLegalName,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.taxId,
              label: l.billingTaxId,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.email,
              label: l.billingEmailLabel,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.website,
              label: l.billingWebsite,
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.iban,
              label: l.billingIban,
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.street,
              label: l.addressStreet,
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.extra,
              label: l.addressExtra,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: field(
                    controller: controllers.city,
                    label: l.addressCity,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: field(
                    controller: controllers.province,
                    label: l.addressProvince,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: field(
                    controller: controllers.postal,
                    label: l.addressPostalCode,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: field(
                    controller: controllers.country,
                    label: l.addressCountry,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: field(
                    controller: controllers.currency,
                    label: l.billingCurrency,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: field(
                    controller: controllers.vatRate,
                    label: l.billingTaxRate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            field(
              controller: controllers.language,
              label: l.billingLanguage,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
          ],
        ),
      ),
    );
  }
}
