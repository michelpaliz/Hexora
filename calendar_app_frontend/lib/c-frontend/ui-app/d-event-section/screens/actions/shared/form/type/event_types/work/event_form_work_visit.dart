// c-frontend/d-event-section/screens/actions/add_screen/screen/event_form_work_visit.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/utils/form/reminder_options.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/simple/section/title_section.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/section_card_work_type.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit/work_visit_sections.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit_style.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EventFormWorkVisit extends StatefulWidget {
  final BaseEventLogic logic;
  final Future<void> Function() onSubmit;
  final String ownerUserId;
  final bool isEditing;

  /// Optional: lets the parent/router provide a dialog implementation.
  final EventDialogs? dialogs;

  /// show/hide the client & service pickers section
  final bool enableClientServicePickers;

  const EventFormWorkVisit({
    super.key,
    required this.logic,
    required this.onSubmit,
    required this.ownerUserId,
    this.isEditing = false,
    this.dialogs,
    this.enableClientServicePickers = true,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.logic.setEventType?.call('work_visit');

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

    _clientId = widget.logic.clientId;
    _primaryServiceId = widget.logic.primaryServiceId;
  }

  @override
  void didUpdateWidget(covariant EventFormWorkVisit oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStart = widget.logic.selectedStartDate;
    final nextEnd = widget.logic.selectedEndDate;
    if (startDate == nextStart &&
        endDate == nextEnd &&
        _clientId == widget.logic.clientId &&
        _primaryServiceId == widget.logic.primaryServiceId) {
      return;
    }
    setState(() {
      startDate = nextStart;
      endDate = nextEnd;
      _clientId = widget.logic.clientId;
      _primaryServiceId = widget.logic.primaryServiceId;
    });
  }

  Future<void> _handleDateSelection(bool isStart) async {
    await widget.logic.selectDate(context, isStart);
    if (!mounted) return;
    setState(() {
      startDate = widget.logic.selectedStartDate;
      endDate = widget.logic.selectedEndDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    final clients = widget.logic.clients;
    final services = widget.logic.services;

    return Theme(
      data: WorkVisitStyle.compactThemeOf(context),
      child: ListView(
        padding: WorkVisitStyle.outerPadding,
        shrinkWrap: true,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── EVENTO ──────────────────────────────────────────────────────
          // Title — no label, it's the form header
          SectionCard(
            title: loc.title(15),
            child: TitleSection(
              title: loc.title(15),
              cardBuilder: SectionCard.new,
              controller: widget.logic.titleController,
              hintText: loc.titleHint,
            ),
          ),

          // Cliente + Servicio on the same row (responsive)
          if (widget.enableClientServicePickers) ...[
            WorkVisitStyle.sectionGap,
            ClientServiceSection(
              title: loc.workVisit,
              cardBuilder: SectionCard.new,
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
          ],

          // ── HORARIO ──────────────────────────────────────────────────────
          _FormSectionLabel(isSpanish ? 'Horario' : 'Schedule'),
          DateTimeSection(
            title: loc.date,
            cardBuilder: SectionCard.new,
            startDate: startDate,
            endDate: endDate,
            onStartTap: () => _handleDateSelection(true),
            onEndTap: () => _handleDateSelection(false),
          ),

          // ── RECORDATORIO ─────────────────────────────────────────────────
          _FormSectionLabel(isSpanish ? 'Recordatorio' : 'Reminder'),
          ReminderSection(
            title: loc.notifyMe,
            cardBuilder: SectionCard.new,
            notifyMe: _notifyMe,
            reminderMinutes: _reminder,
            onNotifyChanged: (v) {
              setState(() {
                _notifyMe = v;
                if (!v) _reminder = 0;
              });
            },
            onReminderChanged: (val) => _reminder = val,
          ),

          // ── DETALLES ─────────────────────────────────────────────────────
          _FormSectionLabel(isSpanish ? 'Detalles' : 'Details'),
          DescriptionSection(
            title: loc.descriptionLabel,
            cardBuilder: SectionCard.new,
            controller: widget.logic.descriptionController,
          ),
          const SizedBox(height: 8),
          ColorSection(
            title: loc.colorLabel,
            cardBuilder: SectionCard.new,
            selectedColorValue: widget.logic.selectedEventColor,
            onColorChanged: (color) {
              if (color != null) widget.logic.setSelectedColor(color.value);
            },
            colorValues: widget.logic.colorList,
          ),

          // ── PARTICIPANTES ────────────────────────────────────────────────
          _FormSectionLabel(isSpanish ? 'Participantes' : 'Participants'),
          AssignedUsersSection(
            title: loc.assignedUsers,
            cardBuilder: SectionCard.new,
            usersAvailable: widget.logic.users,
            initiallySelected: widget.logic.selectedUsers,
            excludeUserId: widget.ownerUserId,
            onSelectedUsersChanged: (selected) {
              widget.logic.setSelectedUsers(selected);
              setState(() {});
            },
          ),

          // ── RECURRENCIA ──────────────────────────────────────────────────
          _FormSectionLabel(isSpanish ? 'Recurrencia' : 'Recurrence'),
          RepetitionSection(
            title: loc.repetition,
            cardBuilder: SectionCard.new,
            isRepetitive: widget.logic.isRepetitive,
            toggleWidth: widget.logic.toggleWidth,
            onTap: () async {
              final wasRepeated = widget.logic.isRepetitive;

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

          // ── SUBMIT ───────────────────────────────────────────────────────
          WorkVisitStyle.afterSubmitGap,
          ValueListenableBuilder<bool>(
            valueListenable: widget.logic.canSubmit,
            builder: (context, canSubmit, _) {
              final cs = Theme.of(context).colorScheme;
              final label =
                  widget.isEditing ? loc.save : loc.addEvent;
              final icon = widget.isEditing
                  ? Icons.check_rounded
                  : Icons.add_rounded;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: FilledButton.icon(
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
                  icon: Icon(icon, size: 18),
                  label: Text(
                    label,
                    style: typo.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: canSubmit ? Colors.white : null,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: canSubmit ? cs.primary : null,
                    foregroundColor: canSubmit ? Colors.white : null,
                    disabledBackgroundColor:
                        cs.onSurface.withValues(alpha: 0.1),
                    disabledForegroundColor:
                        cs.onSurface.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _FormSectionLabel extends StatelessWidget {
  final String label;
  const _FormSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
