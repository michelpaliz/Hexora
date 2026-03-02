part of '../invoice_editor_controller.dart';
extension InvoiceEditorControllerEvidenceFlow on InvoiceEditorController {
  Future<String?> _ensureDraftIdForOcr(BuildContext context) async {
    final existing = _savedInvoice?.id.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = await _saveDraftInternal(context, allowEmptyLines: true);
    final id = created.id.trim();
    if (id.isEmpty) return null;
    return id;
  }

  Future<void> extractLinesFromImage(BuildContext context) async {
    if (extractingLinesFromImage) return;

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      withData: true,
    );
    final files = picked?.files;
    final file = (files == null || files.isEmpty) ? null : files.first;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) return;
    if (!context.mounted) return;
    _lastOcrImageBytes = bytes;
    _lastOcrImageName = file.name;
    notifyListeners();

    try {
      final draftId = await _ensureDraftIdForOcr(context);
      if (!context.mounted) return;
      if (draftId == null || draftId.isEmpty) {
        final l = AppLocalizations.of(context)!;
        throw Exception(l.invoiceDraftSaveFailedSnack);
      }
      await _ocrFlow.startExtraction(
        OcrImageFile(bytes: bytes, fileName: file.name),
        draftId,
      );
      if (!context.mounted) return;
      if (_ocrState.stage == OcrExtractionStage.error &&
          _ocrState.extractionError != null &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ocrState.extractionError!)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.failedToUploadImage,
            ),
          ),
        ),
      );
    }
  }

  void applyExtractedLinesToDraft() {
    final extracted = _ocrState.extractedLines;
    if (extracted.isEmpty) return;
    if (_useBlocks) {
      _useBlocks = false;
      _resetDraftLines();
    } else if (lines.length == 1) {
      final only = lines.first;
      final isPlaceholder = only.description.text.trim().isEmpty &&
          (only.unitPrice ?? 0) == 0 &&
          (only.quantity ?? 1) == 1;
      if (isPlaceholder) {
        _resetDraftLines();
      }
    }

    final startAt = lines.length;
    for (var i = 0; i < extracted.length; i++) {
      final line = extracted[i];
      final draft = LineDraft(position: startAt + i + 1);
      draft.description.text = line.description;
      draft.quantityCtrl.text = line.quantity.toString();
      draft.unitPriceCtrl.text = line.unitPrice.toStringAsFixed(2);
      draft.taxRateCtrl.text = line.taxRate.toStringAsFixed(2);
      lines.add(draft);
    }
    notifyUi();
  }

  void clearExtractedLines() {
    _ocrFlow.resetExtraction();
    _lastOcrImageBytes = null;
    _lastOcrImageName = null;
    notifyListeners();
  }

  Future<void> previewLastOcrImage(BuildContext context) async {
    final bytes = _lastOcrImageBytes;
    if (bytes == null || !context.mounted) return;
    final l = AppLocalizations.of(context)!;
    final title = (_lastOcrImageName ?? '').trim().isEmpty
        ? l.invoiceLinesModePhoto
        : _lastOcrImageName!.trim();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 960,
              maxHeight: 760,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(dialogContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: l.close,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Center(
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  bool canAttachEvidenceForLine(LineDraft line) =>
      (line.id ?? '').trim().isNotEmpty;

  String? lineEvidenceBlobName(LineDraft line) {
    final value = (line.evidenceBlobName ?? '').trim();
    return value.isEmpty ? null : value;
  }

  String _resolveMimeTypeFromFile(PlatformFile file) {
    final raw = (file.extension ?? '').toLowerCase().trim();
    switch (raw) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return '';
    }
  }

  Future<void> attachEvidenceForLine(
    BuildContext context,
    LineDraft line,
  ) async {
    final invoiceId = (_savedInvoice?.id ?? '').trim();
    final lineId = (line.id ?? '').trim();
    if (invoiceId.isEmpty || lineId.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceNoId)),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    final files = picked?.files;
    final file = (files == null || files.isEmpty) ? null : files.first;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) return;
    if (!context.mounted) return;

    final mimeType = _resolveMimeTypeFromFile(file);
    if (mimeType.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceAttachFailed)),
      );
      return;
    }

    try {
      final result = await _linesApi.attachEvidenceToLine(
        invoiceId: invoiceId,
        lineId: lineId,
        file: line_ev.InvoiceLineEvidenceFile(
          bytes: bytes,
          fileName: file.name,
          mimeType: mimeType,
        ),
      );
      line.evidenceBlobName = result.evidenceBlobName;
      notifyListeners();
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceAttached)),
      );
      await _previewEvidenceUrl(
        context,
        line,
        evidenceUrl: result.evidenceUrl,
        evidenceBlobName: result.evidenceBlobName,
      );
    } on line_ev.InvoiceLineEvidenceException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceAttachFailed)),
      );
    }
  }

  Future<void> openEvidenceForLine(
    BuildContext context,
    LineDraft line,
  ) async {
    await _previewEvidenceUrl(context, line);
  }

  Future<void> deleteEvidenceForLine(
    BuildContext context,
    LineDraft line,
  ) async {
    final invoiceId = (_savedInvoice?.id ?? '').trim();
    final lineId = (line.id ?? '').trim();
    if (invoiceId.isEmpty || lineId.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceNoId)),
      );
      return;
    }
    try {
      await _linesApi.deleteLineEvidence(invoiceId, lineId);
      line.evidenceBlobName = null;
      notifyListeners();
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceRemoved)),
      );
    } on line_ev.InvoiceLineEvidenceException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceDeleteFailed)),
      );
    }
  }

  bool _isImageEvidence(String? value) {
    final source = (value ?? '').toLowerCase();
    return source.endsWith('.jpg') ||
        source.endsWith('.jpeg') ||
        source.endsWith('.png') ||
        source.endsWith('.webp') ||
        source.contains('image/jpeg') ||
        source.contains('image/png') ||
        source.contains('image/webp');
  }

  Future<void> _previewEvidenceUrl(
    BuildContext context,
    LineDraft line, {
    String? evidenceUrl,
    String? evidenceBlobName,
  }) async {
    final invoiceId = (_savedInvoice?.id ?? '').trim();
    final lineId = (line.id ?? '').trim();
    if (invoiceId.isEmpty || lineId.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceNoId)),
      );
      return;
    }

    try {
      String url = (evidenceUrl ?? '').trim();
      String blobName =
          (evidenceBlobName ?? line.evidenceBlobName ?? '').trim();
      if (url.isEmpty) {
        final read = await _linesApi.getLineEvidenceReadUrl(
          invoiceId,
          lineId,
          blobName: blobName.isEmpty ? null : blobName,
        );
        url = read.url.trim();
        if (blobName.isEmpty) {
          blobName = read.blobName.trim();
        }
      }

      final uri = Uri.tryParse(url);
      if (uri == null || url.isEmpty) {
        throw Exception('invalid-url');
      }
      if (!context.mounted) return;

      final isImage = _isImageEvidence(blobName) || _isImageEvidence(url);
      if (!isImage) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final l = AppLocalizations.of(dialogContext)!;
          final cs = Theme.of(dialogContext).colorScheme;
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 960,
                maxHeight: 760,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.invoiceLineEvidenceOpen,
                            style: Theme.of(dialogContext)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: l.close,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5,
                        child: Center(
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l.invoiceLineEvidenceOpenFailed,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            loadingBuilder: (c, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            uri,
                            mode: LaunchMode.platformDefault,
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(l.invoiceOpenCta),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } on line_ev.InvoiceLineEvidenceException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLineEvidenceOpenFailed)),
      );
    }
  }

  List<InvoiceBlock> _sanitizeBlocks(List<InvoiceBlockDraft> draftBlocks) {
    return draftBlocks.map((draft) {
      final block = draft.toBlock();
      final type = block.type;
      if (type == InvoiceBlockType.item) {
        return InvoiceBlock(
          type: type,
          sku: block.sku,
          description: block.description,
          qty: block.qty,
          unit: block.unit,
          unitPrice: block.unitPrice,
          taxRate: block.taxRate,
          level: block.level,
          isBillable: block.isBillable,
        );
      }
      if (type == InvoiceBlockType.date ||
          type == InvoiceBlockType.section ||
          type == InvoiceBlockType.subsection) {
        if (type == InvoiceBlockType.section && block.isBillable == true) {
          return InvoiceBlock(
            type: InvoiceBlockType.item,
            description: block.title,
            qty: block.qty,
            unit: block.unit,
            unitPrice: block.unitPrice,
            taxRate: block.taxRate,
            isBillable: true,
          );
        }
        return InvoiceBlock(
          type: type,
          title: block.title,
          qty: type == InvoiceBlockType.section ? block.qty : null,
          unit: type == InvoiceBlockType.section ? block.unit : null,
          unitPrice: type == InvoiceBlockType.section ? block.unitPrice : null,
          taxRate: type == InvoiceBlockType.section ? block.taxRate : null,
          isBillable:
              type == InvoiceBlockType.section ? block.isBillable : null,
          level: type == InvoiceBlockType.subsection ? block.level : null,
        );
      }
      if (type == InvoiceBlockType.note) {
        return InvoiceBlock(
          type: type,
          text: block.text,
          level: block.level,
        );
      }
      if (type == InvoiceBlockType.checklist) {
        final itemTexts = (block.items ?? const [])
            .map((item) => item.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();
        final title = (block.title ?? '').trim();
        final checklistDescription = () {
          if (itemTexts.isEmpty) return title;
          final lines = <String>[];
          if (title.isNotEmpty) {
            lines.add(title);
          }
          lines.addAll(itemTexts.map((item) => '- $item'));
          return lines.join('\n');
        }();
        if (block.isBillable == true) {
          return InvoiceBlock(
            type: InvoiceBlockType.item,
            description: checklistDescription,
            qty: block.qty,
            unit: block.unit,
            unitPrice: block.unitPrice,
            taxRate: block.taxRate,
            isBillable: true,
          );
        }
        return InvoiceBlock(
          type: type,
          items: block.items,
          level: block.level,
        );
      }
      return InvoiceBlock(type: type);
    }).toList();
  }

  Map<String, dynamic> _buildDraftUpdatePayload(List<InvoiceBlock> blocks) {
    return {
      if (_clientId != null) 'clientId': _clientId,
      if (invoiceDate.value != null)
        'issueDate': invoiceDate.value!.toUtc().toIso8601String(),
      if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      if (currency.text.trim().isNotEmpty) 'currency': currency.text.trim(),
      ...buildDiscountPayload(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  List<InvoiceBlock> _blocksFromLines(List<LineDraft> draftLines) {
    final blocks = <InvoiceBlock>[];
    for (final line in draftLines) {
      final desc = line.description.text.trim();
      if (desc.isEmpty) continue;
      blocks.add(InvoiceBlock(
        type: InvoiceBlockType.item,
        description: desc,
        qty: line.quantity ?? 1,
        unitPrice: line.unitPrice ?? 0,
        taxRate: line.taxRate ?? 21,
        isBillable: true,
      ));
    }
    return blocks;
  }

  Future<void> handleSaveDraft(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    try {
      final editing =
          _editingDraftId != null && _editingDraftId!.trim().isNotEmpty;
      if (editing) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Update Draft Invoice'),
            content: const Text(
              'Edit draft details and line items before issuing the invoice.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child:
                    Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.saveDraft),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      if (!context.mounted) return;
      final inv = await saveDraft(context);
      if (!context.mounted) return;

      final msg = editing
          ? 'Draft updated successfully.'
          : (inv.invoiceNumber.isNotEmpty
              ? l.invoiceDraftSavedSnack(inv.invoiceNumber)
              : l.invoiceDraftSavedSnackNoNumber);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('[InvoicePreview] $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftSaveFailedSnack,
            ),
          ),
        ),
      );
    }
  }

  Future<void> previewPdf(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    if (_previewing) return;
    _previewing = true;
    notifyListeners();
    try {
      final inv = await saveDraft(context);
      final count = await _syncLinesForInvoice(inv.id);
      if (count == 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.invoiceLinesRequired)),
        );
        return;
      }
      final r = await _invoicesApi.previewPdf(inv.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);

      if (kIsWeb) {
        _previewPdfBytes = bytes;
      } else {
        await pdf_launcher.launchPdfPreview(
          bytes,
          fileName: 'invoice-${_savedInvoice!.invoiceNumber}.pdf',
        );
      }
      _previewedPdf = true;
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoicePdfPreviewFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      _previewing = false;
      notifyListeners();
    }
  }

  Future<void> issue(BuildContext context) async {
    final l = AppLocalizations.of(context)!;

    if (!hasBillableEntries || total <= 0 || _clientId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }

    try {
      final inv = await saveDraft(context);
      final count = await _syncLinesForInvoice(inv.id);
      if (count == 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.invoiceLinesRequired)),
        );
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftSaveFailedSnack,
            ),
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceIssueConfirmTitle),
        content: Text(l.invoiceIssueConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.invoiceIssueCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _issuing = true;
    notifyListeners();
    try {
      final issued = await _invoicesApi.issue(_savedInvoice!.id);
      _savedInvoice = issued;
      notifyListeners();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.invoiceIssueSuccessSnack(issued.invoiceNumber)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
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
          content: Text(
            msg,
          ),
        ),
      );
    } finally {
      _issuing = false;
      notifyListeners();
    }
  }

  void _validateBlocks(AppLocalizations l) {
    if (blocks.isEmpty) {
      throw Exception(l.invoiceLinesRequired);
    }
    for (final block in blocks) {
      final type = block.type;
      if (type == InvoiceBlockType.item) {
        final qty = block.qty;
        final price = block.unitPrice;
        final tax = block.taxRate;
        if (qty != null && qty < 0) {
          throw Exception(l.invoiceValidationNonNegative);
        }
        if (price != null && price < 0) {
          throw Exception(l.invoiceValidationNonNegative);
        }
        if (tax != null && (tax < 0 || tax > 100)) {
          throw Exception(l.invoiceValidationTaxRate);
        }
        if (block.description.text.trim().isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
      } else if (type == InvoiceBlockType.date ||
          type == InvoiceBlockType.section ||
          type == InvoiceBlockType.subsection) {
        if (block.title.text.trim().isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
        if (type == InvoiceBlockType.section && block.isBillable) {
          final qty = block.qty;
          final price = block.unitPrice;
          final tax = block.taxRate;
          if (qty != null && qty < 0) {
            throw Exception(l.invoiceValidationNonNegative);
          }
          if (price != null && price < 0) {
            throw Exception(l.invoiceValidationNonNegative);
          }
          if (tax != null && (tax < 0 || tax > 100)) {
            throw Exception(l.invoiceValidationTaxRate);
          }
          if ((price ?? 0) <= 0) {
            throw Exception(l.invoiceValidationNonNegative);
          }
        }
      } else if (type == InvoiceBlockType.note) {
        if (block.text.text.trim().isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
      } else if (type == InvoiceBlockType.checklist) {
        if (block.checklistItems.isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
        for (final item in block.checklistItems) {
          if (item.text.text.trim().isEmpty) {
            throw Exception(l.fieldIsRequired);
          }
        }
        if (block.isBillable) {
          final price = block.unitPrice;
          if (price != null && price < 0) {
            throw Exception(l.invoiceValidationNonNegative);
          }
          if ((price ?? 0) <= 0) {
            throw Exception(l.invoiceValidationNonNegative);
          }
        }
      }
    }
  }

  Future<void> deleteDraft(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final draft = _savedInvoice;
    if (draft == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceDraftRemoveTitle),
        content: Text(l.invoiceDraftRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _deletingDraft = true;
    notifyListeners();
    try {
      await _invoicesApi.delete(draft.id);
      _savedInvoice = null;
      _previewedPdf = false;
      _previewPdfBytes = null;
      await _refreshClientStats();
      notifyListeners();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDraftRemovedSnack)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftRemoveFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      _deletingDraft = false;
      notifyListeners();
    }
  }

  Future<void> previewDraft(BuildContext context, Invoice draft) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await _invoicesApi.previewPdf(draft.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'invoice-${draft.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoicePdfPreviewFailedSnack,
            ),
          ),
        ),
      );
    }
  }

  Future<void> deleteDraftById(BuildContext context, Invoice draft) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceDraftRemoveTitle),
        content: Text(l.invoiceDraftRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _deletingDraft = true;
    notifyListeners();
    try {
      await _invoicesApi.delete(draft.id);
      _pendingDrafts = _pendingDrafts.where((d) => d.id != draft.id).toList();
      _pendingDraftsCount = _pendingDrafts.length;
      notifyListeners();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDraftRemovedSnack)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftRemoveFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      _deletingDraft = false;
      notifyListeners();
    }
  }


}
