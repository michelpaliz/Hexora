import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/emails/email_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_lines.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_party.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_email_widgets.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceDetailSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final BillingProfile? billingProfile;
  final Group group;
  final ValueChanged<String>? onOpenRecurringSeries;

  const InvoiceDetailSheet({
    super.key,
    required this.invoice,
    required this.client,
    required this.billingProfile,
    required this.group,
    this.onOpenRecurringSeries,
  });

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet> {
  final _invoicesApi = InvoicesApi();
  final _linesApi = InvoiceLinesApi();
  final _emailApi = EmailApi();
  Invoice? _currentInvoice;
  bool _loading = true;
  String? _error;
  List<InvoiceLine> _lines = const [];
  bool _previewing = false;
  bool _issuing = false;
  bool _emailStatusLoading = true;
  bool? _emailConfigured;
  String? _emailStatusError;
  bool _emailLogsLoading = true;
  String? _emailLogsError;
  List<Map<String, dynamic>> _emailLogs = const [];
  bool _emailHistoryExpanded = false;
  String? _resendingLogId;
  bool _downloadingPdf = false;
  bool _savingBillingName = false;

  @override
  void initState() {
    super.initState();
    _lines = widget.invoice.lines;
    _fetchLines();
    _loadEmailStatus();
    _loadEmailLogs();
  }

  Invoice get _invoice => _currentInvoice ?? widget.invoice;

  Future<void> _fetchLines() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _linesApi.list(_invoice.id);
      if (!mounted) return;
      setState(() => _lines = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEmailStatus() async {
    setState(() {
      _emailStatusLoading = true;
      _emailStatusError = null;
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
      setState(() => _emailConfigured = configured);
    } catch (e) {
      if (!mounted) return;
      setState(() => _emailStatusError = e.toString());
    } finally {
      if (mounted) setState(() => _emailStatusLoading = false);
    }
  }

  Future<void> _loadEmailLogs() async {
    setState(() {
      _emailLogsLoading = true;
      _emailLogsError = null;
    });
    try {
      final logs = await _emailApi.getLogs(
        invoiceId: _invoice.id,
        groupId: _invoice.groupId,
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
      setState(() => _emailLogs = logs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _emailLogsError = e.toString());
    } finally {
      if (mounted) setState(() => _emailLogsLoading = false);
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

  String _buildPdfLink() {
    final url = _invoice.pdfUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return '${ApiConstants.baseUrl}/invoices/${_invoice.id}/pdf';
  }

  num get _total => _lines.fold<num>(0, (sum, l) => sum + (l.lineTotal ?? 0));

  Future<void> _copyPdfLink() async {
    final link = _buildPdfLink();
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.copiedToClipboard)));
  }

  void _showEmailSettingsInfo(AppLocalizations l) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceEmailConfigureCta),
        content: Text(l.invoiceEmailSettingsNeedsSetup),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.dialogClose),
          ),
        ],
      ),
    );
  }

  Future<void> _previewPdf() async {
    setState(() => _previewing = true);
    try {
      final r = await _invoicesApi.previewPdf(_invoice.id);
      final bytes = _validatePdf(r);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'invoice-${_invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  String _fileNameFromHeaders(Map<String, String> headers) {
    final raw = headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final match =
          RegExp(r'filename="?([^";]+)"?', caseSensitive: false).firstMatch(raw);
      if (match != null) {
        final name = match.group(1);
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    }
    final fallback = _invoice.invoiceNumber.trim().isNotEmpty
        ? _invoice.invoiceNumber.trim()
        : _invoice.id.trim();
    return fallback.endsWith('.pdf') ? fallback : 'invoice-$fallback.pdf';
  }

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      final r = await _invoicesApi.downloadPdf(_invoice.id);
      final fileName = _fileNameFromHeaders(r.headers);
      await launchFileDownload(
        r.bodyBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Future<void> _openSendInvoice({required bool canSend}) async {
    if (!canSend) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SendInvoiceSheet(
        invoice: _invoice,
        client: widget.client,
        emailApi: _emailApi,
        pdfLink: _buildPdfLink(),
        onSent: () async {
          await _loadEmailLogs();
        },
      ),
    );
  }

  Future<void> _issueInvoice() async {
    if (_issuing) return;
    setState(() => _issuing = true);
    try {
      final updated = await _invoicesApi.issue(_invoice.id);
      if (!mounted) return;
      setState(() {
        _currentInvoice = updated;
        if (updated.lines.isNotEmpty) {
          _lines = updated.lines;
        }
      });
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.invoiceIssueSuccessSnack(updated.invoiceNumber))),
      );
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceIssueFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  String _safeErrorMessage(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    final l = AppLocalizations.of(context)!;
    final raw = error.toString().trim();
    final msg = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length).trim()
        : raw;
    final normalized = msg.toLowerCase();
    final technical = <String>[
      'socketexception',
      'clientexception',
      'httpexception',
      'handshakeexception',
      'oserror',
      'formatexception',
    ];
    if (msg.isEmpty || technical.any(normalized.contains)) {
      return fallback ?? l.somethingWentWrong;
    }
    return msg;
  }

  String _logId(Map<String, dynamic> log) {
    return (log['id'] ?? log['_id'] ?? '').toString();
  }

  Future<void> _resendEmail(Map<String, dynamic> log) async {
    final id = _logId(log);
    if (id.isEmpty) return;
    setState(() => _resendingLogId = id);
    try {
      await _emailApi.resend(id);
      if (mounted) {
        await _loadEmailLogs();
        final t = AppTypography.of(context);
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.invoiceEmailResentSnack,
              style: t.bodySmall,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _resendingLogId = null);
    }
  }

  void _openEmailLogDetails(Map<String, dynamic> log) {
    final encoder = const JsonEncoder.withIndent('  ');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.invoiceEmailDetailsTitle),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(encoder.convert(log)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.dialogClose),
          ),
        ],
      ),
    );
  }

  Uint8List _validatePdf(http.Response r) {
    final bytes = r.bodyBytes;
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    final looksPdf =
        bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';
    if (bytes.isNotEmpty && (ct.contains('pdf') || looksPdf)) return bytes;

    // Try rebuilding if server returned JSON map of byte values.
    try {
      final parsed =
          jsonDecode(utf8.decode(bytes, allowMalformed: true)) as Map?;
      if (parsed != null && parsed.isNotEmpty) {
        final orderedKeys = parsed.keys
            .map((k) => int.tryParse(k.toString()) ?? -1)
            .where((k) => k >= 0)
            .toList()
          ..sort();
        final buffer = List<int>.generate(
          orderedKeys.length,
          (i) => parsed[orderedKeys[i].toString()] as int? ?? 0,
        );
        final rebuilt = Uint8List.fromList(buffer);
        final looksRebuiltPdf = rebuilt.length > 4 &&
            String.fromCharCodes(rebuilt.take(4)) == '%PDF';
        if (looksRebuiltPdf) return rebuilt;
      }
    } catch (_) {
      // fall through
    }

    final sample = utf8.decode(bytes.take(200).toList(), allowMalformed: true);
    throw Exception(sample.isNotEmpty
        ? 'Preview failed: $sample'
        : 'Preview failed: empty response (${r.statusCode})');
  }

  String _resolveBillingName(Invoice invoice, ClientBilling? clientBilling) {
    final raw = (invoice.billingName ?? '').trim();
    if (raw.isNotEmpty) return raw;
    final clientName = (clientBilling?.legalName ?? '').trim();
    if (clientName.isNotEmpty) return clientName;
    return widget.client.name.trim().isEmpty ? '-' : widget.client.name.trim();
  }

  String _resolveAddressField(String? value, String? fallback) {
    final v = (value ?? '').trim();
    if (v.isNotEmpty) return v;
    final f = (fallback ?? '').trim();
    return f;
  }

  Future<void> _editBillingDetails(
    Invoice invoice,
    ClientBilling? clientBilling,
  ) async {
    if (_savingBillingName) return;
    final l = AppLocalizations.of(context)!;
    final currentName = _resolveBillingName(invoice, clientBilling);
    final currentStreet =
        _resolveAddressField(invoice.addressStreet, clientBilling?.addressStreet);
    final currentCity =
        _resolveAddressField(invoice.addressCity, clientBilling?.addressCity);
    final currentPostal = _resolveAddressField(
      invoice.addressPostalCode,
      clientBilling?.addressPostalCode,
    );
    final currentProvince =
        _resolveAddressField(invoice.addressProvince, clientBilling?.addressProvince);
    final currentCountry =
        _resolveAddressField(invoice.addressCountry, clientBilling?.addressCountry);
    final currentEntityType =
        (invoice.entityType ?? widget.client.entityType ?? '').trim();

    final nameCtrl =
        TextEditingController(text: currentName == '-' ? '' : currentName);
    final entityCtrl = TextEditingController(text: currentEntityType);
    final streetCtrl = TextEditingController(text: currentStreet);
    final cityCtrl = TextEditingController(text: currentCity);
    final postalCtrl = TextEditingController(text: currentPostal);
    final provinceCtrl = TextEditingController(text: currentProvince);
    final countryCtrl = TextEditingController(text: currentCountry);
    final reasonCtrl = TextEditingController();

    final entityOptions = <String>{
      'com.de.prop',
      'c.prop',
      'propietario',
      if (entityCtrl.text.trim().isNotEmpty) entityCtrl.text.trim(),
    }.toList()
      ..removeWhere((e) => e.trim().isEmpty);

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.invoiceBillingNameEditCta),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l.invoiceBillingNameNewLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: entityOptions.contains(entityCtrl.text.trim())
                      ? entityCtrl.text.trim()
                      : null,
                  decoration: InputDecoration(
                    labelText: l.clientEntityTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    if (entityOptions.isEmpty)
                      DropdownMenuItem(
                        value: null,
                        child: Text(l.select),
                      ),
                    ...[
                      ...entityOptions,
                    ].map(
                      (opt) => DropdownMenuItem(
                        value: opt,
                        child: Text(opt),
                      ),
                    ),
                  ],
                  onChanged: (v) => entityCtrl.text = v?.trim() ?? '',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: streetCtrl,
                  decoration: InputDecoration(
                    labelText: l.addressStreet,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cityCtrl,
                        decoration: InputDecoration(
                          labelText: l.addressCity,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: postalCtrl,
                        decoration: InputDecoration(
                          labelText: l.addressPostalCode,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: provinceCtrl,
                  decoration: InputDecoration(
                    labelText: l.addressProvince,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: countryCtrl,
                  decoration: InputDecoration(
                    labelText: l.addressCountry,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: l.invoiceBillingNameReasonLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'billingName': nameCtrl.text.trim(),
                  'entityType': entityCtrl.text.trim(),
                  'addressStreet': streetCtrl.text.trim(),
                  'addressCity': cityCtrl.text.trim(),
                  'addressPostalCode': postalCtrl.text.trim(),
                  'addressProvince': provinceCtrl.text.trim(),
                  'addressCountry': countryCtrl.text.trim(),
                  'reason': reasonCtrl.text.trim(),
                });
              },
              child: Text(l.save),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    final nextName = (result['billingName'] ?? '').trim();
    final nextEntity = (result['entityType'] ?? '').trim();
    final nextStreet = (result['addressStreet'] ?? '').trim();
    final nextCity = (result['addressCity'] ?? '').trim();
    final nextPostal = (result['addressPostalCode'] ?? '').trim();
    final nextProvince = (result['addressProvince'] ?? '').trim();
    final nextCountry = (result['addressCountry'] ?? '').trim();

    final currentNameNormalized = currentName == '-' ? '' : currentName.trim();
    final currentStreetNormalized = currentStreet.trim();
    final currentCityNormalized = currentCity.trim();
    final currentPostalNormalized = currentPostal.trim();
    final currentProvinceNormalized = currentProvince.trim();
    final currentCountryNormalized = currentCountry.trim();
    final currentEntityNormalized = currentEntityType.trim();

    final payload = <String, String?>{};
    if (nextName != currentNameNormalized) {
      payload['billingName'] = nextName;
    }
    if (nextEntity != currentEntityNormalized) {
      payload['entityType'] = nextEntity;
    }
    if (nextStreet != currentStreetNormalized) {
      payload['addressStreet'] = nextStreet;
    }
    if (nextCity != currentCityNormalized) {
      payload['addressCity'] = nextCity;
    }
    if (nextPostal != currentPostalNormalized) {
      payload['addressPostalCode'] = nextPostal;
    }
    if (nextProvince != currentProvinceNormalized) {
      payload['addressProvince'] = nextProvince;
    }
    if (nextCountry != currentCountryNormalized) {
      payload['addressCountry'] = nextCountry;
    }

    if (payload.isEmpty) return;
    setState(() => _savingBillingName = true);
    try {
      final updated = await _invoicesApi.updateBillingName(
        invoice.id,
        billingName: payload['billingName'],
        entityType: payload['entityType'],
        addressStreet: payload['addressStreet'],
        addressCity: payload['addressCity'],
        addressPostalCode: payload['addressPostalCode'],
        addressProvince: payload['addressProvince'],
        addressCountry: payload['addressCountry'],
        reason: result['reason'],
      );
      if (!mounted) return;
      setState(() => _currentInvoice = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceBillingNameUpdateSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingBillingName = false);
    }
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
    final invoice = _invoice;
    final issuer = invoice.issuerSnapshot ?? widget.billingProfile;
    final clientBilling = invoice.clientSnapshot ?? widget.client.billing;
    final billingName = _resolveBillingName(invoice, clientBilling);
    final billingEntity =
        (invoice.entityType ?? widget.client.entityType ?? '').trim();
    final billingStreet = _resolveAddressField(
      invoice.addressStreet,
      clientBilling?.addressStreet,
    );
    final billingCity =
        _resolveAddressField(invoice.addressCity, clientBilling?.addressCity);
    final billingPostal = _resolveAddressField(
      invoice.addressPostalCode,
      clientBilling?.addressPostalCode,
    );
    final billingProvince =
        _resolveAddressField(invoice.addressProvince, clientBilling?.addressProvince);
    final billingCountry =
        _resolveAddressField(invoice.addressCountry, clientBilling?.addressCountry);
    final history = [...invoice.updateHistory]
      ..sort((a, b) {
        final ad = a.changedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.changedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.8;
          final tabHeight = (maxHeight - 140).clamp(320.0, maxHeight);
          final hasRecurrence =
              invoice.recurringSeriesId?.trim().isNotEmpty == true;
          final recurrenceLabel =
              '${l.createdByLabel} ${l.invoiceRecurringLabel.toLowerCase()}';
          final occurrenceLabel = invoice.occurrenceDate == null
              ? null
              : DateFormat.yMMMd(l.localeName)
                  .add_Hm()
                  .format(invoice.occurrenceDate!);

          return DefaultTabController(
            length: 2,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 720;
                        final recurrenceButton = hasRecurrence
                            ? FilledButton.tonalIcon(
                                onPressed: widget.onOpenRecurringSeries == null
                                    ? null
                                    : () => widget.onOpenRecurringSeries!(
                                          invoice.recurringSeriesId!.trim(),
                                        ),
                                icon: const Icon(Icons.repeat, size: 16),
                                label: Text(l.invoiceRecurringLabel),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                        final actionRow = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasRecurrence) recurrenceButton,
                            if (hasRecurrence) const SizedBox(width: 8),
                            _StatusPill(
                              status: invoice.status ?? 'draft',
                            ),
                          ],
                        );
                        final actionWidget = compact
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: actionRow,
                              )
                            : actionRow;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.client.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.titleLarge.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      actionWidget,
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    invoice.invoiceNumber,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (hasRecurrence)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        occurrenceLabel == null
                                            ? recurrenceLabel
                                            : '$recurrenceLabel · $occurrenceLabel',
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      tabs: [
                        Tab(text: l.details),
                        Tab(text: l.email),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: tabHeight,
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom: 96 + bottomInset,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        l.invoiceRegisteredAt,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        invoice.registeredAt != null
                                            ? DateFormat.yMMMd(l.localeName)
                                                .add_Hm()
                                                .format(invoice.registeredAt!
                                                    .toLocal())
                                            : l.invoiceRegisteredUnknown,
                                        textAlign: TextAlign.right,
                                        style: t.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (invoice.pdfUrl != null &&
                                    invoice.pdfUrl!.isNotEmpty)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                    ),
                                    title: Text(l.invoicePdfUrl),
                                    subtitle: Text(invoice.pdfUrl!),
                                    trailing: IconButton(
                                      icon:
                                          const Icon(Icons.open_in_new_rounded),
                                      onPressed: () {
                                        final uri = Uri.tryParse(
                                          invoice.pdfUrl!,
                                        );
                                        if (uri != null) {
                                          launchUrl(
                                            uri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                InvoiceDetailParty(
                                  issuer: issuer,
                                  clientBilling: clientBilling,
                                ),
                                const SizedBox(height: 12),
                                Card(
                                  elevation: 1,
                                  color: cs.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                l.invoiceBillingNameTitle,
                                                style: t.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            if (!(invoice.status ?? '')
                                                .toLowerCase()
                                                .contains('draft'))
                                              TextButton.icon(
                                                onPressed: _savingBillingName
                                                    ? null
                                                    : () => _editBillingDetails(
                                                          invoice,
                                                          clientBilling,
                                                        ),
                                                icon: _savingBillingName
                                                    ? const SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.edit_outlined,
                                                        size: 18,
                                                      ),
                                                label: Text(
                                                  l.invoiceBillingNameEditCta,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          billingName,
                                          style: t.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (billingEntity.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            billingEntity,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        if (billingStreet.isNotEmpty)
                                          Text(
                                            billingStreet,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        if (billingCity.isNotEmpty ||
                                            billingPostal.isNotEmpty)
                                          Text(
                                            [
                                              if (billingPostal.isNotEmpty)
                                                billingPostal,
                                              if (billingCity.isNotEmpty)
                                                billingCity,
                                            ].join(' '),
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        if (billingProvince.isNotEmpty ||
                                            billingCountry.isNotEmpty)
                                          Text(
                                            [
                                              if (billingProvince.isNotEmpty)
                                                billingProvince,
                                              if (billingCountry.isNotEmpty)
                                                billingCountry,
                                            ].join(' · '),
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Card(
                                  elevation: 1,
                                  color: cs.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          l.invoiceChangeHistoryTitle,
                                          style: t.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (history.isEmpty)
                                          Text(
                                            l.invoiceChangeHistoryEmpty,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          )
                                        else
                                          Column(
                                            children: history.map((h) {
                                              final when = h.changedAt == null
                                                  ? '-'
                                                  : DateFormat.yMMMd(
                                                          l.localeName)
                                                      .add_Hm()
                                                      .format(h.changedAt!
                                                          .toLocal());
                                              final oldVal =
                                                  (h.oldValue ?? '-').trim();
                                              final newVal =
                                                  (h.newValue ?? '-').trim();
                                              final fieldLabel =
                                                  h.field.trim().isEmpty
                                                      ? l.details
                                                      : h.field;
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.history,
                                                      size: 18,
                                                      color:
                                                          cs.onSurfaceVariant,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            fieldLabel,
                                                            style: t.bodySmall
                                                                .copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            '$oldVal → $newVal',
                                                            style: t
                                                                .bodyMedium
                                                                .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            [
                                                              when,
                                                              if ((h.reason ??
                                                                      '')
                                                                  .trim()
                                                                  .isNotEmpty)
                                                                '${l.reasonLabel}: ${h.reason}',
                                                              if ((h.userId ??
                                                                      '')
                                                                  .trim()
                                                                  .isNotEmpty)
                                                                '${l.updatedByLabel}: ${h.userId}',
                                                            ].join(' · '),
                                                            style: t
                                                                .bodySmall
                                                                .copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InvoiceDetailLines(
                                  loading: _loading,
                                  error: _error,
                                  lines: _lines,
                                  onRefresh: _fetchLines,
                                  totalLabel:
                                      '${l.invoiceTotalLabel}: ${NumberFormat.simpleCurrency(name: '').format(_total)}',
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom: 96 + bottomInset,
                            ),
                            child: _buildEmailPanel(
                              t: t,
                              l: l,
                              cs: cs,
                              canSend: canSend,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          top: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final controller = DefaultTabController.of(context);
                          return AnimatedBuilder(
                            animation: controller,
                            builder: (_, __) {
                              final onEmailTab = controller.index == 1;
                              final status =
                                  (invoice.status ?? '').toLowerCase();
                              final canIssue = !_issuing &&
                                  (status.isEmpty || status.contains('draft'));
                              final primaryLabel = onEmailTab
                                  ? l.invoiceSendCta
                                  : l.invoiceIssueCta;
                              final primaryIcon = onEmailTab
                                  ? Icons.send_rounded
                                  : Icons.verified_outlined;
                              final primaryAction = onEmailTab
                                  ? (canSend
                                      ? () => _openSendInvoice(
                                            canSend: canSend,
                                          )
                                      : null)
                                  : (canIssue ? _issueInvoice : null);

                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _downloadingPdf ? null : _downloadPdf,
                                      icon: _downloadingPdf
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.download_outlined,
                                            ),
                                      label: Text('${l.download} PDF'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _previewing ? null : _previewPdf,
                                      icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                      label: Text(l.invoicePreviewCta),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: primaryAction,
                                      icon: Icon(primaryIcon),
                                      label: Text(primaryLabel),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailPanel({
    required AppTypography t,
    required AppLocalizations l,
    required ColorScheme cs,
    required bool canSend,
  }) {
    final latest = _emailLogs.isNotEmpty ? _emailLogs.first : null;
    final latestStatus =
        (latest?['status'] ?? latest?['state'] ?? l.invoiceEmailStatusNotSent)
            .toString();
    final latestDate = _formatLogDate(_parseLogDate(latest ?? {}), l);
    final bannerText = _emailStatusLoading
        ? l.invoiceEmailSettingsChecking
        : _emailStatusError != null
            ? l.invoiceEmailSettingsUnavailable
            : (_emailConfigured ?? false)
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
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(
                _emailConfigured == true
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                size: 18,
                color:
                    _emailConfigured == true ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bannerText,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (_emailStatusLoading)
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
        if (!_emailStatusLoading &&
            (_emailStatusError != null || _emailConfigured != true)) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEmailSettingsInfo(l),
                icon: const Icon(Icons.settings_outlined),
                label: Text(l.invoiceEmailConfigureCta),
              ),
              TextButton.icon(
                onPressed: _copyPdfLink,
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
              latest == null ? l.invoiceEmailNoSentYet : latestDate,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() => _emailHistoryExpanded = !_emailHistoryExpanded);
                if (_emailHistoryExpanded && !_emailLogsLoading) {
                  _loadEmailLogs();
                }
              },
              icon: Icon(
                _emailHistoryExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(_emailHistoryExpanded
                  ? l.invoiceEmailHistoryHideCta
                  : l.invoiceEmailHistoryShowCta),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _emailHistoryExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _emailLogsLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: cs.primary),
                          ),
                        )
                      : _emailLogsError != null
                          ? Text(
                              _emailLogsError!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            )
                          : _emailLogs.isEmpty
                              ? Text(
                                  l.invoiceEmailNoHistory,
                                  style: t.bodySmall
                                      .copyWith(color: cs.onSurfaceVariant),
                                )
                              : Column(
                                  children: _emailLogs
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
                                          onResend: () => _resendEmail(log),
                                          onViewDetails: () =>
                                              _openEmailLogDetails(log),
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

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final normalized = status.toLowerCase();
    Color bg = cs.surfaceContainerHighest;
    Color fg = cs.onSurfaceVariant;
    String label = status;

    if (normalized.contains('draft')) {
      label = l.invoiceStatusDraft;
      bg = cs.tertiaryContainer;
      fg = cs.onTertiaryContainer;
    } else if (normalized.contains('sent') || normalized.contains('issued')) {
      label = l.invoiceStatusSent;
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    } else if (normalized.contains('paid')) {
      label = l.invoiceStatusPaid;
      bg = cs.secondaryContainer;
      fg = cs.onSecondaryContainer;
    } else if (normalized.contains('overdue')) {
      label = l.invoiceStatusOverdue;
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    } else if (normalized.contains('cancel')) {
      label = l.invoiceStatusCancelled;
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurfaceVariant;
    } else if (normalized.trim().isEmpty) {
      label = l.invoiceStatusUnknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
