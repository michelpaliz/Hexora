import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_job_models.dart';
import 'package:hexora/presentation/features/dashboard/sections/invoices/group_invoices/expense_upload/expense_batch_preview_visuals.dart';

void main() {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);

  ExpenseBatchPreviewItem item(
    String status, {
    bool duplicate = false,
    bool reviewed = false,
  }) {
    final value = ExpenseBatchPreviewItem(
      id: 'id',
      tempId: '',
      fileName: 'invoice.pdf',
      status: status,
      prediction: {},
      confidence: {},
      warnings: const [],
      duplicate: {'isDuplicate': duplicate},
      selected: false,
    );
    value.reviewed = reviewed;
    return value;
  }

  test('maps preview status precedence to the existing icons', () {
    expect(
      expensePreviewStatusIcon(item('failed', duplicate: true)),
      Icons.content_copy_outlined,
    );
    expect(expensePreviewStatusIcon(item('failed')), Icons.error_outline);
    expect(
      expensePreviewStatusIcon(item('needs_review')),
      Icons.rate_review_outlined,
    );
    expect(expensePreviewStatusIcon(item('ready')), Icons.verified_outlined);
    expect(
      expensePreviewStatusIcon(item('needs_review', reviewed: true)),
      Icons.verified_outlined,
    );
    expect(
      expensePreviewStatusIcon(item('pending')),
      Icons.hourglass_empty_rounded,
    );
  });

  test('maps preview status precedence to the existing colors', () {
    expect(
      expensePreviewStatusColor(item('failed', duplicate: true), colorScheme),
      colorScheme.error,
    );
    expect(
      expensePreviewStatusColor(item('failed'), colorScheme),
      colorScheme.error,
    );
    expect(
      expensePreviewStatusColor(item('needs_review'), colorScheme),
      Colors.amber.shade700,
    );
    expect(
      expensePreviewStatusColor(item('ready'), colorScheme),
      Colors.green.shade600,
    );
    expect(
      expensePreviewStatusColor(
        item('needs_review', reviewed: true),
        colorScheme,
      ),
      Colors.green.shade600,
    );
    expect(
      expensePreviewStatusColor(item('pending'), colorScheme),
      colorScheme.onSurfaceVariant,
    );
  });

  test('preserves confidence color thresholds', () {
    expect(
      expensePreviewConfidenceColor(0, colorScheme),
      colorScheme.onSurfaceVariant,
    );
    expect(
      expensePreviewConfidenceColor(0.71, colorScheme),
      colorScheme.error,
    );
    expect(
      expensePreviewConfidenceColor(0.72, colorScheme),
      Colors.amber.shade700,
    );
    expect(
      expensePreviewConfidenceColor(0.85, colorScheme),
      Colors.amber.shade700,
    );
    expect(
      expensePreviewConfidenceColor(0.86, colorScheme),
      Colors.green.shade600,
    );
  });
}
