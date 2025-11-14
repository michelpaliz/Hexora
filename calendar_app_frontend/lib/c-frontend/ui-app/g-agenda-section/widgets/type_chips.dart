import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TypeChips extends StatelessWidget {
  /// Accepts 'all' | 'simple' | 'work_service' (UI) | 'work_visit' (backend/deeplink)
  final String value;
  final ValueChanged<String> onChanged;

  const TypeChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final all = loc?.allTypes ?? 'All';
    final simple = loc?.simpleEvents ?? 'Simple';
    final work = loc?.workVisits ?? 'Work'; // or "Work services"

    final v = value.toLowerCase();
    final isWork = v == 'work_service' || v == 'work_visit'; // normalize

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: Text(all),
          selected: v == 'all',
          onSelected: (_) => onChanged('all'),
        ),
        ChoiceChip(
          label: Text(simple),
          selected: v == 'simple',
          onSelected: (_) => onChanged('simple'),
        ),
        ChoiceChip(
          label: Text(work),
          selected: isWork,
          onSelected: (_) => onChanged('work_service'), // emit canonical token
        ),
      ],
    );
  }
}
