import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/emails/email_api.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_email_widgets.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupInvoicesEmailsView extends StatefulWidget {
  final Group group;
  final Invoice? selectedInvoice;
  final List<GroupClient> clients;

  const GroupInvoicesEmailsView({
    super.key,
    required this.group,
    required this.selectedInvoice,
    required this.clients,
  });

  @override
  State<GroupInvoicesEmailsView> createState() => _GroupInvoicesEmailsViewState();
}

class _GroupInvoicesEmailsViewState extends State<GroupInvoicesEmailsView> {
  final _emailApi = EmailApi();
  bool _statusLoading = true;
  bool? _configured;
  String? _statusError;
  bool _logsLoading = true;
  String? _logsError;
  List<Map<String, dynamic>> _logs = const [];
  String? _resendingLogId;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _loadLogs();
  }

  @override
  void didUpdateWidget(covariant GroupInvoicesEmailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedInvoice?.id != widget.selectedInvoice?.id) {
      _loadLogs();
    }
  }

  Future<void> _loadStatus() async {
    setState(() {
      _statusLoading = true;
      _statusError = null;
    });
    try {
      final data = await _emailApi.getStatus();
      final raw = data['configured'] ?? data['isConfigured'] ?? data['ready'];
      final configured = raw is bool
          ? raw
          : raw is String
              ? raw.toLowerCase() == 'true'
              : false;
      if (!mounted) return;
      setState(() => _configured = configured);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusError = e.toString());
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  Future<void> _loadLogs() async {
    final invoice = widget.selectedInvoice;
    if (invoice == null) {
      setState(() {
        _logsLoading = false;
        _logsError = null;
        _logs = const [];
      });
      return;
    }
    setState(() {
      _logsLoading = true;
      _logsError = null;
    });
    try {
      final logs = await _emailApi.getLogs(
        invoiceId: invoice.id,
        groupId: invoice.groupId,
      );
      logs.sort((a, b) {
        final aDate = _parseLogDate(a);
        final bDate = _parseLogDate(b);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      if (!mounted) return;
      setState(() => _logs = logs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _logsError = e.toString());
    } finally {
      if (mounted) setState(() => _logsLoading = false);
    }
  }

  DateTime? _parseLogDate(Map<String, dynamic> log) {
    final raw = log['createdAt'] ?? log['sentAt'] ?? log['timestamp'];
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true)
          .toLocal();
    }
    return null;
  }

  String _formatLogDate(DateTime? dt, AppLocalizations l) {
    if (dt == null) return l.invoiceRegisteredUnknown;
    return DateFormat.yMMMd(l.localeName).add_Hm().format(dt.toLocal());
  }

  String _buildPdfLink(Invoice invoice) {
    final url = invoice.pdfUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return '${ApiConstants.baseUrl}/invoices/${invoice.id}/pdf';
  }

  String _logId(Map<String, dynamic> log) {
    return (log['id'] ?? log['_id'] ?? '').toString();
  }

  Future<void> _resend(Map<String, dynamic> log) async {
    final id = _logId(log);
    if (id.isEmpty) return;
    setState(() => _resendingLogId = id);
    try {
      await _emailApi.resend(id);
      if (mounted) await _loadLogs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _resendingLogId = null);
    }
  }

  void _openDetails(Map<String, dynamic> log) {
    final encoder = const JsonEncoder.withIndent('  ');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Email details'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(encoder.convert(log)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSendInvoice() async {
    final invoice = widget.selectedInvoice;
    if (invoice == null) return;
    final client = widget.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => GroupClient(id: invoice.clientId, name: '-', isActive: true),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SendInvoiceSheet(
        invoice: invoice,
        client: client,
        emailApi: _emailApi,
        pdfLink: _buildPdfLink(invoice),
        onSent: _loadLogs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final currentUserId = context.read<UserDomain?>()?.user?.id;
    final role =
        currentUserId == null ? null : widget.group.userRoles[currentUserId];
    final canSend = role == 'owner' || role == 'co-admin';
    final invoice = widget.selectedInvoice;

    final bannerText = _statusLoading
        ? 'Checking email settings...'
        : _statusError != null
            ? 'Email settings unavailable'
            : (_configured ?? false)
                ? 'Email sending is configured ✅'
                : 'Email sending needs setup ⚠️';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Emails',
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (canSend && invoice != null)
                    FilledButton.icon(
                      onPressed: _openSendInvoice,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send invoice'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _configured == true
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      size: 18,
                      color:
                          _configured == true ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bannerText,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    if (_statusLoading)
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
              const SizedBox(height: 12),
              if (invoice == null)
                Text(
                  l.groupInvoicesSelectInvoiceHint,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                )
              else
                Expanded(
                  child: _logsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _logsError != null
                          ? Text(
                              _logsError!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            )
                          : _logs.isEmpty
                              ? Text(
                                  'No email history yet.',
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              : ListView(
                                  children: _logs
                                      .map(
                                        (log) => EmailLogRow(
                                          log: log,
                                          dateLabel: _formatLogDate(
                                            _parseLogDate(log),
                                            l,
                                          ),
                                          canResend: canSend,
                                          resending:
                                              _resendingLogId == _logId(log),
                                          onResend: () => _resend(log),
                                          onViewDetails: () =>
                                              _openDetails(log),
                                        ),
                                      )
                                      .toList(),
                                ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
