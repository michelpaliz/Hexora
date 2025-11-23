import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupStatsPillsCompact extends StatelessWidget {
  final bool loading;
  final int members;
  final String localeName;
  final int? clientCount;
  final int? workerCount;
  final int? pendingEventsCount;
  final VoidCallback? onMembersTap;
  final VoidCallback? onClientsTap;
  final VoidCallback? onWorkersTap;
  final VoidCallback? onPendingEventsTap;

  const GroupStatsPillsCompact({
    super.key,
    required this.loading,
    required this.members,
    required this.localeName,
    this.clientCount,
    this.workerCount,
    this.pendingEventsCount,
    this.onMembersTap,
    this.onClientsTap,
    this.onWorkersTap,
    this.onPendingEventsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _PillsSkeleton();

    final pills = <_Pill>[
      _Pill(
        icon: Icons.group_outlined,
        label: _num(localeName, members),
        onTap: onMembersTap,
      ),
    ];

    if (pendingEventsCount != null) {
      pills.add(
        _Pill(
          icon: Icons.pending_actions_outlined,
          label: _num(localeName, pendingEventsCount!),
          onTap: onPendingEventsTap,
        ),
      );
    }

    if (clientCount != null) {
      pills.add(
        _Pill(
          icon: Icons.handshake_outlined,
          label: _num(localeName, clientCount!),
          onTap: onClientsTap,
        ),
      );
    }

    if (workerCount != null) {
      pills.add(
        _Pill(
          icon: Icons.badge_outlined,
          label: _num(localeName, workerCount!),
          onTap: onWorkersTap,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills,
    );
  }

  String _num(String locale, int v) =>
      NumberFormat.decimalPattern(locale).format(v);
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Pill({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pill = Container(
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

    if (onTap == null) return pill;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: pill,
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
