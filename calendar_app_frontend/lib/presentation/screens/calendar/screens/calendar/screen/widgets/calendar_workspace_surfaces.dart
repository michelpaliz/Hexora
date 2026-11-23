import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Surfaces for the desktop calendar workspace: the light-blue canvas defines
/// the workspace, and white is reserved for calendar content (mini calendar,
/// toolbar, grid and event details).
class CalendarSurfaceCard extends StatelessWidget {
  const CalendarSurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool clip;

  static BoxDecoration decoration(ColorScheme cs) => BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: decoration(Theme.of(context).colorScheme),
      child: child,
    );
  }
}

/// One compact white toolbar above the grid. Controls scroll horizontally
/// instead of wrapping when the window is narrow.
class CalendarToolbarCard extends StatelessWidget {
  const CalendarToolbarCard({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CalendarSurfaceCard(
      key: const ValueKey('calendar-toolbar-card'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  actions[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact header shared by the right-panel cards: title and close control.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(children: [
        Icon(LucideIcons.calendarDays, size: 17, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            key: const ValueKey('calendar-details-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
          ),
        ),
        if (onClose != null)
          IconButton(
            key: const ValueKey('calendar-details-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 17),
            style: IconButton.styleFrom(
              fixedSize: const Size(30, 30),
              minimumSize: const Size(30, 30),
              padding: EdgeInsets.zero,
              foregroundColor: cs.onSurfaceVariant,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ]),
    );
  }
}

/// Selected event / add / edit: a white card that fills the panel so its
/// content can scroll independently, with the close control always visible.
class CalendarDetailsCard extends StatelessWidget {
  const CalendarDetailsCard({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CalendarSurfaceCard(
      key: const ValueKey('calendar-details-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(title: title, onClose: onClose),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class CalendarQuickAction {
  const CalendarQuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Key? key;
}

/// No event selected: a compact card at the top of the panel that ends where
/// its content ends, leaving the canvas visible below.
class CalendarEmptyDetailsCard extends StatelessWidget {
  const CalendarEmptyDetailsCard({
    super.key,
    required this.title,
    required this.message,
    required this.hint,
    this.actionsTitle,
    this.actions = const [],
    this.onClose,
  });

  final String title;
  final String message;
  final String hint;
  final String? actionsTitle;
  final List<CalendarQuickAction> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: CalendarSurfaceCard(
          key: const ValueKey('calendar-empty-details-card'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeader(title: title, onClose: onClose),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(LucideIcons.calendarSearch,
                          size: 16, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: text.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hint,
                            style: text.bodySmall?.copyWith(
                              fontSize: 12,
                              height: 1.4,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                Divider(
                    height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
                if (actionsTitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Text(
                      actionsTitle!,
                      style: text.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final action in actions)
                        _QuickActionRow(action: action),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.action});

  final CalendarQuickAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: action.key,
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: cs.primary.withValues(alpha: 0.06),
        child: SizedBox(
          height: 34,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Icon(action.icon, size: 16, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 15, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}
