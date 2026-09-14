part of '../recent_uploads_tab.dart';

extension _RecentUploadsMobileSection on _ExpenseRecentUploadsTabState {
  Widget _buildMobileExpenseList(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    List<Map<String, String>> items,
  ) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(cs, isEs),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PopupMenuButton<int>(
                    tooltip:
                        isEs ? 'Filtrar por trimestre' : 'Filter by quarter',
                    initialValue: _selectedQuarterFilter ?? 0,
                    onSelected: (value) =>
                        _setQuarterFilter(value == 0 ? null : value),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 0, child: Text(isEs ? 'Todos' : 'All')),
                      for (var q = 1; q <= 4; q++)
                        PopupMenuItem(
                            value: q,
                            child:
                                Text('${isEs ? 'Trimestre' : 'Quarter'} $q')),
                    ],
                    child: Chip(
                      avatar: Icon(Icons.calendar_today_outlined,
                          size: 18, color: cs.primary),
                      label: Text(_selectedQuarterFilter == null
                          ? (isEs ? 'Todos' : 'All')
                          : '${isEs ? 'Trimestre' : 'Quarter'} $_selectedQuarterFilter'),
                    ),
                  ),
                  PopupMenuButton<_ExpenseListSortOption>(
                    tooltip: isEs ? 'Ordenar gastos' : 'Sort expenses',
                    initialValue: _selectedSort,
                    onSelected: _setSortOption,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: _ExpenseListSortOption.newest,
                          child: Text(isEs ? 'Más recientes' : 'Newest')),
                      PopupMenuItem(
                          value: _ExpenseListSortOption.oldest,
                          child: Text(isEs ? 'Más antiguos' : 'Oldest')),
                      PopupMenuItem(
                          value: _ExpenseListSortOption.amountHighToLow,
                          child:
                              Text(isEs ? 'Mayor importe' : 'Highest amount')),
                      PopupMenuItem(
                          value: _ExpenseListSortOption.amountLowToHigh,
                          child:
                              Text(isEs ? 'Menor importe' : 'Lowest amount')),
                      PopupMenuItem(
                          value: _ExpenseListSortOption.vendorAz,
                          child: Text(isEs ? 'Proveedor A–Z' : 'Vendor A–Z')),
                    ],
                    icon: const Icon(Icons.sort_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${items.length} ${isEs ? (items.length == 1 ? 'gasto' : 'gastos') : (items.length == 1 ? 'expense' : 'expenses')}',
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                isEs
                    ? 'No hay gastos que coincidan con la búsqueda o el trimestre.'
                    : 'No expenses match this search or quarter.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildMobileExpenseRow(items[index], l, t, cs, isEs),
            childCount: items.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildMobileExpenseRow(Map<String, String> item, AppLocalizations l,
      AppTypography t, ColorScheme cs, bool isEs) {
    final id = (item['id'] ?? '').trim();
    final vendor = [item['vendor'], item['providerName']]
            .whereType<String>()
            .where((v) => v.trim().isNotEmpty && v != '-')
            .firstOrNull ??
        (isEs ? 'Sin proveedor' : 'Unknown vendor');
    final amount = _formatAmountOrText(item['total'] ?? '');
    final currency = (item['currency'] ?? '').trim();
    final invoice = (item['invoice'] ?? '').trim();
    final date = _shortDate(item['date'] ?? '');
    final busy = _reprocessingExpenseIds.contains(id);
    final duplicate =
        _hasDuplicateInvoiceId(item) || _hasPotentialDuplicateSignature(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openExpenseEditor(item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 4, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(vendor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const SizedBox(height: 6),
                      Text(
                          [amount, currency]
                              .where((v) => v.isNotEmpty)
                              .join(' '),
                          style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800, color: cs.primary)),
                      const SizedBox(height: 6),
                      Text(
                          [date, if (invoice.isNotEmpty) '#$invoice']
                              .where((v) => v.isNotEmpty)
                              .join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                      if (duplicate || busy) ...[
                        const SizedBox(height: 6),
                        Text(
                            busy
                                ? (isEs
                                    ? 'Releyendo factura…'
                                    : 'Re-reading invoice…')
                                : (isEs
                                    ? 'Posible duplicado'
                                    : 'Possible duplicate'),
                            style: t.bodySmall
                                .copyWith(color: busy ? cs.primary : cs.error)),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: isEs ? 'Acciones del gasto' : 'Expense actions',
                  onSelected: (action) {
                    switch (action) {
                      case 'document':
                        _selectExpense(item);
                      case 'edit':
                        _openExpenseEditor(item);
                      case 'reprocess':
                        _reprocessExpense(item);
                      case 'delete':
                        widget.onDeleteExpense(id);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'document',
                        child: Text(isEs ? 'Ver documento' : 'View document')),
                    PopupMenuItem(value: 'edit', child: Text(l.edit)),
                    PopupMenuItem(
                        value: 'reprocess',
                        enabled: id.isNotEmpty && !busy,
                        child:
                            Text(isEs ? 'Releer factura' : 'Re-read invoice')),
                    PopupMenuItem(
                        value: 'delete',
                        enabled: id.isNotEmpty,
                        child:
                            Text(l.remove, style: TextStyle(color: cs.error))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
