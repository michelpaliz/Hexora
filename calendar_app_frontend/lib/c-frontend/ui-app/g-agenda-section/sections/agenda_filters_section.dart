import 'package:hexora/c-frontend/ui-app/g-agenda-section/widgets/agenda_categories.dart';
import 'package:hexora/c-frontend/ui-app/g-agenda-section/widgets/type_chips.dart';
import 'package:flutter/material.dart';


class AgendaFiltersSection extends StatelessWidget {
  final String category;
  final String type;
  final bool showCategories;                         // << was categoryScoped
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onTypeChanged;

  const AgendaFiltersSection({
    super.key,
    required this.category,
    required this.type,
    required this.showCategories,                    // << NEW NAME
    required this.onCategoryChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface.withOpacity(.9);
    final border = BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.4));

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(border),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TypeChips(
                value: type,
                onChanged: onTypeChanged,
              ),
              if (showCategories) ...[
                const SizedBox(height: 6),
                AgendaCategories(
                  selected: category,
                  onSelected: onCategoryChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
