import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../input_border.dart';

class BillingLegalAndTax extends StatelessWidget {
  final AddClientController c;
  final bool requireBilling;
  final bool showValidation;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onFieldBlur;

  const BillingLegalAndTax({
    super.key,
    required this.c,
    required this.requireBilling,
    required this.showValidation,
    required this.onFieldChanged,
    required this.onFieldBlur,
  });

  Future<void> _separateEmbeddedPrefix(BuildContext context) async {
    final prefix = c.embeddedBillingPrefix;
    var remainingName = c.embeddedBillingRemainder ?? '';
    if (prefix == null || remainingName.isEmpty) return;
    final confirmedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Separar prefijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El nombre de facturación cambiará para los próximos documentos. Revisa que siga siendo legalmente correcto. Los documentos emitidos no cambiarán.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: remainingName,
              decoration: const InputDecoration(
                  labelText: 'Nombre de facturación sin prefijo'),
              onChanged: (value) => remainingName = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (remainingName.trim().isNotEmpty) {
                Navigator.pop(dialogContext, remainingName.trim());
              }
            },
            child: const Text('Separar'),
          ),
        ],
      ),
    );
    if (confirmedName == null || !context.mounted) return;
    c.billingLegalName.text = confirmedName;
    c.pdfPrefix.text =
        c.pdfPrefix.text.trim().isEmpty ? prefix : c.pdfPrefix.text.trim();
    onFieldChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('billingLegalName');
          },
          child: TextFormField(
            controller: c.billingLegalName,
            style: text.bodyLarge,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.billingLegalName,
              prefixIcon: const Icon(Icons.badge_outlined),
              isRequired: c.isBillingRequired('billingLegalName'),
              isFilled: c.billingLegalName.text.trim().isNotEmpty,
              showCheck: c.isBillingRequired('billingLegalName') &&
                  c.billingLegalName.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!requireBilling || !c.isBillingRequired('billingLegalName')) {
                return null;
              }
              if (!c.shouldShowError('billingLegalName', showValidation)) {
                return null;
              }
              return (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null;
            },
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c.pdfPrefix,
          style: text.bodyLarge,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          decoration: buildInputDecoration(
            context,
            label: 'Prefijo en PDF (opcional)',
            hintText: 'p. ej., Com. de Prop.',
            helperText:
                'Se muestra antes del nombre de facturación en los PDF.',
            prefixIcon: const Icon(Icons.short_text_outlined),
            isFilled: c.pdfPrefix.text.trim().isNotEmpty,
          ).copyWith(
            suffixIcon: c.pdfPrefix.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Quitar prefijo',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      c.pdfPrefix.clear();
                      onFieldChanged();
                    },
                  ),
          ),
          onChanged: (_) => onFieldChanged(),
        ),
        if (c.embeddedBillingPrefix case final embedded?) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'El nombre de facturación ya contiene “$embedded”. Sepáralo para poder editarlo o quitarlo sin repetirlo.',
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _separateEmbeddedPrefix(context),
              child: const Text('Separar prefijo del nombre'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: c.pdfAlias,
          style: text.bodyLarge,
          inputFormatters: [LengthLimitingTextInputFormatter(120)],
          decoration: buildInputDecoration(
            context,
            label: 'Alias para PDF (opcional)',
            hintText: 'p. ej., Las Alondras',
            helperText:
                'Nombre alternativo bajo el nombre de facturación, si es distinto.',
            prefixIcon: const Icon(Icons.picture_as_pdf_outlined),
            isFilled: c.pdfAlias.text.trim().isNotEmpty,
          ),
          onChanged: (_) => onFieldChanged(),
        ),
        if (c.pdfBillingNamePreview.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Así se verá en el PDF',
                    style:
                        text.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(c.pdfBillingNamePreview,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (c.pdfAliasPreview.isNotEmpty)
                  Text('Alias: ${c.pdfAliasPreview}',
                      style:
                          text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) onFieldBlur('billingTaxId');
          },
          child: TextFormField(
            controller: c.billingTaxId,
            style: text.bodyLarge,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: buildInputDecoration(
              context,
              label: l.billingTaxId,
              prefixIcon: const Icon(Icons.numbers),
              isRequired: c.isBillingRequired('billingTaxId'),
              isFilled: c.billingTaxId.text.trim().isNotEmpty,
              showCheck: c.isBillingRequired('billingTaxId') &&
                  c.billingTaxId.text.trim().isNotEmpty,
            ),
            onChanged: (_) => onFieldChanged(),
            validator: (v) {
              if (!requireBilling || !c.isBillingRequired('billingTaxId')) {
                return null;
              }
              if (!c.shouldShowError('billingTaxId', showValidation)) {
                return null;
              }
              return (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null;
            },
          ),
        ),
      ],
    );
  }
}
