import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/models/notifications/notification_localization.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/service_catalog/service_api_client.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/statements_shared_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_destination.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_density.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationDetailsPanel extends StatefulWidget {
  const NotificationDetailsPanel({
    super.key,
    required this.notification,
    required this.groupName,
    required this.onConfirm,
    required this.onNegate,
    this.onOpen,
    this.openLabel,
    required this.onDelete,
    this.onMarkRead,
    this.onClose,
    this.onOpenRecurrence,
  });

  final NotificationUser? notification;
  final String groupName;
  final VoidCallback? onConfirm;
  final VoidCallback? onNegate;
  final VoidCallback? onOpen;
  final String? openLabel;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  /// Opens the recurrence that generated a document, when navigation and
  /// permissions allow it. Null hides the link.
  final VoidCallback? onOpenRecurrence;

  @override
  State<NotificationDetailsPanel> createState() =>
      _NotificationDetailsPanelState();
}

class _NotificationDetailsPanelState extends State<NotificationDetailsPanel> {
  String? _resolvedClientName;
  String? _resolvedServiceName;
  String? _resolvedOwnerName;

  Future<void> _confirmDelete(bool isEs) async {
    if (widget.onDelete == null) return;
    final confirmed = await showHexoraDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEs ? 'Eliminar notificación' : 'Delete notification'),
        content: Text(isEs
            ? 'Esta acción no se puede deshacer.'
            : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isEs ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete!();
  }

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  @override
  void didUpdateWidget(covariant NotificationDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notification?.id != widget.notification?.id) {
      _resolvedClientName = null;
      _resolvedServiceName = null;
      _resolvedOwnerName = null;
      _loadNames();
    }
  }

  Future<void> _loadNames() async {
    final notification = widget.notification;
    if (notification == null) return;
    final args = EventArgsHelper(notification.args);

    final futures = <Future<void>>[];

    if ((args.clientName ?? '').trim().isEmpty &&
        (args.clientId ?? '').trim().isNotEmpty) {
      futures.add(() async {
        try {
          final client = await ClientsApi().getById(args.clientId!.trim());
          if (!mounted || widget.notification?.id != notification.id) return;
          setState(() => _resolvedClientName =
              client.name.trim().isEmpty ? null : client.name.trim());
        } catch (_) {}
      }());
    }

    if ((args.primaryServiceId ?? '').trim().isNotEmpty) {
      futures.add(() async {
        try {
          final service =
              await ServiceApi().getById(args.primaryServiceId!.trim());
          if (!mounted || widget.notification?.id != notification.id) return;
          setState(() => _resolvedServiceName =
              service.name.trim().isEmpty ? null : service.name.trim());
        } catch (_) {}
      }());
    }

    if ((args.ownerName ?? '').trim().isEmpty &&
        (args.ownerId ?? '').trim().isNotEmpty) {
      futures.add(() async {
        try {
          final owner = await context
              .read<UserDomain>()
              .getUserById(args.ownerId!.trim());
          final name = (owner.displayName?.trim().isNotEmpty ?? false)
              ? owner.displayName!.trim()
              : (owner.name.trim().isNotEmpty
                  ? owner.name.trim()
                  : owner.userName.trim());
          if (!mounted || widget.notification?.id != notification.id) return;
          setState(() => _resolvedOwnerName = name.isEmpty ? null : name);
        } catch (_) {}
      }());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  bool _isSystemActorId(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return normalized == 'system' || normalized == 'sys';
  }

  bool _looksLikeEntityId(String? value) {
    final normalized = value?.trim() ?? '';
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(normalized);
  }

  String? _bestResolvedLabel({
    String? resolvedName,
    String? payloadName,
    String? fallbackId,
  }) {
    final resolved = resolvedName?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }

    final rawName = payloadName?.trim();
    if (rawName != null &&
        rawName.isNotEmpty &&
        !_looksLikeEntityId(rawName) &&
        !_isSystemActorId(rawName)) {
      return rawName;
    }

    final rawId = fallbackId?.trim();
    if (rawId != null && rawId.isNotEmpty) {
      return rawId;
    }

    return null;
  }

  String _fallbackActorLabel({
    required bool isEs,
    String? actorId,
  }) {
    if (_isSystemActorId(actorId)) {
      return isEs ? 'Sistema' : 'System';
    }
    return isEs ? 'Desconocido' : 'Unknown';
  }

  bool _isBankExpenseNotification(NotificationUser notification) {
    final titleKey = notification.titleKey.trim();
    final messageKey = notification.messageKey.trim();
    final title = notification.fallbackTitle.trim().toLowerCase();
    final message = notification.fallbackMessage.trim().toLowerCase();
    return titleKey == 'notification.bankExpensesDetected.title' ||
        titleKey == 'notification.bank.expenses.detected.title' ||
        titleKey == 'notification.suspectExpenses.detected.title' ||
        titleKey == 'notification.statement.expenseDetected.title' ||
        messageKey == 'notification.bankExpensesDetected.message' ||
        messageKey == 'notification.bank.expenses.detected.message' ||
        messageKey == 'notification.suspectExpenses.detected.message' ||
        title.contains('bank expense') ||
        title.contains('gastos bancarios') ||
        message.contains('bank expense') ||
        message.contains('gastos bancarios');
  }

  List<Map<String, dynamic>> _bankExpenseRows(NotificationUser notification) {
    if (!_isBankExpenseNotification(notification)) {
      return const <Map<String, dynamic>>[];
    }
    for (final key in const [
      'expenses',
      'bankExpenses',
      'detectedExpenses',
      'entries',
      'items',
      'rows',
    ]) {
      final value = notification.args[key];
      if (value is List) {
        final rows = value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      }
      if (value is Map && value['items'] is List) {
        final rows = (value['items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
        if (rows.isNotEmpty) return rows;
      }
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (widget.notification == null) {
      return Center(
        child: Text(
          l.groupNotificationsEmpty,
          style: t.bodyMedium.copyWith(
            color: ThemeColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final n = widget.notification!;
    final isBankExpenseNotification = _isBankExpenseNotification(n);
    final bankExpenseRows = _bankExpenseRows(n);
    final hasActions = resolveNotificationDestination(n) ==
            NotificationDestination.invitation ||
        n.questionsAndAnswers.isNotEmpty;

    final documentKey = '${n.titleKey} ${n.fallbackTitle}'.toLowerCase();
    final isDocument = !isBankExpenseNotification &&
        (n.args.containsKey('receiptId') ||
            n.args.containsKey('invoiceId') ||
            RegExp('receipt|invoice|recibo|factura').hasMatch(documentKey));
    final isEvent = !isDocument && isEventNotification(n);
    final meta = resolveNotifMeta(n, cs);
    final args = EventArgsHelper(n.args);
    final locale = Localizations.localeOf(context).toString();
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    final relTime = args.relativeTime(
      inMin: (m) => isEs ? 'en $m min' : 'in $m min',
      inHours: (h) => isEs ? 'en $h h' : 'in $h h',
      agoMin: (m) => isEs ? 'hace $m min' : '$m min ago',
      agoHours: (h) => isEs ? 'hace $h h' : '$h h ago',
      agoDays: (d) => isEs
          ? (d == 1 ? 'hace 1 día' : 'hace $d días')
          : (d == 1 ? '1 day ago' : '$d days ago'),
      inDays: (d) => isEs
          ? (d == 1 ? 'en 1 día' : 'en $d días')
          : (d == 1 ? 'in 1 day' : 'in $d days'),
    );

    final dim = cs.onSurface.withValues(alpha: 0.55);

    final title = isEvent && args.eventTitle != null
        ? args.eventTitle!
        : n.getLocalizedTitle(l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // Both panels stay put; only the changing details fade in.
          child: HexoraMenuContentTransition(
            key: const ValueKey('notification-details-fade'),
            transitionKey: n.id,
            duration: NotifDensity.transition,
            curve: HexoraMotion.enter,
            initialOpacity: 0.55,
            child: SingleChildScrollView(
              key: ValueKey('notification-details-scroll-${n.id}'),
              padding: NotifDensity.detailsPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: icon, title, timestamp and read status grouped, with
                  // the close button aligned to the title line.
                  Row(
                    key: const ValueKey('notification-details-header'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(meta.icon, size: 18, color: meta.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              key: const ValueKey('notification-details-title'),
                              style: t.bodyMedium.copyWith(
                                fontSize: 15.5,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: ThemeColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  formatTimeDifference(n.timestamp, context),
                                  style: t.caption.copyWith(
                                      color: NotifDensity.timestampColor(cs)),
                                ),
                                if (!n.isRead)
                                  _Pill(
                                    label: isEs ? 'No leída' : 'Unread',
                                    color: cs.primary,
                                  ),
                                if (args.action != null)
                                  _Pill(
                                    label: actionLabel(args.action, isEs: isEs),
                                    color: resolveActionMeta(args.action, cs)
                                        .color,
                                  ),
                                if (args.isDone == true)
                                  _Pill(
                                    label: isEs ? 'Hecho' : 'Done',
                                    color: Colors.green.shade600,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.onClose != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: IconButton(
                            key: const ValueKey('notification-details-close'),
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            constraints: const BoxConstraints.tightFor(
                                width: 30, height: 30),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              foregroundColor: cs.onSurfaceVariant,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    n.getLocalizedMessage(l),
                    key: const ValueKey('notification-details-message'),
                    style: t.bodyMedium.copyWith(
                      color: ThemeColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                  if (isDocument)
                    _DocumentDetails(
                        notification: n,
                        onOpenRecurrence: widget.onOpenRecurrence,
                        clientName: _resolvedClientName ?? args.clientName,
                        creatorName: args.createdByName ??
                            args.senderName ??
                            args.ownerName ??
                            _resolvedOwnerName),
                  if (!isDocument) ...[
                    // ── Event section (always for event notifications) ────────────
                    if (isBankExpenseNotification &&
                        bankExpenseRows.isNotEmpty) ...[
                      _SectionDivider(
                        label: isEs ? 'Gastos detectados' : 'Detected expenses',
                        cs: cs,
                        t: t,
                      ),
                      _BankExpenseRowsSection(
                        rows: bankExpenseRows,
                        args: n.args,
                        isEs: isEs,
                      ),
                    ] else if (isBankExpenseNotification) ...[
                      _BankExpenseFallbackSummary(args: n.args, isEs: isEs),
                    ],
                    if (isEvent) ...[
                      _SectionDivider(
                          label: isEs ? 'Evento' : 'Event', cs: cs, t: t),
                      // The event name is already the header title.
                      if (args.eventTitle != null && args.eventTitle != title)
                        _IconDetailRow(
                          icon: Icons.event_rounded,
                          label: isEs ? 'Nombre' : 'Name',
                          value: args.eventTitle!,
                          color: meta.color,
                        ),
                      _IconDetailRow(
                        icon: Icons.person_add_rounded,
                        label: isEs ? 'Creado por' : 'Created by',
                        value: args.createdByName ??
                            args.senderName ??
                            args.ownerName ??
                            _resolvedOwnerName ??
                            _fallbackActorLabel(
                              isEs: isEs,
                              actorId: args.senderId ?? n.senderId,
                            ),
                        color: dim,
                      ),
                      if (args.eventId != null)
                        _IconDetailRow(
                          icon: Icons.tag_rounded,
                          label: 'ID',
                          value: args.eventId!,
                          color: dim,
                        ),
                      if (args.eventType != null)
                        _IconDetailRow(
                          icon: resolveEventTypeMeta(args.eventType, cs).icon,
                          label: isEs ? 'Tipo' : 'Type',
                          value: eventTypeLabel(args.eventType, isEs: isEs),
                          color: resolveEventTypeMeta(args.eventType, cs).color,
                        ),
                      if (args.status != null)
                        _IconDetailRow(
                          icon: resolveStatusMeta(args.status, cs).icon,
                          label: isEs ? 'Estado' : 'Status',
                          value: statusLabel(args.status, isEs: isEs),
                          color: resolveStatusMeta(args.status, cs).color,
                        ),
                      if (args.isDone == true)
                        _IconDetailRow(
                          icon: Icons.task_alt_rounded,
                          label: isEs ? 'Completado' : 'Completed',
                          value: isEs ? 'Sí' : 'Yes',
                          color: Colors.green.shade600,
                        ),
                      if (args.recurrenceRuleId != null)
                        _IconDetailRow(
                          icon: Icons.repeat_rounded,
                          label: isEs ? 'Recurrencia' : 'Recurrence',
                          value: args.recurrenceRuleId!,
                          color: dim,
                        ),
                      if (args.categoryId != null)
                        _IconDetailRow(
                          icon: Icons.label_rounded,
                          label: isEs ? 'Categoría' : 'Category',
                          value: args.subcategoryId != null
                              ? '${args.categoryId!} › ${args.subcategoryId!}'
                              : args.categoryId!,
                          color: dim,
                        ),
                    ],

                    // ── Schedule ──────────────────────────────────────────────────────
                    if (isEvent &&
                        (args.startDate != null ||
                            args.endDate != null ||
                            args.allDay != null ||
                            args.reminderTime != null)) ...[
                      _SectionDivider(
                          label: isEs ? 'Horario' : 'Schedule', cs: cs, t: t),
                      if (args.allDay == true)
                        _IconDetailRow(
                          icon: Icons.wb_sunny_rounded,
                          label: isEs ? 'Todo el día' : 'All day',
                          value: isEs ? 'Sí' : 'Yes',
                          color: Colors.amber.shade600,
                        ),
                      if (args.formattedStartDate(locale) != null)
                        _IconDetailRow(
                          icon: Icons.play_arrow_rounded,
                          label: isEs ? 'Inicio' : 'Start',
                          value: args.formattedStartDate(locale)!,
                          trailing: relTime != null
                              ? _Pill(label: relTime, color: meta.color)
                              : null,
                          color: meta.color,
                        ),
                      if (args.formattedEndDate(locale) != null)
                        _IconDetailRow(
                          icon: Icons.stop_rounded,
                          label: isEs ? 'Fin' : 'End',
                          value: args.formattedEndDate(locale)!,
                          color: dim,
                        ),
                      if (args.formattedReminderTime(isEs: isEs) != null)
                        _IconDetailRow(
                          icon: Icons.alarm_rounded,
                          label: isEs ? 'Recordatorio' : 'Reminder',
                          value: args.formattedReminderTime(isEs: isEs)!,
                          color: const Color(0xFFFF8F00),
                        ),
                    ],

                    // ── Content ───────────────────────────────────────────────────────
                    if (args.location != null ||
                        args.localization != null ||
                        args.description != null ||
                        args.note != null) ...[
                      _SectionDivider(
                          label: isEs ? 'Contenido' : 'Content', cs: cs, t: t),
                      if (args.location != null || args.localization != null)
                        _IconDetailRow(
                          icon: Icons.location_on_rounded,
                          label: isEs ? 'Ubicación' : 'Location',
                          value: args.location ?? args.localization!,
                          color: dim,
                        ),
                      if (args.description != null)
                        _IconDetailRow(
                          icon: Icons.description_rounded,
                          label: isEs ? 'Descripción' : 'Description',
                          value: args.description!,
                          color: dim,
                        ),
                      if (args.note != null)
                        _IconDetailRow(
                          icon: Icons.sticky_note_2_rounded,
                          label: isEs ? 'Nota' : 'Note',
                          value: args.note!,
                          color: dim,
                        ),
                    ],

                    // ── Work visit ────────────────────────────────────────────────────
                    if (args.clientId != null ||
                        args.clientName != null ||
                        args.primaryServiceId != null ||
                        args.stopId != null) ...[
                      _SectionDivider(
                          label: isEs ? 'Visita de trabajo' : 'Work visit',
                          cs: cs,
                          t: t),
                      if (args.clientName != null || args.clientId != null)
                        _IconDetailRow(
                          icon: Icons.person_outline_rounded,
                          label: isEs ? 'Cliente' : 'Client',
                          value: _bestResolvedLabel(
                                resolvedName: _resolvedClientName,
                                payloadName: args.clientName,
                                fallbackId: args.clientId,
                              ) ??
                              args.clientId!,
                          color: dim,
                        ),
                      if (args.primaryServiceId != null ||
                          _resolvedServiceName != null)
                        _IconDetailRow(
                          icon: Icons.home_repair_service_rounded,
                          label: isEs ? 'Servicio' : 'Service',
                          value: _bestResolvedLabel(
                                resolvedName: _resolvedServiceName,
                                payloadName: null,
                                fallbackId: args.primaryServiceId,
                              ) ??
                              args.primaryServiceId!,
                          color: dim,
                        ),
                      if (args.stopId != null)
                        _IconDetailRow(
                          icon: Icons.place_rounded,
                          label: isEs ? 'Parada' : 'Stop',
                          value: args.stopId!,
                          color: dim,
                        ),
                    ],

                    // ── Context ───────────────────────────────────────────────────────
                    ExpansionTile(
                      expansionAnimationStyle:
                          HexoraMotion.expansionStyle(context),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: Text(
                        isEs ? 'Ver detalles' : 'View details',
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            children: [
                              _IconDetailRow(
                                icon: Icons.group_rounded,
                                label: l.groupSectionTitle,
                                value: widget.groupName,
                                color: dim,
                              ),
                              if (args.ownerName != null ||
                                  args.ownerId != null)
                                _IconDetailRow(
                                  icon: Icons.manage_accounts_rounded,
                                  label: isEs ? 'Responsable' : 'Owner',
                                  value: _bestResolvedLabel(
                                        resolvedName: _resolvedOwnerName,
                                        payloadName: args.ownerName,
                                        fallbackId: args.ownerId,
                                      ) ??
                                      args.ownerId!,
                                  color: dim,
                                ),
                              _IconDetailRow(
                                icon: Icons.send_rounded,
                                label: isEs ? 'Enviado por' : 'Sent by',
                                value: args.senderName ??
                                    args.ownerName ??
                                    _fallbackActorLabel(
                                      isEs: isEs,
                                      actorId: args.senderId ?? n.senderId,
                                    ),
                                color: dim,
                              ),
                              _IconDetailRow(
                                icon: Icons.notifications_rounded,
                                label: l.notifications,
                                value: _localizedCategory(n.category, l),
                                color: dim,
                              ),
                              _IconDetailRow(
                                icon: Icons.access_time_rounded,
                                label: isEs ? 'Recibida' : 'Received',
                                value:
                                    formatTimeDifference(n.timestamp, context),
                                color: dim,
                              ),
                              // Priority — always visible
                              _IconDetailRow(
                                icon: Icons.flag_rounded,
                                label: isEs ? 'Prioridad' : 'Priority',
                                value: switch (n.priority) {
                                  PriorityLevel.high => isEs ? 'Alta' : 'High',
                                  PriorityLevel.low => isEs ? 'Baja' : 'Low',
                                  PriorityLevel.medium =>
                                    isEs ? 'Media' : 'Medium',
                                },
                                color: switch (n.priority) {
                                  PriorityLevel.high => Colors.red.shade600,
                                  PriorityLevel.low => Colors.grey.shade500,
                                  PriorityLevel.medium => dim,
                                },
                              ),
                              // Notification type
                              _IconDetailRow(
                                icon: Icons.category_rounded,
                                label: isEs ? 'Tipo de notif.' : 'Notif. type',
                                value: switch (n.type) {
                                  NotificationType.alert =>
                                    isEs ? 'Alerta' : 'Alert',
                                  NotificationType.reminder =>
                                    isEs ? 'Recordatorio' : 'Reminder',
                                  NotificationType.message =>
                                    isEs ? 'Mensaje' : 'Message',
                                  NotificationType.update =>
                                    isEs ? 'Actualización' : 'Update',
                                },
                                color: dim,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (hasActions ||
            widget.onOpen != null ||
            widget.onMarkRead != null ||
            widget.onDelete != null)
          _NotificationDetailsFooter(
            hasActions: hasActions,
            isEs: isEs,
            openLabel: widget.openLabel,
            onConfirm: widget.onConfirm,
            onNegate: widget.onNegate,
            onOpen: widget.onOpen,
            onMarkRead: widget.onMarkRead,
            onDelete: widget.onDelete,
            onDeleteRequested: () => _confirmDelete(isEs),
          ),
      ],
    );
  }
}

class _NotificationDetailsFooter extends StatelessWidget {
  const _NotificationDetailsFooter({
    required this.hasActions,
    required this.isEs,
    required this.openLabel,
    required this.onConfirm,
    required this.onNegate,
    required this.onOpen,
    required this.onMarkRead,
    required this.onDelete,
    required this.onDeleteRequested,
  });

  final bool hasActions;
  final bool isEs;
  final String? openLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onNegate;
  final VoidCallback? onOpen;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;
  final VoidCallback onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const buttonSize = Size(0, 34);
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    final filled = FilledButton.styleFrom(
      minimumSize: buttonSize,
      fixedSize: const Size.fromHeight(34),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: buttonShape,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final outlined = OutlinedButton.styleFrom(
      minimumSize: buttonSize,
      fixedSize: const Size.fromHeight(34),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: buttonShape,
      foregroundColor: cs.primary,
      side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final buttons = <Widget>[
      if (hasActions) ...[
        OutlinedButton(
          onPressed: onNegate,
          style: outlined,
          child: Text(isEs ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: filled,
          child: Text(isEs ? 'Confirmar' : 'Confirm'),
        ),
      ] else ...[
        // Secondary first, primary last: actions read right-to-left by
        // importance.
        if (onMarkRead != null)
          OutlinedButton.icon(
            key: const ValueKey('notification-mark-read'),
            onPressed: onMarkRead,
            style: outlined,
            icon: const Icon(Icons.mark_email_read_outlined, size: 16),
            label: Text(isEs ? 'Marcar como leída' : 'Mark as read'),
          ),
        if (onOpen != null)
          FilledButton.icon(
            key: const ValueKey('notification-open'),
            onPressed: onOpen,
            style: filled,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(openLabel ?? (isEs ? 'Abrir' : 'Open')),
          ),
      ],
    ];
    // Transparent so the panel's light-blue canvas runs underneath; only a
    // hairline separates the fixed action bar from the scrolling details.
    return Container(
      key: const ValueKey('notification-details-footer'),
      padding: NotifDensity.footerPadding,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: buttons,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: isEs ? 'Más acciones' : 'More actions',
            onSelected: (value) {
              if (value == 'delete') onDeleteRequested();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                enabled: onDelete != null,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: cs.error, size: 18),
                    const SizedBox(width: 8),
                    Text(isEs ? 'Eliminar' : 'Delete',
                        style: TextStyle(color: cs.error)),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_horiz_rounded,
                size: 20, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BankExpenseRowsSection extends StatelessWidget {
  const _BankExpenseRowsSection({
    required this.rows,
    required this.args,
    required this.isEs,
  });

  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> args;
  final bool isEs;

  String _text(Map<String, dynamic> row, List<String> keys) {
    return StatementsSharedUtils.entryText(row, keys).trim();
  }

  String _argText(List<String> keys) {
    for (final key in keys) {
      final value = args[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int? _argInt(List<String> keys) {
    for (final key in keys) {
      final value = args[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString().trim() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  bool get _hasMore => args['hasMore'] == true;

  String _currency(Map<String, dynamic> row) {
    final rowCurrency = _text(row, const ['currency']);
    if (rowCurrency.isNotEmpty) return rowCurrency;
    final argsCurrency = _argText(const ['currency']);
    return argsCurrency.isEmpty ? 'EUR' : argsCurrency;
  }

  String _money(BuildContext context, dynamic value, String currency) {
    final parsed = StatementsFormatters.parseAmount(value);
    if (parsed == null) {
      return value?.toString().trim().isNotEmpty == true
          ? value.toString().trim()
          : '-';
    }
    final locale = Localizations.localeOf(context).toString();
    final normalizedCurrency =
        currency.trim().isEmpty ? 'EUR' : currency.trim();
    final formatter = NumberFormat.currency(
      locale: locale,
      name: normalizedCurrency,
      symbol:
          normalizedCurrency.toUpperCase() == 'EUR' ? '€' : normalizedCurrency,
      decimalDigits: 2,
    );
    return formatter.format(parsed);
  }

  String _amount(BuildContext context, Map<String, dynamic> row) {
    final raw = _text(row, const ['amount']);
    return raw.isEmpty ? '-' : _money(context, raw, _currency(row));
  }

  String _date(BuildContext context, Map<String, dynamic> row) {
    final value = _text(row, const [
      'date',
    ]);
    if (value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '-';
    return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  String _description(Map<String, dynamic> row) {
    final value = _text(row, const [
      'description',
      'concept',
      'details',
    ]);
    return value.isEmpty
        ? (isEs ? 'Movimiento bancario' : 'Bank movement')
        : value;
  }

  String _provider(Map<String, dynamic> row) {
    final value = _text(row, const [
      'providerName',
      'counterpartyName',
    ]);
    return value.isEmpty ? (isEs ? 'Sin proveedor' : 'No provider') : value;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final total = _argInt(const ['totalRows', 'count', 'expenseCount']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasMore) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isEs
                  ? 'Mostrando ${rows.length} de ${total ?? rows.length} movimientos detectados.'
                  : 'Showing ${rows.length} of ${total ?? rows.length} detected movements.',
              style: t.bodySmall.copyWith(
                color: cs.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (rows.length == 1)
          _BankExpenseSingleRowCard(
            date: _date(context, rows.first),
            description: _description(rows.first),
            amount: _amount(context, rows.first),
            provider: _provider(rows.first),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              // Subtle row separators instead of a prominent bordered card.
              dividerThickness: NotifDensity.tableDividerThickness,
              headingRowHeight: NotifDensity.tableHeadingHeight,
              dataRowMinHeight: NotifDensity.tableRowMinHeight,
              dataRowMaxHeight: NotifDensity.tableRowMaxHeight,
              horizontalMargin: NotifDensity.tableHorizontalMargin,
              columnSpacing: NotifDensity.tableColumnSpacing,
              headingTextStyle: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
              dataTextStyle: t.caption.copyWith(color: cs.onSurface),
              columns: const [
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Descripción')),
                DataColumn(label: Text('Importe')),
                DataColumn(label: Text('Proveedor')),
              ],
              rows: List<DataRow>.generate(rows.length, (index) {
                final row = rows[index];
                final key = _text(row, const ['entryId', 'id']);
                return DataRow(
                  key: ValueKey(key.isEmpty ? index : key),
                  cells: [
                    DataCell(Text(_date(context, row))),
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Text(
                          _description(row),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _amount(context, row),
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          _provider(row),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _BankExpenseSingleRowCard extends StatelessWidget {
  const _BankExpenseSingleRowCard({
    required this.date,
    required this.description,
    required this.amount,
    required this.provider,
  });

  final String date;
  final String description;
  final String amount;
  final String provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: cs.surfaceContainerHighest.withValues(alpha: .16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(date, style: t.caption.copyWith(color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(
            amount,
            style: t.bodySmall.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          provider,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.caption.copyWith(color: cs.onSurfaceVariant),
        ),
      ]),
    );
  }
}

class _BankExpenseFallbackSummary extends StatelessWidget {
  const _BankExpenseFallbackSummary({
    required this.args,
    required this.isEs,
  });

  final Map<String, dynamic> args;
  final bool isEs;

  String _argText(List<String> keys) {
    for (final key in keys) {
      final value = args[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  int? _argInt(List<String> keys) {
    for (final key in keys) {
      final value = args[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString().trim() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _money(BuildContext context, dynamic value, String currency) {
    final parsed = StatementsFormatters.parseAmount(value);
    if (parsed == null) return '-';
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currency,
      symbol: currency.toUpperCase() == 'EUR' ? '€' : currency,
      decimalDigits: 2,
    );
    return formatter.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final count = _argInt(const ['count', 'expenseCount']);
    final total = _argText(const ['totalAmount']);
    final currency = _argText(const ['currency']).isEmpty
        ? 'EUR'
        : _argText(const ['currency']);
    final sample = _argText(const ['sampleDescription']);
    final summary = count == null
        ? (isEs ? 'Gastos bancarios detectados.' : 'Bank expenses detected.')
        : isEs
            ? 'Se detectaron $count gastos bancarios por un total de ${_money(context, total, currency)}.'
            : '$count bank expenses were detected for a total of ${_money(context, total, currency)}.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Text(
        sample.isEmpty
            ? summary
            : '$summary\n${isEs ? 'Ejemplo' : 'Sample'}: $sample',
        style: t.bodySmall.copyWith(
          color: cs.onSurface.withValues(alpha: 0.78),
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  const _IconDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Widget? trailing;

  /// Slightly stronger value for key facts such as client and amount.
  final bool emphasis;

  /// Fixed label column so every value starts on the same vertical line.
  static const double labelWidth = 118;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: NotifDensity.detailRowPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: labelWidth,
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.caption.copyWith(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: emphasis ? 13.5 : null,
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
    // A hairline opens each metadata group, followed by its small label.
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.55)),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: t.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: NotifDensity.sectionLabelColor(cs),
              letterSpacing: NotifDensity.sectionLabelSpacing,
              fontSize: NotifDensity.sectionLabelSize,
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedCategory(Category category, AppLocalizations loc) {
  switch (category) {
    case Category.groupInvitation:
    case Category.eventReminder:
      return loc.groupNotificationsSectionTitle;
    default:
      return loc.notifications;
  }
}

/// User-facing label for raw document / payment status values.
String documentStatusLabel(String raw, {required bool isEs}) {
  final key = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  final label = switch (key) {
    'draft' => isEs ? 'Borrador' : 'Draft',
    'issued' || 'emitted' => isEs ? 'Emitida' : 'Issued',
    'sent' => isEs ? 'Enviada' : 'Sent',
    'paid' => isEs ? 'Pagada' : 'Paid',
    'partially_paid' ||
    'partial' =>
      isEs ? 'Pagada parcialmente' : 'Partially paid',
    'unpaid' => isEs ? 'Pendiente de pago' : 'Unpaid',
    'pending' => isEs ? 'Pendiente' : 'Pending',
    'overdue' => isEs ? 'Vencida' : 'Overdue',
    'cancelled' ||
    'canceled' ||
    'void' ||
    'voided' =>
      isEs ? 'Anulada' : 'Cancelled',
    'rectified' => isEs ? 'Rectificada' : 'Rectified',
    'confirmed' => isEs ? 'Confirmado' : 'Confirmed',
    'completed' => isEs ? 'Completado' : 'Completed',
    _ => null,
  };
  if (label != null) return label;
  final text = raw.trim().replaceAll('_', ' ');
  return text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}

class _DocumentDetails extends StatelessWidget {
  const _DocumentDetails({
    required this.notification,
    this.clientName,
    this.creatorName,
    this.onOpenRecurrence,
  });
  final NotificationUser notification;
  final String? clientName;
  final String? creatorName;
  final VoidCallback? onOpenRecurrence;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final n = notification;
    String? value(List<String> keys) {
      for (final key in keys) {
        final raw = n.args[key];
        if (raw != null &&
            raw is! Map &&
            raw is! List &&
            raw.toString().trim().isNotEmpty) {
          return raw.toString().trim();
        }
      }
      return null;
    }

    String? clean(String? text) =>
        text == null || text.trim().isEmpty ? null : text.trim();

    // Optional fields render only when they carry a value; the event title is
    // not repeated because it is already the panel header.
    Widget? row(IconData icon, String label, String? text,
            {bool emphasis = false}) =>
        clean(text) == null
            ? null
            : _IconDetailRow(
                icon: icon,
                label: label,
                value: clean(text)!,
                color: cs.onSurfaceVariant,
                emphasis: emphasis,
              );
    final rawAmount = value(['amount', 'totalAmount', 'amountTotal', 'total']);
    final amount = num.tryParse(rawAmount ?? '');
    final currency = value(['currency']) ?? 'EUR';
    final rawDate =
        value(['issueDate', 'issuedAt', 'invoiceDate', 'receiptDate']);
    final date = DateTime.tryParse(rawDate ?? '');
    final reference = value([
      'receiptNumber',
      'invoiceNumber',
      'documentNumber',
      'reference',
      'number'
    ]);
    final recurring = value(['recurrenceName', 'seriesName']);
    final receipt = RegExp('receipt|recibo')
        .hasMatch('${n.titleKey} ${n.fallbackTitle}'.toLowerCase());
    final locale = Localizations.localeOf(context).toString();
    final rawStatus = value(['paymentStatus', 'status']);

    final summary = <Widget>[
      for (final w in [
        row(Icons.person_outline, es ? 'Cliente' : 'Client', clientName,
            emphasis: true),
        row(
            Icons.payments_outlined,
            es ? 'Importe' : 'Amount',
            amount == null
                ? rawAmount
                : NumberFormat.simpleCurrency(locale: locale, name: currency)
                    .format(amount),
            emphasis: true),
        row(
            Icons.calendar_today_outlined,
            es ? 'Fecha de emisión' : 'Issue date',
            date == null ? rawDate : DateFormat.yMMMd(locale).format(date)),
        row(
            Icons.check_circle_outline,
            es ? 'Estado' : 'Status',
            rawStatus == null
                ? null
                : documentStatusLabel(rawStatus, isEs: es)),
        row(
            Icons.credit_card_outlined,
            es ? 'Método de pago' : 'Payment method',
            value(['paymentMethodName', 'paymentMethod'])),
      ])
        if (w != null) w,
    ];
    final details = <Widget>[
      for (final w in [
        row(
            Icons.description_outlined,
            es ? 'Tipo' : 'Type',
            receipt
                ? (es ? 'Recibo' : 'Receipt')
                : (es ? 'Factura' : 'Invoice')),
        row(Icons.receipt_long_outlined, es ? 'Referencia' : 'Reference',
            reference),
        row(Icons.link, es ? 'Relacionado con' : 'Related to',
            value(['relatedInvoiceNumber', 'relatedDocumentNumber'])),
        row(Icons.person_add_outlined, es ? 'Creado por' : 'Created by',
            creatorName),
        row(Icons.notes_outlined, es ? 'Notas' : 'Notes', value(['notes'])),
      ])
        if (w != null) w,
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (recurring != null)
        _RecurrenceBanner(
          name: recurring,
          isEs: es,
          onOpen: onOpenRecurrence,
        ),
      if (summary.isNotEmpty) ...[
        _SectionDivider(label: es ? 'Documento' : 'Document', cs: cs, t: t),
        ...summary,
      ],
      if (details.isNotEmpty) ...[
        _SectionDivider(label: es ? 'Detalles' : 'Details', cs: cs, t: t),
        ...details,
      ],
    ]);
  }
}

class _RecurrenceBanner extends StatelessWidget {
  const _RecurrenceBanner({
    required this.name,
    required this.isEs,
    this.onOpen,
  });

  final String name;
  final bool isEs;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      key: const ValueKey('notification-recurrence-banner'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: cs.primary
            .withValues(alpha: cs.brightness == Brightness.dark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEs ? 'Documento de la recurrencia' : 'Recurring document',
                style: t.caption.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 1),
              Text(
                name,
                key: const ValueKey('notification-recurrence-name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onOpen != null)
          TextButton(
            key: const ValueKey('notification-open-recurrence'),
            onPressed: onOpen,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              textStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            child: Text(isEs ? 'Ver recurrencia' : 'View recurrence'),
          ),
      ]),
    );
  }
}
