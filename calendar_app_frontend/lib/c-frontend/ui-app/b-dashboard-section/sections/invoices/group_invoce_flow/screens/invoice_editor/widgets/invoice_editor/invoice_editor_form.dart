import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/lines_table_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
              final dateBox = _DatesBox(
                invoiceDate: invDate,
                dueDate: due,
                onPickInvoiceDate: onPickInvoiceDate,
                onPickDueDate: onPickDueDate,
              );

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _ClientPickerField(
                        value: clientId,
                        labelText: l.invoiceClientLabel,
                        clients: clients,
                        onChanged: onClientChanged,
                        validator: (v) =>
                            v == null ? l.invoiceClientRequired : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: currencyController,
                        readOnly: true,
                        enableInteractiveSelection: false,
                        decoration: InputDecoration(
                          labelText: l.currencyLabel,
                          suffixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: dateBox),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ClientPickerField(
                          value: clientId,
                          labelText: l.invoiceClientLabel,
                          clients: clients,
                          onChanged: onClientChanged,
                          validator: (v) =>
                              v == null ? l.invoiceClientRequired : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: currencyController,
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
                  const SizedBox(height: 12),
                  dateBox,
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
                  return _CustomerCollapsedSummary(
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
                                child: _ClientPickerField(
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
                          child: _DatesBox(
                            invoiceDate: invDate,
                            dueDate: dueDate,
                            onPickInvoiceDate: widget.onPickInvoiceDate,
                            onPickDueDate: widget.onPickDueDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ClientMonthlyStatsBox(
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

class InvoiceLinesSection extends StatelessWidget {
  final List<LineDraft> lines;
  final VoidCallback onLinesChanged;
  final num total;

  const InvoiceLinesSection({
    super.key,
    required this.lines,
    required this.onLinesChanged,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return SectionCard(
      title: l.invoiceLinesTitle,
      trailing: FilledButton.tonalIcon(
        onPressed: () {
          final nextPos = lines.length + 1;
          lines.add(LineDraft(position: nextPos));
          onLinesChanged();
        },
        icon: const Icon(Icons.add),
        label: Text(l.invoiceAddLine),
      ),
      child: Column(
        children: [
          LinesTableEditor(lines: lines, onChanged: onLinesChanged),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Text(
                l.invoiceTotalLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Text(
                NumberFormat.simpleCurrency(name: '').format(total),
                style: t.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatesBox extends StatelessWidget {
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;

  const _DatesBox({
    required this.invoiceDate,
    required this.dueDate,
    required this.onPickInvoiceDate,
    required this.onPickDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _DateMini(
              label: l.invoiceDateLabel,
              value: invoiceDate,
              onPick: onPickInvoiceDate,
            ),
          ),
          Container(
            width: 1,
            height: double.infinity,
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
          Expanded(
            child: _DateMini(
              label: l.invoiceDueDateLabel,
              value: dueDate,
              onPick: onPickDueDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateMini extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DateMini({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPick,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? DateFormat.yMMMd().format(value!) : '-',
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l.change,
                  style: t.bodySmall.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientPickerField extends FormField<String> {
  _ClientPickerField({
    required String? value,
    required String labelText,
    required List<GroupClient> clients,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (state) {
            final cs = Theme.of(state.context).colorScheme;
            final t = AppTypography.of(state.context);
            final l = AppLocalizations.of(state.context)!;

            final selected = clients.firstWhere(
              (c) => c.id == state.value,
              orElse: () => GroupClient(
                  id: '', name: l.invoiceSelectClientLabel, isActive: true),
            );

            Future<void> openPicker() async {
              final picked = await showModalBottomSheet<String>(
                context: state.context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (ctx) {
                  String query = '';
                  return StatefulBuilder(
                    builder: (ctx, setModalState) {
                      final filtered = query.trim().isEmpty
                          ? clients
                          : clients
                              .where((c) => c.name
                                  .toLowerCase()
                                  .contains(query.trim().toLowerCase()))
                              .toList();

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          MediaQuery.of(ctx).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.invoiceSelectClientLabel,
                                    style: t.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: l.invoiceClientSearchHint,
                              ),
                              onChanged: (v) => setModalState(() => query = v),
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 420),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final c = filtered[i];
                                  final selected = c.id == state.value;
                                  return ListTile(
                                    title: Text(c.name),
                                    subtitle: Text(
                                      c.email ?? (c.billing?.legalName ?? ''),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: selected
                                        ? Icon(Icons.check_circle,
                                            color: cs.primary)
                                        : null,
                                    onTap: () => Navigator.of(ctx).pop(c.id),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );

              if (picked == null) return;
              state.didChange(picked);
              onChanged(picked);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: openPicker,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: labelText,
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.expand_more),
                ),
                child: Text(
                  selected.id.isEmpty
                      ? l.invoiceSelectClientLabel
                      : selected.name,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            );
          },
        );
}

class _CurrencyPill extends StatelessWidget {
  final String currency;
  const _CurrencyPill({required this.currency});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        currency.toUpperCase(),
        style: t.bodySmall.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ClientMonthlyStatsBox extends StatelessWidget {
  final int issuedCount;
  final int pendingDrafts;
  final bool loading;

  const _ClientMonthlyStatsBox({
    required this.issuedCount,
    required this.pendingDrafts,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.invoiceClientInvoicesThisMonthLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (loading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    '$issuedCount',
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.invoicePendingDraftsLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingDrafts',
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCollapsedSummary extends StatelessWidget {
  final String clientName;
  final String currency;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final int issuedCount;
  final int pendingDrafts;
  final bool loading;
  final VoidCallback onExpand;

  const _CustomerCollapsedSummary({
    required this.clientName,
    required this.currency,
    required this.invoiceDate,
    required this.dueDate,
    required this.issuedCount,
    required this.pendingDrafts,
    required this.loading,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd();
    final inv = invoiceDate == null ? '-' : dateFmt.format(invoiceDate!);
    final due = dueDate == null ? '-' : dateFmt.format(dueDate!);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onExpand,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientName,
                          style: t.bodyMedium
                              .copyWith(fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CurrencyPill(currency: currency),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l.invoiceDateLabel}: $inv • ${l.invoiceDueDateLabel}: $due',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (loading)
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniPill(
                          label: l.invoiceClientInvoicesThisMonthLabel,
                          value: '$issuedCount',
                        ),
                        _MiniPill(
                          label: l.invoicePendingDraftsLabel,
                          value: '$pendingDrafts',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.unfold_more, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;
  const _MiniPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
