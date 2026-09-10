import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptMarkSentSelection {
  const ReceiptMarkSentSelection({required this.channel, this.sentAt});

  final String channel;
  final DateTime? sentAt;
}

class ReceiptMarkSentDialog extends StatefulWidget {
  const ReceiptMarkSentDialog({super.key, this.initialNow});

  final DateTime? initialNow;

  @override
  State<ReceiptMarkSentDialog> createState() => _ReceiptMarkSentDialogState();
}

class ReceiptMarkUnsentDialog extends StatelessWidget {
  const ReceiptMarkUnsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marcar como no enviado'),
      content: const Text('¿Quieres cambiar este recibo a “No enviado”?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('confirm-receipt-mark-unsent'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _ReceiptMarkSentDialogState extends State<ReceiptMarkSentDialog> {
  String _channel = 'email';
  bool _customTimestamp = false;
  late DateTime _sentAt;

  @override
  void initState() {
    super.initState();
    _sentAt = widget.initialNow ?? DateTime.now();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sentAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_sentAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _sentAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return AlertDialog(
      title: const Text('Marcar como enviado'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const ValueKey('receipt-delivery-channel'),
              initialValue: _channel,
              decoration: const InputDecoration(
                labelText: 'Canal de envío',
                prefixIcon: Icon(Icons.send_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                DropdownMenuItem(value: 'manual', child: Text('Manual')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _channel = value);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar fecha y hora personalizada'),
              value: _customTimestamp,
              onChanged: (value) => setState(() => _customTimestamp = value),
            ),
            if (_customTimestamp)
              OutlinedButton.icon(
                key: const ValueKey('receipt-delivery-sent-at'),
                onPressed: _pickDateTime,
                icon: const Icon(Icons.event_outlined),
                label: Text(DateFormat.yMMMd(locale).add_Hm().format(_sentAt)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('confirm-receipt-mark-sent'),
          onPressed: () => Navigator.of(context).pop(
            ReceiptMarkSentSelection(
              channel: _channel,
              sentAt: _customTimestamp ? _sentAt : null,
            ),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
