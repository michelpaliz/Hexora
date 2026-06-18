import 'package:flutter/material.dart';
import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class DownloadsList extends StatelessWidget {
  const DownloadsList({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<DownloadJob> items;
  final String? selectedId;
  final ValueChanged<DownloadJob> onSelect;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    if (items.isEmpty) {
      return Center(
        child: Text(
          isEs ? 'Sin descargas recientes.' : 'No recent downloads.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DownloadRow(
          item: item,
          selected: item.id == selectedId,
          onTap: () => onSelect(item),
        );
      },
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DownloadJob item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final statusColor = _statusColor(item.status, cs);
    final statusLabel = _statusLabel(item.status, isEs);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.10)
                : cs.surfaceContainerHighest.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.isActive
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ),
                      )
                    : Icon(
                        item.isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.description_rounded,
                        size: 17,
                        color: statusColor,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.trim().isNotEmpty
                          ? item.title
                          : item.effectiveFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if ((item.size ?? 0) > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatBytes(item.size!),
                            style: t.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTimestamp(item.createdAt),
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.70),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String status, bool isEs) {
    switch (status) {
      case 'queued':
        return isEs ? 'En cola' : 'Queued';
      case 'processing':
        return isEs ? 'Preparando' : 'Preparing';
      case 'ready':
        return isEs ? 'Listo' : 'Ready';
      case 'failed':
        return isEs ? 'Error' : 'Failed';
      case 'expired':
        return isEs ? 'Caducado' : 'Expired';
      default:
        return status;
    }
  }

  static Color _statusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'queued':
      case 'processing':
        return cs.primary;
      case 'ready':
        return Colors.green.shade600;
      case 'failed':
      case 'expired':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  static String _formatTimestamp(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · $hh:$mm';
  }
}
