import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';

/// Inbox actions share the workspace's expanded and icon-only navigation.
class ChatSidebarMenu extends StatelessWidget {
  const ChatSidebarMenu({
    super.key,
    required this.collapsed,
    required this.onMembers,
    this.onCreateTeam,
    this.onCreateIssue,
  });

  final bool collapsed;
  final VoidCallback onMembers;
  final VoidCallback? onCreateTeam;
  final VoidCallback? onCreateIssue;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCreateTeam != null || onCreateIssue != null)
            MenuAnchor(
              menuChildren: [
                if (onCreateTeam != null)
                  MenuItemButton(
                    onPressed: onCreateTeam,
                    leadingIcon: const Icon(Icons.group_add_outlined),
                    child: Text(es ? 'Nuevo chat de equipo' : 'New team chat'),
                  ),
                if (onCreateIssue != null)
                  MenuItemButton(
                    onPressed: onCreateIssue,
                    leadingIcon:
                        const Icon(Icons.report_gmailerrorred_outlined),
                    child: Text(es ? 'Nueva incidencia' : 'New incident'),
                  ),
              ],
              builder: (context, controller, child) => SidebarItem(
                icon: Icons.add,
                label: es ? 'Nueva conversación' : 'New conversation',
                isSelected: controller.isOpen,
                collapsed: collapsed,
                primaryAction: true,
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          SidebarItem(
            icon: Icons.people_outline,
            label: es ? 'Miembros' : 'Members',
            isSelected: false,
            collapsed: collapsed,
            onTap: onMembers,
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  es ? 'CONVERSACIONES' : 'CONVERSATIONS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
