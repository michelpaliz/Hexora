// lib/c-frontend/ui-app/b-dashboard-section/settings/group_settings_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/widgets/notification_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key, required this.group});
  final Group group;

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  String _selectedSection = 'info';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.groupSettingsTitle, style: t.titleLarge),
        centerTitle: false,
        backgroundColor: cs.surface,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: isWide
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSideMenu(context),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildContent(context),
                    ),
                  ],
                ),
              )
            : _buildContent(context),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 22),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: Text(l.goToCalendar),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.groupCalendar,
                      arguments: widget.group,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(l.addEvent),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: Theme.of(context).textTheme.labelLarge,
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addEvent,
                      arguments: widget.group,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const menuWidth = 214.0;

    return SizedBox(
      width: menuWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    label: l.groupInfo,
                    selected: _selectedSection == 'info',
                    onTap: () => setState(() => _selectedSection = 'info'),
                  ),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_none_rounded,
                    label: l.notifications,
                    selected: _selectedSection == 'notifications',
                    onTap: () =>
                        setState(() => _selectedSection = 'notifications'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (selected)
                Container(
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: t.bodySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildContent(BuildContext context) {
    // Show group header only for info section and only on non-web platforms
    final showGroupHeader = _selectedSection == 'info' && !kIsWeb;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGroupHeader) ...[
            GroupHeaderView(group: widget.group),
            const SizedBox(height: 24),
          ],
          _buildSectionContent(context),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context) {
    // Sample notification data - replace with actual data from backend
    final notifications = [
      NotificationUser(
        id: '1',
        senderId: 'system',
        recipientId: widget.group.id,
        titleKey: 'eventReminder',
        messageKey: 'eventReminderMessage',
        fallbackTitle: 'Recordatorio de evento',
        fallbackMessage: '15 minutos antes de cada evento',
        args: {},
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        groupId: widget.group.id,
        isRead: false,
        type: NotificationType.reminder,
        priority: PriorityLevel.high,
        category: Category.eventReminder,
      ),
      NotificationUser(
        id: '2',
        senderId: 'system',
        recipientId: widget.group.id,
        titleKey: 'newClient',
        messageKey: 'newClientMessage',
        fallbackTitle: 'Nuevos clientes',
        fallbackMessage: 'Notificar cuando se añade un cliente',
        args: {},
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        groupId: widget.group.id,
        isRead: false,
        type: NotificationType.alert,
        priority: PriorityLevel.medium,
        category: Category.userInvitation,
      ),
      NotificationUser(
        id: '3',
        senderId: 'system',
        recipientId: widget.group.id,
        titleKey: 'eventCompleted',
        messageKey: 'eventCompletedMessage',
        fallbackTitle: 'Eventos completados',
        fallbackMessage: 'Confirmar finalización de eventos',
        args: {},
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        groupId: widget.group.id,
        isRead: true,
        type: NotificationType.message,
        priority: PriorityLevel.low,
        category: Category.taskUpdate,
      ),
      NotificationUser(
        id: '4',
        senderId: 'system',
        recipientId: widget.group.id,
        titleKey: 'systemUpdate',
        messageKey: 'systemUpdateMessage',
        fallbackTitle: 'Actualizaciones del sistema',
        fallbackMessage: 'Informar sobre nuevas funciones',
        args: {},
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        groupId: widget.group.id,
        isRead: false,
        type: NotificationType.update,
        priority: PriorityLevel.medium,
        category: Category.systemUpdate,
      ),
    ];

    return Column(
      children: [
        for (var notification in notifications)
          NotificationCard(
            notification: notification,
            onDelete: () {
              // Handle delete
            },
            onConfirm: () {
              // Handle confirm
            },
            onNegate: () {
              // Handle negate
            },
          ),
      ],
    );
  }


  Widget _buildSectionContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    switch (_selectedSection) {
      case 'info':
        return FolderSectionCard(
          label: l.groupInfo,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.business,
                  label: 'Nombre del grupo',
                  value: widget.group.name,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Descripción',
                  value: widget.group.description.isNotEmpty
                      ? widget.group.description
                      : 'Sin descripción',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Fecha de creación',
                  value:
                      '${widget.group.createdTime.day}/${widget.group.createdTime.month}/${widget.group.createdTime.year}',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.people_outline,
                  label: 'Miembros',
                  value: '${widget.group.userIds.length} miembros',
                ),
              ],
            ),
          ),
        );
      case 'notifications':
        return FolderSectionCard(
          label: l.notifications,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Añadir notificación',
              onPressed: () {},
              style: IconButton.styleFrom(
                foregroundColor: cs.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
          child: _buildNotificationsList(context),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: t.bodyMedium.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

