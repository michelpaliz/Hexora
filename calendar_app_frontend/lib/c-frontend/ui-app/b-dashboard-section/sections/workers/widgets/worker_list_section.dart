import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerListSection extends StatelessWidget {
  const WorkerListSection({
    super.key,
    required this.workers,
    required this.onEdit,
    required this.onOpenOverview,
  });

  final List<Worker> workers;
  final void Function(Worker worker) onEdit;
  final void Function(Worker worker) onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: workers.map((w) {
        final isLinked = (w.userId != null && w.userId!.isNotEmpty);
        final initials = (w.displayName ?? w.userId ?? '?').trim().isNotEmpty
            ? (w.displayName ?? w.userId ?? '?').trim()[0].toUpperCase()
            : '?';
        final role = w.roleTag ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onOpenOverview(w),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primary.withOpacity(0.12),
                    child: Text(
                      initials,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.displayName ?? w.userId ?? l.unknownWorker,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLinked ? l.linkedUser : l.externalWorker,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface.withOpacity(0.65),
                          ),
                        ),
                        if (role.isNotEmpty)
                          Text(
                            role,
                            style: t.caption.copyWith(
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l.editWorker,
                    color: cs.primary,
                    onPressed: () => onEdit(w),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
