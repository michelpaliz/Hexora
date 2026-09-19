part of '../../widgets/group_invoices_invoices_view.dart';

extension _InvoiceListDialogs on _InvoicesTabListState {
  Future<void> _openPaymentSuggestionsDialog() async {
    await Future.wait([
      _loadUnlinkedInvoices(),
      _loadPaymentSuggestions(),
    ]);
    if (!mounted) return;

    final invoices = (_unlinkedInvoices ?? const <Invoice>[]).where((invoice) {
      final date = _invoiceDate(invoice);
      if (_fromDate != null &&
          (date == null || date.isBefore(_startOfDay(_fromDate!)))) {
        return false;
      }
      if (_toDate != null &&
          (date == null || date.isAfter(_endOfDay(_toDate!)))) {
        return false;
      }
      return true;
    }).toList();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final t = AppTypography.of(dialogContext);
        final isSpanish =
            Localizations.localeOf(dialogContext).languageCode == 'es';
        final size = MediaQuery.sizeOf(dialogContext);

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: size.width.clamp(0, 820).toDouble(),
            height: (size.height - 48).clamp(320, 680).toDouble(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSpanish ? 'Resolver vínculos' : 'Resolve links',
                              style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSpanish
                                  ? 'Revisa los pagos sugeridos para ${invoices.length} facturas no vinculadas.'
                                  : 'Review suggested payments for ${invoices.length} unlinked invoices.',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isSpanish ? 'Cerrar' : 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if ((_paymentSuggestionsError ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _paymentSuggestionsError!.trim(),
                      style: t.bodySmall.copyWith(color: cs.error),
                    ),
                  )
                else if (invoices.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        isSpanish
                            ? 'No hay facturas sin vincular en este periodo.'
                            : 'There are no unlinked invoices in this period.',
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final invoice = invoices[index];
                        final client = _resolveInvoiceClient(
                          invoice,
                          widget.clients,
                          AppLocalizations.of(dialogContext)!,
                        );
                        return Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  widget.onTap(invoice);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice.displayNumber(
                                                draftLabel: AppLocalizations.of(
                                                  dialogContext,
                                                )!
                                                    .statusDraft,
                                              ),
                                              style: t.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              client.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: t.bodySmall.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        size: 17,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _PaymentSuggestionStrip(
                                suggestion:
                                    _paymentSuggestionsByInvoiceId[invoice.id],
                                loading: false,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRecurringDraftDebugDialog(
    BuildContext context,
    Invoice invoice,
  ) async {
    final l = AppLocalizations.of(context)!;
    final seriesId = invoice.recurringSeriesId?.trim() ?? '';
    if (seriesId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta factura no tiene una recurrencia asociada.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final t = AppTypography.of(dialogContext);
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Row(
            children: [
              Icon(Icons.repeat_rounded, color: cs.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Revisar recurrencia del borrador',
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _recurringApi.list(groupId: widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'No se pudo cargar la regla de recurrencia.\n${snapshot.error}',
                    style: t.bodyMedium.copyWith(color: cs.error),
                  );
                }
                Map<String, dynamic>? series;
                final allSeries =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                for (final item in allSeries) {
                  if (_seriesIdOf(item) == seriesId) {
                    series = item;
                    break;
                  }
                }
                final rows = <({String label, String value})>[
                  (
                    label: 'Factura',
                    value: invoice.displayNumber(draftLabel: l.statusDraft),
                  ),
                  (label: 'Serie recurrente', value: seriesId),
                  if (series != null)
                    (label: 'Regla', value: _seriesLabel(series)),
                  if (series != null)
                    (
                      label: 'Cliente en la regla',
                      value: _seriesClientName(series, l),
                    ),
                  if (series != null &&
                      (series['status']?.toString().trim().isNotEmpty ?? false))
                    (
                      label: 'Estado',
                      value: series['status'].toString().trim(),
                    ),
                  if (series != null && _seriesFrequencyLabel(series) != null)
                    (
                      label: 'Frecuencia',
                      value: _seriesFrequencyLabel(series)!,
                    ),
                ];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Este borrador se ha generado con cliente desconocido. Revisa la regla de recurrencia asociada antes de emitirlo.',
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 138,
                              child: Text(
                                row.label,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.value,
                                style: t.bodyMedium.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (series == null)
                      Text(
                        'No se encontró la regla en el listado actual, pero la factura sigue vinculada a la serie indicada.',
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onOpenRecurringSeries?.call(seriesId);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir recurrencia'),
            ),
          ],
        );
      },
    );
  }
}
