import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_list_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ClientReceiptsTab extends StatefulWidget {
  final String groupId;
  final GroupClient client;
  final ValueChanged<int>? onCountChanged;
  final Widget Function(
    BuildContext context,
    Receipt receipt,
    VoidCallback onClose,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  ) previewBuilder;
  final ValueChanged<Receipt>? onEditReceipt;

  const ClientReceiptsTab({
    super.key,
    required this.groupId,
    required this.client,
    required this.previewBuilder,
    this.onEditReceipt,
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
  Receipt? _selectedReceipt;

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
      _selectedReceipt = null;
    });
    try {
      final results = await Future.wait([
        _api.list(groupId: widget.groupId, status: 'issued'),
        _api.list(groupId: widget.groupId, status: 'draft'),
      ]);
      if (!mounted) return;
      final issued =
          results[0].where((r) => r.clientId == widget.client.id).toList();
      final drafts =
          results[1].where((r) => r.clientId == widget.client.id).toList();
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
            const SizedBox.shrink(),
            TextButton(onPressed: _load, child: Text(l.tryAgain)),
          ],
        ),
      );
    }

    final all = [..._drafts, ..._issued];
    all.sort((a, b) {
      final aDate = a.issueDate ?? a.registeredAt;
      final bDate = b.issueDate ?? b.registeredAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    if (all.isEmpty) {
      return Center(
        child: EmptyView(
          icon: Icons.description_outlined,
          title: l.noInvoicesYet,
          subtitle: l.noInvoicesYetSubtitle,
        ),
      );
    }

    final items = <Object>[];
    String? lastMonth;
    for (final receipt in all) {
      final date = receipt.issueDate ?? receipt.registeredAt;
      if (date != null) {
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (key != lastMonth) {
          final raw = DateFormat.yMMMM(l.localeName).format(date.toLocal());
          items.add(_ReceiptMonthLabel(
            raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}',
          ));
          lastMonth = key;
        }
      }
      items.add(receipt);
    }

    return DocumentSplitView(
      storageKey: 'client-receipts',
      initialListFraction: 0.68,
      minListWidth: 360,
      minPreviewWidth: 320,
      selectionKey: _selectedReceipt?.id,
      list: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          if (item is _ReceiptMonthLabel) {
            return HexoraMonthSeparator(label: item.value, flat: true);
          }
          final receipt = item as Receipt;
          void select() => setState(() => _selectedReceipt = receipt);
          return ReceiptListItem(
            receipt: receipt,
            client: widget.client,
            selected: _selectedReceipt?.id == receipt.id,
            onTap: select,
            onPreview: () async => select(),
            onEdit: widget.onEditReceipt == null
                ? null
                : () => widget.onEditReceipt!(receipt),
          );
        },
      ),
      preview: _selectedReceipt == null
          ? const SizedBox.shrink()
          : widget.previewBuilder(
              context,
              _selectedReceipt!,
              () => setState(() => _selectedReceipt = null),
              _adjacentReceipt(all, -1),
              _adjacentReceipt(all, 1),
            ),
    );
  }

  VoidCallback? _adjacentReceipt(List<Receipt> receipts, int offset) {
    final selected = _selectedReceipt;
    if (selected == null) return null;
    final index = receipts.indexWhere((item) => item.id == selected.id);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= receipts.length) return null;
    return () => setState(() => _selectedReceipt = receipts[target]);
  }
}

class _ReceiptMonthLabel {
  const _ReceiptMonthLabel(this.value);

  final String value;
}
