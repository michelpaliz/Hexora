import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/events/event.dart';
import 'package:hexora/presentation/screens/events/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/presentation/viewmodels/groups/group_view_model.dart';
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
    final liveEvent = vm.eventById(event.id) ?? event;
    final loc = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    final date = ml.formatMediumDate(event.startDate);
    final start = ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.startDate));
    final end = ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.endDate));
    final subtitle = '$date · $start – $end';
    final isBusy =
        vm.isProcessing(event.id) || vm.isUploadingEvidence(event.id);
    final description = (event.description?.trim().isNotEmpty ?? false)
        ? event.description!.trim()
        : '—';
    final alreadyDone = liveEvent.isDone == true;
    final owner = vm.ownerInfoOf(event.ownerId);

    Future<void> addPhoto(String type) async {
      final success = await vm.addEvidencePhotos(event.id, photoType: type);
      if (!success && context.mounted && vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.completionPhotoError)),
        );
      }
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
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
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
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
                if (liveEvent.completionRequirements.requirePhotos ||
                    liveEvent.completionPhotos.isNotEmpty) ...[
                  Text(
                    loc.completionPhotosCount(
                      liveEvent.completionPhotos.length,
                      liveEvent.completionRequirements.minPhotos,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isBusy || alreadyDone
                          ? null
                          : () => addPhoto('general'),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(loc.addCompletionPhotos),
                    ),
                  ),
                  if (liveEvent
                      .completionRequirements.requireBeforeAfterPhotos) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: isBusy || alreadyDone
                              ? null
                              : () => addPhoto('before'),
                          child: Text(loc.addBeforePhoto),
                        ),
                        OutlinedButton(
                          onPressed: isBusy ||
                                  alreadyDone ||
                                  !liveEvent.completionPhotos
                                      .any((p) => p.photoType == 'before')
                              ? null
                              : () => addPhoto('after'),
                          child: Text(loc.addAfterPhoto),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                if (allowMarkComplete)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: Text(loc.pendingEventsMarkDone),
                      onPressed: isBusy ||
                              alreadyDone ||
                              liveEvent.needsMorePhotosToComplete
                          ? null
                          : () async {
                              await vm.markEventAsDone(event.id);
                              if (!context.mounted) return;
                              if (vm.eventById(event.id)?.isDone == true) {
                                Navigator.of(context).pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(loc.completionPhotoError)),
                                );
                              }
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
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      Future<void>.microtask(() {
                        if (!navigator.mounted) return;
                        navigator.push(MaterialPageRoute(
                          builder: (_) => EventDetailScreen(event: event),
                        ));
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
