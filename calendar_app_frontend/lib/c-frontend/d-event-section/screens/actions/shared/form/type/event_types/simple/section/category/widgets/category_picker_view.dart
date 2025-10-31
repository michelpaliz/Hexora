import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/category/event_category.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CategoryPickerView extends StatelessWidget {
  final String? label;
  final bool loading;
  final String? error;

  final List<EventCategory> parents;
  final List<EventCategory> children;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;

  /// If true, each field shows its own labelText; if false, we assume a header is rendered above.
  final bool showFieldLabels;

  final VoidCallback onRefresh;
  final VoidCallback? onCreateParent;
  final VoidCallback? onCreateChild;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;

  final AppLocalizations l10n;

  const CategoryPickerView({
    super.key,
    required this.label,
    required this.loading,
    required this.error,
    required this.parents,
    required this.children,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.showFieldLabels,
    required this.onRefresh,
    required this.onCreateParent,
    required this.onCreateChild,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: cs.surfaceVariant,
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.errorContainer),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            IconButton(
              tooltip: l10n.refresh,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    final header = (label == null)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          );

    // Empty state
    if (parents.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.noCategoriesYet,
                    style: typo.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  tooltip: l10n.addCategory,
                  onPressed: onCreateParent,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final fieldLabelStyle = typo.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,

        // Parent category
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: InputDecoration(
                  labelText:
                      showFieldLabels ? l10n.category : null, // 🔑 no dup
                  labelStyle: fieldLabelStyle,
                ),
                items: parents
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: typo.bodyMedium),
                        ))
                    .toList(),
                onChanged: (v) => onCategoryChanged(v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.addCategory,
              onPressed: onCreateParent,
              icon: const Icon(Icons.add),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Subcategory
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedSubcategoryId,
                decoration: InputDecoration(
                  labelText:
                      showFieldLabels ? l10n.subcategory : null, // 🔑 no dup
                  labelStyle: fieldLabelStyle,
                ),
                items: children
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: typo.bodyMedium),
                        ))
                    .toList(),
                onChanged: selectedCategoryId == null
                    ? null
                    : (v) => onSubcategoryChanged(v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.addSubcategory,
              onPressed: (selectedCategoryId == null) ? null : onCreateChild,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
