import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class FilterChips extends StatelessWidget {
  final bool showAccepted;
  final bool showPending;
  final bool showNotWantedToJoin;

  final void Function(String token, bool selected) onFilterChange;

  final String acceptedText;
  final String pendingText;
  final String notAcceptedText;

  final Color acceptedColor;
  final Color pendingColor;
  final Color notAcceptedColor;

  const FilterChips({
    super.key,
    required this.showAccepted,
    required this.showPending,
    required this.showNotWantedToJoin,
    required this.onFilterChange,
    required this.acceptedText,
    required this.pendingText,
    required this.notAcceptedText,
    this.acceptedColor = const Color(0xFFE07A5F), // terracotta
    this.pendingColor = const Color(0xFFF2CC8F), // warm honey
    this.notAcceptedColor = const Color(0xFFE63946), // coral red
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _buildChip(
          context: context,
          label: acceptedText,
          selected: showAccepted,
          baseColor: acceptedColor,
          onSelected: (v) => onFilterChange('Accepted', v),
        ),
        _buildChip(
          context: context,
          label: pendingText,
          selected: showPending,
          baseColor: pendingColor,
          onSelected: (v) => onFilterChange('Pending', v),
        ),
        _buildChip(
          context: context,
          label: notAcceptedText,
          selected: showNotWantedToJoin,
          baseColor: notAcceptedColor,
          onSelected: (v) => onFilterChange('NotAccepted', v),
        ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required Color baseColor,
    required ValueChanged<bool> onSelected,
  }) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final bgSelected = baseColor;
    final fgSelected = _onColor(bgSelected);
    final bgUnselected = cs.surfaceVariant.withOpacity(0.5);
    final borderUnselected = cs.outlineVariant.withOpacity(0.5);
    final fgUnselected = baseColor;

    // ✅ Remove Material overlay entirely by disabling Ink effects.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? bgSelected : bgUnselected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? Colors.transparent : borderUnselected,
          width: 1.2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: baseColor.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          onTap: () => onSelected(!selected),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: typo.bodySmall.copyWith(
                color: selected ? fgSelected : fgUnselected,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _onColor(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    return (brightness == Brightness.dark) ? Colors.white : Colors.black;
  }
}
