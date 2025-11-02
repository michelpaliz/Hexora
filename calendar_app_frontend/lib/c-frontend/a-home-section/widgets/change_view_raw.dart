// lib/c-frontend/home/widgets/change_view_row.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_screen/group_section.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ChangeViewRow extends StatefulWidget {
  const ChangeViewRow({super.key});

  @override
  State<ChangeViewRow> createState() => _ChangeViewRowState();
}

class _ChangeViewRowState extends State<ChangeViewRow> {
  final _axis = ValueNotifier<Axis>(Axis.vertical);

  @override
  void dispose() {
    _axis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final smallBody = Theme.of(context).textTheme.bodySmall!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ smallBody only
          Text(loc.changeView, style: smallBody),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              _axis.value = _axis.value == Axis.vertical
                  ? Axis.horizontal
                  : Axis.vertical;
              GroupListSection.axisOverride.value = _axis.value;
            },
            child: const Icon(Icons.dashboard),
          ),
        ],
      ),
    );
  }
}
