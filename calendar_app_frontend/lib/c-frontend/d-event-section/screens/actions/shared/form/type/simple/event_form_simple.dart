// c-frontend/d-event-section/screens/actions/add_screen/screen/event_form_simple.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/b-backend/group_mng_flow/category/category_api_client.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/screen/widgets/repetition_toggle_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/dialog/user_expandable_card.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/color_picker_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/description_input_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/location_input_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/note_input_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/reminder_options.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/base/base_event_logic.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/event_dialogs.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/simple/section/category/category_picker.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/simple/section/title_section.dart';
// 🔹 Card shell + shared style/typo like Work Visit
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/section_card_work_type.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/date_time_section.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/reminder_section.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/section_card_builder.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit_style.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class EventFormSimple extends StatefulWidget {
  final Future<void> Function() onSubmit;
  final BaseEventLogic logic;
  final bool isEditing;
  final CategoryApi categoryApi;
  final String ownerUserId;

  /// Optional: repetition dialog implementation from parent/router.
  final EventDialogs? dialogs;

  const EventFormSimple({
    super.key,
    required this.logic,
    required this.onSubmit,
    required this.ownerUserId,
    required this.categoryApi,
    this.isEditing = false,
    this.dialogs,
  });

  @override
  State<EventFormSimple> createState() => _EventFormSimpleState();
}

class _EventFormSimpleState extends State<EventFormSimple> {
  late DateTime startDate;
  late DateTime endDate;
  int? _reminder;
  bool _notifyMe = true;

  @override
  void initState() {
    super.initState();
    startDate = widget.logic.selectedStartDate;
    endDate = widget.logic.selectedEndDate;
    _reminder = widget.logic.reminderMinutes;
    _notifyMe = (_reminder ?? 0) > 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.logic.setEventType?.call('simple');

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
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    // 🔹 Match WorkVisit rhythm
    final outer = WorkVisitStyle.outerPadding;
    final runGap = WorkVisitStyle.sectionGap.height ?? 0.0;

    // 🔹 Use the same SectionCard builder used elsewhere
    final SectionCardBuilder cardBuilder = SectionCard.new;

    return SingleChildScrollView(
      padding: outer,
      child: Wrap(
        runSpacing: runGap,
        children: [
          // CATEGORY
          _FullWidth(
            child: cardBuilder(
              title: l.category,
              child: CategoryPicker(
                api: widget.categoryApi,
                label: l.category,
                initialCategoryId: widget.logic.categoryId,
                initialSubcategoryId: widget.logic.subcategoryId,
                onChanged: (sel) {
                  widget.logic.categoryId = sel.categoryId;
                  widget.logic.subcategoryId = sel.subcategoryId;
                  setState(() {});
                },
              ),
            ),
          ),

          // COLOR
          _FullWidth(
            child: cardBuilder(
              title: l.color,
              child: ColorPickerWidget(
                selectedEventColor: widget.logic.selectedEventColor == null
                    ? null
                    : Color(widget.logic.selectedEventColor!),
                onColorChanged: (color) {
                  if (color != null) widget.logic.setSelectedColor(color.value);
                },
                colorList: widget.logic.colorList.map((c) => Color(c)).toList(),
              ),
            ),
          ),

          // TITLE (card section)
          _FullWidth(
            child: TitleSection(
              title: l.title(15), // ensure key exists in l10n
              cardBuilder: cardBuilder,
              controller: widget.logic.titleController,
              hintText: l.titleHint, // optional
            ),
          ),

          // DESCRIPTION (card section)
          _FullWidth(
            child: cardBuilder(
              title: l.descriptionLabel,
              child: DescriptionInputWidget(
                descriptionController: widget.logic.descriptionController,
              ),
            ),
          ),

          // NOTE
          // Notes
          cardBuilder(
            title: l.note(50),
            child: NoteInputWidget(
              noteController: widget.logic.noteController,
              showFieldLabel: false, // card title already shown
              hintText: l.noteHint, // ensures visible hint
              maxWords: 50, // visible live counter
            ),
          ),
          // LOCATION
          _FullWidth(
            child: cardBuilder(
              title: l.location,
              child: LocationInputWidget(
                locationController: widget.logic.locationController,
              ),
            ),
          ),

          // DATES
          _FullWidth(
            child: DateTimeSection(
              title: l.date,
              cardBuilder: SectionCard.new,
              startDate: startDate,
              endDate: endDate,
              onStartTap: () => _handleDateSelection(true),
              onEndTap: () => _handleDateSelection(false),
            ),
          ),

          // REMINDER
          _FullWidth(
            child: ReminderSection(
              title: l.notifyMe,
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
          ),

          // USERS
          _FullWidth(
            child: cardBuilder(
              title: l.assignedUsers,
              child: UserExpandableCard(
                usersAvailable: widget.logic.users,
                initiallySelected: widget.logic.selectedUsers,
                excludeUserId: widget.ownerUserId,
                onSelectedUsersChanged: (selected) {
                  widget.logic.setSelectedUsers(selected);
                  setState(() {});
                },
              ),
            ),
          ),

          // REPETITION
          _FullWidth(
            child: cardBuilder(
              title: l.repetition,
              child: RepetitionToggleWidget(
                key: ValueKey(widget.logic.isRepetitive),
                isRepetitive: widget.logic.isRepetitive,
                toggleWidth: widget.logic.toggleWidth,
                onTap: () async {
                  final wasRepeated = widget.logic.isRepetitive;

                  if (widget.logic.onShowRepetitionDialog == null) {
                    setState(() => widget.logic.toggleRepetition(
                          !wasRepeated,
                          wasRepeated ? null : widget.logic.recurrenceRule,
                        ));
                    return;
                  }

                  final result = await widget.logic.onShowRepetitionDialog!(
                    context,
                    selectedStartDate: widget.logic.selectedStartDate,
                    selectedEndDate: widget.logic.selectedEndDate,
                    initialRule: widget.logic.recurrenceRule,
                  );

                  if (result == null || result.isEmpty) {
                    setState(() => widget.logic.toggleRepetition(
                          !wasRepeated,
                          wasRepeated ? null : widget.logic.recurrenceRule,
                        ));
                    return;
                  }

                  final LegacyRecurrenceRule? rule =
                      result[0] as LegacyRecurrenceRule?;
                  final bool isRepeated =
                      result.length > 1 ? result[1] as bool : true;

                  setState(
                      () => widget.logic.toggleRepetition(isRepeated, rule));
                },
              ),
            ),
          ),

          // SUBMIT
          _FullWidth(
            child: Center(
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
                      widget.isEditing ? l.save : l.addEvent,
                      style: typo.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Forces children inside a Wrap to take full width (so Wrap is only used for runSpacing)
class _FullWidth extends StatelessWidget {
  final Widget child;
  const _FullWidth({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bc) => ConstrainedBox(
        constraints: BoxConstraints(minWidth: bc.maxWidth),
        child: child,
      ),
    );
  }
}
