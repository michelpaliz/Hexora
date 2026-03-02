import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../statements_controller.dart';

/// Dialog for uploading expense documents
class StatementsExpenseUploadDialog {
  static Future<void> show(
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
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
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
                              error = 'Proveedor, fecha y total son obligatorios';
                            });
                            return;
                          }
                          setState(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            final issueDate = DateTime.tryParse(issueDateController.text.trim());
                            final dueDate = DateTime.tryParse(dueDateController.text.trim());
                            if (issueDate == null) {
                              throw Exception('Fecha de emisión inválida');
                            }
                            await api.uploadExpense(
                              bytes: fileBytes!,
                              filename: fileName!,
                              vendorName: vendorController.text.trim(),
                              issueDate: issueDate.toIso8601String(),
                              total: totalController.text.trim(),
                              vendorTaxId: vendorTaxIdController.text.trim().isEmpty
                                  ? null
                                  : vendorTaxIdController.text.trim(),
                              invoiceNumber: invoiceNumberController.text.trim().isEmpty
                                  ? null
                                  : invoiceNumberController.text.trim(),
                              dueDate: dueDate == null ? null : dueDate.toIso8601String(),
                              taxTotal: taxTotalController.text.trim().isEmpty
                                  ? null
                                  : taxTotalController.text.trim(),
                              currency: currencyController.text.trim().isEmpty
                                  ? null
                                  : currencyController.text.trim(),
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              clientId: clientIdController.text.trim().isEmpty
                                  ? null
                                  : clientIdController.text.trim(),
                              statementEntryId: entryId,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gasto subido')),
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
