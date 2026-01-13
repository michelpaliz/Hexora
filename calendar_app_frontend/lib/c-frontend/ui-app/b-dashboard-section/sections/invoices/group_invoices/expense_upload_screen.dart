import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/providers/providers_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_sections.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExpenseUploadScreen extends StatefulWidget {
  const ExpenseUploadScreen({
    super.key,
    this.embedded = false,
    this.onUploaded,
    this.initialTabIndex = 0,
    this.providersOnly = false,
    required this.groupId,
    required this.groupName,
  });

  final bool embedded;
  final VoidCallback? onUploaded;
  final int initialTabIndex;
  final bool providersOnly;
  final String groupId;
  final String groupName;

  @override
  State<ExpenseUploadScreen> createState() => _ExpenseUploadScreenState();
}

class _ExpenseUploadScreenState extends State<ExpenseUploadScreen>
    with SingleTickerProviderStateMixin {
  final _api = ExpensesApi();
  final _providersApi = ProvidersApi();

  final _vendorController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _totalController = TextEditingController();
  final _vendorTaxIdController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _taxTotalController = TextEditingController();
  final _currencyController = TextEditingController(text: 'EUR');
  final _notesController = TextEditingController();
  final _clientIdController = TextEditingController();

  final _providerNameController = TextEditingController();
  final _providerTaxIdController = TextEditingController();
  final _providerEmailController = TextEditingController();
  final _providerPhoneController = TextEditingController();
  final _providerNotesController = TextEditingController();
  final _providerStreetController = TextEditingController();
  final _providerExtraController = TextEditingController();
  final _providerCityController = TextEditingController();
  final _providerProvinceController = TextEditingController();
  final _providerPostalCodeController = TextEditingController();
  final _providerCountryController = TextEditingController();

  String? _fileName;
  Uint8List? _fileBytes;
  String? _error;
  bool _submitting = false;
  final List<Map<String, String>> _recentUploads = [];
  late final TabController _tabs;

  List<Map<String, dynamic>> _providers = [];
  bool _loadingProviders = false;
  String? _providersError;
  bool _savingProvider = false;
  String? _editingProviderId;
  String? _selectedProviderId;
  String? _selectedProviderSummaryId;
  final List<ExpenseLineDraft> _lines = [];
  List<Map<String, dynamic>>? _vatBreakdown;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
          '[ExpenseUploadScreen] init providersOnly=${widget.providersOnly}');
    }
    _tabs = TabController(length: 2, vsync: this);
    final idx = widget.initialTabIndex.clamp(0, 1);
    _tabs.index = idx;
    _loadProviders();
    _loadRecentUploads();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    _vendorController.dispose();
    _issueDateController.dispose();
    _totalController.dispose();
    _vendorTaxIdController.dispose();
    _invoiceNumberController.dispose();
    _dueDateController.dispose();
    _taxTotalController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    _clientIdController.dispose();
    _providerNameController.dispose();
    _providerTaxIdController.dispose();
    _providerEmailController.dispose();
    _providerPhoneController.dispose();
    _providerNotesController.dispose();
    _providerStreetController.dispose();
    _providerExtraController.dispose();
    _providerCityController.dispose();
    _providerProvinceController.dispose();
    _providerPostalCodeController.dispose();
    _providerCountryController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    final groupId = _resolveGroupId();
    if (groupId.isEmpty) {
      setState(() {
        _loadingProviders = false;
        _providersError = 'Missing group id.';
      });
      if (kDebugMode) {
        debugPrint('[ExpenseUploadScreen] providers: missing group id');
      }
      return;
    }
    setState(() {
      _loadingProviders = true;
      _providersError = null;
    });
    try {
      if (kDebugMode) {
        debugPrint('[ExpenseUploadScreen] providers: groupId=$groupId');
      }
      final list = List<Map<String, dynamic>>.from(
        await _providersApi.list(groupId: groupId),
      );
      list.sort((a, b) {
        final an = (a['name'] ?? '').toString();
        final bn = (b['name'] ?? '').toString();
        return an.compareTo(bn);
      });
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[ExpenseUploadScreen] providers: loaded ${list.length} items',
        );
      }
      setState(() {
        _providers = list;
        _selectedProviderSummaryId ??=
            _providers.isEmpty ? null : _providerId(_providers.first);
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[ExpenseUploadScreen] providers: error $e');
      }
      setState(() => _providersError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  void _selectProvider(String? id) {
    setState(() => _selectedProviderId = id);
    if (id == null) return;
    final match = _providers.firstWhere(
      (p) => (p['id'] ?? p['_id'] ?? p['providerId'])?.toString() == id,
      orElse: () => const <String, dynamic>{},
    );
    if (match.isEmpty) return;
    final name = match['name']?.toString() ?? '';
    final taxId = match['taxId']?.toString() ?? '';
    if (name.isNotEmpty) _vendorController.text = name;
    if (taxId.isNotEmpty) _vendorTaxIdController.text = taxId;
  }

  String? _providerId(Map<String, dynamic> provider) {
    return (provider['id'] ?? provider['_id'] ?? provider['providerId'])
        ?.toString();
  }

  String _providerName(Map<String, dynamic> provider) {
    return provider['name']?.toString().trim() ?? '';
  }

  void _resetProviderForm() {
    _editingProviderId = null;
    _providerNameController.clear();
    _providerTaxIdController.clear();
    _providerEmailController.clear();
    _providerPhoneController.clear();
    _providerNotesController.clear();
    _providerStreetController.clear();
    _providerExtraController.clear();
    _providerCityController.clear();
    _providerProvinceController.clear();
    _providerPostalCodeController.clear();
    _providerCountryController.clear();
  }

  void _editProvider(Map<String, dynamic> provider) {
    setState(() {
      _editingProviderId =
          (provider['id'] ?? provider['_id'] ?? provider['providerId'])
              ?.toString();
      _providerNameController.text = provider['name']?.toString() ?? '';
      _providerTaxIdController.text = provider['taxId']?.toString() ?? '';
      _providerEmailController.text = provider['email']?.toString() ?? '';
      _providerPhoneController.text = provider['phone']?.toString() ?? '';
      _providerNotesController.text = provider['notes']?.toString() ?? '';
      final address = provider['address'];
      if (address is Map) {
        _providerStreetController.text = address['street']?.toString() ?? '';
        _providerExtraController.text = address['extra']?.toString() ?? '';
        _providerCityController.text = address['city']?.toString() ?? '';
        _providerProvinceController.text =
            address['province']?.toString() ?? '';
        _providerPostalCodeController.text =
            address['postalCode']?.toString() ?? '';
        _providerCountryController.text = address['country']?.toString() ?? '';
      }
    });
  }

  void _addLine() {
    setState(() => _lines.add(ExpenseLineDraft()));
  }

  void _removeLine(int index) {
    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  String _computeTotalFromLines() {
    final total = _lines.fold<double>(0, (sum, line) => sum + line.total);
    return total.toStringAsFixed(2);
  }

  double _linesSubtotal() =>
      _lines.fold<double>(0, (sum, line) => sum + line.subtotal);

  double _linesTax() =>
      _lines.fold<double>(0, (sum, line) => sum + line.taxAmount);

  double? _parseAmount(String value) => double.tryParse(value.trim());

  String _formatAmount(double? value) =>
      value == null ? '-' : value.toStringAsFixed(2);

  Future<void> _saveProvider() async {
    if (_savingProvider) return;
    final groupId = _resolveGroupId();
    if (groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing group id.')),
      );
      if (kDebugMode) {
        debugPrint('[ExpenseUploadScreen] save provider: missing group id');
      }
      return;
    }
    final name = _providerNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingProvider = true);
    try {
      if (kDebugMode) {
        debugPrint('[ExpenseUploadScreen] save provider: groupId=$groupId');
      }
      final address = <String, dynamic>{
        if (_providerStreetController.text.trim().isNotEmpty)
          'street': _providerStreetController.text.trim(),
        if (_providerExtraController.text.trim().isNotEmpty)
          'extra': _providerExtraController.text.trim(),
        if (_providerCityController.text.trim().isNotEmpty)
          'city': _providerCityController.text.trim(),
        if (_providerProvinceController.text.trim().isNotEmpty)
          'province': _providerProvinceController.text.trim(),
        if (_providerPostalCodeController.text.trim().isNotEmpty)
          'postalCode': _providerPostalCodeController.text.trim(),
        if (_providerCountryController.text.trim().isNotEmpty)
          'country': _providerCountryController.text.trim(),
      };
      if (_editingProviderId == null) {
        await _providersApi.create(
          name: name,
          taxId: _providerTaxIdController.text.trim().isEmpty
              ? null
              : _providerTaxIdController.text.trim(),
          email: _providerEmailController.text.trim().isEmpty
              ? null
              : _providerEmailController.text.trim(),
          phone: _providerPhoneController.text.trim().isEmpty
              ? null
              : _providerPhoneController.text.trim(),
          address: address.isEmpty ? null : address,
          notes: _providerNotesController.text.trim().isEmpty
              ? null
              : _providerNotesController.text.trim(),
          groupId: groupId,
        );
      } else {
        await _providersApi.update(
          id: _editingProviderId!,
          name: name,
          taxId: _providerTaxIdController.text.trim().isEmpty
              ? null
              : _providerTaxIdController.text.trim(),
          email: _providerEmailController.text.trim().isEmpty
              ? null
              : _providerEmailController.text.trim(),
          phone: _providerPhoneController.text.trim().isEmpty
              ? null
              : _providerPhoneController.text.trim(),
          address: address.isEmpty ? null : address,
          notes: _providerNotesController.text.trim().isEmpty
              ? null
              : _providerNotesController.text.trim(),
        );
      }
      await _loadProviders();
      _resetProviderForm();
    } finally {
      if (mounted) setState(() => _savingProvider = false);
    }
  }

  String _resolveGroupId() {
    final explicit = widget.groupId.trim();
    if (explicit.isNotEmpty) return explicit;
    try {
      final gm = context.read<GroupDomain>();
      final fallback = gm.currentGroup?.id;
      if (fallback != null && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    } catch (_) {}
    return '';
  }

  String _resolveGroupName() {
    final explicit = widget.groupName.trim();
    if (explicit.isNotEmpty) return explicit;
    try {
      final gm = context.read<GroupDomain>();
      final fallback = gm.currentGroup?.name;
      if (fallback != null && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    } catch (_) {}
    return '';
  }

  Future<void> _deleteProvider(String id) async {
    await _providersApi.delete(id);
    await _loadProviders();
  }

  Future<void> _loadRecentUploads() async {
    try {
      final groupId = _resolveGroupId();
      if (groupId.isEmpty) {
        return;
      }
      final items = await _api.list(page: 1, size: 50, groupId: groupId);
      if (!mounted) return;
      setState(() {
        _recentUploads
          ..clear()
          ..addAll(items.map(_mapExpenseToRecent));
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load expenses: $e');
      }
    }
  }

  Future<void> _deleteRecentExpense(String id) async {
    try {
      await _api.deleteExpense(id);
      if (!mounted) return;
      setState(() {
        _recentUploads.removeWhere((item) => item['id'] == id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete expense.'),
        ),
      );
    }
  }

  Map<String, String> _mapExpenseToRecent(Map<String, dynamic> item) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = item[key];
        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
      return '';
    }

    String expenseId() {
      final direct = item['id'] ?? item['_id'] ?? item['expenseId'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }
      return '';
    }

    String providerId() {
      final direct = item['providerId'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }
      final provider = item['provider'];
      if (provider is Map) {
        final nested =
            provider['id'] ?? provider['_id'] ?? provider['providerId'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString();
        }
      }
      return '';
    }

    return {
      'id': expenseId(),
      'vendor': pick(['vendorName', 'vendor']),
      'total': pick(['total']),
      'date': pick(['issueDate', 'date']),
      'file': pick(['fileName', 'file']),
      'providerId': providerId(),
    };
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    setState(() {
      _fileName = file.name;
      _fileBytes = file.bytes;
      _error = null;
    });
  }

  Future<void> _previewSelectedPdf() async {
    final bytes = _fileBytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) return;
    try {
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.invoicePdfPreviewFailedSnack),
        ),
      );
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final groupId = _resolveGroupId();
    if (groupId.isEmpty) {
      setState(() => _error = 'Missing group id.');
      return;
    }
    if (_fileBytes == null || _fileName == null) {
      setState(
        () =>
            _error = AppLocalizations.of(context)!.expenseUploadSelectFileError,
      );
      return;
    }
    if (_vendorController.text.trim().isEmpty ||
        _issueDateController.text.trim().isEmpty) {
      setState(
        () => _error =
            AppLocalizations.of(context)!.expenseUploadRequiredFieldsError,
      );
      return;
    }
    if (_lines.isEmpty && _totalController.text.trim().isEmpty) {
      setState(
        () => _error =
            AppLocalizations.of(context)!.expenseUploadTotalOrLinesError,
      );
      return;
    }
    for (final line in _lines) {
      if (line.descriptionController.text.trim().isEmpty ||
          line.quantity <= 0 ||
          line.unitPrice <= 0 ||
          line.taxRate < 0) {
        setState(
          () => _error =
              AppLocalizations.of(context)!.expenseUploadLinesInvalidError,
        );
        return;
      }
    }
    setState(() {
      _submitting = true;
      _error = null;
      _vatBreakdown = null;
    });
    try {
      final issueDate = DateTime.tryParse(_issueDateController.text.trim());
      final dueDate = DateTime.tryParse(_dueDateController.text.trim());
      if (issueDate == null) {
        throw Exception(
          AppLocalizations.of(context)!.expenseUploadInvalidIssueDateError,
        );
      }
      final response = await _api.uploadExpense(
        bytes: _fileBytes!,
        filename: _fileName!,
        vendorName: _vendorController.text.trim(),
        issueDate: issueDate.toIso8601String(),
        total: _totalController.text.trim(),
        groupId: groupId,
        vendorTaxId: _vendorTaxIdController.text.trim().isEmpty
            ? null
            : _vendorTaxIdController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim().isEmpty
            ? null
            : _invoiceNumberController.text.trim(),
        dueDate: dueDate == null ? null : dueDate.toIso8601String(),
        taxTotal: _taxTotalController.text.trim().isEmpty
            ? null
            : _taxTotalController.text.trim(),
        currency: _currencyController.text.trim().isEmpty
            ? null
            : _currencyController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        clientId: _clientIdController.text.trim().isEmpty
            ? null
            : _clientIdController.text.trim(),
        lines: _lines.isEmpty
            ? null
            : _lines.map((line) => line.toJson()).toList(),
        providerId: _selectedProviderId,
      );
      if (!mounted) return;
      final breakdown = response['vatBreakdown'];
      if (breakdown is List) {
        setState(() {
          _vatBreakdown = breakdown
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.expenseUploadSuccessSnack),
        ),
      );
      final newId = (response['id'] ?? response['_id'] ?? response['expenseId'])
          ?.toString()
          .trim();
      setState(() {
        _recentUploads.insert(0, {
          if (newId != null && newId.isNotEmpty) 'id': newId,
          'vendor': _vendorController.text.trim(),
          'total': _totalController.text.trim(),
          'date': _issueDateController.text.trim(),
          'file': _fileName ?? '',
          'providerId': _selectedProviderId ?? '',
        });
      });
      widget.onUploaded?.call();
      if (!widget.embedded) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    final filePicker = ExpenseFilePickerCard(
      fileName: _fileName,
      fileBytes: _fileBytes,
      submitting: _submitting,
      onPick: _pickFile,
      onPreviewPdf: (_fileName?.toLowerCase().endsWith('.pdf') ?? false)
          ? _previewSelectedPdf
          : null,
    );
    final providerPicker = ExpenseProviderPicker(
      providers: _providers,
      selectedProviderId: _selectedProviderId,
      providersError: _providersError,
      loading: _loadingProviders,
      onSelectProvider: _selectProvider,
    );
    final linesEditor = ExpenseLinesEditor(
      lines: _lines,
      onAddLine: _addLine,
      onRemoveLine: _removeLine,
      onLinesChanged: () => setState(() {}),
    );
    final hasLines = _lines.isNotEmpty;
    final computedTotal = hasLines ? _computeTotalFromLines() : '';
    if (hasLines && computedTotal != _totalController.text) {
      _totalController.text = computedTotal;
    }
    final summarySubtotal = hasLines
        ? _formatAmount(_linesSubtotal())
        : (() {
            final total = _parseAmount(_totalController.text);
            final tax = _parseAmount(_taxTotalController.text);
            if (total == null) return '-';
            if (tax == null) return _formatAmount(total);
            return _formatAmount((total - tax).clamp(0, double.infinity));
          })();
    final summaryTax = hasLines
        ? _formatAmount(_linesTax())
        : _formatAmount(_parseAmount(_taxTotalController.text));
    final summaryTotal = hasLines
        ? _formatAmount(_linesSubtotal() + _linesTax())
        : _formatAmount(_parseAmount(_totalController.text));
    final vatBreakdown = ExpenseVatBreakdownCard(
      breakdown: _vatBreakdown,
    );
    final summaryBar = ExpenseTotalsSummaryBar(
      subtotal: summarySubtotal,
      tax: summaryTax,
      total: summaryTotal,
    );
    final displayGroupId = _resolveGroupId();
    final displayGroupName = _resolveGroupName();
    final formFields = ExpenseFormFields(
      groupName: displayGroupName,
      groupId: displayGroupId,
      providerPicker: providerPicker,
      vendorController: _vendorController,
      issueDateController: _issueDateController,
      totalController: _totalController,
      vendorTaxIdController: _vendorTaxIdController,
      invoiceNumberController: _invoiceNumberController,
      dueDateController: _dueDateController,
      taxTotalController: _taxTotalController,
      currencyController: _currencyController,
      notesController: _notesController,
      clientIdController: _clientIdController,
      linesEditor: linesEditor,
      vatBreakdown: vatBreakdown,
      summaryBar: summaryBar,
      hasLines: hasLines,
      submitting: _submitting,
      onPickDate: _pickDate,
    );
    final errorsAndSubmit = ExpenseErrorsAndSubmit(
      error: _error,
      submitting: _submitting,
      onSubmit: _submit,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              widget.providersOnly
                  ? l.expenseUploadTabProviders
                  : l.expenseUploadTitle,
              style: t.titleLarge,
            ),
          ),
        if (widget.providersOnly)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ExpenseProvidersManagementView(
                groupName: _resolveGroupName(),
                groupId: _resolveGroupId(),
                providers: _providers,
                recentUploads: _recentUploads,
                loadingProviders: _loadingProviders,
                savingProvider: _savingProvider,
                editingProviderId: _editingProviderId,
                selectedProviderId: _selectedProviderSummaryId,
                providerId: _providerId,
                providerName: _providerName,
                providerNameController: _providerNameController,
                providerTaxIdController: _providerTaxIdController,
                providerEmailController: _providerEmailController,
                providerPhoneController: _providerPhoneController,
                providerNotesController: _providerNotesController,
                providerStreetController: _providerStreetController,
                providerExtraController: _providerExtraController,
                providerCityController: _providerCityController,
                providerProvinceController: _providerProvinceController,
                providerPostalCodeController: _providerPostalCodeController,
                providerCountryController: _providerCountryController,
                onSelectProvider: (provider) {
                  final id = _providerId(provider);
                  if (id != null) {
                    setState(() => _selectedProviderSummaryId = id);
                  }
                  _editProvider(provider);
                },
                onSaveProvider: _saveProvider,
                onResetProviderForm: _resetProviderForm,
                onDeleteProvider: _deleteProvider,
              ),
            ),
          )
        else ...[
          TabBar(
            controller: _tabs,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              Tab(text: l.expenseUploadTabList),
              Tab(text: l.expenseUploadTabUpload),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TabBarView(
                controller: _tabs,
                children: [
                  ExpenseRecentUploadsTab(
                    recentUploads: _recentUploads,
                    onDeleteExpense: _deleteRecentExpense,
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: ExpenseOrganizerTab(
                          filePicker: filePicker,
                          formFields: formFields,
                        ),
                      ),
                      errorsAndSubmit,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.expenseUploadTitle),
      ),
      body: body,
    );
  }
}
