part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoiceDownloadMenu extends StatelessWidget {
  const _InvoiceDownloadMenu({
    required this.count,
    required this.loading,
    this.onPdf,
    this.onExcel,
  });

  final int count;
  final bool loading;
  final VoidCallback? onPdf;
  final VoidCallback? onExcel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final enabled = count > 0 && !loading && (onPdf != null || onExcel != null);
    final label = isEs ? 'Descargar' : 'Download';
    final selectionLabel = isEs
        ? '$count ${count == 1 ? 'factura filtrada' : 'facturas filtradas'}'
        : '$count filtered ${count == 1 ? 'invoice' : 'invoices'}';

    Widget option(String title, String description, IconData icon, Color color,
            VoidCallback? onPressed) =>
        MenuItemButton(
          onPressed: enabled ? onPressed : null,
          leadingIcon: Icon(icon, size: 20, color: color),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );

    return MenuAnchor(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(selectionLabel,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const Divider(height: 1),
        option('PDF (ZIP)', isEs ? 'Un PDF por factura' : 'One PDF per invoice',
            Icons.picture_as_pdf_outlined, cs.error, onPdf),
        option('Excel', isEs ? 'Datos de las facturas' : 'Invoice data',
            Icons.table_view_outlined, cs.primary, onExcel),
      ],
      builder: (context, controller, child) => Tooltip(
        message: selectionLabel,
        child: OutlinedButton(
          onPressed: enabled
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.standard,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            backgroundColor: controller.isOpen
                ? cs.primaryContainer
                : cs.primary.withValues(alpha: 0.035),
            foregroundColor:
                controller.isOpen ? cs.onPrimaryContainer : cs.primary,
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.download_outlined, size: 16),
              const SizedBox(width: 6),
              Text(label),
              const SizedBox(width: 6),
              Icon(controller.isOpen ? Icons.expand_less : Icons.expand_more,
                  size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
