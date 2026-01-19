import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/summary/summary_lines_and_totals.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _RecurringView { list, create, detail }

class RecurringInvoicesScreen extends StatefulWidget {
  final Group group;
  final bool embedded;
  final String? initialSeriesId;
  final VoidCallback? onSeriesOpened;

  const RecurringInvoicesScreen({
    super.key,
    required this.group,
    this.embedded = false,
    this.initialSeriesId,
    this.onSeriesOpened,
  });

  @override
  State<RecurringInvoicesScreen> createState() =>
      _RecurringInvoicesScreenState();
}

class _RecurringInvoicesScreenState extends State<RecurringInvoicesScreen> {
  final _api = RecurringInvoicesApi();
  final _clientsApi = ClientsApi();

  List<GroupClient> _clients = [];
  List<Map<String, dynamic>> _series = [];
  Map<String, dynamic>? _selectedSeries;

  _RecurringView _view = _RecurringView.list;
  bool _loading = true;
  String? _error;

  String _statusFilter = 'all';
  String? _clientFilter;
  bool _dueSoonOnly = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _clientsApi.list(groupId: widget.group.id, active: null),
        _api.list(groupId: widget.group.id),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<GroupClient>;
        _series = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
      if (widget.initialSeriesId != null) {
        _openSeriesById(widget.initialSeriesId!.trim());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openSeriesById(String id) {
    if (id.isEmpty) return;
    final match = _series.firstWhere(
      (s) => (s['id'] ?? s['_id'] ?? '').toString() == id,
      orElse: () => const <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      setState(() {
        _selectedSeries = match;
        _view = _RecurringView.detail;
      });
      widget.onSeriesOpened?.call();
    }
  }

  void _openSeries(Map<String, dynamic> series) {
    setState(() {
      _selectedSeries = series;
      _view = _RecurringView.detail;
    });
  }

  void _openCreate() => setState(() => _view = _RecurringView.create);

  void _backToList() => setState(() => _view = _RecurringView.list);

  List<Map<String, dynamic>> _filteredSeries() {
    return _series.where((s) {
      if (_statusFilter != 'all') {
        final status = (s['status'] ?? '').toString().toLowerCase();
        if (status != _statusFilter) return false;
      }
      if (_clientFilter != null && _clientFilter!.isNotEmpty) {
        final clientId = (s['clientId'] ?? '').toString();
        if (clientId != _clientFilter) return false;
      }
      if (_dueSoonOnly) {
        final next = _parseDate(s['nextRunAt']);
        if (next == null) return false;
        final now = DateTime.now();
        if (next.isAfter(now.add(const Duration(days: 7)))) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _refreshSeries() async {
    try {
      final items = await _api.list(groupId: widget.group.id);
      if (!mounted) return;
      setState(() => _series = items);
      if (_selectedSeries != null) {
        final id = (_selectedSeries?['id'] ?? _selectedSeries?['_id'] ?? '')
            .toString();
        _openSeriesById(id);
      }
    } catch (_) {
      // ignore; list stays
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final currentUserId = context.read<UserDomain?>()?.user?.id;
    final role =
        currentUserId == null ? null : widget.group.userRoles[currentUserId];
    final canManage = role == null ||
        role == 'owner' ||
        role == 'admin' ||
        role == 'co-admin';

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!, style: t.bodySmall));
    } else if (_view == _RecurringView.create) {
      body = _RecurringCreateWizard(
        group: widget.group,
        clients: _clients,
        api: _api,
        onCancel: _backToList,
        onCreated: (series) {
          setState(() {
            _series = [series, ..._series];
            _selectedSeries = series;
            _view = _RecurringView.detail;
          });
        },
      );
    } else if (_view == _RecurringView.detail && _selectedSeries != null) {
      body = _RecurringDetailView(
        group: widget.group,
        clients: _clients,
        api: _api,
        series: _selectedSeries!,
        canManage: canManage,
        onBack: _backToList,
        onUpdated: _refreshSeries,
      );
    } else {
      body = _RecurringSeriesListView(
        group: widget.group,
        series: _filteredSeries(),
        clients: _clients,
        canManage: canManage,
        statusFilter: _statusFilter,
        clientFilter: _clientFilter,
        dueSoonOnly: _dueSoonOnly,
        onStatusFilter: (v) => setState(() => _statusFilter = v),
        onClientFilter: (v) => setState(() => _clientFilter = v),
        onDueSoon: (v) => setState(() => _dueSoonOnly = v),
        onRefresh: _refreshSeries,
        onCreate: canManage ? _openCreate : () {},
        onOpenSeries: _openSeries,
        onPreviewSeries: (series) => _previewSeries(context, series, _api),
        onPauseSeries: canManage
            ? (series) => _updateSeriesStatus(series, 'paused')
            : null,
        onResumeSeries: canManage
            ? (series) => _updateSeriesStatus(series, 'active')
            : null,
        onCancelSeries: canManage ? (series) => _cancelSeries(series) : null,
      );
    }

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurrentes'),
      ),
      body: body,
    );
  }

  Future<void> _updateSeriesStatus(
    Map<String, dynamic> series,
    String status,
  ) async {
    final id = (series['id'] ?? series['_id'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      await _api.update(id, {'status': status});
      await _refreshSeries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _cancelSeries(Map<String, dynamic> series) async {
    final id = (series['id'] ?? series['_id'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      await _api.cancel(id);
      await _refreshSeries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _RecurringSeriesListView extends StatelessWidget {
  final Group group;
  final List<Map<String, dynamic>> series;
  final List<GroupClient> clients;
  final bool canManage;
  final String statusFilter;
  final String? clientFilter;
  final bool dueSoonOnly;
  final ValueChanged<String> onStatusFilter;
  final ValueChanged<String?> onClientFilter;
  final ValueChanged<bool> onDueSoon;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onOpenSeries;
  final ValueChanged<Map<String, dynamic>> onPreviewSeries;
  final ValueChanged<Map<String, dynamic>>? onPauseSeries;
  final ValueChanged<Map<String, dynamic>>? onResumeSeries;
  final ValueChanged<Map<String, dynamic>>? onCancelSeries;

  const _RecurringSeriesListView({
    required this.group,
    required this.series,
    required this.clients,
    required this.canManage,
    required this.statusFilter,
    required this.clientFilter,
    required this.dueSoonOnly,
    required this.onStatusFilter,
    required this.onClientFilter,
    required this.onDueSoon,
    required this.onRefresh,
    required this.onCreate,
    required this.onOpenSeries,
    required this.onPreviewSeries,
    required this.onPauseSeries,
    required this.onResumeSeries,
    required this.onCancelSeries,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recurrentes',
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: canManage ? onCreate : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear recurrencia'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _FilterDropdown(
                label: 'Estado',
                value: statusFilter,
                items: const ['all', 'active', 'paused', 'cancelled'],
                labels: const {
                  'all': 'Todos',
                  'active': 'Activas',
                  'paused': 'Pausadas',
                  'cancelled': 'Canceladas',
                },
                onChanged: onStatusFilter,
              ),
              _FilterDropdown(
                label: 'Cliente',
                value: clientFilter ?? '',
                items: [''].followedBy(clients.map((c) => c.id)).toList(),
                labels: {
                  '': 'Todos',
                  for (final c in clients) c.id: c.name,
                },
                onChanged: (v) => onClientFilter(v.isEmpty ? null : v),
              ),
              FilterChip(
                label: const Text('Vencen pronto'),
                selected: dueSoonOnly,
                onSelected: onDueSoon,
                selectedColor: cs.primaryContainer,
                checkmarkColor: cs.onPrimaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: series.isEmpty
                ? Center(
                    child: Text(
                      'No hay recurrencias todavía.',
                      style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    itemCount: series.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SeriesCard(
                      series: series[i],
                      onOpen: onOpenSeries,
                      onPreview: onPreviewSeries,
                      onPause: onPauseSeries,
                      onResume: onResumeSeries,
                      onCancel: onCancelSeries,
                      canManage: canManage,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String> labels;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(labels[v] ?? v, style: t.bodySmall),
                ))
            .toList(),
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final Map<String, dynamic> series;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<Map<String, dynamic>> onPreview;
  final ValueChanged<Map<String, dynamic>>? onPause;
  final ValueChanged<Map<String, dynamic>>? onResume;
  final ValueChanged<Map<String, dynamic>>? onCancel;
  final bool canManage;

  const _SeriesCard({
    required this.series,
    required this.onOpen,
    required this.onPreview,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final status = (series['status'] ?? 'active').toString().toLowerCase();
    final nextRun = _parseDate(series['nextRunAt']);
    final total = _seriesTotal(context, series);
    final schedule = _ruleSummary(series['rule'] as Map?);
    final clientName =
        (series['clientName'] ?? series['client']?['name'] ?? '-').toString();

    final statusLabel = status == 'paused'
        ? 'Pausada'
        : status == 'cancelled'
            ? 'Cancelada'
            : 'Activa';
    final statusColor = status == 'paused'
        ? cs.tertiaryContainer
        : status == 'cancelled'
            ? cs.errorContainer
            : cs.secondaryContainer;
    final statusText = status == 'paused'
        ? cs.onTertiaryContainer
        : status == 'cancelled'
            ? cs.onErrorContainer
            : cs.onSecondaryContainer;

    return Card(
      child: InkWell(
        onTap: () => onOpen(series),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: t.bodySmall.copyWith(
                        color: statusText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                schedule,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nextRun == null
                          ? 'Próxima: -'
                          : 'Próxima: ${DateFormat.yMMMd('es').add_Hm().format(nextRun)}',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    total,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onPreview(series),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: const Text('Ver próximas facturas'),
                  ),
                  if (status == 'active' && canManage)
                    TextButton.icon(
                      onPressed:
                          onPause == null ? null : () => onPause!(series),
                      icon: const Icon(Icons.pause_circle_outline),
                      label: const Text('Pausar'),
                    )
                  else if (status == 'paused' && canManage)
                    TextButton.icon(
                      onPressed:
                          onResume == null ? null : () => onResume!(series),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Reanudar'),
                    ),
                  if (canManage)
                    TextButton.icon(
                      onPressed:
                          onCancel == null ? null : () => onCancel!(series),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar recurrencia'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringCreateWizard extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final RecurringInvoicesApi api;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onCreated;

  const _RecurringCreateWizard({
    required this.group,
    required this.clients,
    required this.api,
    required this.onCancel,
    required this.onCreated,
  });

  @override
  State<_RecurringCreateWizard> createState() => _RecurringCreateWizardState();
}

class _RecurringCreateWizardState extends State<_RecurringCreateWizard> {
  int _step = 0;
  String? _clientId;
  final List<LineDraft> _lines = [LineDraft(position: 1)];

  String _freq = 'monthly';
  final TextEditingController _intervalCtrl = TextEditingController(text: '1');
  DateTime _startDate = DateTime.now();
  String _endType = 'never';
  DateTime? _endDate;
  final TextEditingController _countCtrl = TextEditingController();
  final TextEditingController _billDayCtrl = TextEditingController();
  final TextEditingController _timezoneCtrl =
      TextEditingController(text: 'Europe/Madrid');
  final List<DateTime> _exceptions = [];

  bool _loadingPreview = false;
  List<String> _previewDates = [];

  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) {
      _clientId = widget.clients.first.id;
    }
    _billDayCtrl.text = DateTime.now().day.toString();
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    _billDayCtrl.dispose();
    _timezoneCtrl.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  num _lineSubtotal(LineDraft line) {
    final qty = line.quantity ?? 1;
    final price = line.unitPrice ?? 0;
    return qty * price;
  }

  num _lineTax(LineDraft line) {
    final taxRate = line.taxRate ?? 21;
    return _lineSubtotal(line) * (taxRate / 100);
  }

  num get _subtotal => _lines.fold<num>(0, (sum, l) => sum + _lineSubtotal(l));
  num get _tax => _lines.fold<num>(0, (sum, l) => sum + _lineTax(l));
  num get _total => _subtotal + _tax;

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    setState(() => _endDate = date);
  }

  Future<void> _addException() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    setState(() => _exceptions.add(date));
  }

  Map<String, dynamic> _buildRule() {
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final billDay = int.tryParse(_billDayCtrl.text.trim());
    final count = int.tryParse(_countCtrl.text.trim());
    final rule = <String, dynamic>{
      'freq': _freq,
      'interval': interval,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
      'timezone': _timezoneCtrl.text.trim().isEmpty
          ? 'Europe/Madrid'
          : _timezoneCtrl.text.trim(),
    };
    if (_freq == 'monthly' && billDay != null) {
      rule['billDay'] = billDay;
    }
    if (_endType == 'date' && _endDate != null) {
      rule['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    } else if (_endType == 'count' && count != null) {
      rule['count'] = count;
    }
    if (_exceptions.isNotEmpty) {
      rule['exceptions'] =
          _exceptions.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    }
    return rule;
  }

  List<Map<String, dynamic>> _buildLines() {
    return _lines.map((line) {
      return {
        'position': line.position,
        'description': line.description.text.trim(),
        'quantity': line.quantity ?? 1,
        'unitPrice': line.unitPrice ?? 0,
        'taxRate': line.taxRate ?? 21,
      };
    }).toList();
  }

  Future<void> _loadPreview() async {
    if (_loadingPreview) return;
    setState(() => _loadingPreview = true);
    try {
      final payload = {
        'rule': _buildRule(),
      };
      final result = await widget.api.preview(payload);
      final items = result['dates'];
      final list = <String>[];
      if (items is List) {
        for (final item in items) {
          list.add(item.toString());
        }
      }
      if (mounted) setState(() => _previewDates = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (_clientId == null || _clientId!.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceClientRequired)));
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }
    final payload = {
      'groupId': widget.group.id,
      'clientId': _clientId,
      'status': 'active',
      'rule': _buildRule(),
      'lines': _buildLines(),
      'totals': {
        'subtotal': _subtotal,
        'taxTotal': _tax,
        'total': _total,
      },
    };
    try {
      final created = await widget.api.create(payload);
      if (!mounted) return;
      widget.onCreated(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget wrapStepContent(Widget child) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: child,
      );
    }

    final steps = [
      Step(
        title: const Text('Cliente'),
        content: wrapStepContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _clientId,
                decoration: const InputDecoration(
                  labelText: 'Cliente',
                  border: OutlineInputBorder(),
                ),
                items: widget.clients
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, style: t.bodySmall),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _clientId = v),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        isActive: _step >= 0,
      ),
      Step(
        title: const Text('Plantilla'),
        content: wrapStepContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InvoiceLinesEditor(lines: _lines, onChanged: _onChanged),
              const SizedBox(height: 12),
              InvoiceSummaryLinesAndTotals(
                lines: _lines,
                subtotal: _subtotal,
                tax: _tax,
                total: _total,
              ),
            ],
          ),
        ),
        isActive: _step >= 1,
      ),
      Step(
        title: const Text('Programación'),
        content: wrapStepContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _freq,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Diaria')),
                  DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                ],
                onChanged: (v) => setState(() => _freq = v ?? 'monthly'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _intervalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Intervalo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickStartDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  'Inicio: ${DateFormat.yMMMd('es').format(_startDate)}',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _endType,
                decoration: const InputDecoration(
                  labelText: 'Finalización',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'never', child: Text('Nunca')),
                  DropdownMenuItem(value: 'date', child: Text('Hasta fecha')),
                  DropdownMenuItem(
                      value: 'count', child: Text('Número de veces')),
                ],
                onChanged: (v) => setState(() => _endType = v ?? 'never'),
              ),
              if (_endType == 'date') ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(
                    _endDate == null
                        ? 'Seleccionar fecha'
                        : 'Hasta: ${DateFormat.yMMMd('es').format(_endDate!)}',
                  ),
                ),
              ],
              if (_endType == 'count') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de facturas',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_freq == 'monthly') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _billDayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Día de facturación (1-31)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Si el mes no tiene ese día, se usará el último día del mes.',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: _timezoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Zona horaria',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Excepciones',
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: _addException,
                    child: const Text('Añadir fecha'),
                  ),
                ],
              ),
              if (_exceptions.isEmpty)
                Text(
                  'Sin excepciones.',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _exceptions
                      .map(
                        (d) => Chip(
                          label: Text(DateFormat.yMMMd('es').format(d)),
                          onDeleted: () =>
                              setState(() => _exceptions.remove(d)),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        isActive: _step >= 2,
      ),
      Step(
        title: const Text('Preview'),
        content: wrapStepContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Los cambios solo afectarán a facturas futuras ya que las generadas son un snapshot.',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loadPreview,
                icon: _loadingPreview
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calendar_today_outlined),
                label: const Text('Ver próximas facturas'),
              ),
              const SizedBox(height: 10),
              if (_previewDates.isEmpty)
                Text(
                  'No hay fechas calculadas todavía.',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _previewDates
                      .take(12)
                      .map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $d', style: t.bodySmall),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        isActive: _step >= 3,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Crear recurrencia',
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancelar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stepper(
              currentStep: _step,
              onStepContinue: () {
                if (_step < steps.length - 1) {
                  setState(() => _step += 1);
                } else {
                  _submit();
                }
              },
              onStepCancel: () {
                if (_step == 0) {
                  widget.onCancel();
                } else {
                  setState(() => _step -= 1);
                }
              },
              controlsBuilder: (context, details) {
                final isLast = _step == steps.length - 1;
                return Row(
                  children: [
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: Text(isLast ? 'Crear recurrencia' : 'Continuar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(_step == 0 ? 'Volver' : 'Atrás'),
                    ),
                  ],
                );
              },
              steps: steps,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringDetailView extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final RecurringInvoicesApi api;
  final Map<String, dynamic> series;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onUpdated;

  const _RecurringDetailView({
    required this.group,
    required this.clients,
    required this.api,
    required this.series,
    required this.canManage,
    required this.onBack,
    required this.onUpdated,
  });

  @override
  State<_RecurringDetailView> createState() => _RecurringDetailViewState();
}

class _RecurringDetailViewState extends State<_RecurringDetailView> {
  late String _freq;
  late TextEditingController _intervalCtrl;
  late DateTime _startDate;
  late String _endType;
  DateTime? _endDate;
  late TextEditingController _countCtrl;
  late TextEditingController _billDayCtrl;
  late TextEditingController _timezoneCtrl;
  final List<DateTime> _exceptions = [];

  late List<LineDraft> _lines;

  bool _savingRule = false;
  bool _savingTemplate = false;

  @override
  void initState() {
    super.initState();
    final rule = (widget.series['rule'] as Map?) ?? const {};
    _freq = (rule['freq'] ?? 'monthly').toString();
    _intervalCtrl = TextEditingController(
      text: (rule['interval'] ?? 1).toString(),
    );
    _startDate = _parseDate(rule['startDate']) ?? DateTime.now();
    _timezoneCtrl = TextEditingController(
      text: (rule['timezone'] ?? 'Europe/Madrid').toString(),
    );
    _billDayCtrl = TextEditingController(
      text: (rule['billDay'] ?? DateTime.now().day).toString(),
    );
    _endDate = _parseDate(rule['endDate']);
    final count = rule['count'];
    _countCtrl = TextEditingController(text: count?.toString() ?? '');
    _endType = _endDate != null ? 'date' : (count != null ? 'count' : 'never');

    final exceptions = rule['exceptions'];
    if (exceptions is List) {
      for (final e in exceptions) {
        final d = _parseDate(e);
        if (d != null) _exceptions.add(d);
      }
    }

    _lines = _buildLineDrafts(widget.series);
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    _billDayCtrl.dispose();
    _timezoneCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildRule() {
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final billDay = int.tryParse(_billDayCtrl.text.trim());
    final count = int.tryParse(_countCtrl.text.trim());
    final rule = <String, dynamic>{
      'freq': _freq,
      'interval': interval,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
      'timezone': _timezoneCtrl.text.trim().isNotEmpty
          ? _timezoneCtrl.text.trim()
          : 'Europe/Madrid',
    };
    if (_freq == 'monthly' && billDay != null) {
      rule['billDay'] = billDay;
    }
    if (_endType == 'date' && _endDate != null) {
      rule['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    } else if (_endType == 'count' && count != null) {
      rule['count'] = count;
    }
    if (_exceptions.isNotEmpty) {
      rule['exceptions'] =
          _exceptions.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    }
    return rule;
  }

  Future<void> _saveRule() async {
    if (_savingRule) return;
    final id = (widget.series['id'] ?? widget.series['_id'] ?? '').toString();
    if (id.isEmpty) return;
    setState(() => _savingRule = true);
    try {
      await widget.api.update(id, {'rule': _buildRule()});
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingRule = false);
    }
  }

  Future<void> _saveTemplate() async {
    if (_savingTemplate) return;
    final id = (widget.series['id'] ?? widget.series['_id'] ?? '').toString();
    if (id.isEmpty) return;
    setState(() => _savingTemplate = true);
    final payload = {
      'lines': _lines
          .map((line) => {
                'position': line.position,
                'description': line.description.text.trim(),
                'quantity': line.quantity ?? 1,
                'unitPrice': line.unitPrice ?? 0,
                'taxRate': line.taxRate ?? 21,
              })
          .toList(),
      'totals': {
        'subtotal': _subtotal,
        'taxTotal': _tax,
        'total': _total,
      },
    };
    try {
      await widget.api.update(id, payload);
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  num _lineSubtotal(LineDraft line) {
    final qty = line.quantity ?? 1;
    final price = line.unitPrice ?? 0;
    return qty * price;
  }

  num _lineTax(LineDraft line) {
    final taxRate = line.taxRate ?? 21;
    return _lineSubtotal(line) * (taxRate / 100);
  }

  num get _subtotal => _lines.fold<num>(0, (sum, l) => sum + _lineSubtotal(l));
  num get _tax => _lines.fold<num>(0, (sum, l) => sum + _lineTax(l));
  num get _total => _subtotal + _tax;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final rule = widget.series['rule'] as Map?;
    final status = (widget.series['status'] ?? 'active').toString();
    final clientName =
        (widget.series['clientName'] ?? widget.series['client']?['name'] ?? '-')
            .toString();
    final nextRun = _parseDate(widget.series['nextRunAt']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  clientName,
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _SeriesStatusPill(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _ruleSummary(rule),
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            nextRun == null
                ? 'Próxima: -'
                : 'Próxima: ${DateFormat.yMMMd('es').add_Hm().format(nextRun)}',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    _previewSeries(context, widget.series, widget.api),
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Ver próximas facturas'),
              ),
              if (widget.canManage)
                TextButton.icon(
                  onPressed: status.toLowerCase() == 'paused'
                      ? () => widget.api.update(_seriesId(widget.series),
                          {'status': 'active'}).then((_) => widget.onUpdated())
                      : () => widget.api.update(_seriesId(widget.series),
                          {'status': 'paused'}).then((_) => widget.onUpdated()),
                  icon: Icon(
                    status.toLowerCase() == 'paused'
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                  label: Text(
                    status.toLowerCase() == 'paused' ? 'Reanudar' : 'Pausar',
                  ),
                ),
              if (widget.canManage)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await widget.api.cancel(_seriesId(widget.series));
                      widget.onUpdated();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar recurrencia'),
                ),
              if (widget.canManage)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final result = await widget.api.run();
                      if (!mounted) return;
                      final created = result['created']?.toString() ?? '0';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(created == '0'
                              ? 'No había facturas pendientes para generar.'
                              : 'Facturas generadas: $created'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('Ejecutar ahora'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Los cambios solo afectarán a facturas futuras ya que las generadas son un snapshot.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Regla'),
                      Tab(text: 'Plantilla'),
                      Tab(text: 'Generadas'),
                      Tab(text: 'Actividad'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ScheduleForm(
                                freq: _freq,
                                intervalCtrl: _intervalCtrl,
                                startDate: _startDate,
                                endType: _endType,
                                endDate: _endDate,
                                countCtrl: _countCtrl,
                                billDayCtrl: _billDayCtrl,
                                timezoneCtrl: _timezoneCtrl,
                                exceptions: _exceptions,
                                onFreqChanged: (v) => setState(() => _freq = v),
                                onPickStart: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(_startDate.year - 1),
                                    lastDate: DateTime(_startDate.year + 5),
                                  );
                                  if (date == null) return;
                                  setState(() => _startDate = date);
                                },
                                onPickEnd: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate ?? _startDate,
                                    firstDate: _startDate,
                                    lastDate: DateTime(_startDate.year + 5),
                                  );
                                  if (date == null) return;
                                  setState(() => _endDate = date);
                                },
                                onEndTypeChanged: (v) =>
                                    setState(() => _endType = v),
                                onAddException: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(_startDate.year - 1),
                                    lastDate: DateTime(_startDate.year + 5),
                                  );
                                  if (date == null) return;
                                  setState(() => _exceptions.add(date));
                                },
                                onRemoveException: (d) =>
                                    setState(() => _exceptions.remove(d)),
                              ),
                              const SizedBox(height: 12),
                              if (widget.canManage)
                                FilledButton(
                                  onPressed: _savingRule ? null : _saveRule,
                                  child: Text(
                                    _savingRule
                                        ? 'Guardando...'
                                        : 'Guardar regla',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InvoiceLinesEditor(
                                lines: _lines,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              InvoiceSummaryLinesAndTotals(
                                lines: _lines,
                                subtotal: _subtotal,
                                tax: _tax,
                                total: _total,
                              ),
                              const SizedBox(height: 12),
                              if (widget.canManage)
                                FilledButton(
                                  onPressed:
                                      _savingTemplate ? null : _saveTemplate,
                                  child: Text(
                                    _savingTemplate
                                        ? 'Guardando...'
                                        : 'Guardar plantilla',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            'Las facturas generadas aparecerán en Borradores.',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Actividad disponible próximamente.',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleForm extends StatelessWidget {
  final String freq;
  final TextEditingController intervalCtrl;
  final DateTime startDate;
  final String endType;
  final DateTime? endDate;
  final TextEditingController countCtrl;
  final TextEditingController billDayCtrl;
  final TextEditingController timezoneCtrl;
  final List<DateTime> exceptions;
  final ValueChanged<String> onFreqChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onEndTypeChanged;
  final VoidCallback onAddException;
  final ValueChanged<DateTime> onRemoveException;

  const _ScheduleForm({
    required this.freq,
    required this.intervalCtrl,
    required this.startDate,
    required this.endType,
    required this.endDate,
    required this.countCtrl,
    required this.billDayCtrl,
    required this.timezoneCtrl,
    required this.exceptions,
    required this.onFreqChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onEndTypeChanged,
    required this.onAddException,
    required this.onRemoveException,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: freq,
          decoration: const InputDecoration(
            labelText: 'Frecuencia',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('Diaria')),
            DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
            DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
            DropdownMenuItem(value: 'yearly', child: Text('Anual')),
          ],
          onChanged: (v) => onFreqChanged(v ?? 'monthly'),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: intervalCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Intervalo',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onPickStart,
          icon: const Icon(Icons.event_outlined),
          label: Text('Inicio: ${DateFormat.yMMMd('es').format(startDate)}'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: endType,
          decoration: const InputDecoration(
            labelText: 'Finalización',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'never', child: Text('Nunca')),
            DropdownMenuItem(value: 'date', child: Text('Hasta fecha')),
            DropdownMenuItem(value: 'count', child: Text('Número de veces')),
          ],
          onChanged: (v) => onEndTypeChanged(v ?? 'never'),
        ),
        if (endType == 'date') ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPickEnd,
            icon: const Icon(Icons.event_busy_outlined),
            label: Text(
              endDate == null
                  ? 'Seleccionar fecha'
                  : 'Hasta: ${DateFormat.yMMMd('es').format(endDate!)}',
            ),
          ),
        ],
        if (endType == 'count') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: countCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Número de facturas',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (freq == 'monthly') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: billDayCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Día de facturación (1-31)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Si el mes no tiene ese día, se usará el último día del mes.',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 10),
        TextFormField(
          controller: timezoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Zona horaria',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Excepciones',
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: onAddException,
              child: const Text('Añadir fecha'),
            ),
          ],
        ),
        if (exceptions.isEmpty)
          Text(
            'Sin excepciones.',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: exceptions
                .map(
                  (d) => Chip(
                    label: Text(DateFormat.yMMMd('es').format(d)),
                    onDeleted: () => onRemoveException(d),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _SeriesStatusPill extends StatelessWidget {
  final String status;

  const _SeriesStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final label = normalized == 'paused'
        ? 'Pausada'
        : normalized == 'cancelled'
            ? 'Cancelada'
            : 'Activa';
    final bg = normalized == 'paused'
        ? cs.tertiaryContainer
        : normalized == 'cancelled'
            ? cs.errorContainer
            : cs.secondaryContainer;
    final fg = normalized == 'paused'
        ? cs.onTertiaryContainer
        : normalized == 'cancelled'
            ? cs.onErrorContainer
            : cs.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _seriesId(Map<String, dynamic> series) =>
    (series['id'] ?? series['_id'] ?? '').toString();

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is Map && v[r'$date'] is num) {
    return DateTime.fromMillisecondsSinceEpoch((v[r'$date'] as num).toInt());
  }
  return null;
}

String _ruleSummary(Map? rule) {
  if (rule == null) return 'Sin programación';
  final freq = (rule['freq'] ?? 'monthly').toString();
  final interval = (rule['interval'] ?? 1).toString();
  final start = _parseDate(rule['startDate']);
  final startLabel =
      start == null ? '' : ' desde ${DateFormat.yMMMd('es').format(start)}';
  final billDay = rule['billDay'];
  String base;
  switch (freq) {
    case 'daily':
      base = interval == '1' ? 'Diaria' : 'Cada $interval días';
      break;
    case 'weekly':
      base = interval == '1' ? 'Semanal' : 'Cada $interval semanas';
      break;
    case 'yearly':
      base = interval == '1' ? 'Anual' : 'Cada $interval años';
      break;
    default:
      base = interval == '1' ? 'Mensual' : 'Cada $interval meses';
      if (billDay != null) base = '$base · día $billDay';
  }
  return '$base$startLabel';
}

String _seriesTotal(BuildContext context, Map<String, dynamic> series) {
  final l = AppLocalizations.of(context)!;
  final format = NumberFormat.currency(locale: l.localeName, symbol: '€');
  final totals = series['totals'];
  num? total;
  if (totals is Map && totals['total'] is num) {
    total = totals['total'] as num;
  } else if (series['grandTotal'] is num) {
    total = series['grandTotal'] as num;
  } else if (series['total'] is num) {
    total = series['total'] as num;
  }
  if (total == null) return format.format(0);
  return format.format(total);
}

List<LineDraft> _buildLineDrafts(Map<String, dynamic> series) {
  final raw = series['lines'] ?? series['templateLines'];
  if (raw is List) {
    int pos = 1;
    return raw.map((item) {
      if (item is! Map) {
        return LineDraft(position: pos++);
      }
      final line = LineDraft(position: pos++);
      line.description.text = (item['description'] ?? '').toString();
      line.quantityCtrl.text = (item['quantity'] ?? '1').toString();
      line.unitPriceCtrl.text = (item['unitPrice'] ?? '').toString();
      line.taxRateCtrl.text = (item['taxRate'] ?? '21').toString();
      return line;
    }).toList();
  }
  return [LineDraft(position: 1)];
}

Future<void> _previewSeries(
  BuildContext context,
  Map<String, dynamic> series,
  RecurringInvoicesApi api,
) async {
  final rule = series['rule'];
  if (rule is! Map) return;
  try {
    final result = await api.preview({'rule': rule});
    final dates =
        (result['dates'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Próximas facturas'),
        content: SizedBox(
          width: 320,
          child: dates.isEmpty
              ? const Text('No hay fechas calculadas.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dates
                      .take(12)
                      .map((d) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text('• $d'),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
