import 'package:flutter/material.dart';

class MetaText extends StatelessWidget {
  final String text;
  const MetaText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
    );
  }
}

class MetaSeparatorDot extends StatelessWidget {
  const MetaSeparatorDot({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
    );
  }
}
