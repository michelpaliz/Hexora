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
                final id = (provider['id'] ?? provider['_id'] ?? provider['providerId'])?.toString() ?? '';
                final name = provider['name']?.toString() ?? '-';
                final selected = id.isNotEmpty && id == state.selectedProviderId;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(id.isEmpty ? '-' : id, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      maxListHeight: stacked ? 160 : 240,
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
    final issued =
        invoices.where((i) => (i.status ?? '') == 'issued').toList();
    final drafts =
        invoices.where((i) => (i.status ?? '') != 'issued').toList();
    final totalSelected = state.selectedInvoiceIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Manual ID input
        TextField(
          controller: state.idController,
          onChanged: (_) => onStateChanged(),
          decoration: const InputDecoration(
            hintText: 'IDs separados por comas',
            prefixIcon: Icon(Icons.search_rounded, size: 18),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        // Selection count badge
        Row(
          children: [
            Text(
              'IDs de factura: $totalSelected',
              style: TextStyle(
                color: totalSelected > 0 ? cs.primary : cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: totalSelected > 0
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
            if (totalSelected > 0) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  state.selectedInvoiceIds.clear();
                  state.idController.clear();
                  onStateChanged();
                },
                child: Text(
                  'Limpiar',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.error,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
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
                ),
              ),
              if (drafts.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInvoiceColumn(
                    'Recibos',
                    drafts,
                    onStateChanged,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildInvoiceColumn(
    String title,
    List<Invoice> invoices,
    VoidCallback onStateChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        ...invoices.map((inv) => _buildInvoiceCheckRow(inv, onStateChanged)),
      ],
    );
  }

  Widget _buildInvoiceCheckRow(Invoice inv, VoidCallback onStateChanged) {
    final selected = state.selectedInvoiceIds.contains(inv.id);
    final displayNum =
        inv.invoiceNumber.trim().isEmpty ? inv.id : inv.invoiceNumber;
    final status = inv.status ?? 'draft';
    final shortId =
        inv.id.length > 22 ? '${inv.id.substring(0, 22)}…' : inv.id;

    return InkWell(
      onTap: () => state.toggleInvoiceSelection(inv.id, onStateChanged),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: selected,
                onChanged: (_) =>
                    state.toggleInvoiceSelection(inv.id, onStateChanged),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayNum,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$status · $shortId',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: l.preview,
              icon: Icon(Icons.visibility_outlined,
                  size: 16, color: cs.onSurfaceVariant),
              onPressed: () => _previewInvoice(inv),
            ),
          ],
        ),
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

    final docs =
        state.expenseCacheByProvider[providerId] ?? const <Map<String, dynamic>>[];

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
                  title: Text(title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
