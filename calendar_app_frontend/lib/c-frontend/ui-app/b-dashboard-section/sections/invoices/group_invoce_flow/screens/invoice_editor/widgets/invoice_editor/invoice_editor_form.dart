import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/section_card.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'invoice_editor_form/form_widgets/client_monthly_stats.dart';
import 'invoice_editor_form/form_widgets/client_picker_field.dart';
import 'invoice_editor_form/form_widgets/customer_summary.dart';
import 'invoice_editor_form/form_widgets/dates_box.dart';

class InvoiceEditorForm extends StatefulWidget {
  final List<GroupClient> clients;
  final String? clientId;
  final ValueChanged<String?> onClientChanged;

  final TextEditingController currencyController;
  final ValueNotifier<DateTime?> invoiceDate;
  final ValueNotifier<DateTime?> dueDate;

  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;

  final int issuedThisMonthCount;
  final int pendingDraftsCount;
  final bool loadingClientStats;

  const InvoiceEditorForm({
    super.key,
    required this.clients,
    required this.clientId,
    required this.onClientChanged,
    required this.currencyController,
    required this.invoiceDate,
    required this.dueDate,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
    required this.issuedThisMonthCount,
    required this.pendingDraftsCount,
    required this.loadingClientStats,
  });

  @override
  State<InvoiceEditorForm> createState() => _InvoiceEditorFormState();
}

class InvoiceHeaderFields extends StatelessWidget {
  final List<GroupClient> clients;
  final String? clientId;
  final ValueChanged<String?> onClientChanged;
  final TextEditingController currencyController;
  final ValueNotifier<DateTime?> invoiceDate;
  final ValueNotifier<DateTime?> dueDate;
  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;
  final bool showClient;
  final bool showCurrency;
  final bool showDates;

  const InvoiceHeaderFields({
    super.key,
    required this.clients,
    required this.clientId,
    required this.onClientChanged,
    required this.currencyController,
    required this.invoiceDate,
    required this.dueDate,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
    this.showClient = true,
    this.showCurrency = true,
    this.showDates = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ValueListenableBuilder<DateTime?>(
      valueListenable: invoiceDate,
      builder: (_, invDate, __) => ValueListenableBuilder<DateTime?>(
        valueListenable: dueDate,
        builder: (_, due, __) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final dateBox = showDates
                  ? DatesBox(
                      invoiceDate: invDate,
                      dueDate: due,
                      onPickInvoiceDate: onPickInvoiceDate,
                      onPickDueDate: onPickDueDate,
                    )
                  : const SizedBox.shrink();

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showClient)
                      Expanded(
                        flex: 4,
                        child: ClientPickerField(
                          value: clientId,
                          labelText: l.invoiceClientLabel,
                          clients: clients,
                          onChanged: onClientChanged,
                          validator: (v) =>
                              v == null ? l.invoiceClientRequired : null,
                        ),
                      ),
                    if (showClient && showCurrency) const SizedBox(width: 10),
                    if (showCurrency)
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: currencyController,
                          decoration: InputDecoration(
                            labelText: l.currencyLabel,
                          ),
                        ),
                      ),
                    if ((showClient || showCurrency) && showDates)
                      const SizedBox(width: 12),
                    if (showDates) Expanded(flex: 3, child: dateBox),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showClient || showCurrency)
                    Row(
                      children: [
                        if (showClient)
                          Expanded(
                            child: ClientPickerField(
                              value: clientId,
                              labelText: l.invoiceClientLabel,
                              clients: clients,
                              onChanged: onClientChanged,
                              validator: (v) =>
                                  v == null ? l.invoiceClientRequired : null,
                            ),
                          ),
                        if (showClient && showCurrency)
                          const SizedBox(width: 10),
                        if (showCurrency)
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: currencyController,
                              decoration: InputDecoration(
                                labelText: l.currencyLabel,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (showDates) ...[
                    const SizedBox(height: 12),
                    dateBox,
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _InvoiceEditorFormState extends State<InvoiceEditorForm> {
  bool _showCustomerDetails = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        SectionCard(
          title: l.invoiceCustomerTitle,
          trailing: TextButton(
            onPressed: () =>
                setState(() => _showCustomerDetails = !_showCustomerDetails),
            child: Text(
              _showCustomerDetails
                  ? l.invoiceDetailsHideCta
                  : l.invoiceDetailsShowCta,
            ),
          ),
          child: ValueListenableBuilder<DateTime?>(
            valueListenable: widget.invoiceDate,
            builder: (_, invDate, __) => ValueListenableBuilder<DateTime?>(
              valueListenable: widget.dueDate,
              builder: (_, dueDate, __) {
                final selectedName = widget.clientId == null
                    ? l.invoiceSelectClientLabel
                    : widget.clients
                        .firstWhere(
                          (c) => c.id == widget.clientId,
                          orElse: () => GroupClient(
                            id: widget.clientId!,
                            name: l.invoiceSelectClientLabel,
                            isActive: true,
                          ),
                        )
                        .name;

                final currency = widget.currencyController.text.trim().isEmpty
                    ? 'EUR'
                    : widget.currencyController.text.trim();

                if (!_showCustomerDetails) {
                  return CustomerCollapsedSummary(
                    clientName: selectedName,
                    currency: currency,
                    invoiceDate: invDate,
                    dueDate: dueDate,
                    issuedCount: widget.issuedThisMonthCount,
                    pendingDrafts: widget.pendingDraftsCount,
                    loading: widget.loadingClientStats,
                    onExpand: () => setState(() => _showCustomerDetails = true),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: ClientPickerField(
                                  value: widget.clientId,
                                  labelText: l.invoiceClientLabel,
                                  clients: widget.clients,
                                  onChanged: widget.onClientChanged,
                                  validator: (v) => v == null
                                      ? l.invoiceClientRequired
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  controller: widget.currencyController,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  decoration: InputDecoration(
                                    labelText: l.currencyLabel,
                                    suffixIcon: const Icon(Icons.lock_outline),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DatesBox(
                            invoiceDate: invDate,
                            dueDate: dueDate,
                            onPickInvoiceDate: widget.onPickInvoiceDate,
                            onPickDueDate: widget.onPickDueDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClientMonthlyStatsBox(
                      issuedCount: widget.issuedThisMonthCount,
                      pendingDrafts: widget.pendingDraftsCount,
                      loading: widget.loadingClientStats,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
