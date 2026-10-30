import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class HexoraDocumentStatusTab {
  const HexoraDocumentStatusTab({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;
}

class HexoraDocumentStatusTabs extends StatelessWidget {
  const HexoraDocumentStatusTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<HexoraDocumentStatusTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < tabs.length; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              _DocumentStatusTabButton(
                tab: tabs[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ],
          ],
        ),
      );
}

class _DocumentStatusTabButton extends StatelessWidget {
  const _DocumentStatusTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final HexoraDocumentStatusTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${tab.label}, ${tab.count}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.42)
                  : cs.outlineVariant.withValues(alpha: 0.52),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 15,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tab.count}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HexoraDocumentDetailHeader extends StatelessWidget {
  const HexoraDocumentDetailHeader({
    super.key,
    required this.title,
    required this.clientName,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.dateLabel,
    required this.moreActions,
    this.onPrevious,
    this.onNext,
    this.onClose,
    this.onExpand,
    this.isExpanded = false,
    this.trailingLabel,
  });

  final String title;
  final String clientName;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String dateLabel;
  final Widget moreActions;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onClose;
  final VoidCallback? onExpand;
  final bool isExpanded;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final subtitle = dateLabel.trim().isEmpty
        ? clientName
        : '$clientName · ${dateLabel.trim()}';

    Widget actionButton({
      required String tooltip,
      required IconData icon,
      required VoidCallback? onPressed,
    }) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          style: IconButton.styleFrom(
            fixedSize: const Size(30, 30),
            minimumSize: const Size(30, 30),
            padding: EdgeInsets.zero,
            foregroundColor: cs.onSurfaceVariant,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            actionButton(
              tooltip: isEs ? 'Documento anterior' : 'Previous document',
              icon: Icons.chevron_left_rounded,
              onPressed: onPrevious,
            ),
            actionButton(
              tooltip: isEs ? 'Documento siguiente' : 'Next document',
              icon: Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium.copyWith(
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if ((trailingLabel ?? '').trim().isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Text(
                          trailingLabel!.trim(),
                          style: t.caption.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Tooltip(
                    message: subtitle,
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 11, color: statusColor),
                  const SizedBox(width: 3),
                  Text(
                    statusLabel,
                    style: t.bodySmall.copyWith(
                      color: statusColor,
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (onExpand != null)
              actionButton(
                tooltip: isExpanded
                    ? (isEs ? 'Restaurar' : 'Restore')
                    : (isEs ? 'Ampliar panel' : 'Expand panel'),
                icon: isExpanded
                    ? Icons.close_fullscreen_rounded
                    : Icons.open_in_full_rounded,
                onPressed: onExpand,
              ),
            moreActions,
            if (onClose != null)
              actionButton(
                tooltip: isEs ? 'Cerrar panel' : 'Close panel',
                icon: Icons.close_rounded,
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}
