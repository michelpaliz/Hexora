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
      return Row(mainAxisSize: MainAxisSize.min, children: [
        for (final partners in [false, true])
          _buildTab(
            key:
                ValueKey(partners ? 'directory-partners' : 'directory-workers'),
            selected: showPartners == partners,
            icon: partners ? Icons.groups_outlined : Icons.people_outline,
            label: partners
                ? (isEs ? 'Socios' : 'Partners')
                : (isEs ? 'Trabajadores' : 'Workers'),
            count: partners ? partnerCount : workerCount,
            onTap: () => onChanged(partners),
            cs: cs,
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

  Widget _buildTab({
    required Key key,
    required bool selected,
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    final fg = selected ? cs.primary : cs.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: .16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 34,
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Expanded(
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 16, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      '$label  $count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ]),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: selected ? 28 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
