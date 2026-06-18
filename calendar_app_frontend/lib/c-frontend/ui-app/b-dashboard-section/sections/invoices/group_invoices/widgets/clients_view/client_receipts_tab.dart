import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientReceiptsTab extends StatefulWidget {
  final String groupId;
  final GroupClient client;
  final ValueChanged<int>? onCountChanged;

  const ClientReceiptsTab({
    super.key,
    required this.groupId,
    required this.client,
    this.onCountChanged,
  });

  @override
  State<ClientReceiptsTab> createState() => _ClientReceiptsTabState();
}

class _ClientReceiptsTabState extends State<ClientReceiptsTab> {
  final _api = ReceiptsApi();

  List<Receipt> _issued = const [];
  List<Receipt> _drafts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClientReceiptsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client.id != widget.client.id ||
        oldWidget.groupId != widget.groupId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _issued = const [];
      _drafts = const [];
    });
    try {
      final results = await Future.wait([
        _api.list(groupId: widget.groupId, status: 'issued'),
        _api.list(groupId: widget.groupId, status: 'draft'),
      ]);
      if (!mounted) return;
      final issued = results[0]
          .where((r) => r.clientId == widget.client.id)
          .toList();
      final drafts = results[1]
          .where((r) => r.clientId == widget.client.id)
          .toList();
      setState(() {
        _issued = issued;
        _drafts = drafts;
        _loading = false;
      });
      widget.onCountChanged?.call(issued.length + drafts.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _previewReceiptPdf(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    try {
      final response = await _api.previewPdf(receipt.id);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      final fileName = (receipt.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${receipt.receiptNumber!.trim()}.pdf'
          : 'receipt-preview.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.receiptPreviewFailed : msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: t.bodySmall.copyWith(color: cs.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(l.tryAgain)),
          ],
        ),
      );
    }

    final all = [..._drafts, ..._issued];

    if (all.isEmpty) {
      return Center(
        child: EmptyView(
          icon: Icons.description_outlined,
          title: l.noInvoicesYet,
          subtitle: l.noInvoicesYetSubtitle,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => ReceiptListItem(
        receipt: all[i],
        client: widget.client,
        onPreview: () => _previewReceiptPdf(all[i]),
      ),
    );
  }
}
