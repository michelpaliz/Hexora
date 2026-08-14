import 'package:flutter/material.dart';
import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/jobs/background_job.dart';
import 'package:hexora/a-models/jobs/job_notification.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/downloads/downloads_api.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline/widgets/notification_category_filter_bar.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline/widgets/download_details_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline/widgets/downloads_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline/widgets/notification_details_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/notifications_section/right_panel_notifications_inline/widgets/notifications_list.dart';
import 'package:hexora/c-frontend/ui-app/shared/downloads/download_jobs_store.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/utils/errors/group_membership_error_mapper.dart';
import 'package:hexora/c-frontend/utils/errors/premium_upgrade_dialog.dart';
import 'package:hexora/c-frontend/viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/ocr_import_jobs_store.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class NotificationsInlinePanel extends StatefulWidget {
  const NotificationsInlinePanel({super.key, required this.group});

  final Group group;

  @override
  State<NotificationsInlinePanel> createState() =>
      _NotificationsInlinePanelState();
}

class _NotificationsInlinePanelState extends State<NotificationsInlinePanel> {
  late NotificationViewModel _viewModel;
  final DownloadsApi _downloadsApi = DownloadsApi();
  List<NotificationUser> _notifications = const [];
  NotificationUser? _selected;
  DownloadJob? _selectedDownload;
  BackgroundJob? _selectedOcrJob;
  Category? _selectedCategory;
  NotificationWorkflowFilter _selectedWorkflow = NotificationWorkflowFilter.all;
  bool _downloadsMode = false;
  bool _ocrJobsMode = false;
  bool _loading = true;
  String? _error;
  bool _initialized = false;
  List<JobNotification> _jobNotifications = const [];

  List<NotificationUser> get _filteredNotifications {
    return _notifications.where((notification) {
      if (_selectedCategory != null &&
          notification.category != _selectedCategory) {
        return false;
      }
      switch (_selectedWorkflow) {
        case NotificationWorkflowFilter.all:
          return true;
        case NotificationWorkflowFilter.unread:
          return !notification.isRead;
        case NotificationWorkflowFilter.important:
          return _isImportantNotification(notification);
        case NotificationWorkflowFilter.pending:
          return _isPendingNotification(notification);
        case NotificationWorkflowFilter.automations:
          return false;
      }
    }).toList(growable: false);
  }

  List<DownloadJob> get _downloads => DownloadJobsStore.instance.jobs;
  List<BackgroundJob> get _ocrJobs => OcrImportJobsStore.instance.jobs;

  bool _isImportantNotification(NotificationUser notification) {
    return notification.category == Category.systemAlert ||
        notification.category == Category.errorReport ||
        notification.category == Category.billing ||
        notification.category == Category.actionRequired;
  }

  bool _isPendingNotification(NotificationUser notification) {
    return !notification.isRead ||
        notification.category == Category.actionRequired ||
        notification.category == Category.systemAlert ||
        notification.category == Category.errorReport;
  }

