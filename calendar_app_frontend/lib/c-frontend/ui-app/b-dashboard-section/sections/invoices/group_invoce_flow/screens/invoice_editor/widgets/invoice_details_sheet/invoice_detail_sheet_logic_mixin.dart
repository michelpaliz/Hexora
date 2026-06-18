part of 'invoice_detail_sheet.dart';

mixin InvoiceDetailSheetLogic on State<InvoiceDetailSheet> {
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
  bool _inlinePdfLoading = false;
  String? _inlinePdfError;
  Uint8List? _inlinePdfBytes;
  bool _savingBillingName = false;
  bool _updatingDelivery = false;
  Invoice get _invoice => _currentInvoice ?? widget.invoice;
  num get _total => _lines.fold<num>(0, (sum, l) => sum + (l.lineTotal ?? 0));

  Future<void> _loadInvoiceDetail() async {
    final id = widget.invoice.id.trim();
    if (id.isEmpty) return;
    try {
      final full = await _invoicesApi.getById(id);
      if (!mounted) return;
      setState(() => _currentInvoice = full);
    } catch (_) {
      // Keep rendering from the selected list item snapshot if detail refresh fails.
    }
  }

  Future<void> _fetchLines() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _linesApi.list(_invoice.id);
      if (!mounted) return;
      final fallback = _invoice.lines;
      setState(() {
        _lines = items.isNotEmpty
            ? items
            : (fallback.isNotEmpty ? fallback : const <InvoiceLine>[]);
      });
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

  Future<void> _notifyInvoiceChanged() async {
    final cb = widget.onInvoiceChanged;
    if (cb != null) cb();
  }

  Future<void> _loadInlinePdfPreview() async {
    if (_inlinePdfLoading) return;
    setState(() {
      _inlinePdfLoading = true;
      _inlinePdfError = null;
    });
    try {
      final r = await _invoicesApi.previewPdf(_invoice.id);
      final bytes = _validatePdf(r);
      if (!mounted) return;
      setState(() => _inlinePdfBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inlinePdfBytes = null;
        _inlinePdfError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _inlinePdfLoading = false);
      }
    }
  }

  String _fileNameFromHeaders(Map<String, String> headers) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final match = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
          .firstMatch(raw);
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
          await _loadInvoiceDetail();
          await _notifyInvoiceChanged();
        },
      ),
    );
  }

  Future<void> _markInvoiceSent({
    required String channel,
  }) async {
    if (_updatingDelivery) return;
    setState(() => _updatingDelivery = true);
    try {
      final updated = await _invoicesApi.markInvoiceSent(
        _invoice.id,
        channel: channel,
      );
      if (!mounted) return;
      setState(() => _currentInvoice = updated);
      await _notifyInvoiceChanged();
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDeliveryStatusUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      final normalized = message.toLowerCase();
      final readable = normalized.contains('409') ||
              normalized.contains('not issued') ||
              normalized.contains('solo') && normalized.contains('emit')
          ? l.invoiceDeliveryOnlyIssued
          : (message.isEmpty ? l.invoiceDeliveryUpdateError : message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readable)),
      );
    } finally {
      if (mounted) setState(() => _updatingDelivery = false);
    }
  }

  Future<void> _markInvoiceUnsent() async {
    if (_updatingDelivery) return;
    setState(() => _updatingDelivery = true);
    try {
      final updated = await _invoicesApi.markInvoiceUnsent(_invoice.id);
      if (!mounted) return;
      setState(() => _currentInvoice = updated);
      await _notifyInvoiceChanged();
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceMarkedUnsent)),
      );
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      final normalized = message.toLowerCase();
      final readable = normalized.contains('409') ||
              normalized.contains('not issued') ||
              normalized.contains('solo') && normalized.contains('emit')
          ? l.invoiceDeliveryOnlyIssued
          : (message.isEmpty ? l.invoiceDeliveryUpdateError : message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readable)),
      );
    } finally {
      if (mounted) setState(() => _updatingDelivery = false);
    }
  }

  static const _invoiceChronologyErrorMessage =
      'Esta factura tiene una fecha anterior a la última factura emitida. '
      'Para mantener la numeración cronológica, debes emitir primero las '
      'facturas de fechas anteriores o corregir la fecha.';

  DateTime? _invoiceChronologyDate(Invoice invoice) {
    return invoice.issueDate ?? invoice.occurrenceDate ?? invoice.registeredAt;
  }

  bool _isBeforeCalendarDay(DateTime value, DateTime limit) {
    final valueDay = DateTime(value.year, value.month, value.day);
    final limitDay = DateTime(limit.year, limit.month, limit.day);
    return valueDay.isBefore(limitDay);
  }

  Future<bool> _canIssueInvoiceByDate(Invoice invoice) async {
    final selectedDate = _invoiceChronologyDate(invoice);
    if (selectedDate == null) return true;
    final issued =
        await _invoicesApi.listByGroup(invoice.groupId, status: 'issued');
    DateTime? latestIssuedDate;
    for (final item in issued) {
      final date = _invoiceChronologyDate(item);
      if (date == null) continue;
      if (latestIssuedDate == null || date.isAfter(latestIssuedDate)) {
        latestIssuedDate = date;
      }
    }
    if (latestIssuedDate == null) return true;
    return !_isBeforeCalendarDay(selectedDate, latestIssuedDate);
  }

  Future<void> _issueInvoice() async {
    if (_issuing) return;
    setState(() => _issuing = true);
    try {
      final currentLines = await _linesApi.list(_invoice.id);
      if (currentLines.isEmpty) {
        if (!mounted) return;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.invoiceLinesRequired)),
        );
        return;
      }
      if (!await _canIssueInvoiceByDate(_invoice)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(_invoiceChronologyErrorMessage)),
        );
        return;
      }
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
      final msg = _safeErrorMessage(
        context,
        e,
        fallback: l.invoiceIssueFailedSnack,
      );
      if (msg
          .toLowerCase()
          .contains('cannot issue invoice without line items')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
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
    final currentStreet = _resolveAddressField(
        invoice.addressStreet, clientBilling?.addressStreet);
    final currentCity =
        _resolveAddressField(invoice.addressCity, clientBilling?.addressCity);
    final currentPostal = _resolveAddressField(
      invoice.addressPostalCode,
      clientBilling?.addressPostalCode,
    );
    final currentProvince = _resolveAddressField(
        invoice.addressProvince, clientBilling?.addressProvince);
    final currentCountry = _resolveAddressField(
        invoice.addressCountry, clientBilling?.addressCountry);
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
}
