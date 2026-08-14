import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoicePaymentEditor extends StatefulWidget {
  const InvoicePaymentEditor({
    super.key,
    required this.invoice,
    required this.onSave,
    this.compact = false,
    this.showSaveButton = true,
    this.onPaymentChanged,
  });

  final Invoice invoice;
  final Future<void> Function(Map<String, dynamic> payload) onSave;
  final bool compact;
  final bool showSaveButton;
  final ValueChanged<Map<String, dynamic>?>? onPaymentChanged;

  @override
  State<InvoicePaymentEditor> createState() => _InvoicePaymentEditorState();
}

class _InvoicePaymentEditorState extends State<InvoicePaymentEditor> {
  late String _status;
  late String? _method;
  late DateTime? _paidAt;
  late final TextEditingController _amountCtrl;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _status = _normalizeStatus(widget.invoice.paymentStatus);
    _method = _normalizeMethod(widget.invoice.paymentMethod) ?? 'transfer';
    _paidAt = widget.invoice.paidAt;
    _amountCtrl = TextEditingController(
      text: widget.invoice.paidAmount == null
          ? ''
          : _formatAmount(widget.invoice.paidAmount!),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InvoicePaymentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice.id == widget.invoice.id &&
        oldWidget.invoice.paymentStatus == widget.invoice.paymentStatus &&
        oldWidget.invoice.paidAmount == widget.invoice.paidAmount &&
        oldWidget.invoice.paidAt == widget.invoice.paidAt &&
        oldWidget.invoice.paymentMethod == widget.invoice.paymentMethod) {
      return;
    }
    _status = _normalizeStatus(widget.invoice.paymentStatus);
    _method = _normalizeMethod(widget.invoice.paymentMethod) ?? 'transfer';
    _paidAt = widget.invoice.paidAt;
    _amountCtrl.text = widget.invoice.paidAmount == null
        ? ''
        : _formatAmount(widget.invoice.paidAmount!);
  }

  String _normalizeStatus(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw == 'paid' || raw == 'partial' || raw == 'unpaid') return raw;
    return 'unpaid';
  }

  String? _normalizeMethod(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (_paymentMethods.any((item) => item.key == raw)) return raw;
    return null;
  }

  String _formatAmount(num value) {
    final fixed = value.toDouble().toStringAsFixed(2);
    return fixed.replaceAll('.', ',');
  }

  num? _parseAmount(String value) {
    final raw = value.trim();
    if (raw.contains(',')) {
      return num.tryParse(raw.replaceAll('.', '').replaceAll(',', '.'));
    }
    return num.tryParse(raw);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  void _notifyChanged() {
    final callback = widget.onPaymentChanged;
    if (callback == null) return;
    callback(_payload(silent: true));
  }

  Map<String, dynamic>? _payload({bool silent = false}) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    if (_status == 'unpaid') {
      return {'paymentStatus': 'unpaid'};
    }
    if (_status == 'partial') {
      final amount = _parseAmount(_amountCtrl.text);
      final total = widget.invoice.total;
      if (amount == null || amount <= 0) {
        if (!silent) {
          _error = isEs
              ? 'El importe pagado debe ser mayor que 0.'
              : 'Paid amount must be greater than 0.';
        }
        return null;
      }
      if (total != null && amount >= total) {
        if (!silent) {
          _error = isEs
              ? 'El pago parcial debe ser menor que el total de la factura.'
              : 'Partial payment must be less than the invoice total.';
        }
        return null;
      }
      return {
        'paymentStatus': 'partial',
        'paidAmount': amount,
        if ((_method ?? '').isNotEmpty) 'paymentMethod': _method,
        if (_paidAt != null)
          'paidAt': DateFormat('yyyy-MM-dd').format(_paidAt!),
      };
    }
    return {
      'paymentStatus': 'paid',
      if ((_method ?? '').isNotEmpty) 'paymentMethod': _method,
      if (_paidAt != null) 'paidAt': DateFormat('yyyy-MM-dd').format(_paidAt!),
    };
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _error = null;
      _success = null;
    });
    final payload = _payload();
    if (payload == null) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(payload);
      if (!mounted) return;
      final isEs = AppLocalizations.of(context)!
          .localeName
          .toLowerCase()
          .startsWith('es');
      setState(() => _success =
          isEs ? 'Estado de pago guardado.' : 'Payment status saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final cs = Theme.of(context).colorScheme;
    final dateLabel = _paidAt == null
        ? (isEs ? 'Fecha de pago' : 'Payment date')
        : DateFormat.yMMMd(l.localeName).format(_paidAt!);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEs ? 'Estado de pago' : 'Payment status',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              selected: {_status},
              onSelectionChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _status = value.first;
                        _error = null;
                        _success = null;
                        _notifyChanged();
                      }),
              segments: [
                ButtonSegment(
                  value: 'unpaid',
                  label: Text(isEs ? 'Pendiente' : 'Unpaid'),
                  icon: const Icon(Icons.schedule_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'paid',
                  label: Text(isEs ? 'Pagada' : 'Paid'),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                ),
                ButtonSegment(
                  value: 'partial',
                  label: Text(isEs ? 'Pago parcial' : 'Partial'),
                  icon: const Icon(Icons.pie_chart_outline, size: 16),
                ),
              ],
            ),
            if (_status == 'partial') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                enabled: !_saving,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: isEs ? 'Importe pagado' : 'Paid amount',
                  suffixText: widget.invoice.currency ?? 'EUR',
                  isDense: true,
                ),
                onChanged: (_) => _notifyChanged(),
              ),
            ],
            if (_status != 'unpaid') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            await _pickDate();
                            _notifyChanged();
                          },
                    icon: const Icon(Icons.event_outlined, size: 16),
                    label: Text(dateLabel),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: InputDecoration(
                        labelText: isEs ? 'Metodo' : 'Method',
                        isDense: true,
                      ),
                      items: [
                        for (final item in _paymentMethods)
                          DropdownMenuItem(
                            value: item.key,
                            child: Text(isEs ? item.es : item.en),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                                _method = value;
                                _notifyChanged();
                              }),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: cs.error)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 8),
              Text(
                _success!,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (widget.showSaveButton) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(isEs ? 'Guardar pago' : 'Save payment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodOption {
  const _PaymentMethodOption(this.key, this.es, this.en);

  final String key;
  final String es;
  final String en;
}

const _paymentMethods = [
  _PaymentMethodOption('transfer', 'Transferencia', 'Transfer'),
  _PaymentMethodOption('cash', 'Efectivo', 'Cash'),
  _PaymentMethodOption('card', 'Tarjeta', 'Card'),
  _PaymentMethodOption('cheque', 'Cheque', 'Cheque'),
  _PaymentMethodOption('other', 'Otro', 'Other'),
];
