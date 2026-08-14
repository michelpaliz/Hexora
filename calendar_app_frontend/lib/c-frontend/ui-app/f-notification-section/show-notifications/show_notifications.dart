import 'package:flutter/material.dart';
import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/jobs/background_job.dart';
import 'package:hexora/a-models/jobs/job_notification.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/downloads/downloads_api.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/ocr_import_job_mapping_store.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/ocr_import_jobs_store.dart';
import 'package:hexora/c-frontend/utils/errors/group_membership_error_mapper.dart';
import 'package:hexora/c-frontend/utils/errors/premium_upgrade_dialog.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/notification_vm/view_model/notification_view_model.dart';
import 'sections/notifications_tab_view.dart';
import 'sections/show_notifications_header.dart';
import 'utils/notification_payload_helper.dart';

class ShowNotifications extends StatefulWidget {
  final User user;
  final bool showBottomNav;
  const ShowNotifications({
    required this.user,
    this.showBottomNav = true,
    super.key,
  });

  @override
  State<ShowNotifications> createState() => _ShowNotificationsState();
}

class _ShowNotificationsState extends State<ShowNotifications>
    with WidgetsBindingObserver {
  late final NotificationViewModel _notificationViewModel;
  late final Stream<List<NotificationUser>> _notificationsStream;
  bool _clearing = false; // prevent double taps while clearing
  final NotificationApiClient _notificationApiClient = NotificationApiClient();
  final DownloadsApi _downloadsApi = DownloadsApi();
  List<JobNotification> _jobNotifications = const <JobNotification>[];
  bool _loadingJobNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize once to avoid flicker when switching screens
    final userDomain = context.read<UserDomain>();
    final groupDomain = context.read<GroupDomain>();
    final notifMgmt = context.read<NotificationDomain>();

    _notificationViewModel = NotificationViewModel(
      userDomain: userDomain,
      groupDomain: groupDomain,
      notificationDomain: notifMgmt,
      notificationService: NotificationApiClient(),
    );

    _notificationsStream = notifMgmt.notificationStream;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationViewModel.fetchAndUpdateNotifications(widget.user);
      _refreshExpenseActivity();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshExpenseActivity();
    }
  }

  Future<void> _refreshExpenseActivity() async {
    await Future.wait([
      OcrImportJobsStore.instance.refresh(),
      _loadJobNotifications(),
    ]);
  }

  Future<void> _loadJobNotifications() async {
    if (mounted) {
      setState(() => _loadingJobNotifications = true);
    }
    try {
      final items = await _notificationApiClient.getJobNotifications(limit: 20);
      if (!mounted) return;
      setState(() {
        _jobNotifications = items
            .where((item) => _isExpenseJobNotification(item))
            .toList(growable: false);
        _loadingJobNotifications = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingJobNotifications = false);
    }
  }

  Future<void> _confirmAndClearAll(AppLocalizations loc) async {
    if (_clearing) return;
    final t = Theme.of(context).textTheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          loc.clearAll,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          loc.clearAllConfirm,
          style: t.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: t.labelLarge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.confirm,
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _clearing = true);
      try {
        await _notificationViewModel.removeAllNotifications(widget.user);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.clearedAllNotifications, style: t.bodyMedium)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: $e', style: t.bodyMedium)),
        );
      } finally {
        if (mounted) setState(() => _clearing = false);
      }
    }
  }

  Future<void> _handleInviteConfirmation(NotificationUser notification) async {
    final loc = AppLocalizations.of(context)!;
    try {
      await _notificationViewModel.handleConfirmation(notification);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.confirm)),
      );
    } catch (e) {
      if (!mounted) return;
      if (GroupMembershipErrorMapper.isPremiumMultiGroupError(e)) {
        await showPremiumUpgradeDialog(
          context,
          message: GroupMembershipErrorMapper.messageFor(
            loc,
            GroupMembershipErrorContext.joinGroup,
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.error}: $e')),
      );
    }
  }

  GroupInvoicesRouteArgs? _documentRouteArgs(
    Group group,
    NotificationUser notification,
  ) {
    final data = documentIssuedNotification(notification);
    final documentId = (data.documentId ?? '').trim();
    if (documentId.isEmpty) return null;
    switch (data.documentType) {
      case IssuedDocumentType.invoice:
        return GroupInvoicesRouteArgs(
          group: group,
          initialMenu: 'invoices_issued',
          initialInvoiceId: documentId,
        );
      case IssuedDocumentType.receipt:
        return GroupInvoicesRouteArgs(
          group: group,
          initialMenu: 'receipts',
          initialReceiptId: documentId,
        );
      case IssuedDocumentType.presupuesto:
        return GroupInvoicesRouteArgs(
          group: group,
          initialMenu: 'budgets_list',
          initialBudgetId: documentId,
        );
      case IssuedDocumentType.unknown:
        return null;
    }
  }

  Future<void> _openDocumentNotification(NotificationUser notification) async {
    final groupId = (documentIssuedNotification(notification).groupId ??
            notification.groupId)
        .trim();
    if (groupId.isEmpty) return;
    try {
      final group = await context
          .read<GroupDomain>()
          .groupRepository
          .getGroupById(groupId);
      if (!mounted) return;
      final args = _documentRouteArgs(group, notification);
      if (args == null) return;
      Navigator.of(context).pushNamed(
        AppRoutes.groupInvoices,
        arguments: args,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  bool _isInvoiceZipDownloadNotification(NotificationUser notification) {
    final rawCategory = notification.args['category']?.toString().trim();
    final categoryMatches =
        notification.category.index == 8 || rawCategory == '8';
    final jobType = notification.args['jobType']?.toString().trim();
    return categoryMatches && jobType == 'invoice_zip';
  }

  bool _isReadyDownloadNotification(NotificationUser notification) {
    if (!_isInvoiceZipDownloadNotification(notification)) return false;
    final status = notification.args['downloadStatus']?.toString().trim();
    return status == 'ready';
  }

  bool _isFailedDownloadNotification(NotificationUser notification) {
    if (!_isInvoiceZipDownloadNotification(notification)) return false;
    final status = notification.args['downloadStatus']?.toString().trim();
    return status == 'failed';
  }

  DownloadJob? _downloadJobFromNotification(NotificationUser notification) {
    if (!_isInvoiceZipDownloadNotification(notification)) return null;
    final args = notification.args;
    final jobId = (args['downloadJobId'] ??
            args['downloadId'] ??
            args['id'] ??
            args['jobId'])
        ?.toString()
        .trim();
    final downloadUrl = args['downloadUrl']?.toString().trim() ?? '';
    if ((jobId == null || jobId.isEmpty) && downloadUrl.isEmpty) return null;

    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    final status = (args['downloadStatus'] ?? args['status'] ?? '')
        .toString()
        .trim();

    return DownloadJob(
      id: jobId?.isNotEmpty == true ? jobId! : notification.id,
      groupId: (args['groupId'] ?? notification.groupId).toString(),
      requestedByUserId: (args['requestedByUserId'] ?? '').toString(),
      requestedByUserName: (args['requestedByUserName'] ?? '').toString(),
      jobType: (args['jobType'] ?? '').toString(),
      title: (args['title']?.toString().trim().isNotEmpty == true)
          ? args['title'].toString()
          : notification.fallbackTitle,
      description: (args['description']?.toString().trim().isNotEmpty == true)
          ? args['description'].toString()
          : notification.fallbackMessage,
      status: status,
      fileName: (args['fileName'] ?? '').toString(),
      mimeType: (args['mimeType'] ?? 'application/zip').toString(),
      size: parseInt(args['size']),
      errorMessage: (args['errorMessage'] ?? '').toString(),
      params: const <String, dynamic>{},
      notificationId: notification.id,
      expiresAt: parseDate(args['expiresAt']),
      startedAt: parseDate(args['startedAt']),
      createdAt: parseDate(args['createdAt']) ?? notification.timestamp,
      updatedAt: parseDate(args['updatedAt']) ?? notification.timestamp,
      completedAt: parseDate(args['completedAt']),
      downloadUrl: downloadUrl,
      canDownload: status == 'ready' && downloadUrl.isNotEmpty,
    );
  }

  Future<void> _downloadNotificationFile(NotificationUser notification) async {
    final job = _downloadJobFromNotification(notification);
    if (job == null || !job.canDownload) return;
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

  Future<void> _handleNotificationOpen(NotificationUser notification) async {
    if (_isReadyDownloadNotification(notification)) {
      await _downloadNotificationFile(notification);
      return;
    }
    if (_isFailedDownloadNotification(notification)) {
      final message =
          notification.args['errorMessage']?.toString().trim().isNotEmpty ==
                  true
              ? notification.args['errorMessage'].toString()
              : notification.fallbackMessage;
      if (!mounted || message.trim().isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    if (isIssuedDocumentNotification(notification)) {
      await _openDocumentNotification(notification);
    }
  }

  bool _isExpenseJobNotification(JobNotification notification) {
    final type = notification.type.toUpperCase();
    return type.startsWith('OCR_IMPORT');
  }

  bool _isAttentionJobNotification(JobNotification notification) {
    final severity = notification.severity.toLowerCase();
    final type = notification.type.toUpperCase();
    return severity == 'warning' || type == 'OCR_IMPORT_REQUIRES_REVIEW';
  }

  String _jobMenuForActionUrl(String? actionUrl, {String? fallbackStatus}) {
    final raw = (actionUrl ?? '').trim().toLowerCase();
    if (raw.contains('/review')) return 'expenses_upload';
    if (raw.contains('/results')) return 'expenses_list';
    switch ((fallbackStatus ?? '').toLowerCase()) {
      case 'completed':
        return 'expenses_list';
      default:
        return 'expenses_upload';
    }
  }

  String? _extractGroupIdFromMap(Map<String, dynamic> raw) {
    for (final key in const [
      'groupId',
      'group_id',
      'workspaceGroupId',
      'targetGroupId',
    ]) {
      final value = raw[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    for (final value in raw.values) {
      if (value is Map) {
        final nested = _extractGroupIdFromMap(Map<String, dynamic>.from(value));
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  String? _extractGroupIdFromJob(BackgroundJob job) {
    final fromMetadata = _extractGroupIdFromMap(job.metadata);
    if (fromMetadata != null) return fromMetadata;
    return _extractGroupIdFromMap(job.resultSummary);
  }

  Future<Group?> _groupFromId(String groupId) async {
    final trimmed = groupId.trim();
    if (trimmed.isEmpty) return null;
    return context.read<GroupDomain>().groupRepository.getGroupById(trimmed);
  }

  Future<void> _openExpenseJob(BackgroundJob job) async {
    final latest = await OcrImportJobsStore.instance.fetchJob(job.id) ?? job;
    final groupId =
        _extractGroupIdFromJob(latest) ?? _extractGroupIdFromJob(job);
    if (!mounted) return;
    if (groupId == null || groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'es'
                ? 'No pudimos abrir esta importacion todavia.'
                : 'We could not open this import yet.',
          ),
        ),
      );
      return;
    }
    final group = await _groupFromId(groupId);
    if (!mounted || group == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.groupInvoices,
      arguments: GroupInvoicesRouteArgs(
        group: group,
        initialMenu: _jobMenuForActionUrl(null, fallbackStatus: latest.status),
      ),
    );
  }

  Future<void> _openJobNotification(JobNotification notification) async {
    try {
      await _notificationApiClient.markJobNotificationRead(notification.id);
    } catch (_) {}

    var groupId = '';
    String? fallbackStatus;
    final jobId = notification.jobId?.trim() ?? '';
    if (jobId.isNotEmpty) {
      final job = await OcrImportJobsStore.instance.fetchJob(jobId);
      if (job != null) {
        fallbackStatus = job.status;
        groupId = _extractGroupIdFromJob(job) ?? '';
      }
    }

    if (!mounted) return;

    if (groupId.isEmpty) {
      final mapping =
          await OcrImportJobMappingStore.instance.findByBackgroundJobId(jobId);
      if (mapping != null) {
        OcrImportJobsStore.instance.trackStartedJob(
          backgroundJobId: mapping.backgroundJobId,
          totalFiles: 0,
        );
      }
    }

    if (!mounted) return;
    if (groupId.isEmpty) {
      await _loadJobNotifications();
      return;
    }

    final group = await _groupFromId(groupId);
    if (!mounted || group == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.groupInvoices,
      arguments: GroupInvoicesRouteArgs(
        group: group,
        initialMenu: _jobMenuForActionUrl(
          notification.actionUrl,
          fallbackStatus: fallbackStatus,
        ),
      ),
    );
    await _loadJobNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return MainScaffold(
      title: '',
      showAppBar: true,
      showBottomNavAndFab: widget.showBottomNav,
      appBarBackgroundColor: Theme.of(context).colorScheme.surface,
      iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
      centerTitle: true,
      titleWidget: ShowNotificationsHeader(
        onClear: _clearing ? null : () => _confirmAndClearAll(loc),
        clearing: _clearing,
      ),
      actions: [
        Tooltip(
          message: loc.clearAll,
          child: IconButton(
            icon: _clearing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.clear_all),
            onPressed: _clearing ? null : () => _confirmAndClearAll(loc),
          ),
        ),
      ],
      body: ListenableBuilder(
        listenable: OcrImportJobsStore.instance,
        builder: (context, _) => NotificationsTabView(
          notificationsStream: _notificationsStream,
          notificationViewModel: _notificationViewModel,
          activeJobs: OcrImportJobsStore.instance.activeJobs,
          jobNotifications: _jobNotifications,
          loadingJobNotifications: _loadingJobNotifications,
          isAttentionJobNotification: _isAttentionJobNotification,
          onConfirm: _handleInviteConfirmation,
          onOpenDocument: (notification) {
            _handleNotificationOpen(notification);
          },
          onOpenActiveJob: _openExpenseJob,
          onOpenJobNotification: _openJobNotification,
        ),
      ),
    );
  }
}
