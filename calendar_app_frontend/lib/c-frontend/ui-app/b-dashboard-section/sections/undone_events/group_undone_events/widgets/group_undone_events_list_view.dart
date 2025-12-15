import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_widgets.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupUndoneEventsListView extends StatelessWidget {
  const GroupUndoneEventsListView({
    super.key,
    required this.events,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.allowAction,
    required this.viewModel,
    this.doneList = false,
    this.showError = false,
    this.errorMessage,
    this.onTapEvent,
  });

  final List<Event> events;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool allowAction;
  final bool doneList;
  final bool showError;
  final String? errorMessage;
  final GroupUndoneEventsViewModel viewModel;
  final ValueChanged<Event>? onTapEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    if (events.isEmpty) {
      final placeholderMessage =
          showError ? (errorMessage ?? emptyMessage) : emptyMessage;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          UndoneEventsPlaceholder(
            icon: showError ? Icons.warning_amber_outlined : emptyIcon,
            message: placeholderMessage,
            actionLabel: showError ? loc.tryAgain : null,
            onAction: showError ? viewModel.refresh : null,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final canManage = viewModel.canManageEvent(event);
        return Card(
          elevation: doneList ? 0 : 1,
          color: doneList
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface,
          child: PendingEventTile(
            event: event,
            enableAction: allowAction && canManage,
            isDone: doneList,
            owner: viewModel.ownerInfoOf(event.ownerId),
            viewModel: viewModel,
            onTap: () {
              if (onTapEvent != null) {
                onTapEvent!(event);
              }
            },
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );
  }
}
