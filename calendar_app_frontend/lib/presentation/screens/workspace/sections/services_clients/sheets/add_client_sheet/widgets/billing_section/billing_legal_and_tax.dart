import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../add_client_controller.dart';
import '../client_form_fields.dart';
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
    final confirmedName = await showHexoraDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Separar prefijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El nombre de facturación cambiará para los próximos documentos. '
              'Los documentos ya emitidos no cambiarán.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: remainingName,
              decoration: const InputDecoration(
                labelText: 'Nombre de facturación sin prefijo',
              ),
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
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Column(
      children: [
        ClientFormFields(
          first: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) onFieldBlur('billingLegalName');
            },
            child: TextFormField(
              controller: c.billingLegalName,
              style: text.bodyLarge,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: buildInputDecoration(
                context,
                label: isSpanish ? 'Nombre de facturación' : 'Billing name',
                hintText: isSpanish
                    ? 'Nombre legal del cliente'
                    : 'Customer legal name',
                prefixIcon: const Icon(Icons.badge_outlined),
                isRequired: c.isBillingRequired('billingLegalName'),
                isFilled: c.billingLegalName.text.trim().isNotEmpty,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => onFieldChanged(),
              validator: (value) {
                if (!requireBilling ||
                    !c.isBillingRequired('billingLegalName')) {
                  return null;
                }
                if (!c.shouldShowError('billingLegalName', showValidation)) {
                  return null;
                }
                return (value == null || value.trim().isEmpty)
                    ? l.fieldIsRequired
                    : null;
              },
            ),
          ),
          second: Focus(
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
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => onFieldChanged(),
              validator: (value) {
                if (!requireBilling || !c.isBillingRequired('billingTaxId')) {
                  return null;
                }
                if (!c.shouldShowError('billingTaxId', showValidation)) {
                  return null;
                }
                return (value == null || value.trim().isEmpty)
                    ? l.fieldIsRequired
                    : null;
              },
            ),
          ),
        ),
        // Subtle label separating "Identidad fiscal" above from the PDF
        // presentation fields below. Pure typography, no card wrapping.
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                (isSpanish ? 'Presentación en PDF' : 'PDF presentation')
                    .toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ClientFormFields(
          first: TextFormField(
            controller: c.pdfPrefix,
            style: text.bodyLarge,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: buildInputDecoration(
              context,
              label: isSpanish
                  ? 'Prefijo en PDF (opcional)'
                  : 'PDF prefix (optional)',
              hintText: isSpanish
                  ? 'p. ej., Com. de Prop.'
                  : 'e.g. Homeowners Assoc.',
              prefixIcon: const Icon(Icons.short_text_outlined),
              isFilled: c.pdfPrefix.text.trim().isNotEmpty,
            ).copyWith(
              suffixIcon: c.pdfPrefix.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: isSpanish ? 'Quitar prefijo' : 'Remove prefix',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        c.pdfPrefix.clear();
                        onFieldChanged();
                      },
                    ),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onFieldChanged(),
          ),
          second: TextFormField(
            controller: c.pdfAlias,
            style: text.bodyLarge,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            decoration: buildInputDecoration(
              context,
              label: isSpanish
                  ? 'Alias para PDF (opcional)'
                  : 'PDF alias (optional)',
              hintText: isSpanish ? 'p. ej., Las Alondras' : 'e.g. The Larks',
              prefixIcon: const Icon(Icons.picture_as_pdf_outlined),
              isFilled: c.pdfAlias.text.trim().isNotEmpty,
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onFieldChanged(),
          ),
        ),
        if (c.embeddedBillingPrefix case final embedded?) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish
                      ? 'El nombre ya contiene “$embedded”. Sepáralo para evitar duplicarlo.'
                      : 'The name already contains “$embedded”. Separate it to avoid duplication.',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => _separateEmbeddedPrefix(context),
                child: Text(isSpanish ? 'Separar' : 'Separate'),
              ),
            ],
          ),
        ],
        if (c.pdfBillingNamePreview.isNotEmpty) ...[
          const SizedBox(height: 6),
          // Compact inline preview, immediately below the PDF fields.
          DefaultTextStyle(
            style: text.bodySmall!.copyWith(color: cs.onSurfaceVariant),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSpanish ? 'Vista previa:' : 'Preview:',
                    style: text.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: c.pdfBillingNamePreview,
                            style: text.bodySmall?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (c.pdfAliasPreview.isNotEmpty)
                            TextSpan(
                              text: '  ·  ${c.pdfAliasPreview}',
                              style: text.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
