import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/suspects/suspect_expenses_api.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/expense_ocr_reprocess_results_screen.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/vat_ocr_reprocess_job_store.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

class SuspectExpensesView extends StatefulWidget {
  final SuspectExpensesApi api;
  final String? groupId;
  final void Function(String expenseId) onEditExpense;

  const SuspectExpensesView({
    super.key,
    required this.api,
    required this.onEditExpense,
    this.groupId,
  });

  @override
  State<SuspectExpensesView> createState() => _SuspectExpensesViewState();
}

// ---------------------------------------------------------------------------
// Review status constants
// ---------------------------------------------------------------------------

class _ReviewStatus {
  static const String unreviewed = 'unreviewed';
  static const String confirmedOk = 'confirmed_ok';
  static const String needsFix = 'needs_fix';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _SuspectExpensesViewState extends State<SuspectExpensesView> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _response;

  /// null = all (omit reviewStatus param), otherwise a _ReviewStatus constant
  String? _reviewFilter = _ReviewStatus.unreviewed;

  /// IDs currently being patched
  final Set<String> _busyIds = {};

  /// IDs currently being deleted
  final Set<String> _deletingIds = {};

  /// Inline notes text per card (expenseId -> controller)
  final Map<String, TextEditingController> _noteControllers = {};

  /// Which cards have the notes field visible
  final Set<String> _notesVisible = {};

  /// The expense currently shown in the right preview panel (null = hidden)
  Map<String, dynamic>? _previewExpense;

  final ExpensesApi _expensesApi = ExpensesApi();
  final Set<String> _selectedVatOcrIds = <String>{};
  Map<String, dynamic>? _activeVatOcrJob;
  Timer? _vatOcrPollTimer;
  bool _startingVatOcr = false;

  @override
  void initState() {
    super.initState();
    _load();
    _resumeVatOcrJob();
  }

  @override
  void dispose() {
    _vatOcrPollTimer?.cancel();
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _resumeVatOcrJob() async {
    final groupId = (widget.groupId ?? '').trim();
    if (groupId.isEmpty) return;
    final ref = await VatOcrReprocessJobStore.read(groupId);
    if (!mounted || ref == null) return;
    setState(() {
      _activeVatOcrJob = {
        'jobId': ref.jobId,
        'groupId': ref.groupId,
        'status': 'queued',
        'processed': 0,
      };
    });
    _startVatOcrPolling(ref.jobId);
  }

  Future<void> _startVatOcrForSelection() async {
    final groupId = (widget.groupId ?? '').trim();
    final ids = _selectedVatOcrIds.where((id) => id.isNotEmpty).toList();
    if (groupId.isEmpty || ids.isEmpty || _startingVatOcr) return;
    setState(() => _startingVatOcr = true);
    try {
      final job = await _expensesApi.startBulkExpenseOcrReprocess(
        groupId: groupId,
        expenseIds: ids,
        reason: 'zero_vat_review',
        apply: false,
      );
      final jobId = (job['jobId'] ?? '').toString().trim();
      if (jobId.isEmpty) throw StateError('Missing jobId');
      await VatOcrReprocessJobStore.save(
        VatOcrReprocessJobRef(
          jobId: jobId,
          groupId: groupId,
          startedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _activeVatOcrJob = job;
        _selectedVatOcrIds.clear();
      });
      _startVatOcrPolling(jobId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Relectura IVA 0 iniciada. Puedes salir de la pantalla.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la relectura IVA 0.')),
      );
    } finally {
      if (mounted) setState(() => _startingVatOcr = false);
    }
  }

  void _startVatOcrPolling(String jobId) {
    _vatOcrPollTimer?.cancel();
    _pollVatOcrJob(jobId);
    _vatOcrPollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollVatOcrJob(jobId),
    );
  }

