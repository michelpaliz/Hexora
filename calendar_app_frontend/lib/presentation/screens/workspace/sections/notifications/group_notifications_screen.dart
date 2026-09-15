import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_category_meta.dart';
import 'widgets/mobile_notification.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:hexora/services/notification/notification_api_client.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/enums/category/broad_category.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/ocr/expense_ocr_reprocess_results_screen.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_payload_helper.dart';
import 'package:hexora/presentation/utils/errors/group_membership_error_mapper.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/premium_upgrade_dialog.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_grouping.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/widgets/notification_card.dart';
import 'package:hexora/presentation/viewmodels/notifications/notification_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupNotificationsScreen extends StatefulWidget {
  const GroupNotificationsScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupNotificationsScreen> createState() =>
      _GroupNotificationsScreenState();
}

class _GroupNotificationsScreenState extends State<GroupNotificationsScreen> {
  late NotificationViewModel _viewModel;
  List<NotificationUser> _notifications = const [];
  bool _loading = true;
  bool _processing = false;
  bool _initialized = false;
  String? _error;

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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _notifications.isEmpty;
      _error = null;
    });
    try {
      final data = await _viewModel.fetchNotificationsForGroup(widget.group.id);
      if (!mounted) return;
      setState(() {
        _notifications = data;
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

  Future<void> _handleDelete(NotificationUser notification) async {
    try {
      await _viewModel.deleteNotification(notification);
      if (!mounted) return;
      setState(() {
        _notifications =
            _notifications.where((n) => n.id != notification.id).toList();
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

  Future<void> _handleMarkRead(NotificationUser notification) async {
    try {
      await _viewModel.markNotificationAsRead(notification);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            n.isRead = true;
          }
          return n;
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  void _openEvent(String eventId, String groupId) {
    Navigator.of(context).pushNamed(
      AppRoutes.groupCalendar,
      arguments: groupId,
    );
  }

  GroupInvoicesRouteArgs? _documentRouteArgs(NotificationUser notification) {
    final data = documentIssuedNotification(notification);
    final documentId = (data.documentId ?? '').trim();
    if (documentId.isEmpty) return null;
    switch (data.documentType) {
      case IssuedDocumentType.invoice:
        return GroupInvoicesRouteArgs(
          group: widget.group,
          initialMenu: 'invoices_issued',
          initialInvoiceId: documentId,
        );
      case IssuedDocumentType.receipt:
        return GroupInvoicesRouteArgs(
          group: widget.group,
          initialMenu: 'receipts',
          initialReceiptId: documentId,
        );
      case IssuedDocumentType.presupuesto:
        return GroupInvoicesRouteArgs(
          group: widget.group,
          initialMenu: 'budgets_list',
          initialBudgetId: documentId,
        );
      case IssuedDocumentType.unknown:
        return null;
    }
  }

  void _openDocument(NotificationUser notification) {
    final args = _documentRouteArgs(notification);
    if (args == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.groupInvoices,
      arguments: args,
    );
  }

  bool _isOcrReprocessNotification(NotificationUser notification) {
    final haystack = [
      notification.titleKey,
      notification.messageKey,
      notification.fallbackTitle,
      notification.fallbackMessage,
      notification.args['key'],
      notification.args['type'],
      notification.args['actionUrl'],
    ].join(' ').toLowerCase();
    return haystack.contains('reprocess') ||
        haystack.contains('reproces') ||
        haystack.contains('iva 0') ||
        haystack.contains('zero_vat');
  }

  void _openOcrReprocessResults(NotificationUser notification) {
    final jobId = (notification.args['jobId'] ?? '').toString().trim();
    final groupId = (notification.args['groupId'] ?? notification.groupId)
        .toString()
        .trim();
    if (jobId.isEmpty || groupId.isEmpty) return;
    Navigator.of(context).pushNamed(
      AppRoutes.expenseOcrReprocessResults,
      arguments: ExpenseOcrReprocessResultsArgs(
        group: widget.group,
        groupId: groupId,
        jobId: jobId,
      ),
    );
  }

  Future<void> _showNotification(NotificationUser notification) async {
    if (_processing) return;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final event = EventArgsHelper(notification.args);
    final documentArgs = _documentRouteArgs(notification);
    final ocr = _isOcrReprocessNotification(notification) &&
        (notification.args['jobId'] ?? '').toString().trim().isNotEmpty;
    final calendar = isEventNotification(notification) ||
        isConcurrentEventNotification(notification);
    final openLabel = ocr
        ? (es ? 'Ver resultados' : 'View results')
        : documentArgs != null
            ? (es ? 'Ver documento' : 'View document')
            : calendar && event.eventId != null
                ? (es ? 'Ver calendario' : 'View calendar')
                : null;
    final action = await Navigator.of(context).push<NotificationDetailAction>(
      MaterialPageRoute(
          builder: (_) => NotificationDetailPage(
              notification: notification, openLabel: openLabel)),
    );
    if (!mounted || action == null) return;
    setState(() => _processing = true);
    try {
      switch (action) {
        case NotificationDetailAction.open:
          if (!notification.isRead) await _handleMarkRead(notification);
          if (!mounted) return;
          if (ocr) {
            _openOcrReprocessResults(notification);
          } else if (documentArgs != null) {
            _openDocument(notification);
          } else if (calendar && event.eventId != null) {
            _openEvent(event.eventId!, event.groupId ?? notification.groupId);
          }
          break;
        case NotificationDetailAction.markRead:
          await _handleMarkRead(notification);
          break;
        case NotificationDetailAction.confirm:
          await _handleConfirm(notification);
          break;
        case NotificationDetailAction.decline:
          try {
            await _handleNegate(notification);
          } catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('${AppLocalizations.of(context)!.error}: $error')));
          }
          break;
        case NotificationDetailAction.delete:
          await _handleDelete(notification);
          break;
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = theme.textTheme;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.groupNotificationsError,
                      style: t.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                          Localizations.localeOf(context).languageCode == 'es'
                              ? 'Reintentar'
                              : 'Retry')),
                ],
              )));
    } else if (_notifications.isEmpty) {
      body = Center(
        child: Text(
          l.groupNotificationsEmpty,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      final tabs = _buildTabs(context, _notifications);
      body = DefaultTabController(
        length: tabs.length,
        child: Column(
          children: [
            TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              labelStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              tabs: tabs.map((tab) => Tab(text: tab.label)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: tabs
                    .map(
                      (tab) => RefreshIndicator(
                        onRefresh: _load,
                        child: _NotificationsList(
                          key: PageStorageKey(tab.label),
                          notifications: tab.notifications,
                          onTap: _showNotification,
                          onDelete: _handleDelete,
                          onConfirm: _handleConfirm,
                          onNegate: _handleNegate,
                          onMarkRead: _handleMarkRead,
                          onOpenEvent: _openEvent,
                          onOpenDocument: (notification) =>
                              _isOcrReprocessNotification(notification)
                                  ? _openOcrReprocessResults(notification)
                                  : _openDocument(notification),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: SectionAppBar(
        title: MediaQuery.sizeOf(context).width < 600
            ? (Localizations.localeOf(context).languageCode == 'es'
                ? 'Notificaciones'
                : 'Notifications')
            : l.groupNotificationsTitle(widget.group.name),
      ),
      body: SafeArea(
          top: false,
          child: Stack(children: [
            AbsorbPointer(absorbing: _processing, child: body),
            if (_processing)
              const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator()),
          ])),
    );
  }

  List<_NotificationTab> _buildTabs(
    BuildContext context,
    List<NotificationUser> notifications,
  ) {
    final loc = AppLocalizations.of(context)!;
    final buckets = <BroadCategory, List<NotificationUser>>{
      for (final cat in BroadCategory.values) cat: <NotificationUser>[],
    };

    for (final notification in notifications) {
      final resolved = resolveBroadCategoryForNotification(notification);
      buckets.putIfAbsent(resolved, () => []).add(notification);
    }

    final tabs = <_NotificationTab>[
      _NotificationTab(
        label: loc.all,
        notifications: notifications,
      ),
    ];

    for (final cat in BroadCategory.values) {
      final entries = buckets[cat] ?? const <NotificationUser>[];
      tabs.add(
        _NotificationTab(
          label: cat.localizedName(context),
          notifications: entries,
        ),
      );
    }

    return tabs;
  }
}

class _NotificationTab {
  const _NotificationTab({
    required this.label,
    required this.notifications,
  });

  final String label;
  final List<NotificationUser> notifications;
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    super.key,
    required this.notifications,
    required this.onTap,
    required this.onDelete,
    required this.onConfirm,
    required this.onNegate,
    required this.onMarkRead,
    required this.onOpenEvent,
    required this.onOpenDocument,
  });

  final List<NotificationUser> notifications;
  final ValueChanged<NotificationUser> onTap;
  final ValueChanged<NotificationUser> onDelete;
  final ValueChanged<NotificationUser> onConfirm;
  final ValueChanged<NotificationUser> onNegate;
  final ValueChanged<NotificationUser> onMarkRead;
  final void Function(String eventId, String groupId) onOpenEvent;
  final ValueChanged<NotificationUser> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    if (notifications.isEmpty) {
      return Center(
        child: Text(
          loc.groupNotificationsEmpty,
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final grouped = groupNotificationsByTime(notifications, loc);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: grouped.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              entry.key,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...entry.value.map(
            (notification) => MediaQuery.sizeOf(context).width < 600
                ? MobileNotificationTile(
                    notification: notification,
                    onTap: () => onTap(notification))
                : NotificationCard(
                    notification: notification,
                    onDelete: () => onDelete(notification),
                    onConfirm: () => onConfirm(notification),
                    onNegate: () => onNegate(notification),
                    onMarkRead: () => onMarkRead(notification),
                    onOpenEvent: onOpenEvent,
                    onOpenDocument: () => onOpenDocument(notification),
                  ),
          ),
        ];
      }).toList(),
    );
  }
}
