import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter data class
// ─────────────────────────────────────────────────────────────────────────────

enum BulkDownloadPeriodMode { month, quarter, custom }

class BulkDownloadFilter {
  final BulkDownloadPeriodMode periodMode;
  final int year;
  final int? month;
  final int? quarter;
  final DateTime? from;
  final DateTime? to;
  final List<String> status; // 'issued' | 'draft' | 'void'
  final String dateField; // 'issueDate' | 'createdAt'

  const BulkDownloadFilter({
    required this.periodMode,
    required this.year,
    this.month,
    this.quarter,
    this.from,
    this.to,
    required this.status,
    required this.dateField,
  });

  Map<String, String> toQueryParams(String groupId) {
    final p = <String, String>{'groupId': groupId};
    switch (periodMode) {
      case BulkDownloadPeriodMode.month:
        p['year'] = year.toString();
        if (month != null) p['month'] = month.toString();
      case BulkDownloadPeriodMode.quarter:
        p['year'] = year.toString();
        if (quarter != null) p['quarter'] = quarter.toString();
      case BulkDownloadPeriodMode.custom:
        if (from != null) {
          p['from'] =
              '${from!.year.toString().padLeft(4, '0')}-${from!.month.toString().padLeft(2, '0')}-${from!.day.toString().padLeft(2, '0')}';
        }
        if (to != null) {
          p['to'] =
              '${to!.year.toString().padLeft(4, '0')}-${to!.month.toString().padLeft(2, '0')}-${to!.day.toString().padLeft(2, '0')}';
        }
    }
    if (status.isNotEmpty) p['status'] = status.join(',');
    p['dateField'] = dateField;
    return p;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog widget
// ─────────────────────────────────────────────────────────────────────────────

class BulkDownloadDialog extends StatefulWidget {
  const BulkDownloadDialog({super.key, required this.onDownload});

  /// Called with the confirmed filter. The caller handles the actual download.
  final void Function(BulkDownloadFilter) onDownload;

  @override
  State<BulkDownloadDialog> createState() => _BulkDownloadDialogState();
}

class _BulkDownloadDialogState extends State<BulkDownloadDialog> {
  BulkDownloadPeriodMode _periodMode = BulkDownloadPeriodMode.month;

  late int _year;
  int _month = DateTime.now().month;
  int _quarter = _currentQuarter();
  DateTime? _from;
  DateTime? _to;

  // status: at least one must be selected
  final Set<String> _status = {'issued'};

  // dateField — auto-defaults per requirement
  String get _dateField {
    if (_status.length == 1 && _status.contains('issued')) return 'issueDate';
    return 'createdAt';
  }

  bool _isEs(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  static int _currentQuarter() => ((DateTime.now().month - 1) ~/ 3) + 1;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validate() {
    if (_status.isEmpty) return _isEs(context) ? 'Selecciona al menos un estado.' : 'Select at least one status.';
    if (_periodMode == BulkDownloadPeriodMode.custom) {
      if (_from == null || _to == null) {
        return _isEs(context)
            ? 'Selecciona una fecha de inicio y fin.'
            : 'Select a from and to date.';
      }
      if (_from!.isAfter(_to!)) {
        return _isEs(context)
            ? 'La fecha de inicio debe ser anterior a la de fin.'
            : 'From date must be before to date.';
      }
    }
    return null;
  }

  void _submit() {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final filter = BulkDownloadFilter(
      periodMode: _periodMode,
      year: _year,
      month: _periodMode == BulkDownloadPeriodMode.month ? _month : null,
      quarter: _periodMode == BulkDownloadPeriodMode.quarter ? _quarter : null,
      from: _periodMode == BulkDownloadPeriodMode.custom ? _from : null,
      to: _periodMode == BulkDownloadPeriodMode.custom ? _to : null,
      status: _status.toList(),
      dateField: _dateField,
    );
    Navigator.of(context).pop();
    widget.onDownload(filter);
  }

  // ── Date picker helpers ─────────────────────────────────────────────────────

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime(_year, 1, 1),
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime(_year, 12, 31),
      firstDate: DateTime(2015),
      lastDate: DateTime(2050),
    );
    if (picked != null) setState(() => _to = picked);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final cardBg = ThemeColors.cardBg(context);
    final isEs = _isEs(context);

    final labelPeriod = isEs ? 'Periodo' : 'Period';
    final labelYear = isEs ? 'Año' : 'Year';
    final labelStatus = isEs ? 'Estado' : 'Status';
    final labelDateField = isEs ? 'Campo de fecha' : 'Date field';
    final labelDownload = isEs ? 'Descargar ZIP' : 'Download ZIP';
    final labelCancel = isEs ? 'Cancelar' : 'Cancel';
    final labelTitle = isEs ? 'Descargar facturas' : 'Download invoices';
    final labelHelper = isEs
        ? 'Más rápido al filtrar por mes o trimestre.'
        : 'Faster when filtering by month or quarter.';

    final modeLabels = {
      BulkDownloadPeriodMode.month: isEs ? 'Mes' : 'Month',
      BulkDownloadPeriodMode.quarter: isEs ? 'Trimestre' : 'Quarter',
      BulkDownloadPeriodMode.custom: isEs ? 'Rango' : 'Range',
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardBg,
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_zip_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labelTitle,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Period mode selector ──────────────────────────────
                    _sectionLabel(context, labelPeriod),
                    const SizedBox(height: 8),
                    _segmentRow(
                      context,
                      values: BulkDownloadPeriodMode.values,
                      selected: _periodMode,
                      labelOf: (m) => modeLabels[m]!,
                      onSelect: (m) => setState(() => _periodMode = m),
                    ),
                    const SizedBox(height: 14),

                    // ── Year ─────────────────────────────────────────────
                    if (_periodMode != BulkDownloadPeriodMode.custom) ...[
                      _sectionLabel(context, labelYear),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 110,
                        child: _YearField(
                          year: _year,
                          onChanged: (y) => setState(() => _year = y),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Month selector ────────────────────────────────────
                    if (_periodMode == BulkDownloadPeriodMode.month) ...[
                      _sectionLabel(context, isEs ? 'Mes' : 'Month'),
                      const SizedBox(height: 8),
                      _MonthGrid(
                        selected: _month,
                        isEs: isEs,
                        onSelect: (m) => setState(() => _month = m),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Quarter selector ──────────────────────────────────
                    if (_periodMode == BulkDownloadPeriodMode.quarter) ...[
                      _sectionLabel(
                          context, isEs ? 'Trimestre' : 'Quarter'),
                      const SizedBox(height: 8),
                      _segmentRow(
                        context,
                        values: const [1, 2, 3, 4],
                        selected: _quarter,
                        labelOf: (q) => 'Q$q',
                        onSelect: (q) => setState(() => _quarter = q),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Custom range ──────────────────────────────────────
                    if (_periodMode == BulkDownloadPeriodMode.custom) ...[
                      _sectionLabel(
                          context, isEs ? 'Rango de fechas' : 'Date range'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: isEs ? 'Desde' : 'From',
                              date: _from,
                              onTap: _pickFrom,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DatePickerField(
                              label: isEs ? 'Hasta' : 'To',
                              date: _to,
                              onTap: _pickTo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Status ────────────────────────────────────────────
                    _sectionLabel(context, labelStatus),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          label: isEs ? 'Emitida' : 'Issued',
                          value: 'issued',
                          selected: _status.contains('issued'),
                          color: cs.primary,
                          onToggle: (v) => setState(() =>
                              v ? _status.add('issued') : _status.remove('issued')),
                        ),
                        _StatusChip(
                          label: isEs ? 'Borrador' : 'Draft',
                          value: 'draft',
                          selected: _status.contains('draft'),
                          color: cs.tertiary,
                          onToggle: (v) => setState(() =>
                              v ? _status.add('draft') : _status.remove('draft')),
                        ),
                        _StatusChip(
                          label: isEs ? 'Anulada' : 'Void',
                          value: 'void',
                          selected: _status.contains('void'),
                          color: cs.error,
                          onToggle: (v) => setState(() =>
                              v ? _status.add('void') : _status.remove('void')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Date field ────────────────────────────────────────
                    _sectionLabel(context, labelDateField),
                    const SizedBox(height: 4),
                    Text(
                      _dateField == 'issueDate'
                          ? (isEs ? 'Fecha de emisión (auto)' : 'Issue date (auto)')
                          : (isEs ? 'Fecha de creación (auto)' : 'Created date (auto)'),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Helper ────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 13,
                            color: cs.onSurface.withValues(alpha: 0.45)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            labelHelper,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(labelCancel,
                          style: t.buttonText.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.7))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(labelDownload, style: t.buttonText),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String label) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: t.bodySmall.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface.withValues(alpha: 0.7),
        letterSpacing: .3,
      ),
    );
  }

  Widget _segmentRow<T>(
    BuildContext context, {
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onSelect,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              labelOf(v),
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? ThemeColors.contrastOn(cs.primary)
                    : cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month grid (3×4)
// ─────────────────────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.selected,
    required this.isEs,
    required this.onSelect,
  });

  final int selected;
  final bool isEs;
  final ValueChanged<int> onSelect;

  static const _esMonths = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  static const _enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final labels = isEs ? _esMonths : _enMonths;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 2.0,
      ),
      itemCount: 12,
      itemBuilder: (_, i) {
        final month = i + 1;
        final isSelected = month == selected;
        return GestureDetector(
          onTap: () => onSelect(month),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              labels[i],
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: isSelected
                    ? ThemeColors.contrastOn(cs.primary)
                    : cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status chip (toggleable)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  final String label;
  final String value;
  final bool selected;
  final Color color;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onToggle(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: selected ? color : cs.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? color : cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Year number field
// ─────────────────────────────────────────────────────────────────────────────

class _YearField extends StatefulWidget {
  const _YearField({required this.year, required this.onChanged});
  final int year;
  final ValueChanged<int> onChanged;

  @override
  State<_YearField> createState() => _YearFieldState();
}

class _YearFieldState extends State<_YearField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.year.toString());
  }

  @override
  void didUpdateWidget(_YearField old) {
    super.didUpdateWidget(old);
    if (old.year != widget.year) {
      _ctrl.text = widget.year.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      onChanged: (v) {
        final y = int.tryParse(v);
        if (y != null && y >= 2000 && y <= 2100) widget.onChanged(y);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date picker field
// ─────────────────────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = date == null
        ? label
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14,
                color: cs.onSurface.withValues(alpha: date != null ? 0.7 : 0.4)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: t.bodySmall.copyWith(
                  color: date != null
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
