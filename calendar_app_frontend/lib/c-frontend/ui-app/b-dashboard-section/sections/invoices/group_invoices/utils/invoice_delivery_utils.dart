import 'package:flutter/material.dart';

enum InvoiceDeliveryVisualState { neutral, success, error }

class InvoiceDeliveryViewData {
  final String status;
  final String labelEs;
  final InvoiceDeliveryVisualState visual;

  const InvoiceDeliveryViewData({
    required this.status,
    required this.labelEs,
    required this.visual,
  });
}

String normalizeDeliveryStatus(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  switch (value) {
    case 'sent':
      return 'sent';
    case 'failed':
      return 'failed';
    case 'not_sent':
    default:
      return 'not_sent';
  }
}

InvoiceDeliveryViewData invoiceDeliveryViewData(String? raw) {
  final status = normalizeDeliveryStatus(raw);
  switch (status) {
    case 'sent':
      return const InvoiceDeliveryViewData(
        status: 'sent',
        labelEs: 'Enviada',
        visual: InvoiceDeliveryVisualState.success,
      );
    case 'failed':
      return const InvoiceDeliveryViewData(
        status: 'failed',
        labelEs: 'Fallo envio',
        visual: InvoiceDeliveryVisualState.error,
      );
    case 'not_sent':
    default:
      return const InvoiceDeliveryViewData(
        status: 'not_sent',
        labelEs: 'No enviada',
        visual: InvoiceDeliveryVisualState.neutral,
      );
  }
}

String invoiceDeliveryChannelLabelEs(String? channel) {
  switch ((channel ?? '').trim().toLowerCase()) {
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

Color invoiceDeliveryColor(
  ColorScheme cs,
  InvoiceDeliveryVisualState state,
) {
  switch (state) {
    case InvoiceDeliveryVisualState.success:
      return cs.tertiary;
    case InvoiceDeliveryVisualState.error:
      return cs.error;
    case InvoiceDeliveryVisualState.neutral:
      return cs.onSurfaceVariant;
  }
}
