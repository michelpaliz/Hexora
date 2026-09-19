import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/presentation/viewmodels/groups/group_view_model.dart';
import 'package:provider/provider.dart';

/// Completes the confirmed, visible selection using individual-event permissions.
class PendingEventsBulkAction extends StatelessWidget {
  const PendingEventsBulkAction({super.key, this.events});

  final List<Event>? events;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupUndoneEventsViewModel>();
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final candidates = events ?? vm.pendingEvents;
    final ids = candidates
        .where((e) =>
            e.isDone != true && vm.canManageEvent(e) && !vm.isProcessing(e.id))
        .map((e) => e.id)
        .toList();
    if (ids.isEmpty && !vm.isCompletingAll) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: FilledButton.tonalIcon(
        onPressed: vm.isLoading || vm.hasPendingWrites
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(isEs
                        ? 'Completar eventos pendientes'
                        : 'Complete pending events'),
                    content: Text(isEs
                        ? 'Se marcarán como completados ${ids.length} eventos de la lista actual que puedes gestionar.'
                        : '${ids.length} events you can manage in the current list will be marked as done.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(isEs ? 'Cancelar' : 'Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child:
                              Text(isEs ? 'Completar todos' : 'Complete all')),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                final result = await vm.markAllAsDone(ids);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEs
                      ? '${result.completed} completados. ${result.failed > 0 ? '${result.failed} no se pudieron completar; puedes reintentarlo.' : ''}'
                      : '${result.completed} completed. ${result.failed > 0 ? '${result.failed} could not be completed; you can retry.' : ''}'),
                ));
              },
        icon: vm.isCompletingAll
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.done_all_rounded),
        label: Text(vm.isCompletingAll
            ? '${vm.bulkFinished} / ${vm.bulkTotal}'
            : isEs
                ? 'Marcar todos como hechos (${ids.length})'
                : 'Mark all as done (${ids.length})'),
      ),
    );
  }
}
