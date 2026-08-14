import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showWorkerMonthPickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required bool isSpanish,
  int firstYear = 2020,
  int? maxYear,
  bool allowFutureMonths = false,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _WorkerMonthPickerDialog(
      initialDate: initialDate,
      isSpanish: isSpanish,
      firstYear: firstYear,
      maxYear: maxYear,
      allowFutureMonths: allowFutureMonths,
    ),
  );
}

class _WorkerMonthPickerDialog extends StatefulWidget {
  const _WorkerMonthPickerDialog({
    required this.initialDate,
    required this.isSpanish,
    required this.firstYear,
    required this.maxYear,
    required this.allowFutureMonths,
  });

  final DateTime initialDate;
  final bool isSpanish;
  final int firstYear;
  final int? maxYear;
  final bool allowFutureMonths;

  @override
  State<_WorkerMonthPickerDialog> createState() =>
      _WorkerMonthPickerDialogState();
}

class _WorkerMonthPickerDialogState extends State<_WorkerMonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final maxYear = widget.maxYear ?? now.year;
    final canGoPrevious = _year > widget.firstYear;
    final canGoNext = _year < maxYear;

    final monthNames = List.generate(
      12,
      (i) => DateFormat.MMM(locale).format(DateTime(_year, i + 1)),
    );

    return Dialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isSpanish ? 'Seleccionar mes' : 'Select month',
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _YearButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed:
                        canGoPrevious ? () => setState(() => _year--) : null,
                  ),
                  Text(
                    '$_year',
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                  _YearButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: canGoNext ? () => setState(() => _year++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 42,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, i) {
                  final month = i + 1;
                  final isFuture = !widget.allowFutureMonths &&
                      (_year > now.year ||
                          (_year == now.year && month > now.month));
                  final isSelected = _year == widget.initialDate.year &&
                      month == widget.initialDate.month;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : cs.surfaceContainerHighest.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(9),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: isFuture
                          ? null
                          : () => Navigator.of(context)
                              .pop(DateTime(_year, month, 1)),
                      child: Center(
                        child: Text(
                          monthNames[i],
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? cs.onPrimary
                                : isFuture
                                    ? cs.onSurface.withValues(alpha: 0.25)
                                    : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(widget.isSpanish ? 'Cancelar' : 'Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearButton extends StatelessWidget {
  const _YearButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
