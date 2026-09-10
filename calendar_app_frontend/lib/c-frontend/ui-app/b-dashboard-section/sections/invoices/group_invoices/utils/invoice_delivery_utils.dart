import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/delivery_status_badge.dart';

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
  return normalizedDeliveryStatus(raw);
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
        labelEs: 'Error de envío',
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
  return deliveryChannelLabel(channel);
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
