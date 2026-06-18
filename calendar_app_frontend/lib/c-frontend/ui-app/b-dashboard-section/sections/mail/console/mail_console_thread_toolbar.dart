part of '../mail_console_screen.dart';

class _ThreadToolbar extends StatelessWidget {
  const _ThreadToolbar({
    required this.folder,
    required this.searchController,
    required this.searching,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.hasSelection,
    required this.hasUnread,
    required this.onRefresh,
    required this.onToggleRead,
    required this.onArchive,
    required this.onSpam,
    required this.onTrash,
  });

  final MailFolder folder;
  final TextEditingController searchController;
  final bool searching;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final bool hasSelection;
  final bool hasUnread;
  final VoidCallback onRefresh;
  final VoidCallback onToggleRead;
  final VoidCallback onArchive;
  final VoidCallback onSpam;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          // ── Search bar (pill, centered hint) ────────────────────────
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered search icon + hint via textAlign center
                  TextField(
                    controller: searchController,
                    textAlign: searchController.text.isEmpty
                        ? TextAlign.center
                        : TextAlign.start,
                    decoration: InputDecoration(
                      hintText: l.mailConsoleSearchPlaceholder,
                      hintStyle: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      suffixIcon: searching
                          ? Padding(
                              padding: const EdgeInsets.all(9),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                            )
                          : (searchController.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l.mailSearchClear,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  onPressed: onClearSearch,
                                  padding: EdgeInsets.zero,
                                )),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 7),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: t.bodySmall.copyWith(fontSize: 12),
                    textInputAction: TextInputAction.search,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchChanged,
                  ),
                  // Search icon — floats on the left, always visible
                  if (searchController.text.isEmpty)
                    Positioned(
                      left: 12,
                      child: Icon(
                        Icons.search_rounded,
                        size: 15,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ── Bilingual search hint ────────────────────────────────────
          Tooltip(
            message: l.mailThreadSearchTooltip,
            preferBelow: true,
            child: Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 6),
          // ── Refresh ──────────────────────────────────────────────────
          _ToolbarIconBtn(
            icon: Icons.refresh_rounded,
            tooltip: l.refreshAction,
            onTap: onRefresh,
            bgColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            iconColor: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          // ── Divider ──────────────────────────────────────────────────
          SizedBox(
            height: 20,
            child: VerticalDivider(
              width: 14,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 2),
          // ── Selection actions ────────────────────────────────────────
          _ToolbarIconBtn(
            icon: hasUnread
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
            tooltip:
                hasUnread ? l.mailDetailMarkRead : l.mailDetailMarkUnread,
            disabledTooltip: l.mailConsoleSelectThread,
            onTap: hasSelection ? onToggleRead : null,
            bgColor: hasSelection
                ? cs.primary.withValues(alpha: 0.10)
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            iconColor: hasSelection
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.22),
          ),
          const SizedBox(width: 4),
          _ToolbarIconBtn(
            icon: Icons.archive_outlined,
            tooltip: l.mailDetailArchived,
            disabledTooltip: l.mailConsoleSelectThread,
            onTap: hasSelection ? onArchive : null,
            bgColor: hasSelection
                ? cs.secondary.withValues(alpha: 0.10)
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            iconColor: hasSelection
                ? cs.secondary
                : cs.onSurface.withValues(alpha: 0.22),
          ),
          const SizedBox(width: 4),
          _ToolbarIconBtn(
            icon: Icons.report_gmailerrorred_outlined,
            tooltip: l.mailDetailSpammed,
            disabledTooltip: l.mailConsoleSelectThread,
            onTap: hasSelection ? onSpam : null,
            bgColor: hasSelection
                ? const Color(0xFFF59E0B).withValues(alpha: 0.10)
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            iconColor: hasSelection
                ? const Color(0xFFF59E0B)
                : cs.onSurface.withValues(alpha: 0.22),
          ),
          // ── Destructive action (separated) ───────────────────────────────
          const SizedBox(width: 8),
          _ToolbarIconBtn(
            icon: Icons.delete_outline_rounded,
            tooltip: l.mailDetailTrashed,
            disabledTooltip: l.mailConsoleSelectThread,
            onTap: hasSelection ? onTrash : null,
            bgColor: hasSelection
                ? cs.error.withValues(alpha: 0.10)
                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
            iconColor: hasSelection
                ? cs.error
                : cs.onSurface.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconBtn extends StatelessWidget {
  const _ToolbarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
    this.disabledTooltip,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color iconColor;
  final String? disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final effectiveTooltip =
        (onTap == null && disabledTooltip != null) ? disabledTooltip! : tooltip;
    return Tooltip(
      message: effectiveTooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}
