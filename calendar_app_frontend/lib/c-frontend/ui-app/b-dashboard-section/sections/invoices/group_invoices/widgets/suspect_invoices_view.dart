import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/suspects/suspect_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SuspectInvoicesView extends StatefulWidget {
  const SuspectInvoicesView({
    super.key,
    this.api,
    required this.onEditInvoice,
    this.groupId,
  });

  final SuspectInvoicesApi? api;
  final String? groupId;
  final Future<void> Function(String invoiceId) onEditInvoice;

  @override
  State<SuspectInvoicesView> createState() => _SuspectInvoicesViewState();
}

class _ReviewStatus {
  static const String unreviewed = 'unreviewed';
  static const String confirmedOk = 'confirmed_ok';
  static const String needsFix = 'needs_fix';
}

class _SuspectInvoicesViewState extends State<SuspectInvoicesView> {
  final InvoicesApi _invoicesApi = InvoicesApi();
  late final SuspectInvoicesApi _api = widget.api ?? SuspectInvoicesApi();
  final Set<String> _busyIds = <String>{};
  final Set<String> _deletingIds = <String>{};
  final Set<String> _notesVisible = <String>{};
  final Map<String, TextEditingController> _noteControllers =
      <String, TextEditingController>{};

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _response;
  String? _reviewFilter = _ReviewStatus.unreviewed;
  Map<String, dynamic>? _previewInvoice;

