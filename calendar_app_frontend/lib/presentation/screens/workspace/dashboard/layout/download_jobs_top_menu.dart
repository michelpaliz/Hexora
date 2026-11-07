import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/models/downloads/download_job.dart';
import 'package:hexora/presentation/shared/downloads/download_jobs_store.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/services/downloads/downloads_api.dart';

class DownloadJobsTopMenu extends StatefulWidget {
  const DownloadJobsTopMenu({
    super.key,
    required this.groupId,
    required this.onViewAllDownloads,
    this.compact = false,
    this.openInNotifications = true,
  });

  final String groupId;
  final VoidCallback onViewAllDownloads;
  final bool compact;
  final bool openInNotifications;

  @override
  State<DownloadJobsTopMenu> createState() => _DownloadJobsTopMenuState();
}

class _DownloadJobsTopMenuState extends State<DownloadJobsTopMenu> {
  final _store = DownloadJobsStore.instance;
  final _api = DownloadsApi();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    unawaited(_bindJobs());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _store.nextRefreshAt != null) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant DownloadJobsTopMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      unawaited(_bindJobs());
    }
  }

  Future<void> _bindJobs() async {
    final groupId = widget.groupId;
    final alreadyLoaded = _store.boundGroupId == groupId &&
        _store.loadedOnce;
    await _store.bindGroup(groupId);
    if (alreadyLoaded && _store.boundGroupId == groupId) {
      await _store.refresh();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _label(DownloadJob job, bool isEs) {
    if (job.fileName.trim().isNotEmpty) return job.fileName;
    return switch (job.jobType) {
      'invoice_zip' => isEs ? 'ZIP de facturas' : 'Invoice ZIP',
      'invoice_vat_audit_excel' => isEs ? 'Excel de IVA de facturas' : 'Invoice VAT Excel',
      'expense_vat_audit_excel' => isEs ? 'Excel de IVA de gastos' : 'Expense VAT Excel',
      'insights_excel' => isEs ? 'Excel de análisis' : 'Insights Excel',
      _ => job.title.trim().isNotEmpty ? job.title : (isEs ? 'Archivo generado' : 'Generated file'),
    };
  }

  String _status(DownloadJob job, bool isEs) => switch (job.status) {
        'queued' => isEs ? 'En cola' : 'Queued',
        'processing' => isEs ? 'Preparando' : 'Preparing',
        'ready' => isEs ? 'Listo para descargar' : 'Ready to download',
        'failed' => isEs ? 'Error al generar' : 'Generation failed',
        'expired' => isEs ? 'Caducado' : 'Expired',
        _ => job.status,
      };

  Future<void> _select(String value) async {
    if (value == 'refresh') {
      await _store.refresh();
      return;
    }
    if (value == 'open') {
      _openAll();
      return;
    }
    final job = _store.jobs.where((item) => item.id == value).firstOrNull;
    if (job == null || job.status != 'ready' || !job.canDownload) {
      _openAll();
      return;
    }
    try {
      final response = await _api.downloadFile(job);
      await launchFileDownload(
        response.bodyBytes,
        fileName: job.effectiveFileName,
        mimeType: job.mimeType.isEmpty ? 'application/octet-stream' : job.mimeType,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _openAll() {
    if (widget.openInNotifications) _store.requestOpenDownloads();
    widget.onViewAllDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final groupJobs = _store.jobs
            .where((job) => job.groupId == widget.groupId)
            .toList(growable: false);
        final jobs = groupJobs.take(5);
        final active = groupJobs.where((job) => job.isActive).length;
        final recentCutoff = DateTime.now().subtract(const Duration(days: 1));
        final ready = groupJobs.where((job) =>
            job.status == 'ready' &&
            job.canDownload &&
            (job.completedAt ?? job.createdAt).isAfter(recentCutoff)).length;
        final nextRefreshAt = _store.nextRefreshAt;
        final seconds = nextRefreshAt == null
            ? null
            : (nextRefreshAt.difference(DateTime.now()).inMilliseconds / 1000)
                .ceil()
                .clamp(0, 12);
        final countdown = active == 0
            ? null
            : _store.loading
                ? (isEs ? 'Comprobando archivos...' : 'Checking files...')
                : seconds == null
                    ? null
                    : '${isEs ? 'Actualiza en' : 'Checks in'} ${seconds}s';
        return PopupMenuButton<String>(
          tooltip: isEs ? 'Archivos generados' : 'Generated files',
          onSelected: (value) => unawaited(_select(value)),
          itemBuilder: (context) => [
            if (countdown != null)
              PopupMenuItem<String>(
                enabled: false,
                child: Text(countdown),
              ),
            if (groupJobs.isEmpty)
              PopupMenuItem<String>(
                enabled: false,
                child: Text(_store.loading
                    ? (isEs ? 'Cargando descargas...' : 'Loading downloads...')
                    : _store.error ??
                        (isEs ? 'No hay descargas recientes' : 'No recent downloads')),
              ),
            for (final job in jobs)
              PopupMenuItem<String>(
                value: job.id,
                child: Row(
                  children: [
                    Icon(job.status == 'ready'
                        ? Icons.download_done_rounded
                        : job.isActive
                            ? Icons.hourglass_top_rounded
                            : Icons.error_outline_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_label(job, isEs), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(_status(job, isEs), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'refresh',
              child: Row(children: [
                const Icon(Icons.refresh_rounded),
                const SizedBox(width: 8),
                Text(isEs ? 'Actualizar ahora' : 'Refresh now'),
              ]),
            ),
            PopupMenuItem<String>(
              value: 'open',
              child: Text(isEs ? 'Ver todas las descargas' : 'View all downloads'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (active > 0 && nextRefreshAt != null)
                TweenAnimationBuilder<double>(
                  key: ValueKey(nextRefreshAt.millisecondsSinceEpoch),
                  tween: Tween<double>(
                    begin: 0,
                    end: (1 -
                            nextRefreshAt.difference(DateTime.now()).inMilliseconds /
                                12000)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                  ),
                  duration: const Duration(seconds: 1),
                  builder: (context, progress, _) => SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.5,
                            color: colors.primary,
                          ),
                        ),
                        Icon(Icons.download_rounded, size: 13, color: colors.primary),
                      ],
                    ),
                  ),
                )
              else
                Icon(ready > 0 && active == 0
                    ? Icons.download_done_rounded
                    : Icons.download_rounded,
                    size: 18,
                    color: ready > 0 && active == 0 ? colors.tertiary : colors.primary),
              if (!widget.compact) ...[
                const SizedBox(width: 5),
                Text(isEs ? 'Descargas' : 'Downloads'),
              ],
              if (active > 0) ...[
                const SizedBox(width: 5),
                Text('$active${seconds == null ? '' : ' · ${seconds}s'}',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700)),
              ],
              if (active == 0 && ready > 0) ...[
                const SizedBox(width: 5),
                Text('$ready ${isEs ? 'listo' : 'ready'}',
                    style: TextStyle(color: colors.tertiary, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
        );
      },
    );
  }
}
