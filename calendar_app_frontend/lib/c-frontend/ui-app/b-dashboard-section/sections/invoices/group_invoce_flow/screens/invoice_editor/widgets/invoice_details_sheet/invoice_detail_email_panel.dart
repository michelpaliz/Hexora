import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_email_widgets.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceDetailEmailPanel extends StatelessWidget {
  final AppTypography t;
  final AppLocalizations l;
  final ColorScheme cs;
  final bool canSend;
  final bool emailStatusLoading;
  final bool? emailConfigured;
  final String? emailStatusError;
  final List<Map<String, dynamic>> emailLogs;
  final bool emailLogsLoading;
  final String? emailLogsError;
  final bool emailHistoryExpanded;
  final VoidCallback onToggleHistory;
  final VoidCallback onShowSettingsInfo;
  final VoidCallback onCopyPdfLink;
  final String latestStatus;
  final String latestDate;
  final String Function(Map<String, dynamic>) formatLogDate;
  final VoidCallback Function(Map<String, dynamic>) onResend;
  final VoidCallback Function(Map<String, dynamic>) onViewDetails;
  final bool Function(Map<String, dynamic>) isResending;

  const InvoiceDetailEmailPanel({
    super.key,
    required this.t,
    required this.l,
    required this.cs,
    required this.canSend,
    required this.emailStatusLoading,
    required this.emailConfigured,
    required this.emailStatusError,
    required this.emailLogs,
    required this.emailLogsLoading,
    required this.emailLogsError,
    required this.emailHistoryExpanded,
    required this.onToggleHistory,
    required this.onShowSettingsInfo,
    required this.onCopyPdfLink,
    required this.latestStatus,
    required this.latestDate,
    required this.formatLogDate,
    required this.onResend,
    required this.onViewDetails,
    required this.isResending,
  });

  @override
  Widget build(BuildContext context) {
    final bannerText = emailStatusLoading
        ? l.invoiceEmailSettingsChecking
        : emailStatusError != null
            ? l.invoiceEmailSettingsUnavailable
            : (emailConfigured ?? false)
                ? l.invoiceEmailSettingsConfigured
                : l.invoiceEmailSettingsNeedsSetup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.email,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(
                emailConfigured == true
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                size: 18,
                color: emailConfigured == true
                    ? cs.primary
                    : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bannerText,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (emailStatusLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
            ],
          ),
        ),
        if (!emailStatusLoading &&
            (emailStatusError != null || emailConfigured != true)) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onShowSettingsInfo,
                icon: const Icon(Icons.settings_outlined),
                label: Text(l.invoiceEmailConfigureCta),
              ),
              TextButton.icon(
                onPressed: onCopyPdfLink,
                icon: const Icon(Icons.link),
                label: Text(l.invoiceEmailCopyLinkCta),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            EmailStatusBadge(status: latestStatus),
            const SizedBox(width: 8),
            Text(
              latestDate,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onToggleHistory,
              icon: Icon(
                emailHistoryExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(emailHistoryExpanded
                  ? l.invoiceEmailHistoryHideCta
                  : l.invoiceEmailHistoryShowCta),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: emailHistoryExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: emailLogsLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: cs.primary),
                          ),
                        )
                      : emailLogsError != null
                          ? Text(
                              emailLogsError!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            )
                          : emailLogs.isEmpty
                              ? Text(
                                  l.invoiceEmailNoHistory,
                                  style: t.bodySmall
                                      .copyWith(color: cs.onSurfaceVariant),
                                )
                              : Column(
                                  children: emailLogs
                                      .map(
                                        (log) => EmailLogRow(
                                          log: log,
                                          dateLabel: formatLogDate(log),
                                          canResend: canSend,
                                          resending: isResending(log),
                                          onResend: onResend(log),
                                          onViewDetails: onViewDetails(log),
                                        ),
                                      )
                                      .toList(),
                                ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
