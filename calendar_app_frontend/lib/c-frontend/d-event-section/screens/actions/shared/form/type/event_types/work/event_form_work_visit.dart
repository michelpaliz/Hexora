// event_form_work_visit.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/screen/widgets/repetition_toggle_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/dialog/user_expandable_card.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/color_picker_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/date_picker_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/description_input_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/reminder_options.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/simple/client_service_pickers.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EventFormWorkVisit extends StatefulWidget {
  final BaseEventLogic logic;
  final Future<void> Function() onSubmit;
  final String ownerUserId;
  final bool isEditing;

  /// Optional: lets the parent/router provide a dialog implementation.
  final EventDialogs? dialogs;

  /// NEW: show/hide the client & service pickers section
  final bool enableClientServicePickers;

  const EventFormWorkVisit({
    super.key,
    required this.logic,
    required this.onSubmit,
    required this.ownerUserId,
    this.isEditing = false,
    this.dialogs,
    this.enableClientServicePickers = true, // default to ON for work visits
  });

  @override
  State<EventFormWorkVisit> createState() => _EventFormWorkVisitState();
}

class _EventFormWorkVisitState extends State<EventFormWorkVisit> {
  late DateTime startDate;
  late DateTime endDate;
  int? _reminder;
  bool _notifyMe = true;

  String? _clientId;
  String? _primaryServiceId;

  @override
  void initState() {
    super.initState();
    startDate = widget.logic.selectedStartDate;
    endDate = widget.logic.selectedEndDate;
    _reminder = widget.logic.reminderMinutes;
    _notifyMe = (_reminder ?? 0) > 0;

    // ensure type and wire dialog hook after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.logic.setEventType?.call('work_visit');

      // If a dialog provider is passed and logic hook is not set, wire it.
      if (widget.dialogs != null &&
          widget.logic.onShowRepetitionDialog == null) {
        widget.logic.onShowRepetitionDialog = (
          BuildContext _, {
          required DateTime selectedStartDate,
          required DateTime selectedEndDate,
          LegacyRecurrenceRule? initialRule,
        }) {
          return widget.dialogs!.showRepetitionDialog(
            context,
            selectedStartDate: selectedStartDate,
            selectedEndDate: selectedEndDate,
            initialRule: initialRule,
          );
        };
      }
    });

    // Preselect if logic already has values
    _clientId = widget.logic.clientId;
    _primaryServiceId = widget.logic.primaryServiceId;
  }

  Future<void> _handleDateSelection(bool isStart) async {
    await widget.logic.selectDate(context, isStart);
    setState(() {
      startDate = widget.logic.selectedStartDate;
      endDate = widget.logic.selectedEndDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final clients = widget.logic.clients; // assume non-null lists from logic
    final services = widget.logic.services; // "

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION TITLE (bodySmall)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            loc.workVisit, // or a more specific string like "Client & Service"
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        ClientServicePickers(
          clients: clients,
          services: services,
          clientId: _clientId,
          serviceId: _primaryServiceId,
          onClientChanged: (v) {
            setState(() => _clientId = v);
            widget.logic.setClientId?.call(v);
          },
          onServiceChanged: (v) {
            setState(() => _primaryServiceId = v);
            widget.logic.setPrimaryServiceId?.call(v);
          },
        ),
        const SizedBox(height: 12),

        // COLOR
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            loc.colorLabel, // ensure exists in l10n, or replace with a literal
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        ColorPickerWidget(
          selectedEventColor: widget.logic.selectedEventColor == null
              ? null
              : Color(widget.logic.selectedEventColor!),
          onColorChanged: (color) {
            if (color != null) widget.logic.setSelectedColor(color.value);
          },
          colorList: widget.logic.colorList.map((c) => Color(c)).toList(),
        ),
        const SizedBox(height: 10),

        // DESCRIPTION
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 2),
          child: Text(
            loc.descriptionLabel,
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        DescriptionInputWidget(
          descriptionController: widget.logic.descriptionController,
          // The field’s own text is typically bodyMedium by default.
        ),
        const SizedBox(height: 12),

        // DATES
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            loc.date, // or something like "Date & Time"
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        DatePickersWidget(
          startDate: startDate,
          endDate: endDate,
          onStartDateTap: () => _handleDateSelection(true),
          onEndDateTap: () => _handleDateSelection(false),
        ),
        const SizedBox(height: 8),

        // REMINDER
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            loc.notifyMe,
            style: typo.bodyMedium,
          ),
          subtitle: Text(
            _notifyMe ? loc.notifyMeOnSubtitle : loc.notifyMeOffSubtitle,
            style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          value: _notifyMe,
          onChanged: (v) {
            setState(() {
              _notifyMe = v;
              if (!v) _reminder = 0;
            });
          },
        ),
        if (_notifyMe) ...[
          const SizedBox(height: 6),
          ReminderTimeDropdownField(
            initialValue: _reminder,
            onChanged: (val) => _reminder = val,
          ),
        ],

        const SizedBox(height: 10),

        // USERS
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 6),
          child: Text(
            loc.assignedUsers, // add to l10n if needed
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        UserExpandableCard(
          usersAvailable: widget.logic.users,
          initiallySelected: widget.logic.selectedUsers,
          excludeUserId: widget.ownerUserId,
          onSelectedUsersChanged: (selected) {
            widget.logic.setSelectedUsers(selected);
            setState(() {});
          },
        ),

        const SizedBox(height: 10),

        // REPETITION
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 6),
          child: Text(
            loc.repetition, // add to l10n if needed
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        RepetitionToggleWidget(
          key: ValueKey(widget.logic.isRepetitive),
          isRepetitive: widget.logic.isRepetitive,
          toggleWidth: widget.logic.toggleWidth,
          onTap: () async {
            final wasRepeated = widget.logic.isRepetitive;

            // If no dialog hook is provided, just toggle
            if (widget.logic.onShowRepetitionDialog == null) {
              setState(() {
                widget.logic.toggleRepetition(
                  !wasRepeated,
                  wasRepeated ? null : widget.logic.recurrenceRule,
                );
              });
              return;
            }

            final result = await widget.logic.onShowRepetitionDialog!(
              context,
              selectedStartDate: widget.logic.selectedStartDate,
              selectedEndDate: widget.logic.selectedEndDate,
              initialRule: widget.logic.recurrenceRule,
            );

            if (result == null || result.isEmpty) {
              setState(() {
                widget.logic.toggleRepetition(
                  !wasRepeated,
                  wasRepeated ? null : widget.logic.recurrenceRule,
                );
              });
              return;
            }

            final LegacyRecurrenceRule? rule =
                result[0] as LegacyRecurrenceRule?;
            final bool isRepeated =
                result.length > 1 ? result[1] as bool : true;

            setState(() {
              widget.logic.toggleRepetition(isRepeated, rule);
            });
          },
        ),

        const SizedBox(height: 24),
        Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.logic.canSubmit,
            builder: (context, canSubmit, _) {
              return ElevatedButton(
                onPressed: canSubmit
                    ? () async {
                        widget.logic.setReminderMinutes(
                          _notifyMe
                              ? (_reminder ?? kDefaultReminderMinutes)
                              : 0,
                        );
                        await widget.onSubmit();
                      }
                    : null,
                child: Text(
                  widget.isEditing ? loc.save : loc.addEvent,
                  style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
