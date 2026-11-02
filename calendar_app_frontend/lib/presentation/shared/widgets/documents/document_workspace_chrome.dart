import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// Shared compact toolbar used by invoice, receipt and proposal lists.
///
/// The caller keeps ownership of navigation, filtering and action callbacks;
/// this widget only standardises their responsive placement and visual rhythm.
class HexoraDocumentToolbar extends StatefulWidget {
  const HexoraDocumentToolbar({
    super.key,
    required this.statusTabs,
    this.viewSwitcher,
    required this.searchHint,
    required this.searchValue,
    required this.onSearchChanged,
    required this.actions,
    this.searchSemanticLabel,
  });

  final Widget statusTabs;
  final Widget? viewSwitcher;
  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final Widget actions;
  final String? searchSemanticLabel;

  @override
  State<HexoraDocumentToolbar> createState() => _HexoraDocumentToolbarState();
}

class _HexoraDocumentToolbarState extends State<HexoraDocumentToolbar> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.searchValue);

  @override
  void didUpdateWidget(covariant HexoraDocumentToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchValue == _controller.text) return;
    _controller.value = TextEditingValue(
      text: widget.searchValue,
      selection: TextSelection.collapsed(offset: widget.searchValue.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final search = Semantics(
      textField: true,
      label: widget.searchSemanticLabel ?? widget.searchHint,
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: _controller,
          onChanged: widget.onSearchChanged,
          textInputAction: TextInputAction.search,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            isDense: true,
            filled: true,
            fillColor: cs.surface.withValues(alpha: .55),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide(
                color: cs.primary.withValues(alpha: .45),
              ),
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final singleRow = constraints.maxWidth >= 1100 &&
            MediaQuery.textScalerOf(context).scale(14) <= 18;
        final content = singleRow
            ? SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Flexible(child: widget.statusTabs),
                    if (widget.viewSwitcher != null) ...[
                      const SizedBox(width: 6),
                      widget.viewSwitcher!,
                    ],
                    const SizedBox(width: 6),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: search,
                      ),
                    ),
                    const Spacer(),
                    widget.actions,
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRect(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: widget.statusTabs,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: widget.actions,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (widget.viewSwitcher != null) ...[
                        widget.viewSwitcher!,
                        const SizedBox(width: 6),
                      ],
                      Expanded(child: search),
                    ],
                  ),
                ],
              );

        return AnimatedSize(
          duration: HexoraMotion.duration(context, HexoraMotion.standard),
          curve: HexoraMotion.emphasized,
          alignment: AlignmentDirectional.topStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: .62),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

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
        child: Container(
          height: 36,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: .32),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < tabs.length; index++) ...[
                if (index > 0) const SizedBox(width: 1),
                _DocumentStatusTabButton(
                  tab: tabs[index],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ],
            ],
          ),
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
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: HexoraMotion.duration(context, HexoraMotion.fast),
          curve: HexoraMotion.enter,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.58)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
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
                      : cs.surface.withValues(alpha: .7),
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
