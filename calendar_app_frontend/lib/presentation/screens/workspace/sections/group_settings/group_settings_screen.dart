import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/settings/sections/settings_info_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/widgets/folder_section_card.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/widgets/notification_card.dart';
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
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SectionAppBar(
        title: l.groupSettingsTitle,
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

  Widget _buildSideMenu(BuildContext context) =>
      NavigationSurface(builder: _buildNavigation);

  Widget _buildNavigation(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const menuWidth = NavigationTokens.sidebarWidth;

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
    return SidebarItem(icon: icon, label: label, isSelected: selected,
      collapsed: false, onTap: onTap);
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildSectionContent(context),
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
        return SettingsInfoSection(group: widget.group);
      case 'notifications':
        return FolderSectionCard(
          label: l.notifications,
          showTitle: false,
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

}
