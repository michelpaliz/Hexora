import 'package:flutter/material.dart';

class StatementsAllDataSkeleton extends StatelessWidget {
  const StatementsAllDataSkeleton({super.key, this.count = 8});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(count, (index) {
        return Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
