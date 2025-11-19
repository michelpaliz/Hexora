import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupStatsPillsCompact extends StatelessWidget {
  final bool loading;
  final int members;
  final int pending;
  final int total;
  final String localeName;

  const GroupStatsPillsCompact({
    super.key,
    required this.loading,
    required this.members,
    required this.pending,
    required this.total,
    required this.localeName,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PillsSkeleton();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Pill(icon: Icons.group_outlined, label: _num(localeName, members)),
        _Pill(
            icon: Icons.hourglass_top_outlined,
            label: _num(localeName, pending)),
        _Pill(icon: Icons.all_inbox_outlined, label: _num(localeName, total)),
      ],
    );
  }

  String _num(String locale, int v) =>
      NumberFormat.decimalPattern(locale).format(v);
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _PillsSkeleton extends StatelessWidget {
  const _PillsSkeleton();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget box(double w) => Container(
          width: w,
          height: 28,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(999),
          ),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        box(72),
        box(68),
        box(64),
      ],
    );
  }
}
