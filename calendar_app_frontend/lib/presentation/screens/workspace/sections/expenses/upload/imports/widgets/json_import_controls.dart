part of '../../expense_upload_screen.dart';

String _expenseImportHelpText(BuildContext context, String key) {
  final isSpanish = Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');
  final messages = <String, ({String es, String en})>{
    'jsonWorkflow': (
      es: 'Importa gastos desde un JSON: adjunta el JSON, la factura original y revisa los importes antes de guardar.',
      en: 'Import expenses from JSON: attach the JSON, the original invoice and review totals before saving.',
    ),
    'promptAi': (
      es: 'Genera una guia para que la IA devuelva el JSON con el formato esperado por Hexora.',
      en: 'Generate guidance so AI returns JSON in the format Hexora expects.',
    ),
    'jsonPayload': (
      es: 'Pega aqui el JSON del gasto. Si adjuntas un archivo JSON, se cargara automaticamente en este editor.',
      en: 'Paste the expense JSON here. If you attach a JSON file, it will load into this editor automatically.',
    ),
    'advanced': (
      es: 'Usa estas opciones solo si necesitas forzar proveedor, grupo, movimiento bancario o cliente concretos.',
      en: 'Use these options only when you need to force a specific provider, group, bank entry or client.',
    ),
    'expenseType': (
      es: 'Define como se tratara el gasto: estandar, anticipo o liquidacion contra un anticipo existente.',
      en: 'Define how the expense is handled: standard, advance payment or settlement against an existing advance.',
    ),
    'discount': (
      es: 'Aplica un descuento al documento completo. Puedes indicar importe o porcentaje; el otro valor se sincroniza.',
      en: 'Apply a discount to the whole document. Enter either amount or percentage; the other value stays in sync.',
    ),
    'totals': (
      es: 'Activa el resumen si quieres validar el total del documento contra los importes que aparecen en la factura.',
      en: 'Enable the summary when you want to validate document totals against the amounts shown on the invoice.',
    ),
  };
  final message = messages[key];
  if (message == null) return '';
  return isSpanish ? message.es : message.en;
}

class _ExpenseImportInfoButton extends StatelessWidget {
  final String message;

  const _ExpenseImportInfoButton({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primaryContainer.withValues(alpha: 0.42),
            border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
          ),
          child: Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _JsonFileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _JsonFileBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    final display = label.length > 28
        ? 'ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦${label.substring(label.length - 26)}'
        : label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            display,
            style: ts.bodySmall?.copyWith(
              fontSize: 11,
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _CompactOutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _CompactIconActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  const _CompactIconActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _JsonImportSummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _JsonImportSummaryRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvancedField extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final bool enabled;
  final String label;

  const _AdvancedField({
    required this.width,
    required this.controller,
    required this.enabled,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: _ExpenseImportTypeScale.fieldValue),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(fontSize: _ExpenseImportTypeScale.fieldLabel),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.34),
            ),
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.14),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.surface.withValues(alpha: 0.32),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
