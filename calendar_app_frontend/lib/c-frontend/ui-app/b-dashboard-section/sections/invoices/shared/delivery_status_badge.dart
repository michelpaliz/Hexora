import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DeliveryStatusVisual { neutral, success, error }

String normalizedDeliveryStatus(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'sent':
      return 'sent';
    case 'failed':
      return 'failed';
    default:
      return 'not_sent';
  }
}

String deliveryChannelLabel(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'email':
      return 'Email';
    case 'whatsapp':
      return 'WhatsApp';
    case 'manual':
      return 'Manual';
    default:
      return '-';
  }
}

String deliveryStatusLabel(String? value, {bool feminine = false}) {
  switch (normalizedDeliveryStatus(value)) {
    case 'sent':
      return feminine ? 'Enviada' : 'Enviado';
    case 'failed':
      return 'Error de envío';
    default:
      return feminine ? 'No enviada' : 'No enviado';
  }
}

class DeliveryStatusBadge extends StatelessWidget {
  const DeliveryStatusBadge({
    super.key,
    required this.status,
    this.channel,
    this.sentAt,
    this.deliveryError,
    this.compact = false,
    this.feminine = false,
  });

  final String? status;
  final String? channel;
  final DateTime? sentAt;
  final String? deliveryError;
  final bool compact;
  final bool feminine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normalized = normalizedDeliveryStatus(status);
    final label = deliveryStatusLabel(status, feminine: feminine);
    final visual = switch (normalized) {
      'sent' => DeliveryStatusVisual.success,
      'failed' => DeliveryStatusVisual.error,
      _ => DeliveryStatusVisual.neutral,
    };
    final color = switch (visual) {
      DeliveryStatusVisual.success => cs.primary,
      DeliveryStatusVisual.error => cs.error,
      DeliveryStatusVisual.neutral => cs.onSurface.withValues(alpha: 0.55),
    };
    final icon = switch (normalized) {
      'sent' => Icons.mark_email_read_outlined,
      'failed' => Icons.error_outline_rounded,
      _ => Icons.mark_email_unread_outlined,
    };
    final locale = Localizations.localeOf(context).toString();
    final sentAtLabel = sentAt == null
        ? null
        : DateFormat.yMMMd(locale).add_Hm().format(sentAt!.toLocal());
    final error = (deliveryError ?? '').trim();
    final tooltip = <String>[
      label,
      if (normalized == 'sent' && (channel ?? '').trim().isNotEmpty)
        deliveryChannelLabel(channel),
      if (sentAtLabel != null) sentAtLabel,
      if (normalized == 'failed' && error.isNotEmpty) error,
    ].join(' · ');

    final child = compact
        ? Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(icon, size: 15, color: color),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          );

    return Semantics(
      label: tooltip,
      child: Tooltip(message: tooltip, child: child),
    );
  }
}
