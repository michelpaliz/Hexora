import 'package:flutter/material.dart';
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
  int _year = DateTime.now().year;
  final Map<int, Map<String, dynamic>> _data = {};
  final Map<int, String?> _errors = {};
  final Map<int, bool> _loading = {};

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

  Future<void> _loadQuarter(int quarter) async {
    setState(() {
      _loading[quarter] = true;
      _errors[quarter] = null;
    });
    final range = quarterRangeDates(_year, quarter);
    final from = formatVatDate(range.$1);
    final to = formatVatDate(range.$2);
    try {
      final data = await widget.api.getSummary(
        groupId: widget.groupId,
        from: from,
        to: to,
        currency: 'EUR',
      );
      if (!mounted) return;
      setState(() => _data[quarter] = data);
    } catch (e) {
      if (!mounted) return;
      var message = e.toString();
      if (e is VatSummaryApiException) {
        final isEurOnly = e.statusCode == 400 &&
            e.message.toLowerCase().contains('only eur currency is supported');
        if (isEurOnly) {
          message =
              'IVA summary is only available when all documents in this period are in EUR.';
        } else {
          message = e.message;
        }
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
      _errors.clear();
      _loading.clear();
    });
    _ensureLoaded(_tabs.index + 1);
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
