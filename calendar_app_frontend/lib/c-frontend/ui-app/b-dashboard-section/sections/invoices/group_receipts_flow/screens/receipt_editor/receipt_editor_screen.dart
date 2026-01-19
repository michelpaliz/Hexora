import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_form_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_line_draft.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_summary_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptEditorScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  final Receipt? initialReceipt;

  const ReceiptEditorScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialReceipt,
  });

  @override
  State<ReceiptEditorScreen> createState() => _ReceiptEditorScreenState();
}

class _ReceiptEditorScreenState extends State<ReceiptEditorScreen> {
  final _api = ReceiptsApi();
  final _notesCtrl = TextEditingController();

  Receipt? _saved;
  bool _didPersist = false;
  String? _clientId;
  DateTime? _issueDate;
  bool _saving = false;
  bool _issuing = false;
  bool _previewing = false;
  bool _downloading = false;

  final List<ReceiptLineDraft> _lines = [];

  @override
  void initState() {
    super.initState();
    _saved = widget.initialReceipt;
    _clientId = widget.initialClientId ?? widget.initialReceipt?.clientId;
    _issueDate = widget.initialReceipt?.issueDate;
    _notesCtrl.text = widget.initialReceipt?.notes ?? '';

    final initialLines = widget.initialReceipt?.lines ?? const [];
    if (initialLines.isEmpty) {
      _lines.add(ReceiptLineDraft.empty());
    } else {
      for (final l in initialLines) {
        _lines.add(ReceiptLineDraft.fromLine(l));
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  bool get _isDraft {
    final s = (_saved?.status ?? 'draft').toLowerCase();
    return s.isEmpty || s.contains('draft');
  }

  GroupClient? get _client {
    final id = _clientId;
    if (id == null) return null;
    for (final c in widget.clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  num get _total {
    num sum = 0;
    for (final l in _lines) {
      sum += l.total;
    }
    return sum;
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final initial = _issueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) {
      setState(() => _issueDate = picked);
    }
  }

  Receipt _buildReceiptPayload({required String status}) {
    final lines = _lines
        .where((l) => l.hasAnyValue)
        .map((l) => ReceiptLine(
              description: l.description.trim(),
              quantity: l.quantity,
              unitPrice: l.unitPrice,
            ))
        .toList();

    return Receipt(
      id: _saved?.id ?? '',
      groupId: widget.group.id,
      clientId: _clientId ?? '',
      status: status,
      issueDate: _issueDate,
      notes: _notesCtrl.text.trim(),
      lines: lines,
    );
  }

  String _safeErrorMessage(AppLocalizations l, Object e, {String? fallback}) {
    final msg = e.toString().replaceFirst('Exception: ', '').trim();
    if (msg.isEmpty) return fallback ?? l.receiptSaveFailed;
    return msg;
  }

  Future<Receipt?> _saveDraft({bool showSnack = true}) async {
    final l = AppLocalizations.of(context)!;
    if (_clientId == null || _clientId!.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.receiptClientRequired)));
      return null;
    }
    if (_lines.every((e) => !e.hasAnyValue)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.receiptLinesRequired)));
      return null;
    }

    setState(() => _saving = true);
    try {
      final payload = _buildReceiptPayload(status: 'draft');
      final saved = _saved == null
          ? await _api.create(payload)
          : await _api.update(_saved!.id, payload.toUpdatePayload());
      if (!mounted) return saved;
      setState(() => _saved = saved);
      _didPersist = true;
      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.receiptDraftSavedSnack)),
        );
      }
      return saved;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_safeErrorMessage(l, e, fallback: l.receiptSaveFailed)),
        ),
      );
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _previewPdf() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _previewing = true);
    try {
      final saved = _saved ?? await _saveDraft(showSnack: false);
      if (saved == null) return;

      final r = await _api.previewPdf(saved.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = (saved.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${saved.receiptNumber!.trim()}.pdf'
          : 'receipt-draft.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_safeErrorMessage(l, e, fallback: l.receiptPreviewFailed)),
        ),
      );
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _downloadPdf() async {
    final l = AppLocalizations.of(context)!;
    if (_saved == null) return;
    setState(() => _downloading = true);
    try {
      final r = await _api.downloadPdf(_saved!.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = (_saved!.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${_saved!.receiptNumber!.trim()}.pdf'
          : 'receipt.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_safeErrorMessage(l, e, fallback: l.receiptDownloadFailed)),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _issue() async {
    final l = AppLocalizations.of(context)!;
    if (!_isDraft) return;

    final saved = _saved ?? await _saveDraft(showSnack: false);
    if (saved == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.receiptIssueConfirmTitle),
        content: Text(l.receiptIssueConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.receiptIssueCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _issuing = true);
    try {
      final issued = await _api.issue(saved.id);
      if (!mounted) return;
      setState(() => _saved = issued);
      _didPersist = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l.receiptIssueSuccessSnack(issued.receiptNumber ?? ''))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_safeErrorMessage(l, e, fallback: l.receiptIssueFailed))),
      );
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    final receiptNumber = (_saved?.receiptNumber?.trim().isNotEmpty == true)
        ? _saved!.receiptNumber!.trim()
        : l.receiptDraftNumberPlaceholder;
    final status = (_saved?.status ?? 'draft').toLowerCase();
    final fmt = DateFormat.yMMMd(l.localeName);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didPersist);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.receiptEditorTitle(receiptNumber),
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_previewing)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: l.preview,
                onPressed: _previewPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final form = ReceiptFormCard(
                clientId: _clientId,
                clients: widget.clients,
                issueDateLabel:
                    _issueDate == null ? '-' : fmt.format(_issueDate!),
                notesController: _notesCtrl,
                canEdit: _isDraft,
                onPickDate: _pickIssueDate,
                onClientChanged: (v) => setState(() => _clientId = v),
                lines: _lines,
                onLinesChanged: () => setState(() {}),
                onAddLine: () =>
                    setState(() => _lines.add(ReceiptLineDraft.empty())),
                onRemoveLine: (idx) {
                  setState(() {
                    _lines.removeAt(idx).dispose();
                    if (_lines.isEmpty) _lines.add(ReceiptLineDraft.empty());
                  });
                },
              );

            final summary = ReceiptSummaryCard(
              status: status,
              clientName: _client?.name ?? l.receiptSelectClientLabel,
              issueDateLabel:
                  _issueDate == null ? '-' : fmt.format(_issueDate!),
              lineCount: _lines.where((e) => e.hasAnyValue).length,
              subtotal: _total,
              total: _total,
              onSaveDraft: _saving || !_isDraft ? null : () => _saveDraft(),
              onIssue: _issuing || !_isDraft ? null : _issue,
              onDownload: _downloading || (_saved == null) || _isDraft
                  ? null
                  : _downloadPdf,
            );

            if (!wide) {
              return ListView(
                children: [
                  summary,
                  const SizedBox(height: 12),
                  form,
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: form,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 380,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: summary,
                  ),
                ),
              ],
            );
          },
          ),
        ),
      ),
    );
  }
}
