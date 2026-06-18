import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/vat_ocr_reprocess_job_store.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class ExpenseOcrReprocessResultsArgs {
  final Group? group;
  final String groupId;
  final String jobId;

  const ExpenseOcrReprocessResultsArgs({
    this.group,
    required this.groupId,
    required this.jobId,
  });
}

class ExpenseOcrReprocessResultsScreen extends StatefulWidget {
  const ExpenseOcrReprocessResultsScreen({
    super.key,
    required this.groupId,
    required this.jobId,
  });

  final String groupId;
  final String jobId;

  @override
  State<ExpenseOcrReprocessResultsScreen> createState() =>
      _ExpenseOcrReprocessResultsScreenState();
}

class _ExpenseOcrReprocessResultsScreenState
    extends State<ExpenseOcrReprocessResultsScreen> {
  final ExpensesApi _api = ExpensesApi();
  final Set<String> _selected = <String>{};
  Map<String, dynamic>? _job;
  bool _loading = true;
  bool _applying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final job = await _api.getExpenseOcrReprocessJob(
        jobId: widget.jobId,
        groupId: widget.groupId,
      );
      if (!mounted) return;
      final changed = _withSuggestions(job);
      setState(() {
        _job = job;
        _selected
          ..clear()
          ..addAll(changed.map(_expenseId).where((id) => id.isNotEmpty));
      });
      final status = (job['status'] ?? '').toString().toLowerCase();
      if (status == 'completed' || status == 'failed') {
        await VatOcrReprocessJobStore.clear(widget.groupId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudieron cargar los resultados OCR.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _results {
    final raw = _job?['results'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _withSuggestions(Map<String, dynamic>? job) {
    final raw = job?['results'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(_hasSuggestion)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _changed =>
      _results.where(_hasSuggestion).toList(growable: false);

  List<Map<String, dynamic>> get _failed => _results.where((item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return status == 'failed' || item['error'] != null;
      }).toList(growable: false);

  List<Map<String, dynamic>> get _noChanges => _results.where((item) {
        return !_hasSuggestion(item) &&
            !_failed.any((failed) => identical(failed, item));
      }).toList(growable: false);

  static Map<String, dynamic> _mapOf(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String _expenseId(Map<String, dynamic> item) =>
      (item['expenseId'] ?? item['id'] ?? '').toString().trim();

  static bool _hasSuggestion(Map<String, dynamic> item) {
    final suggested = _mapOf(item['suggested']);
    if (suggested.isEmpty) return false;
    final changes = item['changes'];
    return changes is List ? changes.isNotEmpty : true;
  }

  String _value(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      return value.toStringAsFixed(value.toDouble() % 1 == 0 ? 0 : 2);
    }
    if (value is List) return '${value.length} linea(s)';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Future<void> _applySelected() async {
    final items = _changed
        .where((item) => _selected.contains(_expenseId(item)))
        .map((item) => {
              'expenseId': _expenseId(item),
              'suggested': _mapOf(item['suggested']),
            })
        .where((item) =>
            (item['expenseId'] as String).isNotEmpty &&
            (item['suggested'] as Map).isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty || _applying) return;
    setState(() => _applying = true);
    try {
      await _api.applyExpenseOcrReprocessSuggestions(
        groupId: widget.groupId,
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios OCR aplicados.')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron aplicar los cambios.')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _markNoVat(String expenseId, bool confirmed) async {
    try {
      await _api.patchSuspicionReview(
        expenseId,
        status: confirmed ? 'confirmed_ok' : 'unreviewed',
        notes:
            confirmed ? 'Documento revisado: sin IVA / no sujeto a IVA.' : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmed ? 'Marcado como sin IVA.' : 'Revision reabierta.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la revision.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados OCR IVA 0')),
        body: Center(child: Text(_error!)),
      );
    }
    final job = _job ?? const <String, dynamic>{};
    final status = (job['status'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados OCR IVA 0'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(label: 'Estado', value: status, color: cs.primary),
                _SummaryChip(
                    label: 'Total',
                    value: '${job['total'] ?? 0}',
                    color: cs.primary),
                _SummaryChip(
                    label: 'Procesados',
                    value: '${job['processed'] ?? 0}',
                    color: cs.tertiary),
                _SummaryChip(
                    label: 'Sugerencias',
                    value: '${job['withSuggestions'] ?? _changed.length}',
                    color: const Color(0xFFD97706)),
                _SummaryChip(
                    label: 'Errores',
                    value: '${job['failed'] ?? _failed.length}',
                    color: cs.error),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  _section('Cambios sugeridos', _changed, cs, t, changed: true),
                  _section('Sin cambios', _noChanges, cs, t),
                  _section('Errores', _failed, cs, t, failed: true),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nada se aplica automaticamente. Selecciona las sugerencias que quieres guardar.',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _selected.isEmpty || _applying ? null : _applySelected,
                  icon: _applying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text('Aplicar ${_selected.length} cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    List<Map<String, dynamic>> items,
    ColorScheme cs,
    AppTypography t, {
    bool changed = false,
    bool failed = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items) _resultCard(item, cs, t, changed, failed),
        ],
      ),
    );
  }

  Widget _resultCard(
    Map<String, dynamic> item,
    ColorScheme cs,
    AppTypography t,
    bool changed,
    bool failed,
  ) {
    final id = _expenseId(item);
    final current = _mapOf(item['current']);
    final suggested = _mapOf(item['suggested']);
    final vendor =
        (suggested['vendorName'] ?? current['vendorName'] ?? id).toString();
    final fields = suggested.keys
        .where((key) => _value(suggested[key]) != _value(current[key]))
        .toList(growable: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: failed
            ? cs.error.withValues(alpha: 0.05)
            : changed
                ? cs.primary.withValues(alpha: 0.045)
                : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (changed)
                Checkbox(
                  value: _selected.contains(id),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                  }),
                ),
              Expanded(
                child: Text(
                  vendor,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _markNoVat(id, true),
                child: const Text('Marcar como sin IVA'),
              ),
            ],
          ),
          if (failed)
            Text(
              (item['message'] ??
                      item['error'] ??
                      'No se pudo releer la factura.')
                  .toString(),
              style: t.bodySmall.copyWith(color: cs.error),
            )
          else if (fields.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in fields.take(10))
                  Container(
                    width: 180,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(field,
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w800)),
                        Text(_value(current[field]),
                            style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough)),
                        Text(_value(suggested[field]),
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
              ],
            )
          else
            Text(
              'OCR no propuso cambios relevantes.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$label: $value',
        style: t.bodySmall.copyWith(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
