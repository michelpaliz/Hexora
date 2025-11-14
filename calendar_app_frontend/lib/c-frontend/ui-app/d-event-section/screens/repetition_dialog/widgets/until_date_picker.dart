import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class UntilDatePicker extends StatelessWidget {
  final bool isForever;
  final DateTime? untilDate;
  final Function(bool) onForeverChanged;
  final Function(DateTime) onDateSelected;

  const UntilDatePicker({
    Key? key,
    required this.isForever,
    required this.untilDate,
    required this.onForeverChanged,
    required this.onDateSelected,
  }) : super(key: key);

  Future<void> _pickDate(BuildContext context) async {
    final DateTime initialDate = untilDate ?? DateTime.now();
    final DateTime firstDate = DateTime.now();
    final DateTime lastDate = DateTime(DateTime.now().year + 10);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Checkbox(
            value: !isForever,
            onChanged: (bool? newValue) {
              onForeverChanged(!(newValue ?? false));
            },
          ),
          Text(AppLocalizations.of(context)!.untilDate,
              style: const TextStyle(fontSize: 14)),
          if (!isForever)
            InkWell(
              onTap: () => _pickDate(context),
              child: Text(
                AppLocalizations.of(context)!.selectDay,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ]),
        if (!isForever)
          Text(
            untilDate == null
                ? AppLocalizations.of(context)!.utilDateNotSelected
                : AppLocalizations.of(context)!.untilDateSelected(
                    DateFormat('yyyy-MM-dd').format(untilDate!)),
            style: const TextStyle(fontSize: 14),
          ),
      ],
    );
  }
}
