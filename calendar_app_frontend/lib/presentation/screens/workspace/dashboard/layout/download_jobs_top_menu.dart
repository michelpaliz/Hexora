import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/downloads/download_job.dart';
import 'package:hexora/presentation/shared/downloads/download_job_display.dart';
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
  final _menu = MenuController();

  @override
  void initState() {
    super.initState();
    unawaited(_bindJobs());
  }

  @override
  void didUpdateWidget(covariant DownloadJobsTopMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _menu.close();
      unawaited(_bindJobs());
    }
  }

  Future<void> _bindJobs() async {
    final groupId = widget.groupId;
    final alreadyLoaded = _store.boundGroupId == groupId && _store.loadedOnce;
    await _store.bindGroup(groupId);
    if (alreadyLoaded && _store.boundGroupId == groupId) {
      await _store.refresh();
    }
  }

  Future<void> _download(DownloadJob job) async {
    if (job.status != 'ready' || !job.canDownload) return;
    _menu.close();
    try {
      final response = await _api.downloadFile(job);
      await launchFileDownload(
        response.bodyBytes,
        fileName: DownloadJobDisplay.downloadFilename(context, job, response.headers),
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
    _menu.close();
    if (widget.openInNotifications) _store.requestOpenDownloads();
    widget.onViewAllDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final jobs = _store.jobs
            .where((job) => job.groupId == widget.groupId)
            .take(5)
            .toList(growable: false);
        final hasActiveJobs = _store.jobs.any((job) =>
            job.groupId == widget.groupId && job.isActive);
        final nextRefreshAt = _store.nextRefreshAt;
        final newReady = _store.newReadyCount;
        final compact = widget.compact || MediaQuery.sizeOf(context).width < 1200;
        final menuWidth = math.min(340.0, MediaQuery.sizeOf(context).width - 32.0);
        final maxListHeight = math.max(64.0,
            math.min(260.0, MediaQuery.sizeOf(context).height - 160.0));
        return MenuAnchor(
          controller: _menu,
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(colors.surface),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            maximumSize: WidgetStatePropertyAll(Size(menuWidth, MediaQuery.sizeOf(context).height - 40)),
          ),
          menuChildren: [
            SizedBox(
              width: menuWidth,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
                  child: Row(children: [
                    Expanded(child: Text(l.downloadsRecent,
                        style: Theme.of(context).textTheme.titleSmall)),
                    IconButton(
                      tooltip: l.downloadsRefresh,
                      onPressed: _store.loading ? null : () => unawaited(_store.refresh()),
                      icon: _store.loading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded, size: 19),
                    ),
                  ]),
                ),
                if (jobs.isEmpty)
                  SizedBox(height: 56, child: Center(child: Text(
                    _store.loading ? l.downloadsChecking : _store.error ?? l.downloadsEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  )))
                else
                  SizedBox(
                    height: math.min(maxListHeight, jobs.length * 52.0),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: jobs.length,
                      itemBuilder: (context, index) => _DownloadMenuRow(
                        job: jobs[index],
                        onDownload: () => unawaited(_download(jobs[index])),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _openAll,
                    child: Text(l.downloadsViewAll),
                  ),
                ),
              ]),
            ),
          ],
          builder: (context, controller, child) {
            void toggle() {
              if (controller.isOpen) {
                controller.close();
              } else {
                _store.markReadySeen();
                controller.open();
              }
            }
            final icon = Stack(clipBehavior: Clip.none, children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.download_rounded, size: 19),
                  if (hasActiveJobs && nextRefreshAt != null)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(nextRefreshAt.millisecondsSinceEpoch),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 12),
                      builder: (context, progress, _) => SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 1.5,
                          color: colors.primary,
                        ),
                      ),
                    ),
                ]),
              ),
              if (newReady > 0)
                Positioned(
                  right: -9,
                  top: -8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(newReady > 9 ? '9+' : '$newReady',
                        style: TextStyle(color: colors.onError, fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ]);
            if (compact) {
              return IconButton(
                tooltip: l.downloadsTitle,
                onPressed: toggle,
                icon: icon,
              );
            }
            return TextButton.icon(
              onPressed: toggle,
              icon: icon,
              label: Text(l.downloadsTitle),
            );
          },
        );
      },
    );
  }
}

class _DownloadMenuRow extends StatelessWidget {
  const _DownloadMenuRow({required this.job, required this.onDownload});

  final DownloadJob job;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = DownloadJobDisplay.name(context, job);
    final status = DownloadJobDisplay.status(context, job);
    final type = DownloadJobDisplay.fileType(job);
    final time = DownloadJobDisplay.timestamp(context, job);
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Icon(DownloadJobDisplay.icon(job), size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: job.effectiveFileName,
                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text('$type · $status · $time', maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: job.status == 'failed' ? colors.error : colors.onSurfaceVariant,
                  )),
            ],
          )),
          IconButton(
            tooltip: AppLocalizations.of(context)!.download,
            onPressed: job.status == 'ready' && job.canDownload ? onDownload : null,
            icon: const Icon(Icons.download_rounded, size: 19),
          ),
        ]),
      ),
    );
  }
}
