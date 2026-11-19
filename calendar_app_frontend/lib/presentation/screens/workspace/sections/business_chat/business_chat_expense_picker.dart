import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/services/expenses/expenses_api.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BusinessChatExpenseSelection {
  const BusinessChatExpenseSelection({
    required this.id,
    required this.label,
    required this.fileName,
    required this.bytes,
  });

  final String id;
  final String label;
  final String fileName;
  final Uint8List bytes;
}

Future<BusinessChatExpenseSelection?> showBusinessChatExpensePicker(
  BuildContext context, {
  required String groupId,
}) =>
    showHexoraDialog<BusinessChatExpenseSelection>(
      context: context,
      builder: (_) => _BusinessChatExpensePicker(groupId: groupId),
    );

class _BusinessChatExpensePicker extends StatefulWidget {
  const _BusinessChatExpensePicker({required this.groupId});

  final String groupId;

  @override
  State<_BusinessChatExpensePicker> createState() =>
      _BusinessChatExpensePickerState();
}

class _BusinessChatExpensePickerState
    extends State<_BusinessChatExpensePicker> {
  final _api = ExpensesApi();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _downloadingId;
  Object? _error;

  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await _api.list(groupId: widget.groupId, size: 100);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String _value(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> _select(Map<String, dynamic> item) async {
    final id = _value(item, const ['id', '_id', 'expenseId']);
    if (id.isEmpty || _downloadingId != null) return;
    setState(() {
      _downloadingId = id;
      _error = null;
    });
    try {
      var url = _value(
        item,
        const ['fileUrl', 'fileURL', 'url', 'file', 'filePath'],
      );
      if (!url.startsWith('http')) {
        final file = await _api.fetchExpenseFile(id);
        url = (file['url'] ?? '').toString().trim();
      }
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        throw StateError(_es
            ? 'Este gasto no tiene un documento disponible.'
            : 'This expense has no available document.');
      }
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(_es
            ? 'No se pudo descargar el documento del gasto.'
            : 'Could not download the expense document.');
      }
      if (!mounted) return;
      final provider = _value(
        item,
        const ['providerName', 'vendorName', 'supplierName', 'merchantName'],
      );
      final number = _value(
        item,
        const ['invoiceNumber', 'documentNumber', 'reference', 'number'],
      );
      final label =
          [provider, number].where((part) => part.isNotEmpty).join(' · ');
      final pathName = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      final isImage =
          (response.headers['content-type'] ?? '').startsWith('image/');
      Navigator.of(context).pop(BusinessChatExpenseSelection(
        id: id,
        label: label.isEmpty ? (_es ? 'Gasto' : 'Expense') : label,
        fileName: pathName.contains('.')
            ? pathName
            : 'expense-$id.${isImage ? 'jpg' : 'pdf'}',
        bytes: response.bodyBytes,
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _downloadingId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _items.where((item) {
      if (query.isEmpty) return true;
      return item.values.join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
    return AlertDialog(
      title: Text(_es ? 'Compartir gasto' : 'Share expense'),
      content: SizedBox(
        width: 620,
        height: 480,
        child: Column(children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: _es ? 'Buscar gastos…' : 'Search expenses…',
              isDense: true,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? Center(
                        child: Text(_es
                            ? 'No hay gastos disponibles.'
                            : 'No expenses available.'),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = visible[index];
                          final id =
                              _value(item, const ['id', '_id', 'expenseId']);
                          final provider = _value(item, const [
                            'providerName',
                            'vendorName',
                            'supplierName',
                            'merchantName',
                          ]);
                          final number = _value(item, const [
                            'invoiceNumber',
                            'documentNumber',
                            'reference',
                          ]);
                          final rawTotal = item['total'] ?? item['amount'];
                          final total = rawTotal is num
                              ? NumberFormat.currency(
                                      locale: 'es_ES', symbol: '€')
                                  .format(rawTotal)
                              : '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(provider.isEmpty
                                ? (_es ? 'Gasto' : 'Expense')
                                : provider),
                            subtitle: Text([number, total]
                                .where((part) => part.isNotEmpty)
                                .join(' · ')),
                            trailing: _downloadingId == id
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: _downloadingId == null
                                ? () => _select(item)
                                : null,
                          );
                        },
                      ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_es ? 'Cancelar' : 'Cancel'),
        ),
      ],
    );
  }
}
