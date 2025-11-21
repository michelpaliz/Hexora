import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Future<void> showEventDetailSheet({
  required BuildContext context,
  required Event event,
  required GroupUndoneEventsViewModel viewModel,
  bool allowMarkComplete = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return ChangeNotifierProvider.value(
        value: viewModel,
        child: _PendingEventDetailContent(
          event: event,
          allowMarkComplete: allowMarkComplete,
        ),
      );
    },
  );
}

class _PendingEventDetailContent extends StatelessWidget {
  const _PendingEventDetailContent({
    required this.event,
    required this.allowMarkComplete,
  });

  final Event event;
  final bool allowMarkComplete;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroupUndoneEventsViewModel>();
    final loc = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    final date = ml.formatMediumDate(event.startDate);
    final start = ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.startDate));
    final end = ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.endDate));
    final subtitle = '$date · $start – $end';
    final isBusy = vm.isProcessing(event.id);
    final description = (event.description?.trim().isNotEmpty ?? false)
        ? event.description!.trim()
        : '—';
    final alreadyDone = event.isDone == true;
    final owner = vm.ownerInfoOf(event.ownerId);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoHeader(
              title: event.title.isEmpty ? loc.untitledEvent : event.title,
              subtitle: subtitle,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline,
                  color: theme.colorScheme.primary),
              title: Text(loc.createdByLabel),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(owner?.displayName ?? event.ownerId,
                      style: theme.textTheme.bodyMedium),
                  if (owner?.username != null)
                    Text(
                      owner!.username!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.place_outlined,
                  color: theme.colorScheme.primary),
              title: Text(loc.details),
              subtitle: Text(
                description,
              ),
            ),
            const SizedBox(height: 12),
            if (allowMarkComplete)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: Text(loc.pendingEventsMarkDone),
                  onPressed: isBusy || alreadyDone
                      ? null
                      : () async {
                          await vm.markEventAsDone(event.id);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(loc.viewDetails),
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.microtask(() {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EventDetailScreen(event: event),
                    ));
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
