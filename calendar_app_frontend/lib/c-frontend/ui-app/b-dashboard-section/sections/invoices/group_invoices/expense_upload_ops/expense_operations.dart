import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/form_helpers.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mixin for expense management operations
mixin ExpenseOperationsMixin<T extends StatefulWidget> on State<T> {
  ExpensesApi get expensesApi;
  List<Map<String, String>> get recentUploads;
  Map<String, String>? get selectedRecentExpense;
  set selectedRecentExpense(Map<String, String>? value);
  bool get loadingPreview;
  set loadingPreview(bool value);
  String? get previewError;
  set previewError(String? value);

  String resolveGroupId();

  /// Load recent expense uploads
  Future<void> loadRecentUploads() async {
    try {
      final groupId = resolveGroupId();
      if (groupId.isEmpty) {
        return;
      }
      final items = await expensesApi.listAll(groupId: groupId);
      if (!mounted) return;
      Map<String, String>? matchedSelection;
      setState(() {
        recentUploads
          ..clear()
          ..addAll(items.map(mapExpenseToRecent));
        final selectedId = selectedRecentExpense?['id'];
        if (selectedId != null && selectedId.isNotEmpty) {
          matchedSelection = recentUploads.firstWhere(
            (item) => item['id'] == selectedId,
            orElse: () => const <String, String>{},
          );
          if (matchedSelection!.isEmpty) {
            selectedRecentExpense = null;
          } else {
            selectedRecentExpense = matchedSelection;
          }
        }
      });
      if (matchedSelection != null && matchedSelection!.isNotEmpty) {
        loadExpensePreview(matchedSelection!);
        loadExpenseDetails(matchedSelection!);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load expenses: $e');
      }
    }
  }

  /// Map expense API response to recent upload format
  Map<String, String> mapExpenseToRecent(Map<String, dynamic> item) {
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

    String providerName() {
      final provider = item['provider'];
      if (provider is Map) {
        final name = provider['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) return name;
      }
      final direct = item['providerName'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
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

    String fileUrl() {
      final candidates = [
        item['fileUrl'],
        item['fileURL'],
        item['url'],
        item['file'],
        item['filePath'],
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final v = c.toString().trim();
        if (v.startsWith('http://') || v.startsWith('https://')) {
          return v;
        }
      }
      return '';
    }

    final advancePayment = item['advancePayment'] is Map
        ? Map<String, dynamic>.from(item['advancePayment'] as Map)
        : const <String, dynamic>{};
    final finalSettlement = item['finalSettlement'] is Map
        ? Map<String, dynamic>.from(item['finalSettlement'] as Map)
        : const <String, dynamic>{};
    final rawLines = item['lines'] is List
        ? item['lines']
        : item['items'] is List
            ? item['items']
            : null;
    final mappedLines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false)
        : null;
    final useSummaryTotals = ExpenseFormHelpers.shouldUseSummaryTotals(
      expense: item,
      storedTotal: ExpenseFormHelpers.parseNum(item['total'])?.toDouble(),
      storedTax: ExpenseFormHelpers.parseNum(
        item['taxTotal'] ?? item['vatTotal'] ?? item['tax'],
      )?.toDouble(),
      lines: mappedLines,
    );

    return {
      'id': expenseId(),
      'vendor': pick(['vendorName', 'vendor']),
      'subtotal': pick(['subtotal']),
      'total': pick(['total']),
      'date': pick(['issueDate', 'date']),
      'file': pick(['fileName', 'file']),
      'mimeType': pick(['mimeType']),
      'providerId': providerId(),
      'fileUrl': fileUrl(),
      'providerName': providerName(),
      'invoice': pick(['invoiceNumber']),
      'currency': pick(['currency']),
      'tax': pick(['taxTotal', 'vatTotal', 'tax']),
      'due': pick(['dueDate']),
      'status': pick(['status']),
      'discountAmount': pick(['discountAmount', 'discount_amount']),
      'discountPercent': pick(['discountPercent', 'discount_percent']),
      'taxSource': pick(['taxSource', 'totalsSource']),
      'expenseType': pick(['expenseType']),
      'advancePercent': (advancePayment['percent'] ?? '').toString(),
      'advanceProjectBaseAmount':
          (advancePayment['projectBaseAmount'] ?? '').toString(),
      'advanceTaxRate': (advancePayment['taxRate'] ?? '').toString(),
      'finalAdvanceExpenseId':
          (finalSettlement['advanceExpenseId'] ?? '').toString(),
      'finalAdvanceInvoiceNumber':
          (finalSettlement['advanceInvoiceNumber'] ?? '').toString(),
      'settlementDeductedBase':
          (finalSettlement['deductedBase'] ?? '').toString(),
      'settlementDeductedTax':
          (finalSettlement['deductedTax'] ?? '').toString(),
      'settlementDeductedTotal':
          (finalSettlement['deductedTotal'] ?? '').toString(),
      'settlementGrossBase':
          (finalSettlement['grossBase'] ?? '').toString(),
      'settlementGrossTax':
          (finalSettlement['grossTax'] ?? '').toString(),
      'settlementGrossTotal':
          (finalSettlement['grossTotal'] ?? '').toString(),
      'settlementRemainingBase':
          (finalSettlement['remainingBase'] ?? '').toString(),
      'settlementRemainingTax':
          (finalSettlement['remainingTax'] ?? '').toString(),
      'settlementRemainingTotal':
          (finalSettlement['remainingTotal'] ?? '').toString(),
      'useSummaryTotals': useSummaryTotals ? 'true' : 'false',
    };
  }

  /// Apply expense file data to recent upload entry
  void applyExpenseFileToRecent(
    String id, {
    String? url,
    String? mimeType,
    String? fileName,
  }) {
    final idx = recentUploads.indexWhere((item) => item['id'] == id);
    if (idx == -1) return;
    final updated = Map<String, String>.from(recentUploads[idx]);
    if (url != null) updated['fileUrl'] = url;
    if (mimeType != null) updated['mimeType'] = mimeType;
    if (fileName != null && fileName.trim().isNotEmpty) {
      updated['file'] = fileName.trim();
    }
    recentUploads[idx] = updated;
    if (selectedRecentExpense?['id'] == id) {
      selectedRecentExpense = updated;
    }
  }

  /// Apply expense details to recent upload entry
  void applyExpenseDetailsToRecent(
    String id, {
    int? linesCount,
    String? linesSummary,
    String? linesSubtotal,
    String? linesTotal,
    String? expenseType,
    String? advancePercent,
    String? advanceProjectBaseAmount,
    String? advanceTaxRate,
    String? finalAdvanceExpenseId,
    String? finalAdvanceInvoiceNumber,
    String? settlementDeductedBase,
    String? settlementDeductedTax,
    String? settlementDeductedTotal,
    String? settlementGrossBase,
    String? settlementGrossTax,
    String? settlementGrossTotal,
    String? settlementRemainingBase,
    String? settlementRemainingTax,
    String? settlementRemainingTotal,
    String? discountAmount,
    String? discountPercent,
    String? useSummaryTotals,
    String? subtotal,
    String? taxSource,
  }) {
    final idx = recentUploads.indexWhere((item) => item['id'] == id);
    if (idx == -1) return;
    final updated = Map<String, String>.from(recentUploads[idx]);
    if (linesCount != null) updated['linesCount'] = linesCount.toString();
    if (linesSummary != null) updated['linesSummary'] = linesSummary;
    if (linesSubtotal != null) updated['linesSubtotal'] = linesSubtotal;
    if (linesTotal != null) updated['linesTotal'] = linesTotal;
    if (expenseType != null) updated['expenseType'] = expenseType;
    if (advancePercent != null) updated['advancePercent'] = advancePercent;
    if (advanceProjectBaseAmount != null) {
      updated['advanceProjectBaseAmount'] = advanceProjectBaseAmount;
    }
    if (advanceTaxRate != null) updated['advanceTaxRate'] = advanceTaxRate;
    if (finalAdvanceExpenseId != null) {
      updated['finalAdvanceExpenseId'] = finalAdvanceExpenseId;
    }
    if (finalAdvanceInvoiceNumber != null) {
      updated['finalAdvanceInvoiceNumber'] = finalAdvanceInvoiceNumber;
    }
    if (settlementDeductedBase != null) {
      updated['settlementDeductedBase'] = settlementDeductedBase;
    }
    if (settlementDeductedTax != null) {
      updated['settlementDeductedTax'] = settlementDeductedTax;
    }
    if (settlementDeductedTotal != null) {
      updated['settlementDeductedTotal'] = settlementDeductedTotal;
    }
    if (settlementGrossBase != null) {
      updated['settlementGrossBase'] = settlementGrossBase;
    }
    if (settlementGrossTax != null) {
      updated['settlementGrossTax'] = settlementGrossTax;
    }
    if (settlementGrossTotal != null) {
      updated['settlementGrossTotal'] = settlementGrossTotal;
    }
    if (settlementRemainingBase != null) {
      updated['settlementRemainingBase'] = settlementRemainingBase;
    }
    if (settlementRemainingTax != null) {
      updated['settlementRemainingTax'] = settlementRemainingTax;
    }
    if (settlementRemainingTotal != null) {
      updated['settlementRemainingTotal'] = settlementRemainingTotal;
    }
    if (discountAmount != null) updated['discountAmount'] = discountAmount;
    if (discountPercent != null) updated['discountPercent'] = discountPercent;
    if (useSummaryTotals != null) {
      updated['useSummaryTotals'] = useSummaryTotals;
    }
    if (subtotal != null) updated['subtotal'] = subtotal;
    if (taxSource != null) updated['taxSource'] = taxSource;
    recentUploads[idx] = updated;
    if (selectedRecentExpense?['id'] == id) {
      selectedRecentExpense = updated;
    }
  }

  /// Load expense file preview
  Future<void> loadExpensePreview(Map<String, String> item) async {
    final id = (item['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    setState(() {
      loadingPreview = true;
      previewError = null;
    });
    try {
      final result = await expensesApi.fetchExpenseFile(id);
      if (!mounted) return;
      final url = (result['url'] ?? '').toString().trim();
      final mimeType = (result['mimeType'] ?? '').toString().trim();
      final fileName = (result['fileName'] ?? '').toString().trim();
      setState(() {
        applyExpenseFileToRecent(
          id,
          url: url,
          mimeType: mimeType,
          fileName: fileName,
        );
        loadingPreview = false;
      });
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      setState(() {
        applyExpenseFileToRecent(id, url: '', mimeType: '', fileName: '');
        loadingPreview = false;
        previewError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingPreview = false;
        previewError = e.toString();
      });
    }
  }

  /// Load expense details including lines
  Future<void> loadExpenseDetails(Map<String, String> item) async {
    final id = (item['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    try {
      final result = await expensesApi.fetchExpense(id);
      if (!mounted) return;
      final lines = result['lines'];
      int? linesCount;
      String? linesSummary;
      String? linesSubtotal;
      String? linesTotal;
      final storedTotal = ExpenseFormHelpers.parseNum(result['total']);
      final storedTax = ExpenseFormHelpers.parseNum(
        result['taxTotal'] ?? result['vatTotal'] ?? result['tax'],
      );
      final mappedLines = lines is List
          ? lines
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      final useSummaryTotals = ExpenseFormHelpers.shouldUseSummaryTotals(
        expense: result,
        storedTotal: storedTotal?.toDouble(),
        storedTax: storedTax?.toDouble(),
        lines: mappedLines,
      );
      if (lines is List) {
        final summary = ExpenseFormHelpers.summarizeLines(lines);
        linesCount = summary['count'] as int?;
        linesSummary = (summary['summary'] ?? '').toString();
        final subtotal = summary['subtotal'] as double?;
        final lineTotal = summary['total'] as double?;
        if (useSummaryTotals) {
          final storedBase = (storedTotal != null)
              ? (storedTotal - (storedTax ?? 0))
                  .clamp(0, double.infinity)
                  .toDouble()
              : null;
          if (storedBase != null) {
            linesSubtotal = storedBase.toStringAsFixed(2);
          }
          if (storedTotal != null) {
            linesTotal = storedTotal.toStringAsFixed(2);
          }
        } else if (subtotal != null) {
          linesSubtotal = subtotal.toStringAsFixed(2);
        }
        if (!useSummaryTotals && lineTotal != null) {
          linesTotal = lineTotal.toStringAsFixed(2);
        }
      }
      final advancePayment = result['advancePayment'] is Map
          ? Map<String, dynamic>.from(result['advancePayment'] as Map)
          : const <String, dynamic>{};
      final finalSettlement = result['finalSettlement'] is Map
          ? Map<String, dynamic>.from(result['finalSettlement'] as Map)
          : const <String, dynamic>{};
      setState(() {
        applyExpenseDetailsToRecent(
          id,
          linesCount: linesCount,
          linesSummary: linesSummary,
          linesSubtotal: linesSubtotal,
          linesTotal: linesTotal,
          subtotal: (result['subtotal'] ?? '').toString(),
          taxSource: (result['taxSource'] ?? result['totalsSource'] ?? '')
              .toString(),
          expenseType: (result['expenseType'] ?? '').toString(),
          advancePercent: (advancePayment['percent'] ?? '').toString(),
          advanceProjectBaseAmount:
              (advancePayment['projectBaseAmount'] ?? '').toString(),
          advanceTaxRate: (advancePayment['taxRate'] ?? '').toString(),
          finalAdvanceExpenseId:
              (finalSettlement['advanceExpenseId'] ?? '').toString(),
          finalAdvanceInvoiceNumber:
              (finalSettlement['advanceInvoiceNumber'] ?? '').toString(),
          settlementDeductedBase:
              (finalSettlement['deductedBase'] ?? '').toString(),
          settlementDeductedTax:
              (finalSettlement['deductedTax'] ?? '').toString(),
          settlementDeductedTotal:
              (finalSettlement['deductedTotal'] ?? '').toString(),
          settlementGrossBase:
              (finalSettlement['grossBase'] ?? '').toString(),
          settlementGrossTax:
              (finalSettlement['grossTax'] ?? '').toString(),
          settlementGrossTotal:
              (finalSettlement['grossTotal'] ?? '').toString(),
          settlementRemainingBase:
              (finalSettlement['remainingBase'] ?? '').toString(),
          settlementRemainingTax:
              (finalSettlement['remainingTax'] ?? '').toString(),
          settlementRemainingTotal:
              (finalSettlement['remainingTotal'] ?? '').toString(),
          discountAmount:
              (result['discountAmount'] ?? result['discount_amount'] ?? '')
                  .toString(),
          discountPercent:
              (result['discountPercent'] ?? result['discount_percent'] ?? '')
                  .toString(),
          useSummaryTotals: useSummaryTotals ? 'true' : 'false',
        );
      });
    } catch (_) {
      // Ignore detail fetch errors; preview/list still render.
    }
  }

  /// Select a recent expense and load its preview
  void selectRecentExpense(Map<String, String> item) {
    setState(() {
      selectedRecentExpense = item;
      previewError = null;
    });
    loadExpensePreview(item);
    loadExpenseDetails(item);
  }

  /// Preview expense from providers tab
  Future<void> previewExpenseFromProviders(Map<String, String> item) async {
    final l = AppLocalizations.of(context)!;
    final id = (item['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    setState(() {
      loadingPreview = true;
      previewError = null;
    });
    try {
      var fileUrl = (item['fileUrl'] ?? '').toString().trim();
      var mimeType = (item['mimeType'] ?? '').toString().trim();
      var fileName = (item['file'] ?? '').toString().trim();
      if (fileUrl.isEmpty) {
        final result = await expensesApi.fetchExpenseFile(id);
        if (!mounted) return;
        fileUrl = (result['url'] ?? '').toString().trim();
        mimeType = (result['mimeType'] ?? '').toString().trim();
        fileName = (result['fileName'] ?? '').toString().trim();
        setState(() {
          applyExpenseFileToRecent(
            id,
            url: fileUrl,
            mimeType: mimeType,
            fileName: fileName,
          );
        });
      }
      if (!mounted) return;
      setState(() => loadingPreview = false);
      if (fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.preview} unavailable')),
        );
        return;
      }
      final url = Uri.tryParse(fileUrl);
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.preview} unavailable')),
        );
        return;
      }
      await launchUrl(url);
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      setState(() {
        loadingPreview = false;
        previewError = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingPreview = false;
        previewError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.preview} unavailable')),
      );
    }
  }

  /// Delete a recent expense
  Future<void> deleteRecentExpense(String id) async {
    try {
      await expensesApi.deleteExpense(id);
      if (!mounted) return;
      setState(() {
        recentUploads.removeWhere((item) => item['id'] == id);
        if ((selectedRecentExpense?['id'] ?? '').trim() == id.trim()) {
          selectedRecentExpense =
              recentUploads.isEmpty ? null : recentUploads.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete expense.'),
        ),
      );
    }
  }
}

