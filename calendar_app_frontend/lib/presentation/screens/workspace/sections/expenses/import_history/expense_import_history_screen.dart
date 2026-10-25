import 'package:flutter/material.dart';
import 'package:hexora/services/expenses/expenses_api.dart';
import 'package:intl/intl.dart';

class ExpenseImportHistoryScreen extends StatefulWidget {
  const ExpenseImportHistoryScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<ExpenseImportHistoryScreen> createState() =>
      _ExpenseImportHistoryScreenState();
}

class _ExpenseImportHistoryScreenState
    extends State<ExpenseImportHistoryScreen> {
  final _api = ExpensesApi();
  final Map<String, Map<String, dynamic>> _details = {};
  final Set<String> _detailsLoading = {};
  final Map<String, String> _detailsErrors = {};
  List<Map<String, dynamic>> _jobs = const [];
  String? _error;
  bool _loading = true;
  int _page = 1;
  int _total = 0;
  int _requestVersion = 0;

  bool get _isEs => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExpenseImportHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId == widget.groupId) return;
    _page = 1;
    _total = 0;
    _jobs = const [];
    _details.clear();
    _detailsLoading.clear();
    _detailsErrors.clear();
    _load();
  }

  Future<void> _load() async {
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
      _details.clear();
      _detailsLoading.clear();
      _detailsErrors.clear();
    });
    try {
      final payload =
          await _api.listExpenseImportHistory(widget.groupId, page: _page);
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _jobs = (payload['jobs'] as List? ?? const [])
            .whereType<Map>()
            .map((job) => Map<String, dynamic>.from(job))
            .toList(growable: false);
        _total = (payload['total'] as num?)?.toInt() ?? 0;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadDetail(String jobId) async {
    if (_details.containsKey(jobId) || _detailsLoading.contains(jobId)) return;
    setState(() {
      _detailsLoading.add(jobId);
      _detailsErrors.remove(jobId);
    });
    final groupId = widget.groupId;
    final requestVersion = _requestVersion;
    try {
      final detail = await _api.getExpenseImportHistory(groupId, jobId);
      if (!mounted ||
          widget.groupId != groupId ||
          requestVersion != _requestVersion) {
        return;
      }
      setState(() => _details[jobId] = detail);
    } catch (error) {
      if (!mounted ||
          widget.groupId != groupId ||
          requestVersion != _requestVersion) {
        return;
      }
      setState(() => _detailsErrors[jobId] = error.toString());
    } finally {
      if (mounted &&
          widget.groupId == groupId &&
          requestVersion == _requestVersion) {
        setState(() => _detailsLoading.remove(jobId));
      }
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString());
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  String _status(String value) => switch (value) {
        'completed' => _isEs ? 'Analizado' : 'Analyzed',
        'processing' => _isEs ? 'Procesando' : 'Processing',
        'queued' || 'staging' => _isEs ? 'En cola' : 'Queued',
        'failed' => _isEs ? 'Error' : 'Failed',
        'expired' => _isEs ? 'Vista previa caducada' : 'Preview expired',
        'cancelled' => _isEs ? 'Cancelado' : 'Cancelled',
        _ => value,
      };

  String _fileStatus(String value) => switch (value) {
        'imported' => _isEs ? 'Importado' : 'Imported',
        'skipped' => _isEs ? 'Omitido' : 'Skipped',
        'ready' => _isEs ? 'Listo para revisión' : 'Ready for review',
        'needs_review' => _isEs ? 'Requiere revisión' : 'Needs review',
        'duplicate' => _isEs ? 'Duplicado' : 'Duplicate',
        'failed' => _isEs ? 'Error' : 'Failed',
        _ => value,
      };

  String _fileReason(String value) => switch (value) {
        'duplicate' || 'possible_duplicate' =>
          _isEs ? 'Posible duplicado' : 'Possible duplicate',
        'not_confirmed' => _isEs ? 'No seleccionado' : 'Not selected',
        'validation_error' => _isEs ? 'Datos no válidos' : 'Invalid data',
        'already_confirmed' =>
          _isEs ? 'Lote ya confirmado' : 'Batch already confirmed',
        _ => value.replaceAll('_', ' '),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = (_total / 20).ceil().clamp(1, 100000);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _isEs ? 'Historial de importaciones' : 'Import history',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                        _isEs
                            ? 'Lotes ZIP y documentos analizados por el negocio'
                            : 'ZIP and document batches analyzed by the business',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
            ),
            IconButton(
              tooltip: _isEs ? 'Actualizar' : 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ]),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_isEs
                      ? 'No se pudo cargar el historial'
                      : 'Could not load history'),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: _load,
                      child: Text(_isEs ? 'Reintentar' : 'Retry')),
                ]))
              : _jobs.isEmpty && !_loading
                  ? Center(
                      child: Text(_isEs
                          ? 'Todavía no hay lotes analizados'
                          : 'No analyzed batches yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: _jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _jobTile(_jobs[index], cs),
                    ),
        ),
        if (_total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Text(
                  '${_isEs ? "Página" : "Page"} $_page / $pages · $_total ${_isEs ? "lotes" : "batches"}',
                  style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              IconButton(
                tooltip: _isEs ? 'Anterior' : 'Previous',
                onPressed: _loading || _page <= 1
                    ? null
                    : () {
                        setState(() => _page--);
                        _load();
                      },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: _isEs ? 'Siguiente' : 'Next',
                onPressed: _loading || _page >= pages
                    ? null
                    : () {
                        setState(() => _page++);
                        _load();
                      },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
          ),
      ],
    );
  }

  Widget _jobTile(Map<String, dynamic> job, ColorScheme cs) {
    final id = (job['jobId'] ?? '').toString();
    final confirmation =
        job['confirmation'] is Map ? job['confirmation'] as Map : null;
    final uploader = job['uploadedBy'] is Map ? job['uploadedBy'] as Map : null;
    final title = (job['sourceArchiveName'] ?? '').toString().trim();
    final total = (job['totalFiles'] as num?)?.toInt() ?? 0;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: ExpansionTile(
        key: ValueKey('$id-$_requestVersion'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        onExpansionChanged: (expanded) {
          if (expanded) _loadDetail(id);
        },
        leading: Icon(
            job['sourceType'] == 'zip'
                ? Icons.folder_zip_outlined
                : Icons.description_outlined,
            color: cs.primary,
            size: 21),
        title: Text(
            title.isEmpty
                ? (_isEs ? 'Lote de documentos' : 'Document batch')
                : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${_date(job['createdAt'])} · ${uploader?['name'] ?? (_isEs ? "Usuario no disponible" : "User unavailable")} · $total ${_isEs ? "archivos" : "files"} · ${_status((job['displayStatus'] ?? job['status'] ?? '').toString())}${confirmation == null ? '' : ' · ${confirmation['importedCount']} ${_isEs ? "importados" : "imported"}, ${confirmation['skippedCount']} ${_isEs ? "omitidos" : "skipped"}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        children: [_detail(id, cs)],
      ),
    );
  }

  Widget _detail(String id, ColorScheme cs) {
    if (_detailsLoading.contains(id)) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (_detailsErrors.containsKey(id)) {
      return TextButton(
          onPressed: () => _loadDetail(id),
          child: Text(_isEs
              ? 'No se pudo cargar. Reintentar'
              : 'Could not load. Retry'));
    }
    final detail = _details[id];
    if (detail == null) return const SizedBox.shrink();
    final confirmation =
        detail['confirmation'] is Map ? detail['confirmation'] as Map : null;
    final files =
        (detail['files'] as List? ?? const []).whereType<Map>().toList();
    final confirmer = confirmation?['confirmedBy'] is Map
        ? confirmation!['confirmedBy'] as Map
        : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 8),
      Text(
          confirmation == null
              ? (_isEs
                  ? 'No consta una confirmación de importación para este lote.'
                  : 'No import confirmation was recorded for this batch.')
              : '${_isEs ? "Confirmado" : "Confirmed"}: ${_date(confirmation['confirmedAt'])}${confirmer?['name'] == null ? '' : ' · ${confirmer?['name']}'} · ${confirmation['importedCount']} ${_isEs ? "importados" : "imported"} · ${confirmation['skippedCount']} ${_isEs ? "omitidos" : "skipped"}',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      if (detail['previewExpiredAt'] != null)
        Text(
            _isEs
                ? 'La vista previa temporal ya no está disponible; el historial se conserva.'
                : 'The temporary preview expired; this history is retained.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      for (final file in files)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
                file['outcome'] == 'imported'
                    ? Icons.check_circle_outline
                    : Icons.insert_drive_file_outlined,
                size: 16,
                color: file['outcome'] == 'imported'
                    ? cs.primary
                    : cs.onSurfaceVariant),
            const SizedBox(width: 7),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      (file['originalPath'] ?? file['fileName'] ?? '')
                          .toString(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  if (file['vendorName'] != null ||
                      file['invoiceNumber'] != null)
                    Text(
                        [
                          if (file['vendorName'] != null)
                            file['vendorName'].toString(),
                          if (file['invoiceNumber'] != null)
                            file['invoiceNumber'].toString(),
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                  Text(
                      [
                        _fileStatus(
                            (file['outcome'] ?? file['previewStatus'] ?? '')
                                .toString()),
                        if (file['reason'] != null)
                          _fileReason(file['reason'].toString()),
                      ].where((part) => part.isNotEmpty).join(' · '),
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ])),
          ]),
        ),
    ]);
  }
}
