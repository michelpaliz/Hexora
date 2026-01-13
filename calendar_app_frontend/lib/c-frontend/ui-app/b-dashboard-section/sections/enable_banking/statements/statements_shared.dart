import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'statements_controller.dart';

class StatementsShared {
  static String entryText(Map<String, dynamic> entry, List<String> keys) {
    for (final key in keys) {
      final v = entry[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String clientLabel(
    AppLocalizations l,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    final clientId = entry['clientId']?.toString();
    if (clientId == null || clientId.trim().isEmpty) return l.statementsUnlinked;
    final match = s.clients.firstWhere(
      (c) => c['id']?.toString() == clientId || c['_id']?.toString() == clientId,
      orElse: () => const <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      final name = match['name']?.toString().trim();
      final legal = (match['billing'] is Map)
          ? (match['billing'] as Map)['legalName']?.toString().trim()
          : null;
      if (name != null && name.isNotEmpty) return name;
      if (legal != null && legal.isNotEmpty) return legal;
    }
    return clientId;
  }

  static Future<void> showSuggestionsDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;
    final options = await s.suggestClients(entryId);
    if (!context.mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.statementsNoSuggestions)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l.statementsSuggestedClientsTitle),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final opt = options[i];
                final id = opt['_id']?.toString() ?? opt['id']?.toString() ?? '';
                final name = opt['name']?.toString() ?? l.statementsUnnamedClient;
                final legal = (opt['billing'] is Map)
                    ? (opt['billing'] as Map)['legalName']?.toString()
                    : null;
                return ListTile(
                  title: Text(name),
                  subtitle: Text(
                    [if (legal != null && legal.isNotEmpty) legal, if (id.isNotEmpty) id]
                        .where((v) => v.isNotEmpty)
                        .join(' • '),
                  ),
                  onTap: () async {
                    await s.linkClient(entryId: entryId, clientId: id.isEmpty ? null : id);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showClientPickerDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;
    await s.loadClients();
    if (!context.mounted) return;
    String query = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = s.clients.where((c) {
              final name = c['name']?.toString().toLowerCase() ?? '';
              final legal = (c['billing'] is Map)
                  ? (c['billing'] as Map)['legalName']?.toString().toLowerCase() ?? ''
                  : '';
              return query.isEmpty || name.contains(query) || legal.contains(query);
            }).toList();
            final l = AppLocalizations.of(dialogContext)!;
            return AlertDialog(
              title: Text(l.statementsLinkClientTitle),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l.statementsSearchClients,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    if (s.loadingClients)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (s.clientsError != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.clientsError!,
                          style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l.statementsNoClientsMatch),
                      )
                    else
                      SizedBox(
                        height: 280,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            final id = c['id']?.toString() ?? c['_id']?.toString() ?? '';
                            final name = c['name']?.toString() ?? l.statementsUnnamedClient;
                            final legal = (c['billing'] is Map)
                                ? (c['billing'] as Map)['legalName']?.toString()
                                : null;
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(
                                [if (legal != null && legal.isNotEmpty) legal, if (id.isNotEmpty) id]
                                    .where((v) => v.isNotEmpty)
                                    .join(' • '),
                              ),
                              onTap: () async {
                                await s.linkClient(entryId: entryId, clientId: id.isEmpty ? null : id);
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await s.linkClient(entryId: entryId, clientId: null);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(l.statementsClearLink),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> showInvoiceLinkDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry, {
    required bool expenseOnly,
  }) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;
    final currentId =
        (entry['invoiceId'] ?? entry['invoice_id'] ?? entry['invoice'])
            ?.toString();
    final controller = TextEditingController(text: currentId ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: const Text('Vincular factura'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l.documentTypeInvoice,
                hintText: 'ID de factura',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          actions: [
            if (expenseOnly)
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await showExpenseUploadDialog(
                    context,
                    s,
                    entryId: entryId,
                  );
                },
                child: const Text('Subir gasto'),
              ),
            TextButton(
              onPressed: () async {
                await s.linkInvoice(
                  entryId: entryId,
                  invoiceId: null,
                  expenseOnly: expenseOnly,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              },
              child: Text(l.statementsClearLink),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                await s.linkInvoice(
                  entryId: entryId,
                  invoiceId: value.isEmpty ? null : value,
                  expenseOnly: expenseOnly,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Vincular'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showExpenseUploadDialog(
    BuildContext context,
    StatementsController? s, {
    String? entryId,
  }) async {
    final api = ExpensesApi();
    final vendorController = TextEditingController();
    final issueDateController = TextEditingController();
    final totalController = TextEditingController();
    final vendorTaxIdController = TextEditingController();
    final invoiceNumberController = TextEditingController();
    final dueDateController = TextEditingController();
    final taxTotalController = TextEditingController();
    final currencyController = TextEditingController(text: 'EUR');
    final notesController = TextEditingController();
    final clientIdController = TextEditingController();
    String? fileName;
    List<int>? fileBytes;
    String? error;
    bool submitting = false;

    Future<void> pickFile(StateSetter setState) async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null) return;
      setState(() {
        fileName = file.name;
        fileBytes = file.bytes;
        error = null;
      });
    }

    Future<void> pickDate(
      StateSetter setState,
      TextEditingController controller,
    ) async {
      final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      );
      if (picked == null) return;
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Subir gasto'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fileName ?? 'Selecciona un archivo',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: submitting ? null : () => pickFile(setState),
                            child: const Text('Elegir archivo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: vendorController,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: issueDateController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha emisión',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () => pickDate(setState, issueDateController),
                            child: const Text('Fecha'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: totalController,
                        decoration: const InputDecoration(
                          labelText: 'Total',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: vendorTaxIdController,
                        decoration: const InputDecoration(
                          labelText: 'NIF proveedor',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número factura',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dueDateController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha vencimiento',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () => pickDate(setState, dueDateController),
                            child: const Text('Fecha'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: taxTotalController,
                              decoration: const InputDecoration(
                                labelText: 'IVA total',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: currencyController,
                              decoration: const InputDecoration(
                                labelText: 'Moneda',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: clientIdController,
                        decoration: InputDecoration(
                          labelText: l.statementsHeaderClient,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (fileBytes == null || fileName == null) {
                            setState(() {
                              error = 'Selecciona un archivo';
                            });
                            return;
                          }
                          if (vendorController.text.trim().isEmpty ||
                              issueDateController.text.trim().isEmpty ||
                              totalController.text.trim().isEmpty) {
                            setState(() {
                              error =
                                  'Proveedor, fecha y total son obligatorios';
                            });
                            return;
                          }
                          setState(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            final issueDate = DateTime.tryParse(
                                issueDateController.text.trim());
                            final dueDate = DateTime.tryParse(
                                dueDateController.text.trim());
                            if (issueDate == null) {
                              throw Exception('Fecha de emisión inválida');
                            }
                            await api.uploadExpense(
                              bytes: fileBytes!,
                              filename: fileName!,
                              vendorName: vendorController.text.trim(),
                              issueDate: issueDate.toIso8601String(),
                              total: totalController.text.trim(),
                              vendorTaxId:
                                  vendorTaxIdController.text.trim().isEmpty
                                      ? null
                                      : vendorTaxIdController.text.trim(),
                              invoiceNumber:
                                  invoiceNumberController.text.trim().isEmpty
                                      ? null
                                      : invoiceNumberController.text.trim(),
                              dueDate: dueDate == null
                                  ? null
                                  : dueDate.toIso8601String(),
                              taxTotal: taxTotalController.text.trim().isEmpty
                                  ? null
                                  : taxTotalController.text.trim(),
                              currency: currencyController.text.trim().isEmpty
                                  ? null
                                  : currencyController.text.trim(),
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              clientId:
                                  clientIdController.text.trim().isEmpty
                                      ? null
                                      : clientIdController.text.trim(),
                              statementEntryId: entryId,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gasto subido'),
                              ),
                            );
                            if (s != null) {
                              await s.loadAllEntries(page: s.allEntriesPage);
                            }
                          } catch (e) {
                            setState(() {
                              error = e.toString();
                            });
                          } finally {
                            if (dialogContext.mounted) {
                              setState(() => submitting = false);
                            }
                          }
                        },
                  child: const Text('Subir'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
