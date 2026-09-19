// presentation/d-event-section/screens/actions/add_screen/screen/event_form_work_visit.dart
import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/recurrence/legacy_recurrence_rule.dart';
import 'package:hexora/presentation/screens/events/utils/color_manager.dart';
import 'package:hexora/presentation/screens/events/screens/actions/add_screen/utils/form/reminder_options.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/simple/section/title_section.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/section_card_work_type.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/work_visit/work_visit_sections.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/work_visit_style.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EventFormWorkVisit extends StatefulWidget {
  final BaseEventLogic logic;
  final Future<void> Function() onSubmit;
  final String ownerUserId;
  final bool isEditing;
  final bool showSubmitButton;

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
    this.showSubmitButton = true,
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
  bool _advancedExpanded = false;

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

  Future<void> _handleRepetitionTap() async {
    final wasRepeated = widget.logic.isRepetitive;
    if (widget.logic.onShowRepetitionDialog == null) {
      widget.logic.toggleRepetition(!wasRepeated, null);
      setState(() {});
      return;
    }

    final result = await widget.logic.onShowRepetitionDialog!(
      context,
      selectedStartDate: widget.logic.selectedStartDate,
      selectedEndDate: widget.logic.selectedEndDate,
      initialRule: widget.logic.recurrenceRule,
    );
    if (!mounted || result == null || result.isEmpty) return;
    final rule = result[0] as LegacyRecurrenceRule?;
    final isRepeated = result.length > 1 ? result[1] as bool : true;
    widget.logic.toggleRepetition(isRepeated, rule);
    setState(() {});
  }

  Future<void> _chooseReminder() async {
    final loc = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(loc.reminderLabel,
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text(loc.eventFormOff),
                      trailing:
                          !_notifyMe ? const Icon(Icons.check_rounded) : null,
                      onTap: () => Navigator.pop(sheetContext, -1),
                    ),
                    ...getLocalizedReminderOptions(sheetContext)
                        .map((option) => ListTile(
                              title: Text(option.label),
                              trailing: _notifyMe && option.value == _reminder
                                  ? const Icon(Icons.check_rounded)
                                  : null,
                              onTap: () =>
                                  Navigator.pop(sheetContext, option.value),
                            )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _notifyMe = selected >= 0;
      if (selected >= 0) _reminder = selected;
    });
    widget.logic.setReminderMinutes(selected < 0 ? 0 : selected);
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
          TitleSection(
            title: loc.title(15),
            cardBuilder: SectionCard.new,
            controller: widget.logic.titleController,
            hintText: loc.titleHint,
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

          // ── RESPONSABLES ──────────────────────────────────────────────
          const SizedBox(height: 16),
          AssignedUsersSection(
            title: loc.delegateVisit,
            cardBuilder: SectionCard.new,
            usersAvailable: widget.logic.users,
            initiallySelected: widget.logic.selectedUsers,
            excludeUserId: widget.ownerUserId,
            onSelectedUsersChanged: (selected) {
              widget.logic.setSelectedUsers(selected);
              setState(() {});
            },
          ),

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

          // ── AL COMPLETAR ────────────────────────────────────────────────
          _FormSectionLabel(loc.eventFormCompletion),
          _PhotoRequirementTile(
            value: widget.logic.requiresCompletionPhotos,
            minimumPhotos: widget.logic.completionRequirements.minPhotos,
            onChanged: widget.logic.setRequiresCompletionPhotos,
          ),

          // ── OPCIONES ────────────────────────────────────────────────────
          _FormSectionLabel(loc.eventFormOptions),
          _OptionsCard(
            reminderEnabled: _notifyMe,
            reminderMinutes: _reminder,
            onReminderTap: _chooseReminder,
            isRepetitive: widget.logic.isRepetitive,
            onRepetitionTap: _handleRepetitionTap,
          ),

          // ── DETALLES ─────────────────────────────────────────────────────
          _FormSectionLabel(isSpanish ? 'Detalles' : 'Details'),
          DescriptionSection(
            title: loc.descriptionLabel,
            cardBuilder: SectionCard.new,
            controller: widget.logic.descriptionController,
          ),
          const SizedBox(height: 16),
          Material(
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              initiallyExpanded: _advancedExpanded,
              onExpansionChanged: (value) =>
                  setState(() => _advancedExpanded = value),
              title: Text(loc.eventFormMoreOptions),
              subtitle: widget.logic.selectedEventColor == null
                  ? null
                  : Text(
                      '${loc.colorLabel} · ${ColorManager.getColorName(
                        Color(widget.logic.selectedEventColor!),
                        localeCode:
                            Localizations.localeOf(context).languageCode,
                      )}',
                    ),
              leading: const Icon(Icons.tune_rounded),
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              children: [
                ColorSection(
                  title: loc.colorLabel,
                  cardBuilder: SectionCard.new,
                  selectedColorValue: widget.logic.selectedEventColor,
                  onColorChanged: (color) {
                    if (color != null) {
                      widget.logic.setSelectedColor(color.toARGB32());
                    }
                  },
                  colorValues: widget.logic.colorList,
                ),
              ],
            ),
          ),

          // ── SUBMIT ───────────────────────────────────────────────────────
          if (widget.showSubmitButton) ...[
            WorkVisitStyle.afterSubmitGap,
            ValueListenableBuilder<bool>(
              valueListenable: widget.logic.canSubmit,
              builder: (context, canSubmit, _) {
                final cs = Theme.of(context).colorScheme;
                final label = widget.isEditing ? loc.save : loc.addEvent;
                final icon =
                    widget.isEditing ? Icons.check_rounded : Icons.add_rounded;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 50),
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
                      style: typo.buttonText,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: canSubmit ? cs.primary : null,
                      foregroundColor: canSubmit ? cs.onPrimary : null,
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
        ],
      ),
    );
  }
}

class _PhotoRequirementTile extends StatelessWidget {
  const _PhotoRequirementTile({
    required this.value,
    required this.minimumPhotos,
    required this.onChanged,
  });

  final bool value;
  final int minimumPhotos;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Icon(Icons.add_a_photo_outlined, color: cs.primary),
        title: Text(l.requireCompletionPhotos),
        subtitle: Text(minimumPhotos == 1
            ? l.eventFormPhotoHintOne
            : l.eventFormPhotoHintMany(minimumPhotos)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.reminderEnabled,
    required this.reminderMinutes,
    required this.onReminderTap,
    required this.isRepetitive,
    required this.onRepetitionTap,
  });

  final bool reminderEnabled;
  final int? reminderMinutes;
  final VoidCallback onReminderTap;
  final bool isRepetitive;
  final VoidCallback onRepetitionTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final reminderLabel = getLocalizedReminderOptions(context)
        .where((option) => option.value == reminderMinutes)
        .map((option) => option.label)
        .firstOrNull;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            dense: true,
            leading: Icon(Icons.notifications_outlined, color: cs.primary),
            title: Text(
              '${l.reminderLabel} · ${reminderEnabled ? (reminderLabel ?? l.reminderOption10min) : l.eventFormOff}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing:
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            onTap: onReminderTap,
          ),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            dense: true,
            leading: Icon(Icons.repeat_rounded, color: cs.primary),
            title: Text(
              '${l.repetition} · ${isRepetitive ? l.repeatYes : l.repeatNo}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing:
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            onTap: onRepetitionTap,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
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
