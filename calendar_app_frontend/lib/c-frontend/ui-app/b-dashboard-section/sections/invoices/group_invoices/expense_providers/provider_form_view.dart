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
    final isEditing = editingProviderId != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 520;
        final isWide = constraints.maxWidth >= 800;

        Widget input(
          TextEditingController controller,
          String label, {
          int maxLines = 1,
          IconData? icon,
          TextInputType? keyboardType,
        }) {
          return TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: cs.primary.withValues(alpha: 0.7), width: 1.5),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              prefixIcon: icon != null
                  ? Icon(icon, size: 15, color: cs.onSurfaceVariant.withValues(alpha: 0.6))
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

        Widget sectionLabel(String text, IconData icon) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          );
        }

        final formContent = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Form header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isEditing
                          ? cs.secondary.withValues(alpha: 0.12)
                          : cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_outlined
                          : Icons.add_business_outlined,
                      size: 16,
                      color: isEditing ? cs.secondary : cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing
                        ? l.expenseUploadEditProviderTitle
                        : l.expenseUploadNewProviderTitle,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Basic info ───────────────────────────────────────────────
              sectionLabel('DATOS BÁSICOS', Icons.person_outline_rounded),
              input(nameController, l.expenseUploadProviderNameLabel,
                  icon: Icons.business_outlined),
              const SizedBox(height: 8),
              row2(
                input(taxIdController, l.expenseUploadProviderTaxIdLabel,
                    icon: Icons.badge_outlined),
                input(emailController, l.expenseUploadProviderEmailLabel,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
              ),
              const SizedBox(height: 8),
              row2(
                input(phoneController, l.expenseUploadProviderPhoneLabel,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                input(countryController, l.expenseUploadProviderCountryLabel,
                    icon: Icons.flag_outlined),
              ),
              const SizedBox(height: 14),

              // ── Address ──────────────────────────────────────────────────
              sectionLabel('DIRECCIÓN', Icons.location_on_outlined),
              row2(
                input(streetController, l.expenseUploadProviderStreetLabel,
                    icon: Icons.signpost_outlined),
                input(extraController, l.expenseUploadProviderExtraLabel),
              ),
              const SizedBox(height: 8),
              row2(
                input(cityController, l.expenseUploadProviderCityLabel),
                input(provinceController, l.expenseUploadProviderProvinceLabel),
              ),
              const SizedBox(height: 8),
              twoCols
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: input(postalCodeController,
                              l.expenseUploadProviderPostalCodeLabel,
                              keyboardType: TextInputType.number),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: input(
                              notesController, l.expenseUploadNotesLabel,
                              maxLines: 2,
                              icon: Icons.notes_rounded),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        input(postalCodeController,
                            l.expenseUploadProviderPostalCodeLabel,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 8),
                        input(notesController, l.expenseUploadNotesLabel,
                            maxLines: 2, icon: Icons.notes_rounded),
                      ],
                    ),

              const SizedBox(height: 16),

              // ── Actions ──────────────────────────────────────────────────
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: savingProvider ? null : onSave,
                    icon: savingProvider
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isEditing
                                ? Icons.check_rounded
                                : Icons.save_outlined,
                            size: 15,
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isEditing ? cs.secondary : cs.primary,
                      foregroundColor:
                          isEditing ? cs.onSecondary : cs.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: Text(
                      isEditing
                          ? l.expenseUploadProviderUpdateCta
                          : l.expenseUploadProviderSaveCta,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: savingProvider ? null : onReset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l.expenseUploadProviderClearCta,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
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
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 12),
                child: _InfoPanel(cs: cs, t: t),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Info panel
// ---------------------------------------------------------------------------

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.cs, required this.t});

  final ColorScheme cs;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.info_outline,
                    size: 13, color: cs.primary),
              ),
              const SizedBox(width: 7),
              Text(
                'Acerca de los proveedores',
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoTip(
            icon: Icons.link_rounded,
            text:
                'Los proveedores se vinculan automáticamente a los gastos registrados por nombre o NIF.',
            cs: cs,
          ),
          const SizedBox(height: 8),
          _InfoTip(
            icon: Icons.badge_outlined,
            text:
                'El NIF es clave para identificar al proveedor en facturas de forma inequívoca.',
            cs: cs,
          ),
          const SizedBox(height: 8),
          _InfoTip(
            icon: Icons.bar_chart_rounded,
            text:
                'Desde el panel de detalle podrás ver el total facturado y todas las facturas asociadas.',
            cs: cs,
          ),
          const SizedBox(height: 8),
          _InfoTip(
            icon: Icons.edit_note_rounded,
            text:
                'Las notas son solo para uso interno y no aparecen en documentos exportados.',
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _InfoTip extends StatelessWidget {
  const _InfoTip({
    required this.icon,
    required this.text,
    required this.cs,
  });

  final IconData icon;
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 13,
            color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
