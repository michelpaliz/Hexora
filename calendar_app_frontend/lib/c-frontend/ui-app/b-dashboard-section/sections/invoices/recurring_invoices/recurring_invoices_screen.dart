import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
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

  String _statusFilter = 'active';
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
      (s) => seriesId(s) == id,
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
        final rawClient = s['clientId'] ?? s['client']?['id'] ?? s['client']?['_id'];
        final clientId = rawClient is Map
            ? (rawClient[r'$oid'] ?? '').toString()
            : (rawClient ?? '').toString();
        if (clientId != _clientFilter) return false;
      }
      if (_dueSoonOnly) {
        final next = parseDate(s['nextRunAt']);
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
        final id = seriesId(_selectedSeries ?? const <String, dynamic>{});
        _openSeriesById(id);
      }
    } catch (_) {
      // ignore; list stays
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
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
      body = RecurringCreateWizard(
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
      body = RecurringDetailView(
        api: _api,
        series: _selectedSeries!,
        group: widget.group,
        clients: _clients,
        canManage: canManage,
        onBack: _backToList,
        onUpdated: _refreshSeries,
      );
    } else {
      body = RecurringSeriesListView(
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
        onPreviewSeries: (series) => previewSeries(context, series, _api),
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
        title: Text(l.recurringInvoicesTitle),
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
