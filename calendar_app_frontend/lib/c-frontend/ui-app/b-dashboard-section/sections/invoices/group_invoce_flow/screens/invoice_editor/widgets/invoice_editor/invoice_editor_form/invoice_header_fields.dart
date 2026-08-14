import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'form_widgets/client_picker_field.dart';
import 'form_widgets/dates_box.dart';

class InvoiceHeaderFields extends StatelessWidget {
  final List<GroupClient> clients;
  final String? clientId;
  final ValueChanged<String?> onClientChanged;
  final TextEditingController currencyController;
  final ValueNotifier<DateTime?> invoiceDate;
  final ValueNotifier<DateTime?> dueDate;
  final VoidCallback onPickInvoiceDate;
  final VoidCallback onPickDueDate;
  final ValueChanged<String>? onCurrencyChanged;
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
    this.onCurrencyChanged,
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
                          onChanged: onCurrencyChanged,
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
                              onChanged: onCurrencyChanged,
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
