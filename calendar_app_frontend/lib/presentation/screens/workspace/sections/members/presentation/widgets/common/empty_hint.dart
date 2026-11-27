// presentation/b-calendar-section/screens/group-screen/members/widgets/empty_hint.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/hexora_empty_state.dart';

class EmptyHint extends StatelessWidget {
  final String title;
  final String message;
  final String tip;
  final IconData icon;
  const EmptyHint({
    super.key,
    required this.title,
    required this.message,
    required this.tip,
    this.icon = Icons.person_search_outlined,
  });

  @override
  Widget build(BuildContext context) => HexoraEmptyState(
        icon: icon,
        title: title,
        description:
            [message, tip].where((text) => text.trim().isNotEmpty).join(' '),
      );
}
