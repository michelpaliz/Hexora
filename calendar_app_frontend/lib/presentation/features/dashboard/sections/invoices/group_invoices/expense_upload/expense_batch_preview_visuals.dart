import 'package:flutter/material.dart';
import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_job_models.dart';

IconData expensePreviewStatusIcon(ExpenseBatchPreviewItem item) {
  if (item.isDuplicate) return Icons.content_copy_outlined;
  if (item.isFailed) return Icons.error_outline;
  if (item.needsReview && !item.reviewed) return Icons.rate_review_outlined;
  if (item.status == 'ready' || item.reviewed) {
    return Icons.verified_outlined;
  }
  return Icons.hourglass_empty_rounded;
}

Color expensePreviewStatusColor(
  ExpenseBatchPreviewItem item,
  ColorScheme colorScheme,
) {
  if (item.isDuplicate || item.isFailed) return colorScheme.error;
  if (item.needsReview && !item.reviewed) return Colors.amber.shade700;
  if (item.status == 'ready' || item.reviewed) return Colors.green.shade600;
  return colorScheme.onSurfaceVariant;
}

Color expensePreviewConfidenceColor(
  double confidence,
  ColorScheme colorScheme,
) {
  if (confidence <= 0) return colorScheme.onSurfaceVariant;
  if (confidence >= 0.86) return Colors.green.shade600;
  if (confidence >= 0.72) return Colors.amber.shade700;
  return colorScheme.error;
}
