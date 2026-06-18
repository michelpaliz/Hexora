import 'package:flutter/material.dart';
import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class DownloadDetailsPanel extends StatelessWidget {
  const DownloadDetailsPanel({
    super.key,
    required this.item,
    required this.onRefresh,
    required this.onDownload,
  });

  final DownloadJob? item;
  final Future<void> Function() onRefresh;
  final Future<void> Function(DownloadJob job) onDownload;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (item == null) {
      return Center(
        child: Text(
          isEs ? 'Selecciona una descarga.' : 'Select a download.',
          style: t.bodyMedium.copyWith(
            color: ThemeColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final statusColor = _statusColor(item!.status, cs);
    final statusLabel = _statusLabel(item!.status, isEs);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: item!.isActive
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      )
                    : Icon(
                        item!.isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.description_rounded,
                        size: 20,
                        color: statusColor,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item!.title.trim().isNotEmpty
                          ? item!.title
                          : item!.effectiveFileName,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    if (item!.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item!.description,
                        style: t.bodyMedium.copyWith(
                          color: ThemeColors.textSecondary(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(label: statusLabel, color: statusColor),
                        if (item!.jobType.trim().isNotEmpty)
                          _Pill(
                            label: item!.jobType,
                            color: cs.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(isEs ? 'Actualizar' : 'Refresh'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: item!.status == 'ready' && item!.canDownload
                      ? () => onDownload(item!)
                      : null,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(isEs ? 'Descargar' : 'Download'),
                ),
              ),
            ],
          ),
          _SectionDivider(label: isEs ? 'Archivo' : 'File', cs: cs, t: t),
          _DetailRow(
            label: isEs ? 'Nombre' : 'Name',
            value: item!.effectiveFileName,
          ),
          _DetailRow(
            label: isEs ? 'Tipo' : 'Type',
            value: _humanType(item!, isEs),
          ),
          if ((item!.size ?? 0) > 0)
            _DetailRow(
              label: isEs ? 'Tamaño' : 'Size',
              value: _formatBytes(item!.size!),
            ),
          _SectionDivider(label: isEs ? 'Estado' : 'Status', cs: cs, t: t),
          _DetailRow(
            label: isEs ? 'Creado' : 'Created',
            value: _formatDateTime(item!.createdAt),
          ),
          if (item!.startedAt != null)
            _DetailRow(
              label: isEs ? 'Inicio' : 'Started',
              value: _formatDateTime(item!.startedAt!),
            ),
          if (item!.completedAt != null)
            _DetailRow(
              label: isEs ? 'Completado' : 'Completed',
              value: _formatDateTime(item!.completedAt!),
            ),
          if (item!.expiresAt != null)
            _DetailRow(
              label: isEs ? 'Caduca' : 'Expires',
              value: _formatDateTime(item!.expiresAt!),
            ),
          if (item!.requestedByUserName.trim().isNotEmpty)
            _DetailRow(
              label: isEs ? 'Solicitado por' : 'Requested by',
              value: item!.requestedByUserName,
            ),
          if (item!.errorMessage.trim().isNotEmpty)
            _DetailRow(
              label: isEs ? 'Error' : 'Error',
              value: item!.errorMessage,
              valueColor: cs.error,
            ),
        ],
      ),
    );
  }

  static String _humanType(DownloadJob job, bool isEs) {
    if (job.isPdf) return 'PDF';
    if (job.mimeType.contains('spreadsheetml') ||
        job.effectiveFileName.toLowerCase().endsWith('.xlsx')) {
      return isEs ? 'Excel' : 'Excel';
    }
    if (job.mimeType.trim().isNotEmpty) return job.mimeType;
    return isEs ? 'Documento' : 'Document';
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

  static String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} · $hh:$mm';
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.label,
    required this.cs,
    required this.t,
  });

  final String label;
  final ColorScheme cs;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: t.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.45),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: t.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
