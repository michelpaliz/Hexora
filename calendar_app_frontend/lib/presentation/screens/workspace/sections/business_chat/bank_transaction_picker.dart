import 'package:flutter/material.dart';
import 'package:hexora/services/statements/models/statement_entries_page.dart';
import 'package:hexora/services/statements/statements_api.dart';
import 'package:intl/intl.dart';

/// Selects an existing transaction; sharing still requires confirmation.
enum BankTransactionPickerPresentation { dialog, sidePanel }

class BankTransactionPicker extends StatefulWidget {
  const BankTransactionPicker({
    super.key,
    required this.groupId,
    this.presentation = BankTransactionPickerPresentation.dialog,
    this.onSelected,
    this.onClose,
  });

  final String groupId;
  final BankTransactionPickerPresentation presentation;
  final ValueChanged<Map<String, dynamic>>? onSelected;
  final VoidCallback? onClose;

  @override
  State<BankTransactionPicker> createState() => _BankTransactionPickerState();
}

class _BankTransactionPickerState extends State<BankTransactionPicker> {
  final _api = StatementsApi();
  final _search = TextEditingController();
  final _partySearch = TextEditingController();
  late int _year;
  late int _quarter;
  List<StatementEntry> _entries = const [];
  int _page = 1;
  int _totalPages = 1;
  int _revision = 0;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _quarter = ((now.month - 1) ~/ 3) + 1;
    _load(1);
  }

  @override
  void dispose() {
    _revision++;
    _search.dispose();
    _partySearch.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.fetchStatementEntries(
        groupId: widget.groupId,
        page: page,
        size: 25,
        dateFrom: DateTime(_year, (_quarter - 1) * 3 + 1, 1),
        dateTo: DateTime(_year, _quarter * 3 + 1, 0),
        clientProviderQuery: _partySearch.text.trim(),
        descriptionSearch: _search.text.trim(),
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        _entries = result.items.where((entry) => entry.id.isNotEmpty).toList();
        _page = result.page;
        _totalPages = result.totalPages;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los movimientos. Inténtalo de nuevo.';
      });
    }
  }

  void _select(Map<String, dynamic> entry) {
    if (widget.onSelected != null) {
      widget.onSelected!(entry);
      return;
    }
    Navigator.of(context).pop(entry);
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _buildPanel(BuildContext context, bool es, ColorScheme cs) {
    Widget filters = LayoutBuilder(builder: (context, constraints) {
      final year = DropdownButtonFormField<int>(
        value: _year,
        isExpanded: true,
        decoration:
            InputDecoration(isDense: true, labelText: es ? 'Año' : 'Year'),
        items: List.generate(DateTime.now().year - 1999,
                (index) => DateTime.now().year - index)
            .map((value) =>
                DropdownMenuItem(value: value, child: Text('$value')))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            _year = value;
            _load(1);
          }
        },
      );
      final quarter = DropdownButtonFormField<int>(
        value: _quarter,
        isExpanded: true,
        decoration: InputDecoration(
            isDense: true, labelText: es ? 'Trimestre' : 'Quarter'),
        items: List.generate(4, (index) => index + 1)
            .map((value) => DropdownMenuItem(
                value: value, child: Text('${es ? 'T' : 'Q'}$value')))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            _quarter = value;
            _load(1);
          }
        },
      );
      final search = TextField(
        controller: _search,
        onSubmitted: (_) => _load(1),
        decoration: InputDecoration(
          isDense: true,
          labelText: es ? 'Buscar por concepto' : 'Search description',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: es ? 'Buscar' : 'Search',
            onPressed: _loading ? null : () => _load(1),
            icon: const Icon(Icons.arrow_forward),
          ),
        ),
      );
      if (constraints.maxWidth < 500) {
        return Column(children: [
          Row(children: [
            Expanded(child: year),
            const SizedBox(width: 8),
            Expanded(child: quarter),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _partySearch,
            onSubmitted: (_) => _load(1),
            decoration: InputDecoration(
              isDense: true,
              labelText: es ? 'Cliente o proveedor' : 'Client or provider',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          search,
        ]);
      }
      return Column(children: [
        Row(children: [
          SizedBox(width: 100, child: year),
          const SizedBox(width: 8),
          SizedBox(width: 108, child: quarter),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _partySearch,
              onSubmitted: (_) => _load(1),
              decoration: InputDecoration(
                isDense: true,
                labelText: es ? 'Cliente o proveedor' : 'Client or provider',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        search,
      ]);
    });
    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        child: Column(children: [
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: Text(
                      es ? 'Seleccionar movimiento' : 'Select transaction',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: es ? 'Cerrar' : 'Close',
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: filters,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, textAlign: TextAlign.center))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final raw = entry.raw;
                          final amount = double.tryParse(
                                  raw['amount']?.toString() ?? '') ??
                              0;
                          final date = DateTime.tryParse(
                              (raw['valueDate'] ?? raw['date'] ?? '')
                                  .toString());
                          final description =
                              (raw['description'] ?? '').toString();
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            title: Text(
                                description.isEmpty
                                    ? (es
                                        ? 'Movimiento bancario'
                                        : 'Bank transaction')
                                    : description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(date == null
                                ? ''
                                : DateFormat('dd/MM/yyyy').format(date)),
                            trailing: Text(
                              NumberFormat.currency(
                                      locale: es ? 'es_ES' : 'en_US',
                                      symbol: '€')
                                  .format(amount),
                              style: TextStyle(
                                  color: amount < 0 ? cs.error : cs.primary),
                            ),
                            onTap: () => _select(raw),
                          );
                        },
                      ),
          ),
          if (!_loading && _totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    onPressed: _page > 1 ? () => _load(_page - 1) : null,
                    icon: const Icon(Icons.chevron_left)),
                Text('$_page / $_totalPages'),
                IconButton(
                    onPressed:
                        _page < _totalPages ? () => _load(_page + 1) : null,
                    icon: const Icon(Icons.chevron_right)),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    if (widget.presentation == BankTransactionPickerPresentation.sidePanel) {
      return _buildPanel(context, es, cs);
    }
    return AlertDialog(
      title: Text(es ? 'Seleccionar movimiento' : 'Select transaction'),
      content: SizedBox(
        width: 520,
        height: 450,
        child: Column(children: [
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<int>(
              value: _year,
              decoration: InputDecoration(labelText: es ? 'Año' : 'Year'),
              items: List.generate(DateTime.now().year - 1999,
                      (i) => DateTime.now().year - i)
                  .map((year) =>
                      DropdownMenuItem(value: year, child: Text('$year')))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _year = value;
                  _load(1);
                }
              },
            )),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<int>(
              value: _quarter,
              decoration:
                  InputDecoration(labelText: es ? 'Trimestre' : 'Quarter'),
              items: List.generate(4, (i) => i + 1)
                  .map((quarter) => DropdownMenuItem(
                      value: quarter, child: Text('${es ? 'T' : 'Q'}$quarter')))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _quarter = value;
                  _load(1);
                }
              },
            )),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _partySearch,
            onSubmitted: (_) => _load(1),
            decoration: InputDecoration(
              isDense: true,
              labelText: es ? 'Cliente o proveedor' : 'Client or provider',
              suffixIcon: IconButton(
                  onPressed: () => _load(1), icon: const Icon(Icons.search)),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            onSubmitted: (_) => _load(1),
            decoration: InputDecoration(
              isDense: true,
              labelText: es ? 'Buscar por concepto' : 'Search description',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: es ? 'Buscar' : 'Search',
                onPressed: _loading ? null : () => _load(1),
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, textAlign: TextAlign.center))
                    : _entries.isEmpty
                        ? Center(
                            child: Text(es
                                ? 'No hay movimientos.'
                                : 'No transactions found.'))
                        : ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              final raw = entry.raw;
                              final amount = double.tryParse(
                                      raw['amount']?.toString() ?? '') ??
                                  0;
                              final date = DateTime.tryParse(
                                  (raw['valueDate'] ?? raw['date'] ?? '')
                                      .toString());
                              final description = (raw['description'] ?? '')
                                  .toString()
                                  .replaceAll(
                                    RegExp(
                                        r'\b[A-Z]{2}\d{2}(?:[ -]?[A-Z0-9]){11,30}\b',
                                        caseSensitive: false),
                                    '[cuenta oculta]',
                                  );
                              return ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                title: Text(
                                    description.isEmpty
                                        ? (es
                                            ? 'Movimiento bancario'
                                            : 'Bank transaction')
                                        : description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(date == null
                                    ? ''
                                    : DateFormat('dd/MM/yyyy').format(date)),
                                trailing: Text(
                                    NumberFormat.currency(
                                            locale: es ? 'es_ES' : 'en_US',
                                            symbol: '€')
                                        .format(amount),
                                    style: TextStyle(
                                        color: amount < 0
                                            ? cs.error
                                            : cs.primary)),
                                onTap: () => _select(raw),
                              );
                            },
                          ),
          ),
          if (!_loading && _totalPages > 1)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: _page > 1 ? () => _load(_page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page / $_totalPages'),
              IconButton(
                onPressed: _page < _totalPages ? () => _load(_page + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: _close,
          child: Text(es ? 'Cancelar' : 'Cancel'),
        ),
      ],
    );
  }
}
