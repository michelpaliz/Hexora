// c-frontend/d-event-section/screens/actions/add_screen/widgets/work_visit/work_visit_sections.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/screen/widgets/repetition_toggle_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/dialog/user_expandable_card.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/color_picker_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/date_picker_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/description_input_widget.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/add_screen/utils/form/reminder_options.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/simple/client_service_pickers.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/section_card_work_type.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart'; // <-- use your l10n

typedef SectionCardBuilder = SectionCard Function({
  Key? key,
  required String title,
  required Widget child,
});

/// 1) Client & Service
class ClientServiceSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;

  final List<dynamic> clients;
  final List<dynamic> services;
  final String? clientId;
  final String? serviceId;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onServiceChanged;

  const ClientServiceSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.clients,
    required this.services,
    required this.clientId,
    required this.serviceId,
    required this.onClientChanged,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: ClientServicePickers(
        clients: clients,
        services: services,
        clientId: clientId,
        serviceId: serviceId,
        onClientChanged: onClientChanged,
        onServiceChanged: onServiceChanged,
      ),
    );
  }
}

/// 2) Date & Time
class DateTimeSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;

  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const DateTimeSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: DatePickersWidget(
        startDate: startDate,
        endDate: endDate,
        onStartDateTap: onStartTap,
        onEndDateTap: onEndTap,
      ),
    );
  }
}

/// 3) Reminder  (uses AppLocalizations instead of MaterialLocalizations.on/off)
class ReminderSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;

  final bool notifyMe;
  final int? reminderMinutes;
  final ValueChanged<bool> onNotifyChanged;
  final ValueChanged<int?> onReminderChanged;

  const ReminderSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.notifyMe,
    required this.reminderMinutes,
    required this.onNotifyChanged,
    required this.onReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!; // <-- here

    return cardBuilder(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title, style: typo.bodyMedium),
            subtitle: Text(
              notifyMe ? loc.notifyMeOnSubtitle : loc.notifyMeOffSubtitle,
              style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            value: notifyMe,
            onChanged: onNotifyChanged,
          ),
          if (notifyMe)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ReminderTimeDropdownField(
                initialValue: reminderMinutes,
                onChanged: onReminderChanged,
              ),
            ),
        ],
      ),
    );
  }
}

/// 4) Description
class DescriptionSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final TextEditingController controller;

  const DescriptionSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: DescriptionInputWidget(
        descriptionController: controller,
      ),
    );
  }
}

/// 5) Color
class ColorSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;

  final int? selectedColorValue;
  final ValueChanged<Color?> onColorChanged;
  final List<int> colorValues;

  const ColorSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.selectedColorValue,
    required this.onColorChanged,
    required this.colorValues,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: ColorPickerWidget(
        selectedEventColor:
            selectedColorValue == null ? null : Color(selectedColorValue!),
        onColorChanged: onColorChanged,
        colorList: colorValues.map((c) => Color(c)).toList(),
      ),
    );
  }
}

/// 6) Assigned Users  (strongly typed)
class AssignedUsersSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;

  final List<User> usersAvailable;
  final List<User> initiallySelected;
  final String excludeUserId;
  final ValueChanged<List<User>> onSelectedUsersChanged;

  const AssignedUsersSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.usersAvailable,
    required this.initiallySelected,
    required this.excludeUserId,
    required this.onSelectedUsersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: UserExpandableCard(
        usersAvailable: usersAvailable,
        initiallySelected: initiallySelected,
        excludeUserId: excludeUserId,
        onSelectedUsersChanged: onSelectedUsersChanged,
      ),
    );
  }
}

/// 7) Repetition  (nullable width guarded)
class RepetitionSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;

  final bool isRepetitive;
  final double? toggleWidth; // may be null
  final Future<void> Function() onTap;

  const RepetitionSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.isRepetitive,
    required this.toggleWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: RepetitionToggleWidget(
        key: ValueKey(isRepetitive),
        isRepetitive: isRepetitive,
        toggleWidth: toggleWidth ?? 0, // provide a safe default
        onTap: onTap,
      ),
    );
  }
}
