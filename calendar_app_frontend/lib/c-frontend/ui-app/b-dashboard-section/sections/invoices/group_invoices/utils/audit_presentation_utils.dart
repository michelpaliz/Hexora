import 'package:flutter/material.dart';

typedef AuditTranslator = String Function(String spanish, String english);

String auditReviewLabel(String status, AuditTranslator translate) {
  switch (status) {
    case 'confirmed_ok':
      return translate('Confirmado', 'Confirmed');
    case 'needs_fix':
      return translate('A corregir', 'Needs fix');
    default:
      return translate('Sin revisar', 'Unreviewed');
  }
}

String auditReasonLabel(String code, AuditTranslator translate) {
  switch (code.toUpperCase()) {
    case 'SUBTOTAL_MISMATCH':
      return translate('Discrepancia en base', 'Base mismatch');
    case 'TAX_TOTAL_MISMATCH':
      return translate('Discrepancia en IVA', 'VAT mismatch');
    case 'TOTAL_MISMATCH':
      return translate('Discrepancia en total', 'Total mismatch');
    case 'IMPOSSIBLE_ZERO_TOTAL':
      return translate('Total imposible (0)', 'Impossible zero total');
    default:
      return code;
  }
}

Color auditStatusColor(
  bool isSuspect,
  String review,
  ColorScheme colors,
) {
  if (isSuspect) return colors.error;
  if (review == 'confirmed_ok') return colors.tertiary;
  return colors.onSurfaceVariant;
}