  Future<void> _pollVatOcrJob(String jobId) async {
    final groupId = (widget.groupId ?? '').trim();
    if (groupId.isEmpty || jobId.trim().isEmpty) return;
    try {
      final job = await _expensesApi.getExpenseOcrReprocessJob(
        jobId: jobId,
        groupId: groupId,
      );
      if (!mounted) return;
      setState(() => _activeVatOcrJob = job);
      final status = (job['status'] ?? '').toString().toLowerCase();
      if (status == 'completed' || status == 'failed') {
        _vatOcrPollTimer?.cancel();
        await VatOcrReprocessJobStore.clear(groupId);
        if (!mounted) return;
        final failed =
            (job['failed'] is num) ? (job['failed'] as num).toInt() : 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'failed'
                  ? 'La relectura de IVA 0 no pudo completarse.'
                  : failed > 0
                      ? 'Relectura finalizada con algunos errores.'
                      : 'Relectura IVA 0 finalizada.',
            ),
          ),
        );
      }
    } catch (_) {}
  }

  void _openVatOcrResults() {
    final groupId = (widget.groupId ?? '').trim();
    final jobId = (_activeVatOcrJob?['jobId'] ?? '').toString().trim();
    if (groupId.isEmpty || jobId.isEmpty) return;
    Navigator.of(context).pushNamed(
      AppRoutes.expenseOcrReprocessResults,
      arguments: ExpenseOcrReprocessResultsArgs(groupId: groupId, jobId: jobId),
    );
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load({bool showSpinner = true}) async {
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.getSuspects(
        groupId: widget.groupId,
        reviewStatus: _reviewFilter,
      );
      if (!mounted) return;
      setState(() => _response = result.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && showSpinner) setState(() => _loading = false);
    }
  }

  // ── Patch action ──────────────────────────────────────────────────────────

  Future<void> _patch(String expenseId, String status) async {
    if (_busyIds.contains(expenseId)) return;
    setState(() => _busyIds.add(expenseId));

    final noteCtrl = _noteControllers[expenseId];
    final notes = noteCtrl != null && noteCtrl.text.trim().isNotEmpty
        ? noteCtrl.text.trim()
        : null;

    try {
      await widget.api.patchReview(expenseId, status: status, notes: notes);
      if (!mounted) return;
      setState(() => _notesVisible.remove(expenseId));
      await _load(showSpinner: false);
      // Refresh the preview panel if the patched expense is being previewed
      if (_previewExpense?['id']?.toString() == expenseId) {
        final updated = _suspects.firstWhere(
          (s) => s['id']?.toString() == expenseId,
          orElse: () => _previewExpense!,
        );
        setState(() => _previewExpense = updated);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busyIds.remove(expenseId));
    }
  }

  // ── Delete action ─────────────────────────────────────────────────────────

  Future<void> _deleteExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final t = AppTypography.of(ctx);
        return AlertDialog(
          title: Text(
            'Eliminar gasto',
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            '¿Seguro que quieres eliminar este gasto? Esta acción no se puede deshacer.',
            style: t.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    if (_deletingIds.contains(expenseId)) return;
    setState(() => _deletingIds.add(expenseId));
    try {
      await _expensesApi.deleteExpense(expenseId);
      if (!mounted) return;
      if (_previewExpense?['id']?.toString() == expenseId) {
        setState(() => _previewExpense = null);
      }
      await _load(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _deletingIds.remove(expenseId));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _suspects {
    final raw = _response?['suspects'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  TextEditingController _noteCtrl(String id) =>
      _noteControllers.putIfAbsent(id, TextEditingController.new);

  String _emptyMessage(AppLocalizations l) {
    switch (_reviewFilter) {
      case _ReviewStatus.needsFix:
        return l.suspectExpensesEmptyNeedsFix;
      case _ReviewStatus.confirmedOk:
        return l.suspectExpensesEmptyConfirmedOk;
      case _ReviewStatus.unreviewed:
        return l.suspectExpensesEmptyUnreviewed;
      default:
        return l.suspectExpensesEmpty;
    }
  }

  String _fmt(dynamic value) {
    if (value == null) return '—';
    final n = (value is num) ? value.toDouble() : double.tryParse('$value');
    if (n == null) return '$value';
    return n.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
        );
  }

  // ── Open document in browser tab ──────────────────────────────────────────

  Future<void> _openFullPage(Map<String, dynamic> expense) async {
    final id = (expense['id'] ?? expense['_id'] ?? '').toString().trim();

    // Try URL directly from expense data first
    String? fileUrl;
    for (final key in ['fileUrl', 'fileURL', 'url', 'file', 'filePath']) {
      final val = expense[key]?.toString().trim();
      if (val != null && val.startsWith('http')) {
        fileUrl = val;
        break;
      }
    }

    // Fall back to API fetch
    if ((fileUrl == null || fileUrl.isEmpty) && id.isNotEmpty) {
      try {
        final result = await _expensesApi.fetchExpenseFile(id);
        final url = (result['url'] ?? '').toString().trim();
        if (url.isNotEmpty) fileUrl = url;
      } catch (_) {}
    }

    if (fileUrl != null && fileUrl.isNotEmpty) {
      final uri = Uri.tryParse(fileUrl);
      if (uri != null) await launchUrl(uri, webOnlyWindowName: '_blank');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el documento.')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 36),
            const SizedBox(height: 10),
            Text(_error!, style: t.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _load, child: Text(l.tryAgain)),
          ],
        ),
      );
    }

    if (_response == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final suspects = _suspects;
    final scanned = _response!['totalExpensesScanned'];
    final count = _response!['suspectCount'];

    final listSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsBar(
          scanned: scanned,
          suspectCount: count,
          displayedCount: suspects.length,
          selectedVatOcrCount: _selectedVatOcrIds.length,
          activeVatOcrJob: _activeVatOcrJob,
          startingVatOcr: _startingVatOcr,
          filter: _reviewFilter,
          onFilterChanged: (f) {
            setState(() => _reviewFilter = f);
            _load();
          },
          onRefresh: _load,
          onStartVatOcr: _startVatOcrForSelection,
          onOpenVatOcrResults: _openVatOcrResults,
          l: l,
          t: t,
          cs: cs,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: suspects.isEmpty
              ? _EmptyState(message: _emptyMessage(l), t: t, cs: cs)
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: suspects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final s = suspects[i];
                    final id = s['id']?.toString() ?? '';
                    final isSelected = _previewExpense?['id']?.toString() == id;
                    final selectedForOcr = _selectedVatOcrIds.contains(id);
                    return _SuspectCard(
                      expense: s,
                      busy: _busyIds.contains(id),
                      deleting: _deletingIds.contains(id),
                      isSelected: isSelected,
                      selectedForOcr: selectedForOcr,
                      notesVisible: _notesVisible.contains(id),
                      noteController: _noteCtrl(id),
                      onToggleOcrSelection: () {
                        setState(() {
                          if (selectedForOcr) {
                            _selectedVatOcrIds.remove(id);
                          } else if (id.isNotEmpty) {
                            _selectedVatOcrIds.add(id);
                          }
                        });
                      },
                      onToggleNotes: () => setState(() {
                        if (_notesVisible.contains(id)) {
                          _notesVisible.remove(id);
                        } else {
                          _notesVisible.add(id);
                        }
                      }),
                      onConfirmOk: () => _patch(id, _ReviewStatus.confirmedOk),
                      onNeedsFix: () => _patch(id, _ReviewStatus.needsFix),
                      onReset: () => _patch(id, _ReviewStatus.unreviewed),
                      onPreview: () => setState(() {
                        _previewExpense =
                            isSelected ? null : Map<String, dynamic>.from(s);
                      }),
                      onFullPage: () => _openFullPage(s),
                      onEdit: () => widget.onEditExpense(id),
                      onDelete: () => _deleteExpense(id),
                      fmt: _fmt,
                      l: l,
                      t: t,
                      cs: cs,
                    );
                  },
                ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: listSection),
        // Right preview panel
        if (_previewExpense != null) ...[
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
          SizedBox(
            width: 380,
            child: _ExpensePreviewPanel(
              key: ValueKey(_previewExpense!['id']),
              expense: _previewExpense!,
              busy: _busyIds.contains(_previewExpense!['id']?.toString() ?? ''),
              notesVisible: _notesVisible
                  .contains(_previewExpense!['id']?.toString() ?? ''),
              noteController:
                  _noteCtrl(_previewExpense!['id']?.toString() ?? ''),
              onClose: () => setState(() => _previewExpense = null),
              onConfirmOk: () => _patch(
                _previewExpense!['id']?.toString() ?? '',
                _ReviewStatus.confirmedOk,
              ),
              onNeedsFix: () => _patch(
                _previewExpense!['id']?.toString() ?? '',
                _ReviewStatus.needsFix,
              ),
              onReset: () => _patch(
                _previewExpense!['id']?.toString() ?? '',
                _ReviewStatus.unreviewed,
              ),
              onToggleNotes: () {
                final id = _previewExpense!['id']?.toString() ?? '';
                setState(() {
                  if (_notesVisible.contains(id)) {
                    _notesVisible.remove(id);
                  } else {
                    _notesVisible.add(id);
                  }
                });
              },
              onEdit: () => widget.onEditExpense(
                _previewExpense!['id']?.toString() ?? '',
              ),
              onDelete: () => _deleteExpense(
                _previewExpense!['id']?.toString() ?? '',
              ),
              fmt: _fmt,
              l: l,
              t: t,
              cs: cs,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Right preview panel
// ---------------------------------------------------------------------------

class _ExpensePreviewPanel extends StatefulWidget {
  const _ExpensePreviewPanel({
    super.key,
    required this.expense,
    required this.busy,
    required this.notesVisible,
    required this.noteController,
    required this.onClose,
    required this.onConfirmOk,
    required this.onNeedsFix,
    required this.onReset,
    required this.onToggleNotes,
    required this.onEdit,
    required this.onDelete,
    required this.fmt,
    required this.l,
    required this.t,
    required this.cs,
  });

  final Map<String, dynamic> expense;
  final bool busy;
  final bool notesVisible;
  final TextEditingController noteController;
  final VoidCallback onClose;
  final VoidCallback onConfirmOk;
  final VoidCallback onNeedsFix;
  final VoidCallback onReset;
  final VoidCallback onToggleNotes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(dynamic) fmt;
  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;

  @override
  State<_ExpensePreviewPanel> createState() => _ExpensePreviewPanelState();
}

class _ExpensePreviewPanelState extends State<_ExpensePreviewPanel> {
  final ExpensesApi _expensesApi = ExpensesApi();
  Future<Uint8List?>? _pdfBytesFuture;
  String? _resolvedFileUrl;
  String? _resolvedMimeType;
  bool _loadingDocumentPreview = false;
  String? _documentPreviewError;

  // ── Expense shortcuts ──────────────────────────────────────────────────────

  Map<String, dynamic> get _expense => widget.expense;
  String get _vendorName => _expense['vendorName']?.toString() ?? '—';
  String get _invoiceNumber => _expense['invoiceNumber']?.toString() ?? '';
  String get _issueDate {
    final raw = _expense['issueDate']?.toString() ?? '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  String get _uploadedAt {
    final raw = _expense['uploadedAt']?.toString() ?? '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Map<String, dynamic> get _stored {
    final s = _expense['suspicion']?['stored'];
    return s is Map ? Map<String, dynamic>.from(s) : {};
  }

  Map<String, dynamic> get _derived {
    final d = _expense['suspicion']?['derived'];
    return d is Map ? Map<String, dynamic>.from(d) : {};
  }

  List<Map<String, dynamic>> get _reasons {
    final raw = _expense['suspicion']?['reasons'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    }
    return const [];
  }

  String get _reviewStatus =>
      _expense['suspicionReview']?['status']?.toString() ??
      _ReviewStatus.unreviewed;
  String get _reviewNotes =>
      _expense['suspicionReview']?['notes']?.toString() ?? '';
  String get _expenseId =>
      (_expense['id'] ?? _expense['_id'] ?? '').toString().trim();

  // ── Document URL helpers ───────────────────────────────────────────────────

  String get _fileUrl {
    final resolved = (_resolvedFileUrl ?? '').trim();
    if (resolved.startsWith('http')) return resolved;
    for (final key in ['fileUrl', 'fileURL', 'url', 'file', 'filePath']) {
      final val = _expense[key]?.toString().trim();
      if (val != null && val.startsWith('http')) return val;
    }
    return '';
  }

  String get _mimeType {
    final resolved = (_resolvedMimeType ?? '').trim();
    if (resolved.isNotEmpty) return resolved;
    return (_expense['mimeType']?.toString() ?? '').trim();
  }

  bool get _isImage {
    final lc = _fileUrl.toLowerCase();
    final mime = _mimeType.toLowerCase();
    return mime.startsWith('image/') ||
        lc.endsWith('.png') ||
        lc.endsWith('.jpg') ||
        lc.endsWith('.jpeg') ||
        lc.endsWith('.jpe') ||
        lc.endsWith('.webp') ||
        lc.endsWith('.gif');
  }

  bool get _isPdf {
    return _fileUrl.toLowerCase().endsWith('.pdf') ||
        _mimeType.toLowerCase().contains('pdf');
  }

  @override
  void initState() {
    super.initState();
    _primeDocumentPreview();
  }

  @override
  void didUpdateWidget(covariant _ExpensePreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expense['id'] != widget.expense['id']) {
      _resolvedFileUrl = null;
      _resolvedMimeType = null;
      _loadingDocumentPreview = false;
      _documentPreviewError = null;
      _pdfBytesFuture = null;
      _primeDocumentPreview();
    }
  }

  void _primeDocumentPreview() {
    final url = _fileUrl;
    if (url.isNotEmpty) {
      _loadingDocumentPreview = false;
      _documentPreviewError = null;
      _pdfBytesFuture = _isPdf ? _loadPdfBytes(url) : null;
      return;
    }

    _pdfBytesFuture = null;
    if (_expenseId.isEmpty) {
      _loadingDocumentPreview = false;
      _documentPreviewError = null;
      return;
    }

    _loadingDocumentPreview = true;
    _documentPreviewError = null;
    Future.microtask(_resolveDocumentPreview);
  }

  Future<void> _resolveDocumentPreview() async {
    final expenseId = _expenseId;
    if (expenseId.isEmpty) return;

    try {
      final result = await _expensesApi.fetchExpenseFile(expenseId);
      if (!mounted) return;

      final url = (result['url'] ?? '').toString().trim();
      final mimeType = (result['mimeType'] ?? '').toString().trim();
      final pdfFuture = (url.isNotEmpty &&
              (url.toLowerCase().endsWith('.pdf') ||
                  mimeType.toLowerCase().contains('pdf')))
          ? _loadPdfBytes(url)
          : null;

      setState(() {
        _resolvedFileUrl = url.isEmpty ? null : url;
        _resolvedMimeType = mimeType.isEmpty ? null : mimeType;
        _loadingDocumentPreview = false;
        _documentPreviewError =
            url.isEmpty ? 'No se pudo cargar el documento.' : null;
        _pdfBytesFuture = pdfFuture;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDocumentPreview = false;
        _documentPreviewError = 'No se pudo cargar el documento.';
        _pdfBytesFuture = null;
      });
    }
  }

  Future<Uint8List?> _loadPdfBytes(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final r = await http.get(uri);
      if (r.statusCode < 200 || r.statusCode >= 300) return null;
      return r.bodyBytes.isEmpty ? null : r.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  // ── Document preview widget ────────────────────────────────────────────────

  Widget _buildDocumentPreview() {
    final fileUrl = _fileUrl;
    final l = widget.l;
    final cs = widget.cs;
    final t = widget.t;

    if (_loadingDocumentPreview) {
      return _documentPreviewStateCard(
        cs: cs,
        child: const SizedBox(
          height: 160,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (fileUrl.isEmpty) {
      return _documentPreviewStateCard(
        cs: cs,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 26,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              _documentPreviewError ?? 'Documento no disponible.',
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            if (_expenseId.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _loadingDocumentPreview = true;
                    _documentPreviewError = null;
                  });
                  _resolveDocumentPreview();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(l.tryAgain),
              ),
            ],
          ],
        ),
      );
    }

    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.network(
            fileUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
            errorBuilder: (_, __, ___) => _openInNewTabButton(fileUrl, t, cs),
          ),
        ),
      );
    }

    if (_isPdf) {
      return FutureBuilder<Uint8List?>(
        future: _pdfBytesFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final bytes = snap.data;
          if (bytes != null && bytes.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PdfInlinePreview(bytes: bytes, height: 420),
            );
          }
          return _openInNewTabButton(fileUrl, t, cs);
        },
      );
    }

    return _openInNewTabButton(fileUrl, t, cs);
  }

  Widget _documentPreviewStateCard({
    required ColorScheme cs,
    required Widget child,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _openInNewTabButton(String fileUrl, AppTypography t, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(fileUrl);
          if (uri != null) await launchUrl(uri);
        },
        icon: const Icon(Icons.open_in_new, size: 14),
        label: const Text('Abrir documento'),
      ),
    );
  }

  Widget _statusBadge(AppLocalizations l, AppTypography t, ColorScheme cs) {
    Color color;
    String label;
    IconData icon;
    switch (_reviewStatus) {
      case _ReviewStatus.confirmedOk:
        color = cs.tertiary;
        label = l.suspectExpensesStatusConfirmedOk;
        icon = Icons.check_circle_outline;
        break;
      case _ReviewStatus.needsFix:
        color = cs.error;
        label = l.suspectExpensesStatusNeedsFix;
        icon = Icons.build_circle_outlined;
        break;
      default:
        color = cs.onSurfaceVariant;
        label = l.suspectExpensesStatusUnreviewed;
        icon = Icons.radio_button_unchecked;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    dynamic value,
    Color color,
    AppTypography t,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          Text(
            '${widget.fmt(value)} EUR',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final t = widget.t;
    final cs = widget.cs;

    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Vista previa',
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // Edit button
                Tooltip(
                  message: 'Editar gasto',
                  child: InkWell(
                    onTap: widget.onEdit,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 15, color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Delete button
                Tooltip(
                  message: 'Eliminar gasto',
                  child: InkWell(
                    onTap: widget.onDelete,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child:
                          Icon(Icons.delete_outline, size: 15, color: cs.error),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Close button
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(Icons.close, size: 15, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
          // Panel body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Document image / PDF preview ───────────────────────────
                  _buildDocumentPreview(),
                  if (_fileUrl.isNotEmpty) const SizedBox(height: 14),
                  // ── Vendor + metadata ──────────────────────────────────────
                  Text(
                    _vendorName,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (_invoiceNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _invoiceNumber,
                      style: t.bodySmall.copyWith(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_issueDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _uploadedAt.isNotEmpty
                          ? '$_issueDate · ${l.suspectExpensesUploadedAt}: $_uploadedAt'
                          : _issueDate,
                      style: t.bodySmall.copyWith(
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _statusBadge(l, t, cs),
                  const SizedBox(height: 14),
                  // ── Comparison table ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.suspectExpensesStoredLabel.toUpperCase(),
                              style: t.bodySmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _amountRow(
                                l.suspectExpensesStoredSubtotal,
                                _stored['subtotal'],
                                cs.onSurfaceVariant,
                                t,
                                cs),
                            _amountRow(
                                l.suspectExpensesStoredTax,
                                _stored['taxTotal'],
                                cs.onSurfaceVariant,
                                t,
                                cs),
                            _amountRow(l.suspectExpensesStoredTotal,
                                _stored['total'], cs.onSurfaceVariant, t, cs),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.suspectExpensesDerivedLabel.toUpperCase(),
                              style: t.bodySmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _amountRow(l.suspectExpensesStoredSubtotal,
                                _derived['subtotal'], cs.primary, t, cs),
                            _amountRow(l.suspectExpensesStoredTax,
                                _derived['taxTotal'], cs.primary, t, cs),
                            _amountRow(l.suspectExpensesStoredTotal,
                                _derived['total'], cs.primary, t, cs),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // ── Reasons ────────────────────────────────────────────────
                  if (_reasons.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      l.suspectExpensesReasons.toUpperCase(),
                      style: t.bodySmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cs.error,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._reasons.map(
                      (r) => _ReasonChip(
                        reason: r,
                        fmt: widget.fmt,
                        l: l,
                        t: t,
                        cs: cs,
                      ),
                    ),
                  ],
                  // ── Prior notes ────────────────────────────────────────────
                  if (_reviewNotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _reviewNotes,
                        style: t.bodySmall.copyWith(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  // ── Notes input ────────────────────────────────────────────
                  if (widget.notesVisible) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: widget.noteController,
                      maxLines: 3,
                      style: t.bodySmall.copyWith(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: l.suspectExpensesNotesHint,
                        hintStyle: t.bodySmall.copyWith(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                  // ── Action buttons ─────────────────────────────────────────
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_reviewStatus != _ReviewStatus.confirmedOk)
                        _ActionButton(
                          label: l.suspectExpensesActionConfirmOk,
                          icon: Icons.check_rounded,
                          color: cs.tertiary,
                          busy: widget.busy,
                          onPressed: widget.onConfirmOk,
                          t: t,
                        ),
                      if (_reviewStatus != _ReviewStatus.needsFix)
                        _ActionButton(
                          label: l.suspectExpensesActionNeedsFix,
                          icon: Icons.build_outlined,
                          color: cs.error,
                          busy: widget.busy,
                          onPressed: widget.onNeedsFix,
                          t: t,
                        ),
                      if (_reviewStatus != _ReviewStatus.unreviewed)
                        _ActionButton(
                          label: l.suspectExpensesActionReset,
                          icon: Icons.undo_rounded,
                          color: cs.onSurfaceVariant,
                          busy: widget.busy,
                          onPressed: widget.onReset,
                          t: t,
                        ),
                      GestureDetector(
                        onTap: widget.onToggleNotes,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 13, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                l.suspectExpensesNotes,
                                style: t.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Stats + filter bar
// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.scanned,
    required this.suspectCount,
    required this.displayedCount,
    required this.selectedVatOcrCount,
    required this.activeVatOcrJob,
    required this.startingVatOcr,
    required this.filter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onStartVatOcr,
    required this.onOpenVatOcrResults,
    required this.l,
    required this.t,
    required this.cs,
  });

  final dynamic scanned;
  final dynamic suspectCount;
  final int displayedCount;
  final int selectedVatOcrCount;
  final Map<String, dynamic>? activeVatOcrJob;
  final bool startingVatOcr;
  final String? filter;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onStartVatOcr;
  final VoidCallback onOpenVatOcrResults;
  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final filterActive = filter != null;
    final primaryLabel = filterActive
        ? l.suspectExpensesFilterResults
        : l.suspectExpensesScanned;
    final primaryValue = filterActive
        ? (suspectCount?.toString() ?? displayedCount.toString())
        : scanned?.toString() ?? '-';
    final secondaryLabel =
        filterActive ? l.suspectExpensesShown : l.suspectExpensesCount;
    final job = activeVatOcrJob;
    final jobStatus = (job?['status'] ?? '').toString();
    final jobId = (job?['jobId'] ?? '').toString();
    final processed =
        job?['processed'] is num ? (job!['processed'] as num).toInt() : 0;
    final total = job?['total'] is num ? (job!['total'] as num).toInt() : 0;
    final hasRunningJob =
        jobId.isNotEmpty && !['completed', 'failed'].contains(jobStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _statChip(
              icon: filterActive
                  ? Icons.filter_alt_outlined
                  : Icons.document_scanner_outlined,
              label: primaryLabel,
              value: primaryValue,
              color: filterActive ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            _statChip(
              icon: Icons.warning_amber_rounded,
              label: secondaryLabel,
              value: displayedCount.toString(),
              color: cs.error,
            ),
            const Spacer(),
            if (jobId.isNotEmpty) ...[
              _statChip(
                icon: hasRunningJob
                    ? Icons.sync_rounded
                    : Icons.fact_check_outlined,
                label: hasRunningJob ? 'OCR IVA 0' : 'Resultados',
                value: hasRunningJob
                    ? '$processed/$total'
                    : jobStatus.isEmpty
                        ? 'listo'
                        : jobStatus,
                color: hasRunningJob ? const Color(0xFFD97706) : cs.primary,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onOpenVatOcrResults,
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Ver resultados'),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton.tonalIcon(
              onPressed: selectedVatOcrCount == 0 || startingVatOcr
                  ? null
                  : onStartVatOcr,
              icon: startingVatOcr
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined, size: 16),
              label: Text(
                selectedVatOcrCount == 0
                    ? 'Selecciona IVA 0'
                    : 'Releer IVA 0 ($selectedVatOcrCount)',
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l.tryAgain,
              iconSize: 18,
              onPressed: onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: l.suspectExpensesFilterAll,
                selected: filter == null,
                onTap: () => onFilterChanged(null),
                cs: cs,
                t: t,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: l.suspectExpensesFilterUnreviewed,
                selected: filter == _ReviewStatus.unreviewed,
                onTap: () => onFilterChanged(_ReviewStatus.unreviewed),
                cs: cs,
                t: t,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: l.suspectExpensesFilterConfirmedOk,
                selected: filter == _ReviewStatus.confirmedOk,
                onTap: () => onFilterChanged(_ReviewStatus.confirmedOk),
                cs: cs,
                t: t,
                color: cs.tertiary,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: l.suspectExpensesFilterNeedsFix,
                selected: filter == _ReviewStatus.needsFix,
                onTap: () => onFilterChanged(_ReviewStatus.needsFix),
                cs: cs,
                t: t,
                color: cs.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text('$label: ', style: t.bodySmall.copyWith(color: color)),
          Text(
            value,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
    required this.t,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final AppTypography t;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? cs.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? c.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: t.bodySmall.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? c : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.t,
    required this.cs,
  });
  final String message;
  final AppTypography t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined,
              size: 42, color: cs.tertiary.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(
            message,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Suspect expense card (compact)
// ---------------------------------------------------------------------------

class _SuspectCard extends StatelessWidget {
  const _SuspectCard({
    required this.expense,
    required this.busy,
    required this.deleting,
    required this.isSelected,
    required this.selectedForOcr,
    required this.notesVisible,
    required this.noteController,
    required this.onToggleOcrSelection,
    required this.onToggleNotes,
    required this.onConfirmOk,
    required this.onNeedsFix,
    required this.onReset,
    required this.onPreview,
    required this.onFullPage,
    required this.onEdit,
    required this.onDelete,
    required this.fmt,
    required this.l,
    required this.t,
    required this.cs,
  });

  final Map<String, dynamic> expense;
  final bool busy;
  final bool deleting;
  final bool isSelected;
  final bool selectedForOcr;
  final bool notesVisible;
  final TextEditingController noteController;
  final VoidCallback onToggleOcrSelection;
  final VoidCallback onToggleNotes;
  final VoidCallback onConfirmOk;
  final VoidCallback onNeedsFix;
  final VoidCallback onReset;
  final VoidCallback onPreview;
  final VoidCallback onFullPage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(dynamic) fmt;
  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;

  String get _vendorName => expense['vendorName']?.toString() ?? '—';
  String get _invoiceNumber => expense['invoiceNumber']?.toString() ?? '';
  String get _issueDate {
    final raw = expense['issueDate']?.toString() ?? '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  List<Map<String, dynamic>> get _reasons {
    final raw = expense['suspicion']?['reasons'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    }
    return const [];
  }

  String get _reviewStatus =>
      expense['suspicionReview']?['status']?.toString() ??
      _ReviewStatus.unreviewed;

  Widget _statusBadge() {
    Color color;
    String label;
    IconData icon;
    switch (_reviewStatus) {
      case _ReviewStatus.confirmedOk:
        color = cs.tertiary;
        label = l.suspectExpensesStatusConfirmedOk;
        icon = Icons.check_circle_outline;
        break;
      case _ReviewStatus.needsFix:
        color = cs.error;
        label = l.suspectExpensesStatusNeedsFix;
        icon = Icons.build_circle_outlined;
        break;
      default:
        color = cs.onSurfaceVariant;
        label = l.suspectExpensesStatusUnreviewed;
        icon = Icons.radio_button_unchecked;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    bool loading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected && icon == Icons.visibility_outlined
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
          ),
          child: loading
              ? SizedBox(
                  width: 13,
                  height: 13,
                  child:
                      CircularProgressIndicator(strokeWidth: 1.5, color: color),
                )
              : Icon(icon, size: 13, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? cs.primary.withValues(alpha: 0.5)
        : _reviewStatus == _ReviewStatus.needsFix
            ? cs.error.withValues(alpha: 0.3)
            : _reviewStatus == _ReviewStatus.confirmedOk
                ? cs.tertiary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.4);

    final reasonText = _reasons
        .map((r) => r['message']?.toString() ?? r['code']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return GestureDetector(
      onTap: onPreview,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary.withValues(alpha: 0.04) : cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: selectedForOcr,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => onToggleOcrSelection(),
              ),
              const SizedBox(width: 4),
              // Left: vendor name + invoice number + dates
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _vendorName,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_invoiceNumber.isNotEmpty || _issueDate.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        [
                          if (_invoiceNumber.isNotEmpty) _invoiceNumber,
                          if (_issueDate.isNotEmpty) _issueDate,
                        ].join(' · '),
                        style: t.bodySmall.copyWith(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Middle: status badge + reason text
              Expanded(
                flex: 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _statusBadge(),
                    if (reasonText.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reasonText,
                          style: t.bodySmall.copyWith(
                            fontSize: 10,
                            color: cs.error.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right: full-page + edit + delete icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_reviewStatus != _ReviewStatus.confirmedOk) ...[
                    _iconBtn(
                      icon: Icons.verified_outlined,
                      color: cs.tertiary,
                      onTap: onConfirmOk,
                      tooltip: 'Marcar como sin IVA',
                      loading: busy,
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    _iconBtn(
                      icon: Icons.undo_rounded,
                      color: cs.onSurfaceVariant,
                      onTap: onReset,
                      tooltip: 'Reabrir revisi\u00f3n',
                      loading: busy,
                    ),
                    const SizedBox(width: 4),
                  ],
                  _iconBtn(
                    icon: Icons.open_in_full_rounded,
                    color: cs.primary,
                    onTap: onFullPage,
                    tooltip: 'Ver página completa',
                  ),
                  const SizedBox(width: 4),
                  _iconBtn(
                    icon: Icons.edit_outlined,
                    color: cs.secondary,
                    onTap: onEdit,
                    tooltip: 'Editar gasto',
                  ),
                  const SizedBox(width: 4),
                  _iconBtn(
                    icon: Icons.delete_outline,
                    color: cs.error,
                    onTap: onDelete,
                    tooltip: 'Eliminar',
                    loading: deleting,
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

// ---------------------------------------------------------------------------
// Reason chip
// ---------------------------------------------------------------------------

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.reason,
    required this.fmt,
    required this.l,
    required this.t,
    required this.cs,
  });

  final Map<String, dynamic> reason;
  final String Function(dynamic) fmt;
  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final code = reason['code']?.toString() ?? '';
    final message = reason['message']?.toString() ?? code;
    final delta = reason['delta'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 13, color: cs.error),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: t.bodySmall.copyWith(
                      fontSize: 11,
                      color: cs.onSurface,
                    ),
                  ),
                  if (delta != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Δ ${fmt(delta)} EUR',
                      style: t.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onPressed,
    required this.t,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onPressed;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onPressed,
      child: AnimatedOpacity(
        opacity: busy ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 11,
                  height: 11,
                  child:
                      CircularProgressIndicator(strokeWidth: 1.5, color: color),
                )
              else
                Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
