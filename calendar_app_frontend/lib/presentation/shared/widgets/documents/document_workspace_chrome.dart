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
    this.searchMaxWidth = 320,
    this.centerSearch = false,
  });

  final Widget statusTabs;
  final Widget? viewSwitcher;
  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final Widget actions;
  final String? searchSemanticLabel;
  final double searchMaxWidth;
  final bool centerSearch;

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
        height: widget.centerSearch ? 40 : 36,
        child: TextField(
          controller: _controller,
          onChanged: widget.onSearchChanged,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12.5),
          decoration: InputDecoration(
            constraints: widget.centerSearch
                ? const BoxConstraints.tightFor(height: 40)
                : null,
            hintText: widget.searchHint,
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant,
                ),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: widget.searchValue.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        Localizations.localeOf(context).languageCode == 'es'
                            ? 'Limpiar búsqueda'
                            : 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      widget.onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                  ),
            prefixIconConstraints: BoxConstraints(
              minWidth: widget.centerSearch ? 44 : 36,
              minHeight: widget.centerSearch ? 40 : 36,
            ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: 40,
              height: 36,
            ),
            isDense: true,
            filled: true,
            fillColor: widget.centerSearch
                ? cs.primary.withValues(alpha: .045)
                : cs.surface.withValues(alpha: .55),
            contentPadding: widget.centerSearch
                ? const EdgeInsets.symmetric(horizontal: 14)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: widget.centerSearch
                  ? BorderSide(color: cs.outlineVariant.withValues(alpha: .5))
                  : BorderSide.none,
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
        final singleRow =
            constraints.maxWidth >= (widget.centerSearch ? 1280 : 1100) &&
                MediaQuery.textScalerOf(context).scale(14) <= 18;
        final centeredRow = SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(child: widget.statusTabs),
                    if (widget.viewSwitcher != null) ...[
                      const SizedBox(width: 8),
                      widget.viewSwitcher!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: (constraints.maxWidth * .30)
                    .clamp(320.0, widget.searchMaxWidth),
                child: search,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: widget.actions,
                ),
              ),
            ],
          ),
        );
        final content = singleRow && widget.centerSearch
            ? centeredRow
            : singleRow
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
                            constraints:
                                BoxConstraints(maxWidth: widget.searchMaxWidth),
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
                          Expanded(
                            child: widget.centerSearch
                                ? Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: widget.searchMaxWidth,
                                      ),
                                      child: search,
                                    ),
                                  )
                                : search,
                          ),
                          if (widget.centerSearch &&
                              widget.viewSwitcher != null)
                            Visibility(
                              visible: false,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: widget.viewSwitcher!,
                              ),
                            ),
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
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: .45),
              ),
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: .45),
            ),
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
                ? cs.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(color: cs.primary.withValues(alpha: .28))
                : null,
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
                      ? cs.primary.withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest.withValues(alpha: .75),
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
    this.compact = false,
    this.statusInline = false,
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
  final bool compact;
  final bool statusInline;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final subtitle = dateLabel.trim().isEmpty
        ? clientName
        : '$clientName · ${dateLabel.trim()}';

    Widget statusBadge() => Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 7,
            vertical: compact ? 2 : 3,
          ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: statusColor,
                  fontSize: compact ? 10.5 : 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

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
            fixedSize: Size.square(compact ? 28 : 30),
            minimumSize: Size.square(compact ? 28 : 30),
            padding: EdgeInsets.zero,
            foregroundColor: cs.onSurfaceVariant,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

    return SizedBox(
      height: compact ? 44 : 48,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
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
                      if (statusInline) ...[
                        const SizedBox(width: 6),
                        Flexible(child: statusBadge()),
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
            if (!statusInline) ...[
              const SizedBox(width: 6),
              statusBadge(),
            ],
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
