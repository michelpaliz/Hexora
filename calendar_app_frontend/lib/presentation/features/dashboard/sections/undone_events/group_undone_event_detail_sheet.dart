import 'package:flutter/material.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/presentation/features/events/screens/event_screen/event_detail/event_detail_screen.dart';
import 'package:hexora/presentation/features/events/widgets/evidence_photo_thumbnail.dart';
import 'package:hexora/presentation/features/dashboard/sections/members/presentation/widgets/shared/header_info.dart';
import 'package:hexora/presentation/viewmodels/group/group_view_model.dart';
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

    // Use the live event from the view model so photo uploads/completion
    // state stay fresh without needing to re-open the sheet.
    final liveEvent = vm.eventById(event.id) ?? event;

    final date = ml.formatMediumDate(liveEvent.startDate);
    final start =
        ml.formatTimeOfDay(TimeOfDay.fromDateTime(liveEvent.startDate));
    final end = ml.formatTimeOfDay(TimeOfDay.fromDateTime(liveEvent.endDate));
    final subtitle = '$date · $start – $end';
    final isBusy = vm.isProcessing(liveEvent.id);
    final isUploadingEvidence = vm.isUploadingEvidence(liveEvent.id);
    final description = (liveEvent.description?.trim().isNotEmpty ?? false)
        ? liveEvent.description!.trim()
        : '—';
    final alreadyDone = liveEvent.isDone == true;
    final owner = vm.ownerInfoOf(liveEvent.ownerId);
    final requirePhotos = liveEvent.completionRequirements.requirePhotos;
    final minPhotos = liveEvent.completionRequirements.minPhotos;
    final photoCount = liveEvent.completionPhotos.length;
    final needsMorePhotos = liveEvent.needsMorePhotosToComplete;

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
              title:
                  liveEvent.title.isEmpty ? loc.untitledEvent : liveEvent.title,
              subtitle: subtitle,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.person_outline, color: theme.colorScheme.primary),
              title: Text(loc.createdByLabel),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(owner?.displayName ?? liveEvent.ownerId,
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
              leading:
                  Icon(Icons.place_outlined, color: theme.colorScheme.primary),
              title: Text(loc.details),
              subtitle: Text(
                description,
              ),
            ),
            const SizedBox(height: 12),
            if (allowMarkComplete) ...[
              _CompletionEvidenceSection(
                event: liveEvent,
                isUploading: isUploadingEvidence,
                onAddPhotos: (photoType) => vm.addEvidencePhotos(
                  context,
                  liveEvent.id,
                  photoType: photoType,
                ),
                fetchPhotoUrl: (blobName) =>
                    vm.evidencePhotoUrl(liveEvent.id, blobName),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: Icon(
                    needsMorePhotos ? Icons.lock_outline : Icons.check_circle,
                  ),
                  label: Text(
                    requirePhotos && !alreadyDone
                        ? '${loc.pendingEventsMarkDone} ($photoCount/$minPhotos)'
                        : loc.pendingEventsMarkDone,
                  ),
                  onPressed: isBusy || alreadyDone || needsMorePhotos
                      ? null
                      : () async {
                          final success =
                              await vm.markEventAsDone(liveEvent.id);
                          if (!context.mounted) return;
                          if (success) {
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  vm.errorMessage ??
                                      'Failed to mark event as finished.',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
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
                      builder: (_) => EventDetailScreen(event: liveEvent),
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

/// Shows the manager's photo requirement (if any), lets the worker add
/// photos regardless of that requirement, and renders uploaded thumbnails.
class _CompletionEvidenceSection extends StatelessWidget {
  const _CompletionEvidenceSection({
    required this.event,
    required this.isUploading,
    required this.onAddPhotos,
    required this.fetchPhotoUrl,
  });

  final Event event;
  final bool isUploading;
  final ValueChanged<String> onAddPhotos;
  final Future<String> Function(String blobName) fetchPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final requirePhotos = event.completionRequirements.requirePhotos;
    final minPhotos = event.completionRequirements.minPhotos;
    final photos = event.completionPhotos;
    final requireBeforeAfter =
        event.completionRequirements.requireBeforeAfterPhotos;
    final hasBefore = photos.any((photo) => photo.photoType == 'before');
    final hasAfter = photos.any((photo) => photo.photoType == 'after');
    final satisfied = !requirePhotos ||
        (photos.length >= minPhotos &&
            (!requireBeforeAfter || (hasBefore && hasAfter)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 18,
                color: requirePhotos && !satisfied ? cs.error : cs.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requirePhotos
                      ? requireBeforeAfter
                          ? 'Before: ${hasBefore ? 'done' : 'required'} · After: ${hasAfter ? 'done' : 'required'}'
                          : '${photos.length}/$minPhotos photo${minPhotos == 1 ? '' : 's'} required'
                      : 'Photos (optional)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        requirePhotos && !satisfied ? cs.error : cs.onSurface,
                  ),
                ),
              ),
              if (!requireBeforeAfter)
                TextButton.icon(
                  onPressed: isUploading ? null : () => onAddPhotos('general'),
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: Text(isUploading ? 'Uploading…' : 'Add photos'),
                ),
            ],
          ),
          if (requireBeforeAfter) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUploading ? null : () => onAddPhotos('before'),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(hasBefore ? 'Retake before' : 'Take before'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isUploading || !hasBefore
                        ? null
                        : () => onAddPhotos('after'),
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('Take after'),
                  ),
                ),
              ],
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return Column(
                    children: [
                      Expanded(
                        child: EvidencePhotoThumbnail(
                          fetchUrl: () => fetchPhotoUrl(photo.blobName),
                        ),
                      ),
                      if (photo.photoType != 'general')
                        Text(
                          photo.photoType == 'before' ? 'Before' : 'After',
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