  bool get _isEs =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  String _tx(String es, String en) => _isEs ? es : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get _suspects {
    final raw = _response?['suspects'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  String _invoiceId(Map<String, dynamic>? invoice) =>
      (invoice?['id'] ?? invoice?['_id'] ?? '').toString().trim();

  TextEditingController _noteCtrl(String id) =>
      _noteControllers.putIfAbsent(id, TextEditingController.new);

  Future<void> _load({bool showSpinner = true}) async {
    if (!mounted) return;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getSuspects(
        groupId: widget.groupId,
        reviewStatus: _reviewFilter,
      );
      if (!mounted) return;
      setState(() {
        _response = result.data;
        final selectedId = _invoiceId(_previewInvoice);
        if (selectedId.isNotEmpty) {
          _previewInvoice = _suspects.cast<Map<String, dynamic>?>().firstWhere(
                (item) => _invoiceId(item) == selectedId,
                orElse: () => _previewInvoice,
              );
        } else if (_previewInvoice == null && _suspects.isNotEmpty) {
          _previewInvoice = _suspects.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && showSpinner) setState(() => _loading = false);
    }
  }

  String _emptyMessage() {
    switch (_reviewFilter) {
      case _ReviewStatus.needsFix:
        return _tx(
          'No hay ingresos marcados como necesita correccion.',
          'No invoices are marked as needs correction.',
        );
      case _ReviewStatus.confirmedOk:
        return _tx(
          'No hay ingresos marcados como confirmado correcto.',
          'No invoices are marked as confirmed correct.',
        );
      case _ReviewStatus.unreviewed:
        return _tx(
          'No hay ingresos sospechosos sin revisar.',
          'No unreviewed suspect invoices found.',
        );
      default:
        return _tx(
          'No hay ingresos sospechosos para este filtro.',
          'No suspect invoices found for this filter.',
        );
    }
  }

  Future<void> _patch(String invoiceId, String status) async {
    if (_busyIds.contains(invoiceId)) return;
    setState(() => _busyIds.add(invoiceId));
    final controller = _noteControllers[invoiceId];
    final notes = controller == null || controller.text.trim().isEmpty
        ? null
        : controller.text.trim();
    try {
      final result =
          await _api.patchReview(invoiceId, status: status, notes: notes);
      if (!mounted) return;
      _mergePatchedInvoice(
        invoiceId: invoiceId,
        invoice: result['invoice'],
        suspicion: result['suspicion'],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(invoiceId));
    }
  }

  void _mergePatchedInvoice({
    required String invoiceId,
    required dynamic invoice,
    required dynamic suspicion,
  }) {
    final response = Map<String, dynamic>.from(_response ?? const {});
    final suspects = _suspects.toList(growable: true);
    final index = suspects.indexWhere((item) => _invoiceId(item) == invoiceId);
    if (index == -1) return;
    final merged = Map<String, dynamic>.from(suspects[index]);
    if (invoice is Map) merged.addAll(Map<String, dynamic>.from(invoice));
    if (suspicion is Map) {
      merged['suspicion'] = Map<String, dynamic>.from(suspicion);
    }
    final status =
        merged['suspicionReview']?['status']?.toString().trim() ?? '';
    final keepVisible = _reviewFilter == null || _reviewFilter == status;
    if (keepVisible) {
      suspects[index] = merged;
    } else {
      suspects.removeAt(index);
    }
    response['suspects'] = suspects;
    if (_reviewFilter != null) response['suspectCount'] = suspects.length;
    setState(() {
      _response = response;
      _notesVisible.remove(invoiceId);
      if (_invoiceId(_previewInvoice) == invoiceId) {
        _previewInvoice = keepVisible ? merged : null;
      }
    });
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    if (_deletingIds.contains(invoiceId)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tx('Eliminar factura', 'Delete invoice')),
        content: Text(
          _tx(
            'Seguro que quieres eliminar esta factura? Esta accion no se puede deshacer.',
            'Are you sure you want to delete this invoice? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_tx('Eliminar', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(invoiceId));
    try {
      await _invoicesApi.delete(invoiceId);
      if (!mounted) return;
      if (_invoiceId(_previewInvoice) == invoiceId) _previewInvoice = null;
      await _load(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _deletingIds.remove(invoiceId));
    }
  }

  Future<void> _openFullPreview(Map<String, dynamic> invoice) async {
    final id = _invoiceId(invoice);
    if (id.isEmpty) return;
    try {
      final response = await _invoicesApi.previewPdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      final number =
          (invoice['invoiceNumber'] ?? invoice['number'] ?? '').toString().trim();
      final fileName =
          (number.isEmpty ? 'invoice-preview-$id' : 'invoice-$number')
              .replaceAll('/', '-');
      await pdf_launcher.launchPdfPreview(bytes, fileName: '$fileName.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _fmt(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null) return '—';
    return number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading && _response == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _response == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.tryAgain),
            ),
          ],
        ),
      );
    }

    final suspects = _suspects;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: _InvoiceSuspectStatsBar(
              scanned: _response?['totalInvoicesScanned'] ?? _response?['totalScanned'],
              suspectCount: _response?['suspectCount'],
              displayedCount: suspects.length,
              filter: _reviewFilter,
              onRefresh: _load,
              onFilterChanged: (value) async {
                setState(() => _reviewFilter = value);
                await _load();
              },
              tx: _tx,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: suspects.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _emptyMessage(),
                                style: t.bodyMedium.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: suspects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final invoice = suspects[index];
                              final id = _invoiceId(invoice);
                              return _InvoiceSuspectCard(
                                invoice: invoice,
                                selected: _invoiceId(_previewInvoice) == id,
                                busy: _busyIds.contains(id),
                                deleting: _deletingIds.contains(id),
                                notesVisible: _notesVisible.contains(id),
                                noteController: _noteCtrl(id),
                                onPreview: () =>
                                    setState(() => _previewInvoice = invoice),
                                onFullPage: () => _openFullPreview(invoice),
                                onEdit: () => widget.onEditInvoice(id),
                                onDelete: () => _deleteInvoice(id),
                                onToggleNotes: () => setState(() {
                                  if (_notesVisible.contains(id)) {
                                    _notesVisible.remove(id);
                                  } else {
                                    _notesVisible.add(id);
                                  }
                                }),
                                onConfirmOk: () =>
                                    _patch(id, _ReviewStatus.confirmedOk),
                                onNeedsFix: () =>
                                    _patch(id, _ReviewStatus.needsFix),
                                onReset: () =>
                                    _patch(id, _ReviewStatus.unreviewed),
                                tx: _tx,
                                fmt: _fmt,
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _previewInvoice == null
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.35),
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _tx(
                                    'Selecciona una factura para ver la vista previa.',
                                    'Select an invoice to view the preview.',
                                  ),
                                  style: t.bodyMedium.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          )
                        : _InvoiceSuspectPreviewPanel(
                            invoice: _previewInvoice!,
                            busy: _busyIds
                                .contains(_invoiceId(_previewInvoice)),
                            deleting: _deletingIds
                                .contains(_invoiceId(_previewInvoice)),
                            notesVisible: _notesVisible
                                .contains(_invoiceId(_previewInvoice)),
                            noteController:
                                _noteCtrl(_invoiceId(_previewInvoice)),
                            onToggleNotes: () => setState(() {
                              final id = _invoiceId(_previewInvoice);
                              if (_notesVisible.contains(id)) {
                                _notesVisible.remove(id);
                              } else {
                                _notesVisible.add(id);
                              }
                            }),
                            onConfirmOk: () => _patch(
                              _invoiceId(_previewInvoice),
                              _ReviewStatus.confirmedOk,
                            ),
                            onNeedsFix: () => _patch(
                              _invoiceId(_previewInvoice),
                              _ReviewStatus.needsFix,
                            ),
                            onReset: () => _patch(
                              _invoiceId(_previewInvoice),
                              _ReviewStatus.unreviewed,
                            ),
                            onEdit: () =>
                                widget.onEditInvoice(_invoiceId(_previewInvoice)),
                            onDelete: () =>
                                _deleteInvoice(_invoiceId(_previewInvoice)),
                            onClose: () =>
                                setState(() => _previewInvoice = null),
                            onFullPage: () => _openFullPreview(_previewInvoice!),
                            tx: _tx,
                            fmt: _fmt,
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

class _InvoiceSuspectStatsBar extends StatelessWidget {
  const _InvoiceSuspectStatsBar({
    required this.scanned,
    required this.suspectCount,
    required this.displayedCount,
    required this.filter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.tx,
  });

  final dynamic scanned;
  final dynamic suspectCount;
  final int displayedCount;
  final String? filter;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onRefresh;
  final String Function(String es, String en) tx;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final filterActive = filter != null;

    Widget chip(IconData icon, String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              '$label: $value',
              style: t.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    Widget filterChip(String label, String? value) {
      final selected = filter == value;
      return InkWell(
        onTap: () => onFilterChanged(value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? cs.primary.withValues(alpha: 0.16) : cs.surface,
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            chip(
              filterActive
                  ? Icons.filter_alt_outlined
                  : Icons.document_scanner_outlined,
              filterActive ? tx('Resultados del filtro', 'Filter results') : tx('Analizados', 'Scanned'),
              filterActive
                  ? (suspectCount?.toString() ?? displayedCount.toString())
                  : scanned?.toString() ?? '-',
              filterActive ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            chip(
              Icons.warning_amber_rounded,
              filterActive
                  ? tx('Sospechosos mostrados', 'Shown suspects')
                  : tx('Sospechosos', 'Suspects'),
              displayedCount.toString(),
              cs.error,
            ),
            const Spacer(),
            IconButton(
              onPressed: onRefresh,
              tooltip: MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              filterChip(tx('Todos', 'All'), null),
              const SizedBox(width: 8),
              filterChip(tx('Sin revisar', 'Unreviewed'), _ReviewStatus.unreviewed),
              const SizedBox(width: 8),
              filterChip(
                tx('Confirmado correcto', 'Confirmed OK'),
                _ReviewStatus.confirmedOk,
              ),
              const SizedBox(width: 8),
              filterChip(
                tx('Necesita correccion', 'Needs Fix'),
                _ReviewStatus.needsFix,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvoiceSuspectCard extends StatelessWidget {
  const _InvoiceSuspectCard({
    required this.invoice,
    required this.selected,
    required this.busy,
    required this.deleting,
    required this.notesVisible,
    required this.noteController,
    required this.onPreview,
    required this.onFullPage,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleNotes,
    required this.onConfirmOk,
    required this.onNeedsFix,
    required this.onReset,
    required this.tx,
    required this.fmt,
  });

  final Map<String, dynamic> invoice;
  final bool selected;
  final bool busy;
  final bool deleting;
  final bool notesVisible;
  final TextEditingController noteController;
  final VoidCallback onPreview;
  final VoidCallback onFullPage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleNotes;
  final VoidCallback onConfirmOk;
  final VoidCallback onNeedsFix;
  final VoidCallback onReset;
  final String Function(String es, String en) tx;
  final String Function(dynamic) fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final clientSnapshot = invoice['clientSnapshot'];
    final clientName = _firstText(<dynamic>[
      invoice['billingName'],
      invoice['clientName'],
      if (clientSnapshot is Map) clientSnapshot['billingName'],
      if (clientSnapshot is Map) clientSnapshot['name'],
      if (invoice['clientId'] is Map) invoice['clientId']['name'],
    ]);
    final invoiceNumber =
        (invoice['invoiceNumber'] ?? invoice['number'] ?? '').toString().trim();
    final issueDate =
        (invoice['issueDate'] ?? invoice['registeredAt'] ?? '').toString().trim();
    final reviewStatus =
        invoice['suspicionReview']?['status']?.toString() ??
            _ReviewStatus.unreviewed;
    final reasons = _reasons(invoice);
    final isLinked = invoice['isLinked'] == true;
    final linkedEntriesCount =
        (invoice['linkedEntriesCount'] as num?)?.toInt() ?? 0;

    late final Color statusColor;
    late final String statusLabel;
    late final IconData statusIcon;
    switch (reviewStatus) {
      case _ReviewStatus.confirmedOk:
        statusColor = cs.tertiary;
        statusLabel = tx('Confirmado correcto', 'Confirmed OK');
        statusIcon = Icons.check_circle_outline;
        break;
      case _ReviewStatus.needsFix:
        statusColor = cs.error;
        statusLabel = tx('Necesita correccion', 'Needs Fix');
        statusIcon = Icons.build_circle_outlined;
        break;
      default:
        statusColor = cs.onSurfaceVariant;
        statusLabel = tx('Sin revisar', 'Unreviewed');
        statusIcon = Icons.radio_button_unchecked;
    }

    return GestureDetector(
      onTap: onPreview,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.06) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.55)
                : reviewStatus == _ReviewStatus.needsFix
                    ? cs.error.withValues(alpha: 0.35)
                    : reviewStatus == _ReviewStatus.confirmedOk
                        ? cs.tertiary.withValues(alpha: 0.35)
                        : cs.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (invoiceNumber.isNotEmpty) invoiceNumber,
                          if (issueDate.isNotEmpty)
                            issueDate.length >= 10 ? issueDate.substring(0, 10) : issueDate,
                        ].join(' · '),
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _iconBtn(context, icon: Icons.visibility_outlined, color: cs.primary, tooltip: tx('Vista previa', 'Preview'), onTap: onPreview, selected: selected),
                const SizedBox(width: 6),
                _iconBtn(context, icon: Icons.open_in_full_rounded, color: cs.primary, tooltip: tx('Ver preview PDF', 'Open PDF'), onTap: onFullPage),
                const SizedBox(width: 6),
                _iconBtn(context, icon: Icons.edit_outlined, color: cs.secondary, tooltip: tx('Editar factura', 'Edit invoice'), onTap: onEdit),
                const SizedBox(width: 6),
                _iconBtn(context, icon: Icons.delete_outline, color: cs.error, tooltip: tx('Eliminar', 'Delete'), onTap: onDelete, loading: deleting),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniBadge(
                  context,
                  icon: statusIcon,
                  label: statusLabel,
                  color: statusColor,
                ),
                if (isLinked)
                  _miniBadge(
                    context,
                    icon: Icons.link_rounded,
                    label: tx('Factura vinculada', 'Linked invoice'),
                    color: cs.secondary,
                  ),
                if (linkedEntriesCount > 0)
                  _miniBadge(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label:
                        '${tx('Movimientos vinculados', 'Linked entries')}: $linkedEntriesCount',
                    color: cs.primary,
                  ),
              ],
            ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                reasons
                    .map(
                      (reason) =>
                          reason['message']?.toString() ??
                          _reasonLabel(reason['code']?.toString()),
                    )
                    .where((text) => text.trim().isNotEmpty)
                    .join(' · '),
                style: t.bodySmall.copyWith(
                  color: cs.error.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in reasons)
                    if (_buildReasonDeltaBadge(
                          context,
                          code: reason['code']?.toString(),
                          delta: reason['delta'],
                        )
                        case final badge?)
                      badge,
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (invoice['suspicion']?['stored'] is Map)
                  _totalsCard(
                    context,
                    title: tx('Importes guardados', 'Stored amounts'),
                    color: cs.onSurfaceVariant,
                    values:
                        Map<String, dynamic>.from(invoice['suspicion']['stored']),
                    fmt: fmt,
                  ),
                if (invoice['suspicion']?['derived'] is Map)
                  _totalsCard(
                    context,
                    title: tx('Importes derivados', 'Derived amounts'),
                    color: cs.primary,
                    values:
                        Map<String, dynamic>.from(invoice['suspicion']['derived']),
                    fmt: fmt,
                  ),
              ],
            ),
            if ((invoice['uiMessage']?.toString().trim() ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  invoice['uiMessage'].toString().trim(),
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (reviewStatus != _ReviewStatus.confirmedOk)
                  _actionChip(
                    context,
                    label: tx('Marcar como correcto', 'Mark as correct'),
                    icon: Icons.check_rounded,
                    color: cs.tertiary,
                    busy: busy,
                    onTap: onConfirmOk,
                  ),
                if (reviewStatus != _ReviewStatus.needsFix)
                  _actionChip(
                    context,
                    label: tx('Marcar para corregir', 'Mark for fix'),
                    icon: Icons.build_outlined,
                    color: cs.error,
                    busy: busy,
                    onTap: onNeedsFix,
                  ),
                if (reviewStatus != _ReviewStatus.unreviewed)
                  _actionChip(
                    context,
                    label: tx('Restablecer revision', 'Reset review'),
                    icon: Icons.undo_rounded,
                    color: cs.onSurfaceVariant,
                    busy: busy,
                    onTap: onReset,
                  ),
                _actionChip(
                  context,
                  label: tx('Notas', 'Notes'),
                  icon: Icons.notes_rounded,
                  color: cs.onSurfaceVariant,
                  busy: false,
                  onTap: onToggleNotes,
                ),
              ],
            ),
            if (notesVisible) ...[
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: tx(
                    'Anade una nota antes de guardar...',
                    'Add a note before saving...',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceSuspectPreviewPanel extends StatefulWidget {
  const _InvoiceSuspectPreviewPanel({
    required this.invoice,
    required this.busy,
    required this.deleting,
    required this.notesVisible,
    required this.noteController,
    required this.onToggleNotes,
    required this.onConfirmOk,
    required this.onNeedsFix,
    required this.onReset,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
    required this.onFullPage,
    required this.tx,
    required this.fmt,
  });

  final Map<String, dynamic> invoice;
  final bool busy;
  final bool deleting;
  final bool notesVisible;
  final TextEditingController noteController;
  final VoidCallback onToggleNotes;
  final VoidCallback onConfirmOk;
  final VoidCallback onNeedsFix;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final VoidCallback onFullPage;
  final String Function(String es, String en) tx;
  final String Function(dynamic) fmt;

  @override
  State<_InvoiceSuspectPreviewPanel> createState() =>
      _InvoiceSuspectPreviewPanelState();
}

class _InvoiceSuspectPreviewPanelState
    extends State<_InvoiceSuspectPreviewPanel> {
  final InvoicesApi _invoicesApi = InvoicesApi();
  Future<Uint8List?>? _pdfBytesFuture;

  Map<String, dynamic> get _invoice => widget.invoice;
  String get _invoiceId =>
      (_invoice['id'] ?? _invoice['_id'] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    _primePdf();
  }

  @override
  void didUpdateWidget(covariant _InvoiceSuspectPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.invoice['id'] ?? oldWidget.invoice['_id']) !=
        (_invoice['id'] ?? _invoice['_id'])) {
      _primePdf();
    }
  }

  void _primePdf() {
    _pdfBytesFuture = _invoiceId.isEmpty
        ? Future<Uint8List?>.value(null)
        : _loadPdfBytes(_invoiceId);
  }

  Future<Uint8List?> _loadPdfBytes(String invoiceId) async {
    try {
      final response = await _invoicesApi.previewPdf(invoiceId);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final clientName = _firstText(<dynamic>[
      _invoice['billingName'],
      _invoice['clientName'],
      if (_invoice['clientSnapshot'] is Map)
        _invoice['clientSnapshot']['billingName'],
      if (_invoice['clientSnapshot'] is Map) _invoice['clientSnapshot']['name'],
      if (_invoice['clientId'] is Map) _invoice['clientId']['name'],
    ]);
    final invoiceNumber =
        (_invoice['invoiceNumber'] ?? _invoice['number'] ?? '').toString().trim();
    final issueDate =
        (_invoice['issueDate'] ?? _invoice['registeredAt'] ?? '').toString().trim();
    final reviewStatus =
        _invoice['suspicionReview']?['status']?.toString() ??
            _ReviewStatus.unreviewed;

    late final Color statusColor;
    late final String statusLabel;
    switch (reviewStatus) {
      case _ReviewStatus.confirmedOk:
        statusLabel = widget.tx('Confirmado correcto', 'Confirmed OK');
        statusColor = cs.tertiary;
        break;
      case _ReviewStatus.needsFix:
        statusLabel = widget.tx('Necesita correccion', 'Needs Fix');
        statusColor = cs.error;
        break;
      default:
        statusLabel = widget.tx('Sin revisar', 'Unreviewed');
        statusColor = cs.onSurfaceVariant;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.tx('Vista previa', 'Preview'),
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _iconBtn(context, icon: Icons.open_in_full_rounded, color: cs.primary, tooltip: widget.tx('Ver preview PDF', 'Open PDF'), onTap: widget.onFullPage),
                const SizedBox(width: 6),
                _iconBtn(context, icon: Icons.edit_outlined, color: cs.primary, tooltip: widget.tx('Editar factura', 'Edit invoice'), onTap: widget.onEdit),
                const SizedBox(width: 6),
                _iconBtn(context, icon: Icons.delete_outline, color: cs.error, tooltip: widget.tx('Eliminar', 'Delete'), onTap: widget.onDelete, loading: widget.deleting),
                const SizedBox(width: 6),
                _iconBtn(context, icon: Icons.close, color: cs.onSurface, tooltip: widget.tx('Cerrar', 'Close'), onTap: widget.onClose),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 220),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
                    ),
                    child: FutureBuilder<Uint8List?>(
                      future: _pdfBytesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final bytes = snapshot.data;
                        if (bytes != null && bytes.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PdfInlinePreview(bytes: bytes, height: 420),
                          );
                        }
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: OutlinedButton.icon(
                              onPressed: widget.onFullPage,
                              icon: const Icon(Icons.open_in_new),
                              label: Text(widget.tx('Abrir PDF', 'Open PDF')),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(clientName, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800)),
                  if (invoiceNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(invoiceNumber, style: t.bodySmall),
                  ],
                  if (issueDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      issueDate.length >= 10 ? issueDate.substring(0, 10) : issueDate,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _miniBadge(
                    context,
                    icon: Icons.info_outline,
                    label: statusLabel,
                    color: statusColor,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _totalsCard(
                          context,
                          title: widget.tx('Importes guardados', 'Stored amounts'),
                          color: cs.onSurfaceVariant,
                          values: _invoice['suspicion']?['stored'] is Map
                              ? Map<String, dynamic>.from(_invoice['suspicion']['stored'])
                              : const {},
                          fmt: widget.fmt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _totalsCard(
                          context,
                          title: widget.tx('Importes derivados', 'Derived amounts'),
                          color: cs.primary,
                          values: _invoice['suspicion']?['derived'] is Map
                              ? Map<String, dynamic>.from(_invoice['suspicion']['derived'])
                              : const {},
                          fmt: widget.fmt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (reviewStatus != _ReviewStatus.confirmedOk)
                        _actionChip(context, label: widget.tx('Marcar como correcto', 'Mark as correct'), icon: Icons.check_rounded, color: cs.tertiary, busy: widget.busy, onTap: widget.onConfirmOk),
                      if (reviewStatus != _ReviewStatus.needsFix)
                        _actionChip(context, label: widget.tx('Marcar para corregir', 'Mark for fix'), icon: Icons.build_outlined, color: cs.error, busy: widget.busy, onTap: widget.onNeedsFix),
                      if (reviewStatus != _ReviewStatus.unreviewed)
                        _actionChip(context, label: widget.tx('Restablecer revision', 'Reset review'), icon: Icons.undo_rounded, color: cs.onSurfaceVariant, busy: widget.busy, onTap: widget.onReset),
                      _actionChip(context, label: widget.tx('Notas', 'Notes'), icon: Icons.notes_rounded, color: cs.onSurfaceVariant, busy: false, onTap: widget.onToggleNotes),
                    ],
                  ),
                  if (widget.notesVisible) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: widget.noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: widget.tx('Anade una nota antes de guardar...', 'Add a note before saving...'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _reasons(Map<String, dynamic> invoice) {
  final raw = invoice['suspicion']?['reasons'];
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _firstText(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final text = candidate?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '—';
}

String _reasonLabel(String? code) {
  switch ((code ?? '').trim().toUpperCase()) {
    case 'SUBTOTAL_MISMATCH':
      return 'Base';
    case 'TAX_TOTAL_MISMATCH':
      return 'IVA';
    case 'TOTAL_MISMATCH':
      return 'Total';
    case 'IMPOSSIBLE_ZERO_TOTAL':
      return 'Factura con total imposible';
    default:
      final safe = (code ?? '').trim();
      return safe.isEmpty ? 'Motivo' : safe;
  }
}

Widget _iconBtn(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String tooltip,
  required VoidCallback onTap,
  bool loading = false,
  bool selected = false,
}) {
  return Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.35)),
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.7,
                  color: color,
                ),
              )
            : Icon(icon, size: 15, color: color),
      ),
    ),
  );
}

Widget _miniBadge(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
}) {
  final t = AppTypography.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: t.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _actionChip(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color color,
  required bool busy,
  required VoidCallback onTap,
}) {
  final t = AppTypography.of(context);
  return InkWell(
    onTap: busy ? null : onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.7,
                    color: color,
                  ),
                )
              : Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget? _buildReasonDeltaBadge(
  BuildContext context, {
  required String? code,
  required dynamic delta,
}) {
  final value = delta is num ? delta.toDouble() : double.tryParse('$delta');
  if (value == null) return null;
  final cs = Theme.of(context).colorScheme;
  final color = value.abs() < 0.01 ? cs.tertiary : cs.error;
  return _miniBadge(
    context,
    icon: Icons.compare_arrows_rounded,
    label: '${_reasonLabel(code)}: ${value.toStringAsFixed(2)}',
    color: color,
  );
}

Widget _totalsCard(
  BuildContext context, {
  required String title,
  required Color color,
  required Map<String, dynamic> values,
  required String Function(dynamic) fmt,
}) {
  final t = AppTypography.of(context);
  final cs = Theme.of(context).colorScheme;

  Widget row(String label, dynamic value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
        Text(
          '${fmt(value)} EUR',
          style: t.bodySmall.copyWith(
            color: emphasize ? color : cs.onSurface,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  return Container(
    constraints: const BoxConstraints(minWidth: 230, maxWidth: 280),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      color: color.withValues(alpha: 0.05),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        row('Base', values['subtotal']),
        const SizedBox(height: 4),
        row('IVA', values['taxTotal']),
        const SizedBox(height: 4),
        row('Total', values['total'], emphasize: true),
      ],
    ),
  );
}
