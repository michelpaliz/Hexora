part of 'invoice_detail_sheet.dart';

mixin InvoiceDetailSheetLogic on State<InvoiceDetailSheet> {
  final _invoicesApi = InvoicesApi();
  final _linesApi = InvoiceLinesApi();
  Invoice? _currentInvoice;
  bool _loading = true;
  String? _error;
  List<InvoiceLine> _lines = const [];
  bool _previewing = false;
  bool _downloadingPdf = false;
  bool _inlinePdfLoading = false;
  String? _inlinePdfError;
  Uint8List? _inlinePdfBytes;
  bool _savingBillingName = false;
  bool _updatingDelivery = false;
  List<Map<String, dynamic>> _invoiceHistory = const [];
  bool _historyLoading = false;
  String? _historyError;
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

  Future<void> _loadInvoiceHistory() async {
    final id = _invoice.id.trim();
    if (id.isEmpty) return;
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final payload = await _invoicesApi.getHistory(id);
      final raw = payload['history'];
      final history = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : const <Map<String, dynamic>>[];
      history.sort((a, b) {
        DateTime value(Map<String, dynamic> item) =>
            DateTime.tryParse(
              (item['changedAt'] ?? item['createdAt'] ?? '').toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return value(b).compareTo(value(a));
      });
      if (!mounted) return;
      setState(() => _invoiceHistory = history);
    } catch (error) {
      if (!mounted) return;
      setState(() => _historyError = error.toString());
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _updateInvoicePayment(Map<String, dynamic> payload) async {
    final updated = await _invoicesApi.updatePayment(_invoice.id, payload);
    if (!mounted) return;
    setState(() => _currentInvoice = updated);
    widget.onInvoiceChanged?.call();
    await _loadInlinePdfPreview();
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

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) return;
    setState(() => _downloadingPdf = true);
    try {
      final r = await _invoicesApi.downloadPdf(_invoice.id);
      final invoiceName = _invoice.invoiceNumber.trim().isNotEmpty
          ? _invoice.invoiceNumber.trim()
          : _invoice.id.trim();
      final fallback = invoiceName.endsWith('.pdf')
          ? invoiceName
          : 'invoice-$invoiceName.pdf';
      final fileName = downloadFileNameFromHeaders(
        r.headers,
        fallback: fallback,
      );
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
                  initialValue: entityOptions.contains(entityCtrl.text.trim())
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
