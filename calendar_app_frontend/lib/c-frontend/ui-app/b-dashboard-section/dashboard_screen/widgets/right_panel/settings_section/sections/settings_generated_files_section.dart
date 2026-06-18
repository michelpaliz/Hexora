import 'package:flutter/material.dart';
import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/downloads/downloads_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline/widgets/download_details_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class SettingsGeneratedFilesSection extends StatefulWidget {
  const SettingsGeneratedFilesSection({
    super.key,
    required this.group,
  });

  final Group group;

  @override
  State<SettingsGeneratedFilesSection> createState() =>
      _SettingsGeneratedFilesSectionState();
}

class _SettingsGeneratedFilesSectionState
    extends State<SettingsGeneratedFilesSection> {
  final DownloadsApi _downloadsApi = DownloadsApi();

  List<DownloadJob> _jobs = const <DownloadJob>[];
  DownloadJob? _selectedJob;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await _downloadsApi.listJobs(
        groupId: widget.group.id,
        mine: true,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _selectedJob = jobs.any((job) => job.id == _selectedJob?.id)
            ? jobs.firstWhere((job) => job.id == _selectedJob!.id)
            : (jobs.isNotEmpty ? jobs.first : null);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _refreshSelectedJob() async {
    final current = _selectedJob;
    if (current == null) {
      await _loadJobs();
      return;
    }
    try {
      final job = await _downloadsApi.getJob(current.id);
      if (!mounted) return;
      setState(() {
        _jobs = _jobs
            .map((item) => item.id == job.id ? job : item)
            .toList(growable: false);
        _selectedJob = job;
      });
    } catch (_) {
      await _loadJobs();
    }
  }

  Future<void> _downloadJob(DownloadJob job) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final response = await _downloadsApi.downloadFile(job);
      await launchFileDownload(
        response.bodyBytes,
        fileName: job.effectiveFileName,
        mimeType: job.mimeType.trim().isNotEmpty
            ? job.mimeType
            : 'application/octet-stream',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return FolderSectionCard(
      label: isEs ? 'Historial de archivos' : 'Generated files',
      leftTabOffset: 0,
      backgroundColor: isLight ? Colors.white : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEs
                        ? 'Archivos generados para este grupo'
                        : 'Generated files for this group',
                    style: t.bodyMedium.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _loadJobs,
                  tooltip: isEs ? 'Actualizar' : 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 560,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error?.isNotEmpty ?? false)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: t.bodySmall.copyWith(color: cs.error),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonalIcon(
                                onPressed: _loadJobs,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(isEs ? 'Reintentar' : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? Colors.white
                                      : cs.surfaceContainerHighest
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.24),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _JobsList(
                                  items: _jobs,
                                  selectedId: _selectedJob?.id,
                                  onSelect: (job) =>
                                      setState(() => _selectedJob = job),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? Colors.white
                                      : cs.surfaceContainerHighest
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.24),
                                  ),
                                ),
                                child: AbsorbPointer(
                                  absorbing: _downloading,
                                  child: DownloadDetailsPanel(
                                    item: _selectedJob,
                                    onRefresh: _refreshSelectedJob,
                                    onDownload: _downloadJob,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsList extends StatelessWidget {
  const _JobsList({
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
          isEs ? 'Sin archivos generados.' : 'No generated files yet.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _JobRow(
          item: item,
          selected: item.id == selectedId,
          onTap: () => onSelect(item),
        );
      },
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final statusColor = _statusColor(item.status, cs);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.12)
                : isLight
                    ? Colors.white
                    : cs.surfaceContainerHighest.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.40)
                  : cs.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title.trim().isNotEmpty
                          ? item.title
                          : item.effectiveFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(item.status, isEs),
                      style: t.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _MetaLine(
                label: isEs ? 'Archivo' : 'File',
                value: item.effectiveFileName,
              ),
              _MetaLine(
                label: isEs ? 'Tipo' : 'Type',
                value: item.jobType.trim().isNotEmpty ? item.jobType : '-',
              ),
              _MetaLine(
                label: isEs ? 'Creado' : 'Created',
                value: _formatDate(item.createdAt),
              ),
              _MetaLine(
                label: isEs ? 'Tamaño' : 'Size',
                value: (item.size ?? 0) > 0 ? _formatBytes(item.size!) : '-',
              ),
              _MetaLine(
                label: isEs ? 'Descargable' : 'Can download',
                value: item.canDownload
                    ? (isEs ? 'Sí' : 'Yes')
                    : (isEs ? 'No' : 'No'),
              ),
            ],
          ),
        ),
      ),
    );
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

  static String _formatDate(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month}/${value.year} · $hh:$mm';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        text: TextSpan(
          style: t.caption.copyWith(color: cs.onSurfaceVariant),
          children: [
            TextSpan(
              text: '$label: ',
              style: t.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
