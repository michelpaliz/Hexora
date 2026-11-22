import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'statements_history_widgets.dart';

/// Read-only details for a single bank-statement import batch.
///
/// Renders only data already present on the frontend (the import map plus the
/// batch freshness status). It never triggers reprocessing. A "Ver entradas"
/// action is offered so the user can open the imported movements from here.
Future<void> showStatementImportDetails({
  required BuildContext context,
  required StatementsController controller,
  required Map<String, dynamic> batch,
  required ValueChanged<String> onCopy,
  VoidCallback? onOpenEntries,
}) {
  return showHexoraDialog<void>(
    context: context,
    builder: (dialogContext) => _ImportDetailsDialog(
      controller: controller,
      batch: batch,
      onCopy: onCopy,
      onOpenEntries: onOpenEntries,
    ),
  );
}

class _ImportDetailsDialog extends StatelessWidget {
  const _ImportDetailsDialog({
    required this.controller,
    required this.batch,
    required this.onCopy,
    this.onOpenEntries,
  });

  final StatementsController controller;
  final Map<String, dynamic> batch;
  final ValueChanged<String> onCopy;
  final VoidCallback? onOpenEntries;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';

    final id =
        (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString() ?? '';
    final filename =
        (batch['originalName'] ?? batch['filename'])?.toString() ?? '';
    final fileLabel =
        filename.isNotEmpty ? filename : l.statementsBatchFallback;
    final uploadedAt =
        batch['uploadedAt'] ?? batch['createdAt'] ?? batch['date'];
    final count = batch['entryCount'] ?? batch['entries'] ?? batch['count'];
    final skipped = batch['skippedDuplicates'] ?? batch['skipped'];
    final checksum = batch['checksum']?.toString();
    final sheet = batch['sheet']?.toString();
    final uploader = batch['userId']?.toString();

    final dateLabel = uploadedAt == null
        ? '—'
        : StatementsFormatters.formatDateTime(context, uploadedAt);
    final countLabel =
        count == null ? '—' : StatementsFormatters.formatCount(context, count);
    final skippedLabel = skipped == null
        ? '—'
        : StatementsFormatters.formatCount(context, skipped);

    final freshness = resolveFreshnessView(context, controller, id);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.description_outlined, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: fileLabel,
              child: Text(
                fileLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: es ? 'Fecha de importación' : 'Import date',
                child: Text(dateLabel, style: t.bodySmall),
              ),
              if (sheet != null && sheet.isNotEmpty)
                _DetailRow(
                  label: es ? 'Hoja' : 'Sheet',
                  child: Text(
                    sheet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
                ),
              _DetailRow(
                label: es ? 'Entradas' : 'Entries',
                child: Text(
                  countLabel,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _DetailRow(
                label: es ? 'Omitidos' : 'Skipped',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skippedLabel,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      es
                          ? 'El backend no proporciona una clasificación detallada.'
                          : 'The backend does not provide a detailed classification.',
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _DetailRow(
                label: es ? 'Estado' : 'Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      label: freshness.shortLabel,
                      color: freshness.color,
                      icon: freshness.icon,
                    ),
                    if (freshness.hasData) ...[
                      const SizedBox(height: 4),
                      Text(
                        freshness.fullLabel,
                        style: t.caption.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                es ? 'Detalles técnicos' : 'Technical details',
                style: t.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              TechLine(
                label: l.statementsTechBatchId,
                value: id,
                onCopy: id.isEmpty ? null : () => onCopy(id),
              ),
              if (checksum != null && checksum.isNotEmpty)
                TechLine(
                  label: l.statementsTechChecksum,
                  value: checksum,
                  onCopy: () => onCopy(checksum),
                ),
              if (uploader != null && uploader.isNotEmpty)
                TechLine(
                  label: l.statementsTechUploader,
                  value: uploader,
                  onCopy: () => onCopy(uploader),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l.close),
        ),
        if (onOpenEntries != null && id.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).maybePop();
              await controller.fetchBatchEntries(id, page: 1);
              await controller.fetchSummary(batchId: id);
              await controller.fetchBatchStatus(id);
              onOpenEntries!.call();
            },
            icon: const Icon(Icons.list_alt_rounded, size: 16),
            label: Text(l.statementsActionViewEntries),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
