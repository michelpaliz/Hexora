part of '../../mail_compose_screen.dart';

Widget _composeInvoiceOptions(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required InputDecoration inputDecoration}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: _CollapsedPanel(
        title: l.mailComposeInvoiceOptions,
        expanded: state._invoiceExpanded,
        onToggle: () => state
            .update(() => state._invoiceExpanded = !state._invoiceExpanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.mailComposeInvoiceOptionsHelper,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: state._invoiceIdsCtrl,
              enabled: !state._sending,
              style: t.bodySmall.copyWith(color: cs.onSurface),
              decoration: inputDecoration.copyWith(
                labelText: l.mailComposeInvoiceIdsLabel,
                hintText: l.mailComposeInvoiceIdsHint,
                helperText: l.mailComposeInvoiceIdsHint,
                prefixIcon: const Icon(Icons.receipt_long_outlined),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,\\s-]')),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: state._sending || state._openingInvoicePicker
                    ? null
                    : state._openInvoicePicker,
                icon: state._openingInvoicePicker
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(l.searchPerson),
              ),
            ),
            const SizedBox(height: 8),
            // Visual feedback for selected invoices
            Builder(
              builder: (context) {
                final invoiceIds = state
                    ._splitValues(
                        state._normalizeInvoiceIds(state._invoiceIdsCtrl.text))
                    .where((id) => id.trim().isNotEmpty)
                    .toList();

                if (invoiceIds.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 18,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${l.invoicesListTitle} PDF (${invoiceIds.length})',
                                  style: t.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              if (state._attachInvoicePdf)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'PDF adjunto',
                                        style: t.bodySmall.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: invoiceIds.map((id) {
                              return Chip(
                                label: Text(
                                  id,
                                  style: t.bodySmall,
                                ),
                                deleteIcon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                                onDeleted: () => state.update(() {
                                  final remaining = invoiceIds
                                      .where((existing) => existing != id)
                                      .toList();
                                  state._invoiceIdsCtrl.text =
                                      remaining.join(',');
                                }),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            if (state._selectedPresupuestoIds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l.budgetsMenuSection} PDF (${state._selectedPresupuestoIds.length})',
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (state._attachInvoicePdf)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'PDF adjunto',
                                  style: t.bodySmall.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state._selectedPresupuestoIds.map((id) {
                        return Chip(
                          label: Text(
                            id,
                            style: t.bodySmall,
                          ),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          onDeleted: () => state.update(() {
                            state._selectedPresupuestoIds.remove(id);
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Visual feedback for selected receipts
            if (state._selectedReceiptIds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 18,
                          color: cs.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recibos PDF (${state._selectedReceiptIds.length})',
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (state._attachInvoicePdf)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: cs.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'PDF adjunto',
                                  style: t.bodySmall.copyWith(
                                    color: cs.tertiary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: state._selectedReceiptIds.map((id) {
                        return Chip(
                          label: Text(
                            id,
                            style: t.bodySmall,
                          ),
                          deleteIcon: Icon(
                            Icons.close,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          onDeleted: () => state.update(() {
                            state._selectedReceiptIds.remove(id);
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            SwitchListTile.adaptive(
              value: state._attachInvoicePdf,
              title: Text(
                l.mailComposeAttachInvoicePdf,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              secondary: const Icon(Icons.picture_as_pdf_outlined),
              onChanged: state._sending
                  ? null
                  : (value) =>
                      state.update(() => state._attachInvoicePdf = value),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile.adaptive(
              value: state._includeInvoiceLinks,
              title: Text(
                l.mailComposeIncludeInvoiceLinks,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              secondary: const Icon(Icons.link_outlined),
              onChanged: state._sending
                  ? null
                  : (value) =>
                      state.update(() => state._includeInvoiceLinks = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              value: state._applyDefaultFooter,
              title: Text(
                l.mailComposeApplyFooterLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l.mailComposeApplyFooterHelper,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              secondary: const Icon(Icons.notes_outlined),
              onChanged: state._sending
                  ? null
                  : (value) =>
                      state.update(() => state._applyDefaultFooter = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
