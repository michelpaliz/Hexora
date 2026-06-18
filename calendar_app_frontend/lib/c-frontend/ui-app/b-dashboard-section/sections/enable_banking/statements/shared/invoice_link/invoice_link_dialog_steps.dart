import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'invoice_link_dialog_state.dart';

/// Step widget builders for the invoice/expense link wizard
class InvoiceLinkDialogSteps {
  final InvoiceLinkDialogState state;
  final BuildContext context;
  final ColorScheme cs;
  final AppLocalizations l;
  final bool stacked;
  final String? groupId;
  final List<GroupClient> pickerClients;
  final InvoicesApi invoicesApi;
  final ExpensesApi expensesApi;

  InvoiceLinkDialogSteps({
    required this.state,
    required this.context,
    required this.cs,
    required this.l,
    required this.stacked,
    required this.groupId,
    required this.pickerClients,
    required this.invoicesApi,
    required this.expensesApi,
  });

  /// Step 0: Provider selector (for expenses)
  Widget buildProviderSelector(VoidCallback onStateChanged) {
    if (state.loadingProviders) {
      return _buildLoadingContainer();
    }
    if (state.providersError != null && state.providersError!.isNotEmpty) {
      return _buildErrorContainer(state.providersError!);
    }

    final filtered = state.providers.where((p) {
      final q = state.providerQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = p['name']?.toString().toLowerCase() ?? '';
      final tax = p['taxId']?.toString().toLowerCase() ?? '';
      return name.contains(q) || tax.contains(q);
    }).toList(growable: false);

    if (filtered.isEmpty) {
      return _buildInfoContainer('No hay proveedores.');
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _borderDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (value) {
              state.providerQuery = value;
              onStateChanged();
            },
            decoration: const InputDecoration(
              hintText: 'Buscar proveedor...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: stacked ? 130 : 190,
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, index) {
                final provider = filtered[index];
                final id = (provider['id'] ??
                            provider['_id'] ??
                            provider['providerId'])
                        ?.toString() ??
                    '';
                final name = provider['name']?.toString() ?? '-';
                final selected =
                    id.isNotEmpty && id == state.selectedProviderId;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  title:
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(id.isEmpty ? '-' : id,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => state.selectProvider(id, onStateChanged),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Step 0: Client selector (for invoices)
  Widget buildClientSelector(VoidCallback onStateChanged) {
    if (pickerClients.isEmpty) {
      return _buildInfoContainer(l.noClientsYet);
    }

    return ClientSearchSelect(
      clients: pickerClients,
      selectedClientId: state.selectedClientId,
      onClientChanged: (value) => state.selectClient(value, onStateChanged),
      useDefaultPropertyKind: false,
      maxListHeight: stacked ? 320 : 520,
    );
  }

  /// Step 1: Invoice selector
  Widget buildInvoiceSelector(VoidCallback onStateChanged) {
    final clientId = state.selectedClientId?.trim() ?? '';
    if (clientId.isEmpty) {
      return _buildInfoContainer('Selecciona un cliente para ver facturas.');
    }
    if (state.loadingInvoices) return _buildLoadingContainer();
    if (state.invoicesError != null && state.invoicesError!.isNotEmpty) {
      return _buildErrorContainer(state.invoicesError!);
    }

    final invoices = state.invoiceCacheByClient[clientId] ?? const <Invoice>[];
    final issued = invoices.where((i) => (i.status ?? '') == 'issued').toList();
    final drafts = invoices.where((i) => (i.status ?? '') != 'issued').toList();
    final totalSelected = state.selectedInvoiceIds.length;
    var clientName = '';
    for (final client in pickerClients) {
      if (client.id == clientId) {
        clientName = client.name.trim();
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxHeight.isFinite;
        final listHeight = bounded
            ? (constraints.maxHeight - 142).clamp(240.0, 560.0).toDouble()
            : (MediaQuery.of(context).size.height * (stacked ? 0.36 : 0.56))
                .clamp(240.0, stacked ? 360.0 : 560.0)
                .toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName.isEmpty
                                  ? 'Selecciona documentos'
                                  : clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              totalSelected == 0
                                  ? 'Elige una factura o recibo para vincular.'
                                  : '$totalSelected documento(s) seleccionado(s)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: totalSelected > 0
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (totalSelected > 0)
                        TextButton.icon(
                          onPressed: () {
                            state.selectedInvoiceIds.clear();
                            state.idController.clear();
                            onStateChanged();
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Limpiar'),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.error,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: state.idController,
                    onChanged: (_) => onStateChanged(),
                    decoration: InputDecoration(
                      hintText: 'IDs separados por comas',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary, width: 1.4),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Two-column layout
            if (invoices.isEmpty)
              _buildInfoContainer(l.noInvoicesYet)
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInvoiceColumn(
                      'IDs de factura',
                      issued.isNotEmpty ? issued : invoices,
                      onStateChanged,
                      listHeight: listHeight,
                    ),
                  ),
                  if (drafts.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInvoiceColumn(
                        'Recibos',
                        drafts,
                        onStateChanged,
                        listHeight: listHeight,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceColumn(
    String title,
    List<Invoice> invoices,
    VoidCallback onStateChanged, {
    required double listHeight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.26),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
            child: Row(
              children: [
                Icon(
                  title == 'Recibos'
                      ? Icons.request_quote_outlined
                      : Icons.receipt_long_outlined,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${invoices.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (_, index) =>
                  _buildInvoiceCheckRow(invoices[index], onStateChanged),
            ),
          ),
        ],
      ),
    );
  }

  String _invoiceStatusLabel(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'issued':
        return l.statusIssued;
      case 'draft':
        return l.statusDraft;
      case 'paid':
        return l.statusPaid;
      case 'cancelled':
      case 'canceled':
        return l.statusCancelled;
      default:
        final value = (raw ?? '').trim();
        return value.isEmpty ? l.statusDraft : value;
    }
  }

  String _invoiceAmountLabel(Invoice inv) {
    final formatted = inv.totalFormatted?.trim() ?? '';
    if (formatted.isNotEmpty) return formatted;
    final total = inv.total;
    if (total == null) return '';
    final parts = total.toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final left = whole.length - i;
      buffer.write(whole[i]);
      if (left > 1 && left % 3 == 1) buffer.write('.');
    }
    final currency = (inv.currency?.trim().isNotEmpty ?? false)
        ? inv.currency!.trim()
        : 'EUR';
    return '${buffer.toString()},${parts.last} $currency';
  }

  String _invoiceDateLabel(DateTime? date) {
    if (date == null) return '';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final hasTime = date.hour != 0 || date.minute != 0;
    return hasTime
        ? '${date.day}/${date.month}/${date.year} - $hh:$mm'
        : '${date.day}/${date.month}/${date.year}';
  }

  String _invoiceLinkLabel(Invoice inv) {
    final rawLabel = inv.linkStatusLabel?.trim() ?? '';
    if (rawLabel.isNotEmpty) return rawLabel;
    if (!inv.isLinkedResolved) return 'Sin vincular';
    final count = inv.linkedEntriesCountSafe;
    return count > 1 ? 'Vinculada ($count)' : 'Vinculada';
  }

  Widget _buildInvoiceCheckRow(Invoice inv, VoidCallback onStateChanged) {
    final selected = state.selectedInvoiceIds.contains(inv.id);
    final displayNum =
        inv.invoiceNumber.trim().isEmpty ? inv.id : inv.invoiceNumber;
    final status = _invoiceStatusLabel(inv.status);
    final linked = inv.isLinkedResolved;

    final clientName = inv.billingName?.trim().isNotEmpty == true
        ? inv.billingName!.trim()
        : (inv.clientSnapshot?.legalName?.trim() ?? '');
    final amount = _invoiceAmountLabel(inv);
    final issueDate = _invoiceDateLabel(inv.issueDate);

    return InkWell(
      onTap: () => state.toggleInvoiceSelection(inv.id, onStateChanged),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.16)
              : cs.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.56)
                : cs.outlineVariant.withValues(alpha: 0.24),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) =>
                  state.toggleInvoiceSelection(inv.id, onStateChanged),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayNum,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (amount.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          amount,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: selected ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _invoiceMetaChip(
                        icon: Icons.verified_outlined,
                        label: status,
                        selected: selected,
                      ),
                      _invoiceMetaChip(
                        icon: linked
                            ? Icons.link_rounded
                            : Icons.link_off_outlined,
                        label: _invoiceLinkLabel(inv),
                        selected: selected,
                        color: linked ? Colors.green : Colors.orange,
                      ),
                      if (issueDate.isNotEmpty)
                        _invoiceMetaChip(
                          icon: Icons.event_outlined,
                          label: issueDate,
                          selected: selected,
                        ),
                      if (clientName.isNotEmpty)
                        _invoiceMetaChip(
                          icon: Icons.person_outline,
                          label: clientName,
                          selected: selected,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              tooltip: l.preview,
              style: IconButton.styleFrom(
                backgroundColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.26),
                foregroundColor: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              onPressed: () => _previewInvoice(inv),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceMetaChip({
    required IconData icon,
    required String label,
    required bool selected,
    Color? color,
  }) {
    final effectiveColor =
        color ?? (selected ? cs.primary : cs.onSurfaceVariant);
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color != null
            ? color.withValues(alpha: selected ? 0.18 : 0.12)
            : selected
                ? cs.primary.withValues(alpha: 0.14)
                : cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color != null
              ? color.withValues(alpha: selected ? 0.34 : 0.24)
              : selected
                  ? cs.primary.withValues(alpha: 0.28)
                  : cs.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: effectiveColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: effectiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Expense selector
  Widget buildExpenseSelector(VoidCallback onStateChanged) {
    final providerId = state.selectedProviderId?.trim() ?? '';
    if (providerId.isEmpty) {
      return _buildInfoContainer('Selecciona un proveedor para ver gastos.');
    }
    if (state.loadingExpenses) return _buildLoadingContainer();
    if (state.expensesError != null && state.expensesError!.isNotEmpty) {
      return _buildErrorContainer(state.expensesError!);
    }

    final docs = state.expenseCacheByProvider[providerId] ??
        const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: state.idController,
          onChanged: (value) => state.updateTextField(value, onStateChanged),
          decoration: const InputDecoration(
            hintText: 'ID de gasto',
            prefixIcon: Icon(Icons.search_rounded, size: 18),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        if (docs.isEmpty)
          _buildInfoContainer('No hay gastos para este proveedor.')
        else
          Container(
            constraints: BoxConstraints(maxHeight: stacked ? 160 : 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, index) {
                final doc = docs[index];
                final id =
                    (doc['id'] ?? doc['_id'] ?? doc['expenseId'])?.toString() ??
                        '';
                final number = doc['invoiceNumber']?.toString().trim() ?? '';
                final title = number.isEmpty ? id : number;
                final subtitle =
                    '${doc['vendorName'] ?? doc['vendor'] ?? 'gasto'} · $id';
                final selected = state.idController.text.trim() == id;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  title:
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected ? cs.primary : cs.outlineVariant,
                  ),
                  trailing: IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: l.preview,
                    icon: Icon(Icons.visibility_outlined,
                        size: 16, color: cs.onSurfaceVariant),
                    onPressed: () => _previewExpense(doc),
                  ),
                  onTap: () => state.selectDocument(id, onStateChanged),
                );
              },
            ),
          ),
      ],
    );
  }

  // Helper methods
  BoxDecoration _borderDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _borderDecoration(),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.5)),
      ),
      child: Text(error, style: TextStyle(color: cs.error)),
    );
  }

  Widget _buildInfoContainer(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _borderDecoration(),
      child: Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }

  Future<void> _previewInvoice(Invoice inv) async {
    try {
      final r = await invoicesApi.previewPdf(inv.id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = inv.invoiceNumber.trim().isNotEmpty
          ? 'invoice-${inv.invoiceNumber.trim()}.pdf'
          : 'invoice-preview-${inv.id}.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.preview : msg)),
      );
    }
  }

  Future<void> _previewExpense(Map<String, dynamic> doc) async {
    final id = (doc['id'] ?? doc['_id'] ?? doc['expenseId'])?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      var fileUrl = (doc['fileUrl'] ?? doc['url'] ?? '').toString().trim();
      if (fileUrl.isEmpty) {
        final result = await expensesApi.fetchExpenseFile(id);
        if (!context.mounted) return;
        fileUrl = (result['url'] ?? '').toString().trim();
      }
      if (fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.preview} unavailable')),
        );
        return;
      }
      final uri = Uri.tryParse(fileUrl);
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.preview} unavailable')),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.preview : msg)),
      );
    }
  }
}
