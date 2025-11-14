// c-frontend/b-calendar-section/screens/group-screen/members/widgets/empty_hint.dart
import 'package:flutter/material.dart';

class EmptyHint extends StatelessWidget {
  final String title;
  final String message;
  final String tip;
  const EmptyHint({
    super.key,
    required this.title,
    required this.message,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined,
                size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message),
            const SizedBox(height: 4),
            Text(tip, style: TextStyle(color: onSurfaceVar)),
          ],
        ),
      ),
    );
  }
}
