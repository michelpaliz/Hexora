import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ProviderFormView extends StatelessWidget {
  final String? editingProviderId;
  final bool savingProvider;
  final TextEditingController nameController;
  final TextEditingController taxIdController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final TextEditingController streetController;
  final TextEditingController extraController;
  final TextEditingController cityController;
  final TextEditingController provinceController;
  final TextEditingController postalCodeController;
  final TextEditingController countryController;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const ProviderFormView({
    super.key,
    required this.editingProviderId,
    required this.savingProvider,
    required this.nameController,
    required this.taxIdController,
    required this.emailController,
    required this.phoneController,
    required this.notesController,
    required this.streetController,
    required this.extraController,
    required this.cityController,
    required this.provinceController,
    required this.postalCodeController,
    required this.countryController,
    required this.onSave,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 520;
        final isWide = constraints.maxWidth >= 800;

        Widget input(
          TextEditingController controller,
          String label, {
          int maxLines = 1,
          IconData? icon,
        }) {
          return TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              prefixIcon: icon != null
                  ? Icon(icon, size: 16, color: cs.onSurfaceVariant)
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 36, minHeight: 0),
            ),
          );
        }

        Widget row2(Widget left, Widget right) {
          if (!twoCols) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, const SizedBox(height: 8), right],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 10),
              Expanded(child: right),
            ],
          );
        }

        final formContent = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editingProviderId == null
                    ? l.expenseUploadNewProviderTitle
                    : l.expenseUploadEditProviderTitle,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              input(nameController, l.expenseUploadProviderNameLabel,
                  icon: Icons.business_outlined),
              const SizedBox(height: 8),
              row2(
                input(taxIdController, l.expenseUploadProviderTaxIdLabel,
                    icon: Icons.badge_outlined),
                input(emailController, l.expenseUploadProviderEmailLabel,
                    icon: Icons.email_outlined),
              ),
              const SizedBox(height: 8),
              row2(
                input(phoneController, l.expenseUploadProviderPhoneLabel,
                    icon: Icons.phone_outlined),
                input(countryController, l.expenseUploadProviderCountryLabel,
                    icon: Icons.flag_outlined),
              ),
              const SizedBox(height: 8),
              row2(
                input(streetController, l.expenseUploadProviderStreetLabel,
                    icon: Icons.location_on_outlined),
                input(extraController, l.expenseUploadProviderExtraLabel),
              ),
              const SizedBox(height: 8),
              row2(
                input(cityController, l.expenseUploadProviderCityLabel),
                input(provinceController, l.expenseUploadProviderProvinceLabel),
              ),
              const SizedBox(height: 8),
              row2(
                input(
                    postalCodeController, l.expenseUploadProviderPostalCodeLabel),
                input(notesController, l.expenseUploadNotesLabel, maxLines: 2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: savingProvider ? null : onSave,
                    icon: savingProvider
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            editingProviderId == null
                                ? Icons.save_outlined
                                : Icons.check_outlined,
                            size: 16,
                          ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    label: Text(
                      editingProviderId == null
                          ? l.expenseUploadProviderSaveCta
                          : l.expenseUploadProviderUpdateCta,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: savingProvider ? null : onReset,
                    child: Text(
                      l.expenseUploadProviderClearCta,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        if (!isWide) return formContent;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: formContent),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Info',
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los proveedores se vinculan automáticamente a los gastos registrados.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
