import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/downloads/download_job.dart';
import 'package:intl/intl.dart';

/// Presentation only: stored filenames and download URLs remain unchanged.
class DownloadJobDisplay {
  static AppLocalizations _l(BuildContext context) =>
      AppLocalizations.of(context)!;

  static String name(BuildContext context, DownloadJob job) {
    final l = _l(context);
    final type = job.jobType;
    final label = switch (type) {
      'invoice_zip' => l.downloadsInvoicesZip,
      'invoice_vat_audit_excel' => l.downloadsInvoiceVatAudit,
      'expense_vat_audit_excel' => l.downloadsExpenseVatAudit,
      'bank_transactions_excel' => job.params['amountType'] == 'expense'
          ? l.downloadsBankExpenses
          : l.downloadsBankTransactions,
      'insights_excel' => l.downloadsInsights,
      'custom_report' => l.downloadsCustomReport,
      'invoice_pdf' => l.downloadsInvoice,
      _ => null,
    };
    if (label == null) {
      return job.fileName.trim().isNotEmpty
          ? job.fileName
          : (job.title.trim().isNotEmpty
              ? job.title
              : l.downloadsGeneratedFile);
    }
    final invoiceNumber = job.params['invoiceNumber']?.toString().trim() ?? '';
    if (type == 'invoice_pdf' && invoiceNumber.isNotEmpty) {
      return '$label $invoiceNumber';
    }
    if (type == 'invoice_zip') {
      final date = job.completedAt ?? job.createdAt;
      final pattern =
          l.localeName.startsWith('es') ? 'd MMM yyyy' : 'MMM d, yyyy';
      return '$label · ${DateFormat(pattern, l.localeName).format(date.toLocal())}';
    }
    return label;
  }

  static String status(BuildContext context, DownloadJob job) {
    final l = _l(context);
    return switch (job.status) {
      'queued' => l.downloadsQueued,
      'processing' => l.downloadsProcessing,
      'ready' => l.downloadsReady,
      'failed' => l.downloadsFailed,
      'expired' => l.downloadsExpired,
      _ => job.status,
    };
  }

  static String timestamp(BuildContext context, DownloadJob job) {
    return dateTime(context, job.completedAt ?? job.createdAt);
  }

  static String dateTime(BuildContext context, DateTime date) {
    final l = _l(context);
    final value = date.toLocal();
    return DateFormat(
            l.localeName.startsWith('es')
                ? 'd MMM yyyy · HH:mm'
                : 'MMM d, yyyy · HH:mm',
            l.localeName)
        .format(value);
  }

  static String fileType(DownloadJob job) {
    final file = job.effectiveFileName.toLowerCase();
    if (file.endsWith('.pdf') || job.isPdf) return 'PDF';
    if (file.endsWith('.zip') || job.mimeType.contains('zip')) return 'ZIP';
    if (file.endsWith('.csv') || job.mimeType.contains('csv')) return 'CSV';
    if (file.endsWith('.xlsx') || job.mimeType.contains('spreadsheetml')) {
      return 'XLSX';
    }
    if (file.endsWith('.xls')) return 'XLS';
    if (job.jobType == 'invoice_zip') return 'ZIP';
    if (job.jobType.endsWith('_excel')) return 'XLSX';
    if (job.jobType.endsWith('_pdf')) return 'PDF';
    return file.contains('.') ? file.split('.').last.toUpperCase() : 'FILE';
  }

  static IconData icon(DownloadJob job) => switch (fileType(job)) {
        'PDF' => Icons.picture_as_pdf_outlined,
        'ZIP' => Icons.folder_zip_outlined,
        'CSV' => Icons.table_chart_outlined,
        'XLSX' || 'XLS' => Icons.grid_on_outlined,
        _ => Icons.insert_drive_file_outlined,
      };
}
