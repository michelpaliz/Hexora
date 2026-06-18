import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_localization.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/shared/statements_shared_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    required this.onDelete,
  });

  final NotificationUser? notification;
  final String groupName;
  final VoidCallback? onConfirm;
  final VoidCallback? onNegate;
  final VoidCallback? onDelete;

  @override
  State<NotificationDetailsPanel> createState() =>
      _NotificationDetailsPanelState();
}

class _NotificationDetailsPanelState extends State<NotificationDetailsPanel> {
  String? _resolvedClientName;
  String? _resolvedServiceName;
  String? _resolvedOwnerName;

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
          if (!mounted) return;
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
          if (!mounted) return;
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
          if (!mounted) return;
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
    final hasActions = n.category == Category.groupInvitation ||
        n.questionsAndAnswers.isNotEmpty;

    final isEvent = isEventNotification(n);
    final meta = resolveNotifMeta(n, cs);
    final args = EventArgsHelper(n.args);
    final locale = Localizations.localeOf(context).toString();
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    final relTime = args.relativeTime(
      inMin: (m) => isEs ? 'en $m min' : 'in $m min',
      inHours: (h) => isEs ? 'en $h h' : 'in $h h',
      agoMin: (m) => isEs ? 'hace $m min' : '$m min ago',
      agoHours: (h) => isEs ? 'hace $h h' : '$h h ago',
    );

    final dim = cs.onSurface.withValues(alpha: 0.55);

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
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.icon, size: 20, color: meta.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEvent && args.eventTitle != null
                          ? args.eventTitle!
                          : n.getLocalizedTitle(l),
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: ThemeColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (!n.isRead)
                          _Pill(
                            label: isEs ? 'No leida' : 'Unread',
                            color: meta.color,
                          ),
                        if (args.action != null)
                          _Pill(
                            label: actionLabel(args.action, isEs: isEs),
                            color: resolveActionMeta(args.action, cs).color,
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            n.getLocalizedMessage(l),
            style: t.bodyMedium.copyWith(
              color: ThemeColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          // ── Event section (always for event notifications) ────────────
          if (isBankExpenseNotification && bankExpenseRows.isNotEmpty) ...[
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
            _SectionDivider(label: isEs ? 'Evento' : 'Event', cs: cs, t: t),
            if (args.eventTitle != null)
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
            _SectionDivider(label: isEs ? 'Horario' : 'Schedule', cs: cs, t: t),
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
                label: isEs ? 'Visita de trabajo' : 'Work visit', cs: cs, t: t),
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
            if (args.primaryServiceId != null || _resolvedServiceName != null)
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
          _SectionDivider(label: isEs ? 'Contexto' : 'Context', cs: cs, t: t),
          _IconDetailRow(
            icon: Icons.group_rounded,
            label: l.groupSectionTitle,
            value: widget.groupName,
            color: dim,
          ),
          if (args.ownerName != null || args.ownerId != null)
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
            value: formatTimeDifference(n.timestamp, context),
            color: dim,
          ),
          // Priority — always visible
          _IconDetailRow(
            icon: Icons.flag_rounded,
            label: isEs ? 'Prioridad' : 'Priority',
            value: switch (n.priority) {
              PriorityLevel.high => isEs ? 'Alta' : 'High',
              PriorityLevel.low => isEs ? 'Baja' : 'Low',
              PriorityLevel.medium => isEs ? 'Media' : 'Medium',
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
              NotificationType.alert => isEs ? 'Alerta' : 'Alert',
              NotificationType.reminder => isEs ? 'Recordatorio' : 'Reminder',
              NotificationType.message => isEs ? 'Mensaje' : 'Message',
              NotificationType.update => isEs ? 'Actualización' : 'Update',
            },
            color: dim,
          ),
          if (hasActions) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                    onPressed: widget.onConfirm, child: Text(l.confirm)),
                OutlinedButton(
                    onPressed: widget.onNegate, child: Text(l.cancel)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            label: Text(l.delete, style: TextStyle(color: cs.error)),
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

  String _balance(BuildContext context, Map<String, dynamic> row) {
    final raw = _text(row, const ['balance']);
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 58,
              horizontalMargin: 12,
              columnSpacing: 18,
              headingTextStyle: t.caption.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
              dataTextStyle: t.caption.copyWith(color: cs.onSurface),
              columns: const [
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Descripción')),
                DataColumn(label: Text('Importe')),
                DataColumn(label: Text('Saldo')),
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
                    DataCell(Text(_balance(context, row))),
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
        ),
      ],
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: t.bodySmall
                    .copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: t.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.4),
              height: 1,
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
