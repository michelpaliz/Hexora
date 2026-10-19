part of '../presupuestos_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewDetailsSection
    on _GroupInvoicesBudgetsViewState {
  Widget _buildBudgetDetails(ColorScheme cs, AppLocalizations l) {
    final es = _isSpanishLocale;
    final valid = _isBudgetAdvancePercentValid;
    final total = _budgetTotalAfterDiscount;
    final advance = valid
        ? (total * _budgetAdvancePercent!).round() / 100
        : null;
    final currency = _budgetCurrencyCtrl.text.trim().toUpperCase();
    final money = NumberFormat.currency(
        locale: l.localeName,
        symbol: currency == 'EUR' || currency.isEmpty ? '€' : currency);
    final hasLines = _hasLineContent;

    InputDecoration decoration(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.22),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
        );

    final fields = <Widget>[
      InkWell(
        key: const ValueKey('budget_issue_date'),
        borderRadius: BorderRadius.circular(12),
        onTap: !(_isDraftEditable || _isIssuedEditable)
            ? null
            : () async {
                final date = await showDatePicker(
                    context: context,
                    initialDate: _budgetIssueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100));
                if (date == null || !mounted) return;
                setState(() {
                  _budgetIssueDate = date;
                  _markDraftDirty();
                  _error = null;
                });
              },
        child: InputDecorator(
          decoration: decoration(es ? 'Fecha de emisión' : 'Issue date',
              Icons.calendar_today_outlined),
          child: Text(_budgetIssueDate == null
              ? (es ? 'Seleccionar fecha' : 'Select date')
              : DateFormat.yMMMd(l.localeName).format(_budgetIssueDate!)),
        ),
      ),
      TextField(
        key: const ValueKey('budget_currency'),
        controller: _budgetCurrencyCtrl,
        enabled: _isDraftEditable,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
          LengthLimitingTextInputFormatter(3)
        ],
        onChanged: (_) => setState(() {
          _markDraftDirty();
          _error = null;
        }),
        decoration: decoration(
                es ? 'Moneda' : 'Currency', Icons.currency_exchange_rounded)
            .copyWith(suffixText: currency == 'EUR' ? '— Euro' : null),
      ),
      TextField(
        key: const ValueKey('budget_advance_percent'),
        controller: _budgetAdvancePercentCtrl,
        enabled: _isDraftEditable,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          LengthLimitingTextInputFormatter(6)
        ],
        onChanged: _setBudgetAdvancePercentText,
        decoration: decoration(
                es ? 'Anticipo (%) · opcional' : 'Advance (%) · optional',
                Icons.percent_rounded)
            .copyWith(
                helperText: es ? '0% = sin anticipo' : '0% = no advance',
                errorText: valid ? null : _budgetAdvancePercentError,
                errorMaxLines: 2),
      ),
      InputDecorator(
        key: const ValueKey('budget_advance_amount'),
        decoration: decoration(es ? 'Importe del anticipo' : 'Advance amount',
                Icons.payments_outlined)
            .copyWith(
                helperText: hasLines && advance != null
                    ? '${es ? 'Pendiente' : 'Remaining'}: ${money.format(total - advance)}'
                    : null,
                helperMaxLines: 2),
        child: Text(
            !hasLines
                ? (es
                    ? 'Se calculará con las líneas'
                    : 'Calculated from line items')
                : advance == null
                    ? '—'
                    : money.format(advance),
            style: TextStyle(
                fontWeight: hasLines ? FontWeight.w700 : FontWeight.w400,
                color: hasLines ? cs.onSurface : cs.onSurfaceVariant)),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(es ? 'Datos generales' : 'General details',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(es ? 'Paso 2 de 4' : 'Step 2 of 4',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 4
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
          return Wrap(spacing: 16, runSpacing: 20, children: [
            for (final field in fields) SizedBox(width: width, child: field)
          ]);
        }),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('budget_notes'),
          controller: _budgetNotesCtrl,
          enabled: _isDraftEditable || _isIssuedEditable,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          onChanged: (_) => setState(() {
            _markDraftDirty();
            _error = null;
          }),
          decoration: decoration(
                  es
                      ? 'Notas adicionales (opcional)'
                      : 'Additional notes (optional)',
                  Icons.notes_rounded)
              .copyWith(
                  alignLabelWithHint: true,
                  hintText: es
                      ? 'Añade observaciones o indicaciones para este presupuesto…'
                      : 'Add notes or instructions for this quotation…'),
        ),
        if (_isIssuedEditable) ...[
          const SizedBox(height: 20),
          _buildIssuedEditReasonPanel(cs, reviewMode: false),
        ] else if (!_isDraftEditable) ...[
          const SizedBox(height: 16),
          Text(es
              ? 'Este presupuesto no se puede editar.'
              : 'This quotation cannot be edited.'),
        ],
      ]),
    );
  }
}
