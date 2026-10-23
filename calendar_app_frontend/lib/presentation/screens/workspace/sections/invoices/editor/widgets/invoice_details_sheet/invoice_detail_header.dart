import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_workspace_chrome.dart';

class InvoiceDetailHeader extends StatelessWidget {
  const InvoiceDetailHeader({
    super.key,
    required this.clientName,
    required this.invoiceNumber,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.issueDateLabel,
    required this.moreActions,
    this.onBack,
    this.onClose,
    this.invoiceType,
    this.onExpand,
    this.isExpanded = false,
  });

  final String clientName;
  final String invoiceNumber;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String issueDateLabel;
  final Widget moreActions;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final String? invoiceType;
  final VoidCallback? onExpand;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final normalizedType = (invoiceType ?? '').trim().toLowerCase();
    final typeLabel = normalizedType == 'advance'
        ? (isEs ? 'ANTICIPO' : 'ADVANCE')
        : normalizedType == 'final'
            ? 'FINAL'
            : null;
    return HexoraDocumentDetailHeader(
      title: invoiceNumber,
      clientName: clientName,
      statusLabel: statusLabel,
      statusColor: statusColor,
      statusIcon: statusIcon,
      dateLabel: issueDateLabel,
      trailingLabel: typeLabel,
      moreActions: moreActions,
      onPrevious: onBack,
      onClose: onClose,
      onExpand: onExpand,
      isExpanded: isExpanded,
    );
  }
}
