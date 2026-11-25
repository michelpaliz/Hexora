import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

import '../insights_chat_enums.dart';

class InsightsAssistantSidebar extends StatelessWidget {
  const InsightsAssistantSidebar({
    super.key,
    required this.isSpanish,
    required this.collapsed,
    required this.days,
    required this.mode,
    required this.sending,
    required this.onToggleCollapsed,
    required this.onNewConversation,
    required this.onCurrentConversation,
    required this.onHistory,
    required this.onResetConversation,
    required this.onContext,
    required this.onModeChanged,
    required this.onVisitGuide,
    required this.onInformation,
  });

  final bool isSpanish;
  final bool collapsed;
  final int days;
  final InsightsResponseMode mode;
  final bool sending;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onNewConversation;
  final VoidCallback onCurrentConversation;
  final VoidCallback onHistory;
  final VoidCallback onResetConversation;
  final VoidCallback onContext;
  final ValueChanged<InsightsResponseMode> onModeChanged;
  final VoidCallback onVisitGuide;
  final VoidCallback onInformation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget selectedMark(bool selected) => Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          size: HexoraIconTokens.compact,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        );

    return CollapsibleSidebar(
      title: isSpanish ? 'Asistente IA' : 'AI assistant',
      headerIcon: Icons.auto_awesome_rounded,
      collapsed: collapsed,
      onToggleCollapsed: onToggleCollapsed,
      items: const [],
      secondaryHeader: true,
      expandTooltip:
          isSpanish ? 'Expandir menú del asistente' : 'Expand assistant menu',
      collapseTooltip: isSpanish
          ? 'Compactar menú del asistente'
          : 'Collapse assistant menu',
      primaryAction: CollapsibleSidebarItem(
        key: const ValueKey('assistant-new-conversation'),
        icon: Icons.add_comment_outlined,
        label: isSpanish ? 'Nueva conversación' : 'New conversation',
        onTap: sending ? null : onNewConversation,
      ),
      groups: [
        CollapsibleSidebarGroup(
          label: isSpanish ? 'CONVERSACIÓN' : 'CONVERSATION',
          items: [
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-current-conversation'),
              icon: Icons.chat_bubble_outline_rounded,
              label: isSpanish ? 'Conversación actual' : 'Current conversation',
              selected: true,
              onTap: onCurrentConversation,
            ),
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-conversation-history'),
              icon: Icons.history_rounded,
              label: isSpanish ? 'Historial' : 'History',
              onTap: onHistory,
            ),
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-reset-conversation'),
              icon: Icons.restart_alt_rounded,
              label:
                  isSpanish ? 'Reiniciar conversación' : 'Reset conversation',
              onTap: sending ? null : onResetConversation,
            ),
          ],
        ),
        CollapsibleSidebarGroup(
          label: isSpanish ? 'CONFIGURACIÓN' : 'SETTINGS',
          items: [
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-context'),
              icon: Icons.calendar_today_rounded,
              label: isSpanish ? 'Contexto' : 'Context',
              trailing: Text(
                '${days}d',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              onTap: onContext,
            ),
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-mode-auto'),
              icon: Icons.auto_fix_high_rounded,
              label: 'Auto',
              selected: mode == InsightsResponseMode.auto,
              trailing: selectedMark(mode == InsightsResponseMode.auto),
              onTap: () => onModeChanged(InsightsResponseMode.auto),
            ),
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-mode-stream'),
              icon: Icons.stream_rounded,
              label: 'Stream',
              selected: mode == InsightsResponseMode.stream,
              trailing: selectedMark(mode == InsightsResponseMode.stream),
              onTap: () => onModeChanged(InsightsResponseMode.stream),
            ),
          ],
        ),
        CollapsibleSidebarGroup(
          label: isSpanish ? 'AYUDA' : 'HELP',
          items: [
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-visit-guide'),
              icon: Icons.event_note_outlined,
              label: isSpanish ? 'Guía de visitas' : 'Visit guide',
              onTap: onVisitGuide,
            ),
            CollapsibleSidebarItem(
              key: const ValueKey('assistant-information'),
              icon: Icons.info_outline_rounded,
              label: isSpanish ? 'Información' : 'Information',
              onTap: onInformation,
            ),
          ],
        ),
      ],
    );
  }
}
