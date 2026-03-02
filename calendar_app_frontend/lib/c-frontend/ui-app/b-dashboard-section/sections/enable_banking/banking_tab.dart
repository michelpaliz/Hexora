import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'enable_banking_controller.dart';
import 'truelayer_controller.dart';
import 'widgets/folder_section_card.dart';

part 'banking_tab/banking_tab_sections.dart';

class BankingTab extends StatefulWidget {
  const BankingTab({super.key});

  @override
  State<BankingTab> createState() => _BankingTabState();
}

class _BankingTabState extends State<BankingTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _bankFilterController = TextEditingController();
  String _bankFilter = '';

  final Map<String, TextEditingController> _tlFromControllers = {};
  final Map<String, TextEditingController> _tlToControllers = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _countryController.dispose();
    _bankFilterController.dispose();
    for (final c in _tlFromControllers.values) {
      c.dispose();
    }
    for (final c in _tlToControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTimeRange?> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = DateTime(now.year, now.month, 1);
    final initialEnd = now;
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
  }

  bool _looksLikeCaixa(Map<String, dynamic> bank) {
    final name = (bank['name'] ?? bank['bankName'] ?? bank['aspsp_name'] ?? '')
        .toString()
        .toLowerCase();
    return name.contains('caixa');
  }

  String _bankTitle(Map<String, dynamic> bank) {
    final candidates = [
      bank['name'],
      bank['bankName'],
      bank['aspsp_name'],
      bank['displayName'],
      bank['bic'],
      bank['id'],
    ];
    final first = candidates.firstWhere(
      (v) => v != null && v.toString().trim().isNotEmpty,
      orElse: () => 'Bank',
    );
    return first.toString();
  }

  String _aspspName(Map<String, dynamic> bank) {
    final v = bank['name'] ?? bank['aspsp_name'] ?? bank['bankName'];
    return (v ?? '').toString().trim();
  }

  String _accountTitle(Map<String, dynamic> a) {
    final candidates = [
      a['name'],
      a['iban'],
      a['accountName'],
      a['id'],
    ];
    final first = candidates.firstWhere(
      (v) => v != null && v.toString().trim().isNotEmpty,
      orElse: () => 'Account',
    );
    return first.toString();
  }

  String _fmtYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime? _tryParseYmd(String s) {
    final v = s.trim();
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }

  TextEditingController _ensureDateController(
    Map<String, TextEditingController> map,
    String key, {
    required String initialText,
  }) {
    final existing = map[key];
    if (existing != null) return existing;
    final c = TextEditingController(text: initialText);
    map[key] = c;
    return c;
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL from backend')));
      return;
    }
    final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open bank URL')),
      );
    }
  }

  void _clearBankFilter() {
    _bankFilterController.clear();
    setState(() => _bankFilter = '');
  }

  void _setBankFilter(String value) {
    setState(() => _bankFilter = value);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.watch<EnableBankingController>();
    final tl = context.watch<TrueLayerController>();
    final cs = Theme.of(context).colorScheme;

    if (_countryController.text != c.country) {
      _countryController.value = _countryController.value.copyWith(
        text: c.country,
        selection: TextSelection.collapsed(offset: c.country.length),
      );
    }

    return _buildBankingBody(context: context, c: c, tl: tl, cs: cs);
  }
}
