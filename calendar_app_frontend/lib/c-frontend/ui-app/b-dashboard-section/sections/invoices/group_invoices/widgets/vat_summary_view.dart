import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/b-backend/vat/vat_summary_api.dart';

import 'vat_summary/vat_summary_header.dart';
import 'vat_summary/vat_summary_quarter.dart';
import 'vat_summary/vat_summary_utils.dart';

class VatSummaryView extends StatefulWidget {
  final VatSummaryApi api;
  final String? groupId;

  const VatSummaryView({
    super.key,
    required this.api,
    this.groupId,
  });

  @override
  State<VatSummaryView> createState() => _VatSummaryViewState();
}

class _VatSummaryViewState extends State<VatSummaryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final ExpensesApi _expensesApi = ExpensesApi();
  final InvoicesApi _invoicesApi = InvoicesApi();
  int _year = DateTime.now().year;
  final Map<int, Map<String, dynamic>> _data = {};
  final Map<int, List<Map<String, dynamic>>> _expenseEntries = {};
  final Map<int, Map<String, dynamic>> _invoiceSummaries = {};
  final Map<int, Map<String, dynamic>> _expenseSummaries = {};
  final Map<int, List<Map<String, dynamic>>> _allYearExpenses = {};
  final Map<int, String?> _errors = {};
  final Map<int, bool> _loading = {};
  bool _exportingVatAudit = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _ensureLoaded(_tabs.index + 1);
      if (mounted) setState(() {});
    });
    _ensureLoaded(1);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _ensureLoaded(int quarter) {
    if (_loading[quarter] == true || _data.containsKey(quarter)) return;
    _loadQuarter(quarter);
  }

  Future<List<Map<String, dynamic>>> _loadExpensesForYear(int year) async {
    final cached = _allYearExpenses[year];
    if (cached != null) return cached;
    final items = await _expensesApi.listAll(groupId: widget.groupId);
    _allYearExpenses[year] = items;
    return items;
  }

  DateTime? _parseExpenseDate(Map<String, dynamic> item) {
    for (final key in const ['issueDate', 'date', 'issuedAt']) {
      final raw = item[key];
      if (raw == null) continue;
      if (raw is DateTime) {
        return DateTime.utc(raw.year, raw.month, raw.day);
      }
      final parsed = DateTime.tryParse(raw.toString().trim());
      if (parsed != null) {
        return DateTime.utc(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _filterExpensesForRange(
    List<Map<String, dynamic>> items,
    DateTime from,
    DateTime to,
  ) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    return items.where((item) {
      final issueDate = _parseExpenseDate(item);
      if (issueDate == null) return false;
      return !issueDate.isBefore(start) && !issueDate.isAfter(end);
    }).toList(growable: false);
  }

  Future<void> _loadQuarter(int quarter) async {
    setState(() {
      _loading[quarter] = true;
      _errors[quarter] = null;
    });
    final range = quarterRangeDates(_year, quarter);
    final from = formatVatDate(range.$1);
    final toExclusive = DateTime(range.$2.year, range.$2.month + 1, 1);
    final to = formatVatDate(toExclusive);
    try {
      final results = await Future.wait([
        widget.api.getQuarterSummary(
          groupId: widget.groupId,
          year: _year,
          quarter: quarter,
        ),
        _invoicesApi.getSummary(
          groupId: (widget.groupId ?? '').trim(),
          from: from,
          to: to,
          currency: 'EUR',
        ),
        _expensesApi.summaryTotals(
          groupId: (widget.groupId ?? '').trim(),
          from: from,
          to: to,
          currency: 'EUR',
        ),
        _loadExpensesForYear(_year),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final invoiceSummary = results[1] as Map<String, dynamic>;
      final expenseSummary = results[2] as Map<String, dynamic>;
      final allYearExpenses = results[3] as List<Map<String, dynamic>>;
      final expenseEntries =
          _filterExpensesForRange(allYearExpenses, range.$1, range.$2);
      if (!mounted) return;
      setState(() {
        _data[quarter] = data;
        _expenseEntries[quarter] = expenseEntries;
        _invoiceSummaries[quarter] = invoiceSummary;
        _expenseSummaries[quarter] = expenseSummary;
      });
    } catch (e) {
      if (!mounted) return;
      var message = e.toString();
      if (e is VatSummaryApiException) {
        final isEurOnly = e.statusCode == 400 &&
            e.message.toLowerCase().contains('only eur currency is supported');
        if (isEurOnly) {
          message =
              'El resumen de IVA solo esta disponible cuando todos los documentos del periodo estan en EUR.';
        } else {
          message = 'No se pudo cargar el resumen de IVA.';
        }
      } else {
        message = 'No se pudo cargar el resumen de IVA.';
      }
      setState(() => _errors[quarter] = message);
    } finally {
      if (mounted) setState(() => _loading[quarter] = false);
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      _data.clear();
      _expenseEntries.clear();
      _invoiceSummaries.clear();
      _expenseSummaries.clear();
      _errors.clear();
      _loading.clear();
    });
    _ensureLoaded(_tabs.index + 1);
  }

  Future<void> _exportVatAudit() async {
    final groupId = (widget.groupId ?? '').trim();
    if (groupId.isEmpty || _exportingVatAudit) return;

    final quarter = _tabs.index + 1;
    final range = quarterRangeDates(_year, quarter);
    final from = formatVatDate(range.$1);
    final toExclusive = DateTime(range.$2.year, range.$2.month + 1, 1);
    final to = formatVatDate(toExclusive);

    setState(() => _exportingVatAudit = true);
    try {
      final response = await _invoicesApi.exportVatAuditExcel(
        groupId: groupId,
        from: from,
        to: to,
        status: 'issued',
        currency: 'EUR',
      );
      final fileName = _fileNameFromHeaders(
        response.headers,
        fallback: 'invoice_vat_audit_${from}_$to.xlsx',
      );
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar la auditoría IVA.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingVatAudit = false);
    }
  }

  String _fileNameFromHeaders(
    Map<String, String> headers, {
    required String fallback,
  }) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final plainMatch =
          RegExp(r'filename="?([^"]+)"?', caseSensitive: false).firstMatch(raw);
      if (plainMatch != null) {
        final name = plainMatch.group(1)?.trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final selectedQuarter = _tabs.index + 1;
    final rangeLabel = quarterRangeLabel(
      context,
      year: _year,
      quarter: selectedQuarter,
    );
    final deadlineLabel = quarterDeadlineLabel(
      context,
      year: _year,
      quarter: selectedQuarter,
    );

    final tabView = TabBarView(
      controller: _tabs,
      children: List.generate(4, (index) {
        final quarter = index + 1;
        return VatQuarterSummary(
          loading: _loading[quarter] == true,
          error: _errors[quarter],
          data: _data[quarter],
          expenseEntries: _expenseEntries[quarter],
          invoiceSummary: _invoiceSummaries[quarter],
          expenseSummary: _expenseSummaries[quarter],
          onRetry: () => _loadQuarter(quarter),
        );
      }),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VatSummaryHeader(
              year: _year,
              rangeLabel: rangeLabel,
              deadlineLabel: deadlineLabel,
              exportingVatAudit: _exportingVatAudit,
              onExportVatAudit: _exportVatAudit,
              onPrevYear: () => _changeYear(-1),
              onNextYear: () => _changeYear(1),
              tabs: _tabs,
            ),
            const SizedBox(height: 8),
            Expanded(child: tabView),
          ],
        );
      },
    );
  }
}
