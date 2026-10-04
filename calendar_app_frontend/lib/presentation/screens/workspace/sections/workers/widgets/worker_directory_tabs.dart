import 'package:flutter/material.dart';
import 'package:hexora/l10n/build_context_locale.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';

enum WorkerPartnerRole { owner, admin, coAdmin }

WorkerPartnerRole? partnerRoleForWorker(Worker worker, Group group) {
  final userId = worker.userId?.trim();
  if (userId == null || userId.isEmpty) return null;
  if (userId == group.ownerId) return WorkerPartnerRole.owner;
  final role = group.userRoles[userId]?.trim().toLowerCase();
  return switch (role) {
    'owner' => WorkerPartnerRole.owner,
    'admin' => WorkerPartnerRole.admin,
    'co-admin' => WorkerPartnerRole.coAdmin,
    _ => null,
  };
}

bool isPartnerWorker(Worker worker, Group group) =>
    partnerRoleForWorker(worker, group) != null;

class WorkerDirectoryTabs extends StatelessWidget {
  const WorkerDirectoryTabs({
    super.key,
    required this.showPartners,
    required this.workerCount,
    required this.partnerCount,
    required this.onChanged,
    this.decorated = false,
    this.compact = false,
  });

  final bool showPartners;
  final int workerCount;
  final int partnerCount;
  final ValueChanged<bool> onChanged;
  final bool decorated;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = context.isSpanishLocale;
    if (decorated) {
      return Wrap(spacing: 10, runSpacing: 8, children: [
        for (final partners in [false, true])
          OutlinedButton(
            key:
                ValueKey(partners ? 'directory-partners' : 'directory-workers'),
            onPressed: () => onChanged(partners),
            style: OutlinedButton.styleFrom(
              backgroundColor: showPartners == partners
                  ? cs.primaryContainer.withValues(alpha: 0.4)
                  : cs.surface,
              foregroundColor:
                  showPartners == partners ? cs.primary : cs.onSurface,
              side: BorderSide(
                  color: showPartners == partners
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.outlineVariant),
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 16, vertical: compact ? 8 : 14),
              minimumSize: compact ? const Size(0, 36) : null,
              visualDensity: compact ? VisualDensity.compact : null,
              textStyle: compact
                  ? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(partners ? Icons.groups_outlined : Icons.people_outline,
                  size: compact ? 16 : 20),
              const SizedBox(width: 8),
              Text(partners
                  ? (isEs ? 'Socios' : 'Partners')
                  : (isEs ? 'Trabajadores' : 'Workers')),
              SizedBox(width: compact ? 6 : 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: showPartners == partners
                      ? cs.primary
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${partners ? partnerCount : workerCount}',
                    style: TextStyle(
                        color: showPartners == partners
                            ? cs.onPrimary
                            : cs.onPrimaryContainer)),
              ),
            ]),
          ),
      ]);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        selected: {showPartners},
        onSelectionChanged: (selection) => onChanged(selection.single),
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          side: BorderSide(color: cs.outlineVariant),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        segments: [
          ButtonSegment(
            value: false,
            label: Text('${isEs ? 'Trabajadores' : 'Workers'} ($workerCount)'),
          ),
          ButtonSegment(
            value: true,
            label: Text('${isEs ? 'Socios' : 'Partners'} ($partnerCount)'),
          ),
        ],
      ),
    );
  }
}