  Widget _compactRefreshAction(BuildContext context, String tooltip) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          splashRadius: 16,
          iconSize: 16,
          icon: Icon(
            Icons.refresh_rounded,
            size: 16,
            color: cs.onSurface.withValues(alpha: 0.75),
          ),
          onPressed: _load,
        ),
      ),
    );
  }

  Widget _compactActionsMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final hasUnreadJobs = _jobNotifications.isNotEmpty;
    return PopupMenuButton<String>(
      tooltip: 'Acciones',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      style: IconButton.styleFrom(
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 16,
        color: cs.onSurface.withValues(alpha: 0.75),
      ),
      onSelected: (value) async {
        if (value == 'refresh') {
          await _load();
          return;
        }
        if (value == 'mark_notifications_read') {
          await _markVisibleNotificationsRead();
          return;
        }
        if (value == 'mark_jobs_read') {
          await _markAllJobNotificationsRead();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'refresh',
          child: Text('Actualizar'),
        ),
        if (unreadCount > 0)
          PopupMenuItem(
            value: 'mark_notifications_read',
            child: Text('Marcar $unreadCount como leidas'),
          ),
        if (hasUnreadJobs)
          const PopupMenuItem(
            value: 'mark_jobs_read',
            child: Text('Marcar automatizaciones como leidas'),
          ),
        const PopupMenuItem(
          enabled: false,
          child: Text('Ajustes proximamente'),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _viewModel = NotificationViewModel(
      userDomain: context.read<UserDomain>(),
      groupDomain: context.read<GroupDomain>(),
      notificationDomain: context.read<NotificationDomain>(),
      notificationService: NotificationApiClient(),
    );
    DownloadJobsStore.instance.bindGroup(widget.group.id);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await DownloadJobsStore.instance.bindGroup(widget.group.id);
      await OcrImportJobsStore.instance.refresh();
      var jobNotifications = const <JobNotification>[];
      try {
        jobNotifications =
            await NotificationApiClient().getJobNotifications(unread: true);
      } catch (_) {
        jobNotifications = const <JobNotification>[];
      }
      final data = await _viewModel.fetchNotificationsForGroup(widget.group.id);
      if (!mounted) return;
      NotificationUser? selected = _selected;
      if (data.isEmpty) {
        selected = null;
      } else if (selected == null) {
        selected = data.first;
      } else {
        final match = data.where((n) => n.id == selected!.id);
        selected = match.isNotEmpty ? match.first : data.first;
      }
      setState(() {
        _notifications = data;
        _selected = selected;
        if (_selectedDownload != null) {
          final match = _downloads.where((d) => d.id == _selectedDownload!.id);
          _selectedDownload = match.isNotEmpty
              ? match.first
              : (_downloads.isNotEmpty ? _downloads.first : null);
        } else if (_downloads.isNotEmpty) {
          _selectedDownload = _downloads.first;
        }
        if (_selectedCategory != null &&
            !_notifications.any((n) => n.category == _selectedCategory)) {
          _selectedCategory = null;
        }
        _jobNotifications = jobNotifications;
        if (_selectedOcrJob != null) {
          final match = _ocrJobs.where((job) => job.id == _selectedOcrJob!.id);
          _selectedOcrJob = match.isNotEmpty
              ? match.first
              : (_ocrJobs.isNotEmpty ? _ocrJobs.first : null);
        } else if (_ocrJobs.isNotEmpty) {
          _selectedOcrJob = _ocrJobs.first;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isDownloadNotification(NotificationUser notification) {
    final raw = notification.args['downloadJobId'];
    final id = raw?.toString().trim() ?? '';
    return id.isNotEmpty;
  }

  DownloadJob? _jobFromNotification(NotificationUser notification) {
    if (!_isDownloadNotification(notification)) return null;
    final args = notification.args;
    final id = args['downloadJobId']?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    int? parseSize(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return DownloadJob(
      id: id,
      groupId: widget.group.id,
      requestedByUserId: '',
      requestedByUserName: '',
      jobType: args['jobType']?.toString() ?? '',
      title: args['title']?.toString().trim().isNotEmpty == true
          ? args['title'].toString()
          : notification.fallbackTitle,
      description: args['description']?.toString().trim().isNotEmpty == true
          ? args['description'].toString()
          : notification.fallbackMessage,
      status: (args['downloadStatus'] ?? args['status'] ?? '').toString(),
      fileName: args['fileName']?.toString() ?? '',
      mimeType: args['mimeType']?.toString() ?? '',
      size: parseSize(args['size']),
      errorMessage: args['errorMessage']?.toString() ?? '',
      params: const <String, dynamic>{},
      notificationId: notification.id,
      expiresAt: parseDate(args['expiresAt']),
      startedAt: parseDate(args['startedAt']),
      createdAt: notification.timestamp,
      updatedAt: parseDate(args['completedAt']) ?? notification.timestamp,
      completedAt: parseDate(args['completedAt']),
      downloadUrl: args['downloadUrl']?.toString() ?? '',
      canDownload:
          ((args['downloadStatus'] ?? args['status'])?.toString() == 'ready') &&
              (args['downloadUrl']?.toString().trim().isNotEmpty == true),
    );
  }

  Future<void> _handleNotificationSelected(
      NotificationUser notification) async {
    final jobId = notification.args['downloadJobId']?.toString().trim() ?? '';
    if (jobId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _downloadsMode = false;
        _selected = notification;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _downloadsMode = true;
      _selected = notification;
    });

    final existing = _downloads.cast<DownloadJob?>().firstWhere(
          (job) => job?.id == jobId,
          orElse: () => null,
        );
    final fallbackJob = existing ?? _jobFromNotification(notification);
    if (mounted) {
      setState(() => _selectedDownload = fallbackJob);
    }

    final latest = await DownloadJobsStore.instance.fetchJob(jobId);
    if (!mounted || latest == null) return;
    setState(() {
      _downloadsMode = true;
      _selectedDownload = latest;
    });
  }

  Future<void> _handleOcrJobSelected(BackgroundJob job) async {
    if (!mounted) return;
    setState(() {
      _ocrJobsMode = true;
      _downloadsMode = false;
      _selectedOcrJob = job;
    });
    final latest = await OcrImportJobsStore.instance.fetchJob(job.id);
    if (!mounted || latest == null) return;
    setState(() => _selectedOcrJob = latest);
  }

  void _openOcrJob(BackgroundJob job) {
    final targetMenu =
        job.status == 'completed' ? 'expenses_list' : 'expenses_upload';
    Navigator.of(context).pushNamed(
      AppRoutes.groupInvoices,
      arguments: GroupInvoicesRouteArgs(
        group: widget.group,
        initialMenu: targetMenu,
      ),
    );
  }

  Future<void> _markAllJobNotificationsRead() async {
    await NotificationApiClient().markAllJobNotificationsRead();
    if (!mounted) return;
    setState(() => _jobNotifications = const []);
  }

  Future<void> _markVisibleNotificationsRead() async {
    final unread = _filteredNotifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);
    for (final notification in unread) {
      await _viewModel.markNotificationAsRead(notification);
    }
    if (!mounted) return;
    setState(() {
      _notifications = _notifications.map((notification) {
        if (unread.any((entry) => entry.id == notification.id)) {
          notification.isRead = true;
        }
        return notification;
      }).toList();
    });
  }

  Future<void> _refreshSelectedDownload() async {
    final current = _selectedDownload;
    if (current == null) return;
    final latest = await DownloadJobsStore.instance.fetchJob(current.id);
    if (!mounted || latest == null) return;
    setState(() => _selectedDownload = latest);
  }

  Future<void> _downloadSelectedJob(DownloadJob job) async {
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
    }
  }

  Future<void> _handleDelete(NotificationUser notification) async {
    try {
      await _viewModel.deleteNotification(notification);
      if (!mounted) return;
      final remaining =
          _notifications.where((n) => n.id != notification.id).toList();
      NotificationUser? selected = _selected;
      if (selected?.id == notification.id) {
        selected = remaining.isEmpty ? null : remaining.first;
      }
      setState(() {
        _notifications = remaining;
        _selected = selected;
        if (_selectedCategory != null &&
            !_notifications.any((n) => n.category == _selectedCategory)) {
          _selectedCategory = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  Future<void> _handleConfirm(NotificationUser notification) async {
    final l = AppLocalizations.of(context)!;
    try {
      await _viewModel.handleConfirmation(notification);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      if (GroupMembershipErrorMapper.isPremiumMultiGroupError(e)) {
        await showPremiumUpgradeDialog(
          context,
          message: GroupMembershipErrorMapper.messageFor(
            l,
            GroupMembershipErrorContext.joinGroup,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.error}: $e')),
      );
    }
  }

  Future<void> _handleNegate(NotificationUser notification) async {
    await _viewModel.handleNegation(notification);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 1180;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Text(
          l.groupNotificationsError,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    } else if (_notifications.isEmpty &&
        _downloads.isEmpty &&
        _ocrJobs.isEmpty) {
      body = Center(
        child: Text(
          l.groupNotificationsEmpty,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      body = ListenableBuilder(
        listenable: DownloadJobsStore.instance,
        builder: (context, _) {
          return ListenableBuilder(
            listenable: OcrImportJobsStore.instance,
            builder: (context, _) {
              final visibleNotifications = _filteredNotifications;
              final downloads = _downloads;
              final ocrJobs = _ocrJobs;
              final selectedVisible = _selected != null &&
                  visibleNotifications.any((n) => n.id == _selected!.id);
              final effectiveSelected = selectedVisible
                  ? _selected
                  : (visibleNotifications.isNotEmpty
                      ? visibleNotifications.first
                      : null);
              final effectiveSelectedDownload = _selectedDownload != null
                  ? downloads
                          .where((d) => d.id == _selectedDownload!.id)
                          .isNotEmpty
                      ? downloads
                          .firstWhere((d) => d.id == _selectedDownload!.id)
                      : (downloads.isNotEmpty ? downloads.first : null)
                  : (downloads.isNotEmpty ? downloads.first : null);
              final effectiveSelectedOcrJob = _selectedOcrJob != null
                  ? ocrJobs.where((d) => d.id == _selectedOcrJob!.id).isNotEmpty
                      ? ocrJobs.firstWhere((d) => d.id == _selectedOcrJob!.id)
                      : (ocrJobs.isNotEmpty ? ocrJobs.first : null)
                  : (ocrJobs.isNotEmpty ? ocrJobs.first : null);

              final notificationList = RefreshIndicator(
                onRefresh: _load,
                child: visibleNotifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 36,
                              horizontal: 12,
                            ),
                            child: Center(
                              child: Text(
                                l.groupNotificationsEmpty,
                                style: t.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : NotificationsList(
                        notifications: visibleNotifications,
                        selectedId: effectiveSelected?.id,
                        onSelect: _handleNotificationSelected,
                        onDelete: _handleDelete,
                      ),
              );

              final downloadsList = DownloadsList(
                items: downloads,
                selectedId: effectiveSelectedDownload?.id,
                onSelect: (item) => setState(() {
                  _downloadsMode = true;
                  _selectedDownload = item;
                }),
              );

              final ocrJobsList = _OcrJobsList(
                jobs: ocrJobs,
                selectedId: effectiveSelectedOcrJob?.id,
                notifications: _jobNotifications,
                onSelect: _handleOcrJobSelected,
                onOpen: _openOcrJob,
                onMarkAllRead: _jobNotifications.isEmpty
                    ? null
                    : _markAllJobNotificationsRead,
              );

              final listWithFilter = Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                    child: NotificationCategoryFilterBar(
                      notifications: _notifications,
                      selectedWorkflow: _selectedWorkflow,
                      onWorkflowSelected: (workflow) {
                        setState(() {
                          _selectedWorkflow = workflow;
                          _downloadsMode = false;
                          _ocrJobsMode = workflow ==
                                  NotificationWorkflowFilter.automations &&
                              ocrJobs.isNotEmpty;
                          if (_ocrJobsMode) {
                            _selectedCategory = null;
                            _selectedOcrJob ??=
                                ocrJobs.isNotEmpty ? ocrJobs.first : null;
                            return;
                          }
                          final filtered = _filteredNotifications;
                          if (_selected != null &&
                              !filtered.any((n) => n.id == _selected!.id)) {
                            _selected =
                                filtered.isEmpty ? null : filtered.first;
                          }
                        });
                      },
                      selectedCategory: _selectedCategory,
                      downloadsCount: downloads.length,
                      downloadsSelected: _downloadsMode,
                      onDownloadsSelected: downloads.isEmpty
                          ? null
                          : () => setState(() {
                                _downloadsMode = true;
                                _selectedWorkflow =
                                    NotificationWorkflowFilter.automations;
                                _selectedCategory = null;
                                _selectedDownload ??= downloads.isNotEmpty
                                    ? downloads.first
                                    : null;
                              }),
                      ocrJobsCount: ocrJobs.length,
                      ocrJobsSelected: _ocrJobsMode,
                      onOcrJobsSelected: ocrJobs.isEmpty
                          ? null
                          : () => setState(() {
                                _ocrJobsMode = true;
                                _selectedWorkflow =
                                    NotificationWorkflowFilter.automations;
                                _downloadsMode = false;
                                _selectedCategory = null;
                                _selectedOcrJob ??=
                                    ocrJobs.isNotEmpty ? ocrJobs.first : null;
                              }),
                      onCategorySelected: (category) {
                        setState(() {
                          _downloadsMode = false;
                          _ocrJobsMode = false;
                          _selectedCategory = category;
                          if (category != null) {
                            _selectedWorkflow = NotificationWorkflowFilter.all;
                          }
                          final filtered = _filteredNotifications;
                          if (_selected != null &&
                              !filtered.any((n) => n.id == _selected!.id)) {
                            _selected =
                                filtered.isEmpty ? null : filtered.first;
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _ocrJobsMode
                        ? ocrJobsList
                        : _downloadsMode
                            ? downloadsList
                            : notificationList,
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: FolderPanel(
                        title: l.notifications,
                        contentTopPadding: 44,
                        actions: [
                          _compactRefreshAction(context, l.refreshAction),
                          _compactActionsMenu(context),
                        ],
                        child: listWithFilter,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FolderPanel(
                        title: l.details,
                        child: _ocrJobsMode
                            ? _OcrJobDetailsPanel(
                                job: effectiveSelectedOcrJob,
                                onOpen: effectiveSelectedOcrJob == null
                                    ? null
                                    : () =>
                                        _openOcrJob(effectiveSelectedOcrJob),
                              )
                            : _downloadsMode
                                ? DownloadDetailsPanel(
                                    item: effectiveSelectedDownload,
                                    onRefresh: _refreshSelectedDownload,
                                    onDownload: _downloadSelectedJob,
                                  )
                                : NotificationDetailsPanel(
                                    notification: effectiveSelected,
                                    groupName: widget.group.name,
                                    onConfirm: effectiveSelected == null
                                        ? null
                                        : () =>
                                            _handleConfirm(effectiveSelected),
                                    onNegate: effectiveSelected == null
                                        ? null
                                        : () =>
                                            _handleNegate(effectiveSelected),
                                    onDelete: effectiveSelected == null
                                        ? null
                                        : () =>
                                            _handleDelete(effectiveSelected),
                                  ),
                      ),
                    ),
                  ],
                );
              }

              return FolderPanel(
                title: l.notifications,
                contentTopPadding: 44,
                actions: [
                  _compactRefreshAction(context, l.refreshAction),
                  _compactActionsMenu(context),
                ],
                child: listWithFilter,
              );
            },
          );
        },
      );
    }

    return Column(
      children: [
        Expanded(child: body),
      ],
    );
  }
}

class _OcrJobsList extends StatelessWidget {
  const _OcrJobsList({
    required this.jobs,
    required this.selectedId,
    required this.notifications,
    required this.onSelect,
    required this.onOpen,
    required this.onMarkAllRead,
  });

  final List<BackgroundJob> jobs;
  final String? selectedId;
  final List<JobNotification> notifications;
  final ValueChanged<BackgroundJob> onSelect;
  final ValueChanged<BackgroundJob> onOpen;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'No hay importaciones OCR recientes.',
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
      children: [
        if (notifications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OcrNotificationsSummary(
              notifications: notifications,
              onMarkAllRead: onMarkAllRead,
            ),
          ),
        for (final job in jobs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OcrJobRow(
              job: job,
              selected: selectedId == job.id,
              onTap: () => onSelect(job),
              onOpen: () => onOpen(job),
            ),
          ),
      ],
    );
  }
}

class _OcrNotificationsSummary extends StatelessWidget {
  const _OcrNotificationsSummary({
    required this.notifications,
    required this.onMarkAllRead,
  });

  final List<JobNotification> notifications;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final latest = notifications.first;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              latest.title.isEmpty ? latest.message : latest.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (onMarkAllRead != null)
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text('Marcar leidas'),
            ),
        ],
      ),
    );
  }
}

class _OcrJobRow extends StatelessWidget {
  const _OcrJobRow({
    required this.job,
    required this.selected,
    required this.onTap,
    required this.onOpen,
  });

  final BackgroundJob job;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final statusColor = _jobStatusColor(job.status, cs);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.44)
              : cs.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.26)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.document_scanner_outlined,
                    size: 18, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Importacion OCR',
                    style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(
                    label: _jobStatusLabel(job.status), color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: job.progressFraction,
                minHeight: 6,
                color: statusColor,
                backgroundColor: statusColor.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${job.processedItems} / ${job.totalItems}',
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (job.failedItems > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${job.failedItems} fallidos',
                    style: t.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: onOpen,
                  child: Text(_jobActionLabel(job.status)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OcrJobDetailsPanel extends StatelessWidget {
  const _OcrJobDetailsPanel({
    required this.job,
    required this.onOpen,
  });

  final BackgroundJob? job;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final item = job;
    if (item == null) {
      return const Center(child: Text('Selecciona una importacion OCR.'));
    }
    final color = _jobStatusColor(item.status, cs);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Importacion OCR',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _StatusPill(label: _jobStatusLabel(item.status), color: color),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: item.progressFraction,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 12),
          Text(
              '${item.processedItems} de ${item.totalItems} documentos procesados'),
          if (item.failedItems > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${item.failedItems} documentos con error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
          if ((item.errorMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              item.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(_jobActionLabel(item.status)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: t.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _jobStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'processing':
      return 'Procesando';
    case 'completed':
      return 'Completado';
    case 'failed':
      return 'Fallido';
    case 'needs_review':
      return 'Requiere revision';
    case 'cancelled':
      return 'Cancelado';
    default:
      return status.isEmpty ? 'Pendiente' : status;
  }
}

String _jobActionLabel(String status) {
  switch (status) {
    case 'needs_review':
      return 'Revisar';
    case 'completed':
      return 'Ver resultado';
    case 'failed':
      return 'Ver error';
    default:
      return 'Ver importacion';
  }
}

Color _jobStatusColor(String status, ColorScheme cs) {
  switch (status) {
    case 'completed':
      return const Color(0xFF16A34A);
    case 'needs_review':
      return const Color(0xFFD97706);
    case 'failed':
      return const Color(0xFFDC2626);
    case 'cancelled':
      return cs.onSurfaceVariant;
    default:
      return cs.primary;
  }
}
