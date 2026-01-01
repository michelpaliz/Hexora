import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_app_bar.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/summary_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceEditorScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;

  const InvoiceEditorScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
  });

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  late final InvoiceEditorController _c;

  @override
  void initState() {
    super.initState();
    _c = InvoiceEditorController(
      group: widget.group,
      clients: widget.clients,
      initialClientId: widget.initialClientId,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final l = AppLocalizations.of(context)!;
        GroupClient? selectedClient;
        if (_c.clientId != null && widget.clients.isNotEmpty) {
          selectedClient = widget.clients.firstWhere(
            (c) => c.id == _c.clientId,
            orElse: () => widget.clients.first,
          );
        }

        final canSave = !_c.saving;
        final canIssue =
            !_c.issuing && _c.clientId != null && _c.hasLines && _c.total > 0;

        final actionBar = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      (!canIssue || _c.issuing) ? null : () => _c.issue(context),
                  icon: _c.issuing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _c.issuing ? l.invoiceIssuingLabel : l.invoiceIssueCta,
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: (!canSave || _c.saving)
                      ? null
                      : () => _c.handleSaveDraft(context),
                  icon: _c.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_c.saving ? l.savingLabel : l.invoiceSaveDraftCta),
                ),
                IconButton(
                  tooltip: l.invoiceDraftInfoTooltip,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(l.invoiceDraftInfoTitle),
                        content: Text(
                          '${l.invoiceDraftInfoMessage}\n\n${l.invoicePendingDraftsLabel}: ${_c.pendingDraftsCount}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(MaterialLocalizations.of(context)
                                .okButtonLabel),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _c.previewPdf(context),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l.invoicePdfCta),
                ),
              ],
            ),
          ),
        );

        Widget buildSummary({required bool fillHeight}) {
          return ValueListenableBuilder<DateTime?>(
            valueListenable: _c.invoiceDate,
            builder: (_, invoiceDate, __) => ValueListenableBuilder<DateTime?>(
              valueListenable: _c.dueDate,
              builder: (_, dueDate, __) => InvoiceSummaryCard(
                invoiceNumber: _c.previewInvoiceNumber,
                issuerName: widget.group.name,
                client: selectedClient,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                notes: _c.notes.text,
                lines: _c.lines,
                savedInvoice: _c.savedInvoice,
                fillHeight: fillHeight,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: cs.surfaceContainerLowest,
          appBar: InvoiceEditorAppBar(
            titleStyle: t.titleLarge,
            saving: _c.saving,
            issuing: _c.issuing,
            onSaveDraft: () => _c.handleSaveDraft(context),
            onIssue: () => _c.issue(context),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
              final rightWidth = (constraints.maxWidth * 0.40).clamp(520.0, 640.0);

              final leftPanel = InvoiceEditorForm(
                formKey: _c.formKey,
                clients: widget.clients,
                clientId: _c.clientId,
                onClientChanged: _c.setClientId,
                currencyController: _c.currency,
                invoiceDate: _c.invoiceDate,
                dueDate: _c.dueDate,
                notesController: _c.notes,
                lines: _c.lines,
                onPickInvoiceDate: () => _c.pickDate(context, _c.invoiceDate),
                onPickDueDate: () => _c.pickDate(context, _c.dueDate),
                onLinesChanged: _c.notifyUi,
                issuedThisMonthCount: _c.issuedThisMonthCount,
                pendingDraftsCount: _c.pendingDraftsCount,
                loadingClientStats: _c.loadingClientStats,
              );

              if (wide) {
                final summary = buildSummary(fillHeight: true);
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(child: leftPanel),
                              ),
                              const SizedBox(height: 12),
                              actionBar,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: rightWidth,
                          child: SizedBox(height: double.infinity, child: summary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final summary = buildSummary(fillHeight: false);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    summary,
                    const SizedBox(height: 12),
                    actionBar,
                    const SizedBox(height: 12),
                    leftPanel,
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
