part of '../../widgets/group_invoices_invoices_view.dart';

class InvoiceToolbarOptionsMenu extends StatelessWidget {
  const InvoiceToolbarOptionsMenu({
    super.key,
    required this.count,
    required this.downloading,
    required this.availableColumns,
    required this.visibleColumns,
    required this.onColumnsChanged,
    required this.unlinkedOnly,
    required this.paymentSuggestionsLoading,
    this.toolbarOptions,
    this.onPdf,
    this.onExcel,
    this.onToggleUnlinked,
    this.onResolveLinks,
    this.compact = false,
  });

  final int count;
  final bool downloading;
  final Set<HexoraFinancialColumn> availableColumns;
  final Set<HexoraFinancialColumn> visibleColumns;
  final ValueChanged<Set<HexoraFinancialColumn>> onColumnsChanged;
  final bool unlinkedOnly;
  final bool paymentSuggestionsLoading;
  final InvoiceToolbarOptions? toolbarOptions;
  final VoidCallback? onPdf;
  final VoidCallback? onExcel;
  final VoidCallback? onToggleUnlinked;
  final VoidCallback? onResolveLinks;
  final bool compact;

  String _columnLabel(HexoraFinancialColumn column, bool isEs) =>
      switch (column) {
        HexoraFinancialColumn.date => isEs ? 'Fecha' : 'Date',
        HexoraFinancialColumn.taxableBase =>
          isEs ? 'Base imponible' : 'Taxable base',
        HexoraFinancialColumn.vat => isEs ? 'IVA' : 'VAT',
        HexoraFinancialColumn.total => 'Total',
        HexoraFinancialColumn.payment => isEs ? 'Pago' : 'Payment',
      };

  void _toggleColumn(HexoraFinancialColumn column) {
    final next = Set<HexoraFinancialColumn>.of(visibleColumns);
    if (!next.remove(column)) next.add(column);
    onColumnsChanged(next);
    unawaited(HexoraColumnVisibilityStore.save('facturas', next));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final canDownload =
        count > 0 && !downloading && (onPdf != null || onExcel != null);
    final recentCount = toolbarOptions?.recentExportsCount ?? 0;
    final menuChildren = <Widget>[
      if (toolbarOptions != null) ...[
        MenuItemButton(
          onPressed: toolbarOptions!.onOpenRecentExports,
          leadingIcon: const Icon(Icons.history_rounded, size: 18),
          trailingIcon: recentCount <= 0
              ? null
              : Container(
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$recentCount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          child: Text(isEs ? 'Recientes' : 'Recent exports'),
        ),
        MenuItemButton(
          onPressed: toolbarOptions!.onRefresh,
          leadingIcon: const Icon(Icons.refresh_rounded, size: 18),
          child: Text(isEs ? 'Actualizar' : 'Refresh'),
        ),
        const Divider(height: 1),
      ],
      SubmenuButton(
        leadingIcon: const Icon(Icons.view_column_outlined, size: 18),
        menuChildren: [
          for (final column in HexoraFinancialColumn.values)
            if (availableColumns.contains(column))
              MenuItemButton(
                onPressed: () => _toggleColumn(column),
                leadingIcon: Icon(
                  visibleColumns.contains(column)
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: visibleColumns.contains(column)
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                child: Text(_columnLabel(column, isEs)),
              ),
        ],
        child: Text(isEs ? 'Columnas' : 'Columns'),
      ),
      SubmenuButton(
        leadingIcon: downloading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined, size: 18),
        menuChildren: [
          MenuItemButton(
            onPressed: canDownload ? onPdf : null,
            leadingIcon:
                Icon(Icons.picture_as_pdf_outlined, size: 18, color: cs.error),
            child: const Text('PDF (ZIP)'),
          ),
          MenuItemButton(
            onPressed: canDownload ? onExcel : null,
            leadingIcon:
                Icon(Icons.table_view_outlined, size: 18, color: cs.primary),
            child: const Text('Excel'),
          ),
        ],
        child: Text(isEs ? 'Descargar' : 'Download'),
      ),
      if (onToggleUnlinked != null || onResolveLinks != null) ...[
        const Divider(height: 1),
        MenuItemButton(
          onPressed: onToggleUnlinked,
          leadingIcon: Icon(
            unlinkedOnly
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
            size: 18,
            color: unlinkedOnly ? cs.primary : cs.onSurfaceVariant,
          ),
          child: Text(isEs ? 'Facturas no vinculadas' : 'Unlinked invoices'),
        ),
        MenuItemButton(
          onPressed: paymentSuggestionsLoading ? null : onResolveLinks,
          leadingIcon: paymentSuggestionsLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high_rounded, size: 18),
          child: Text(
              isEs ? 'Resolver v\u00ednculos\u2026' : 'Resolve links\u2026'),
        ),
      ],
    ];

    return MenuAnchor(
      menuChildren: menuChildren,
      builder: (context, controller, child) => Tooltip(
        message: isEs ? 'Opciones de facturas' : 'Invoice options',
        child: compact
            ? IconButton(
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                style: IconButton.styleFrom(
                  fixedSize: const Size(34, 34),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor:
                      controller.isOpen ? cs.primary : cs.onSurfaceVariant,
                  backgroundColor: controller.isOpen
                      ? cs.primaryContainer.withValues(alpha: 0.45)
                      : cs.surface,
                  side: BorderSide(
                    color: controller.isOpen
                        ? cs.primary.withValues(alpha: 0.45)
                        : cs.outlineVariant.withValues(alpha: 0.55),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: Text(isEs ? 'Opciones' : 'Options'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  foregroundColor:
                      controller.isOpen ? cs.primary : cs.onSurfaceVariant,
                  backgroundColor: controller.isOpen
                      ? cs.primaryContainer.withValues(alpha: 0.45)
                      : cs.surface,
                  side: BorderSide(
                    color: controller.isOpen
                        ? cs.primary.withValues(alpha: 0.45)
                        : cs.outlineVariant.withValues(alpha: 0.55),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
      ),
    );
  }
}
