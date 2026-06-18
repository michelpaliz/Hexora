import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/working_time_excel_import.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:provider/provider.dart';

class TelegramWorkerHoursImportView extends StatefulWidget {
  const TelegramWorkerHoursImportView({super.key, required this.group});

  final Group group;

  @override
  State<TelegramWorkerHoursImportView> createState() =>
      _TelegramWorkerHoursImportViewState();
}

class _TelegramWorkerHoursImportViewState
    extends State<TelegramWorkerHoursImportView> {
  final _accountController = TextEditingController();
  final _chatController = TextEditingController();
  final _topicController = TextEditingController();
  final _topicNameController =
      TextEditingController(text: 'Horas_Trabajadores');
  final _monthController = TextEditingController(text: _currentMonth());
  final _limitController = TextEditingController(text: '200');
  final _pageScrollController = ScrollController();
  final _tableScrollController = ScrollController();

  String? _dateFrom;
  String? _dateTo;
  Map<String, dynamic>? _previewFilters;
  Set<String>? _collapsedGroupsNullable;
  Set<String> get _collapsedGroups => _collapsedGroupsNullable ??= <String>{};

  bool _loading = false;
  bool _loadingSource = false;
  bool _confirming = false;
  bool _skipExistingEntries = false;
  bool _importSettingsExpanded = true;
  String? _error;
  String? _telegramDefaultsMessage;
  List<Map<String, dynamic>> _candidates = const <Map<String, dynamic>>[];
  int? _selectedCandidateIndex;
  Map<String, dynamic>? _preview;
  List<Worker> _workers = const <Worker>[];
  List<_TelegramImportRow> _rows = const <_TelegramImportRow>[];
  List<_TelegramIgnoredRow> _ignoredRows = const <_TelegramIgnoredRow>[];
  List<String> _warnings = const <String>[];
  WorkingTimeExcelImportConfirmResult? _lastConfirmResult;

  static String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtShortDate(String isoDate, bool isEs) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final day = parts[2].startsWith('0') ? parts[2].substring(1) : parts[2];
    const esM = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    const enM = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = int.tryParse(parts[1]) ?? 1;
    return '$day ${(isEs ? esM : enM)[m]}';
  }

  bool _isQuickFilterActive(String type) {
    final now = DateTime.now();
    if (type == 'today') {
      final today = _fmtDate(now);
      return _dateFrom == today && _dateTo == today;
    }
    if (type == 'yesterday') {
      final yesterday = _fmtDate(now.subtract(const Duration(days: 1)));
      return _dateFrom == yesterday && _dateTo == yesterday;
    }
    if (type == 'week') {
      final weekStart = _fmtDate(now.subtract(Duration(days: now.weekday - 1)));
      return _dateFrom == weekStart && _dateTo == _fmtDate(now);
    }
    if (type == 'month') return _dateFrom == null && _dateTo == null;
    return false;
  }

  void _applyQuickFilter(String type) {
    final now = DateTime.now();
    String? from, to;
    if (type == 'today') {
      from = _fmtDate(now);
      to = _fmtDate(now);
    } else if (type == 'yesterday') {
      final y = now.subtract(const Duration(days: 1));
      from = _fmtDate(y);
      to = _fmtDate(y);
    } else if (type == 'week') {
      from = _fmtDate(now.subtract(Duration(days: now.weekday - 1)));
      to = _fmtDate(now);
    }
    setState(() {
      _dateFrom = from;
      _dateTo = to;
    });
  }

  String? _filterSummaryLabel(bool isEs) {
    if (_dateFrom == null && _dateTo == null) return null;
    String fmtLabel(String? d) {
      if (d == null) return '';
      final parts = d.split('-');
      if (parts.length != 3) return d;
      final month = int.tryParse(parts[1]) ?? 1;
      const esMonths = [
        '',
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic'
      ];
      const enMonths = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final monthName = (isEs ? esMonths : enMonths)[month];
      return '${parts[2]} $monthName ${parts[0]}';
    }

    if (_dateFrom == _dateTo && _dateFrom != null) {
      return isEs
          ? 'Filtrando: ${fmtLabel(_dateFrom)}'
          : 'Filtering: ${fmtLabel(_dateFrom)}';
    }
    return isEs
        ? 'Filtrando: ${fmtLabel(_dateFrom)} – ${fmtLabel(_dateTo)}'
        : 'Filtering: ${fmtLabel(_dateFrom)} – ${fmtLabel(_dateTo)}';
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = (() {
      final s = isFrom ? _dateFrom : _dateTo;
      if (s == null) return DateTime.now();
      return DateTime.tryParse(s) ?? DateTime.now();
    })();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    final formatted = _fmtDate(picked);
    setState(() {
      if (isFrom) {
        _dateFrom = formatted;
        _dateTo ??= formatted;
      } else {
        _dateTo = formatted;
        _dateFrom ??= formatted;
      }
    });
  }

  bool get _hasBlockingRows =>
      _rows.any((row) => row.include && row.needsReview && !row.confirmed);

  bool get _canConfirm =>
      _rows.any((row) => row.include) &&
      !_hasBlockingRows &&
      !_loading &&
      !_confirming;

  int get _approvableReviewRowsCount => _rows
      .where((row) =>
          row.include && !row.invalid && row.needsReview && !row.confirmed)
      .length;

  void _approveAllReviewRows() {
    final count = _approvableReviewRowsCount;
    if (count == 0) return;
    setState(() {
      for (final row in _rows) {
        if (row.include && !row.invalid && row.needsReview) {
          row.confirmed = true;
        }
      }
    });
    final isEs = _isSpanish(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEs
              ? '$count fila${count == 1 ? '' : 's'} aprobada${count == 1 ? '' : 's'}.'
              : '$count row${count == 1 ? '' : 's'} approved.',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTelegramSource();
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _chatController.dispose();
    _topicController.dispose();
    _topicNameController.dispose();
    _monthController.dispose();
    _limitController.dispose();
    _pageScrollController.dispose();
    _tableScrollController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  Future<String> _token() => context.read<UserDomain>().getAuthToken();

  void _applyTelegramSource(Map<String, dynamic> source) {
    _accountController.text = (source['accountId'] ?? '').toString();
    _chatController.text = (source['chatId'] ?? '').toString();
    _topicController.text = (source['forumTopicId'] ?? '').toString();
    final topicName = (source['topicName'] ?? '').toString().trim();
    if (topicName.isNotEmpty) _topicNameController.text = topicName;
  }

  Future<void> _loadTelegramSource({bool force = false}) async {
    if (_loadingSource) return;
    final isAlreadyFilled = _accountController.text.trim().isNotEmpty &&
        _chatController.text.trim().isNotEmpty &&
        _topicController.text.trim().isNotEmpty;
    if (isAlreadyFilled && !force) return;

    setState(() {
      _loadingSource = true;
      _telegramDefaultsMessage = _isSpanish(context)
          ? 'Buscando tema Horas_Trabajadores...'
          : 'Searching for Horas_Trabajadores...';
    });

    try {
      final repo = context.read<ITimeTrackingRepository>();
      final token = await _token();
      final payload = await repo.getTelegramImportSource(
        widget.group.id,
        token,
        topicName: 'Horas_Trabajadores',
      );
      final source = payload['source'] is Map
          ? Map<String, dynamic>.from(payload['source'] as Map)
          : null;
      final candidates = payload['candidates'] is List
          ? (payload['candidates'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        _selectedCandidateIndex = null;
        if (payload['ok'] == true && source != null) {
          _applyTelegramSource(source);
          _telegramDefaultsMessage = _isSpanish(context)
              ? 'Tema encontrado: ${source['chatTitle'] ?? ''} / ${source['topicName'] ?? 'Horas_Trabajadores'}'
              : 'Topic found: ${source['chatTitle'] ?? ''} / ${source['topicName'] ?? 'Horas_Trabajadores'}';
        } else {
          _telegramDefaultsMessage = _isSpanish(context)
              ? 'No se pudo encontrar automáticamente el tema Horas_Trabajadores.'
              : 'Could not automatically find Horas_Trabajadores.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _telegramDefaultsMessage = _isSpanish(context)
            ? 'No se pudo encontrar automáticamente el tema Horas_Trabajadores.'
            : 'Could not automatically find Horas_Trabajadores.';
      });
    } finally {
      if (mounted) setState(() => _loadingSource = false);
    }
  }

  Future<void> _loadWorkers(ITimeTrackingRepository repo, String token) async {
    _workers = await repo.getWorkers(widget.group.id, token);
  }

  Future<void> _previewTelegram() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ITimeTrackingRepository>();
      final token = await _token();
      await _loadWorkers(repo, token);
      final body = <String, dynamic>{
        'accountId': _accountController.text.trim(),
        'chatId': _chatController.text.trim(),
        'forumTopicId': _topicController.text.trim(),
        'topicName': _topicNameController.text.trim().isEmpty
            ? 'Horas_Trabajadores'
            : _topicNameController.text.trim(),
        'month': _monthController.text.trim(),
        if (_dateFrom != null) 'dateFrom': _dateFrom!,
        if (_dateTo != null) 'dateTo': _dateTo!,
        'limit': int.tryParse(_limitController.text.trim()) ?? 200,
      }..removeWhere((_, value) => value is String && value.isEmpty);
      final preview = await repo.previewTelegramImport(
        widget.group.id,
        token,
        body: body,
      );
      final rawEntries = preview['entries'];
      final rows = rawEntries is List
          ? rawEntries
              .whereType<Map>()
              .map((entry) => _TelegramImportRow.fromJson(
                    Map<String, dynamic>.from(entry),
                    workers: _workers,
                  ))
              .toList(growable: false)
          : const <_TelegramImportRow>[];
      final rawIgnoredRows = preview['ignoredRows'];
      final ignored = rawIgnoredRows is List
          ? rawIgnoredRows
              .map(_TelegramIgnoredRow.fromValue)
              .toList(growable: false)
          : const <_TelegramIgnoredRow>[];
      final warnings = _stringList(preview['warnings']);
      final filtersRaw = preview['filters'];
      final previewFilters =
          filtersRaw is Map ? Map<String, dynamic>.from(filtersRaw) : null;
      if (!mounted) return;
      setState(() {
        for (final row in _rows) {
          row.dispose();
        }
        _preview = preview;
        _rows = rows;
        _ignoredRows = ignored;
        _warnings = warnings;
        _previewFilters = previewFilters;
        _collapsedGroups.clear();
        _importSettingsExpanded = false;
        _lastConfirmResult = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_hasBlockingRows) {
      final isEs = _isSpanish(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEs
              ? 'Confirma las filas con avisos antes de importar.'
              : 'Confirm rows with warnings before importing.'),
        ),
      );
      return;
    }
    final entries = _rows
        .where((row) => row.include)
        .map((row) => row.toConfirmJson())
        .where((row) => (row['workerId'] ?? '').toString().trim().isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) return;
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      final repo = context.read<ITimeTrackingRepository>();
      final token = await _token();
      final result = await repo.confirmJsonImport(
        widget.group.id,
        token,
        month: _monthController.text.trim(),
        duplicateStrategy:
            _skipExistingEntries ? 'skip_existing' : 'fail_on_existing',
        entries: entries,
      );
      if (!mounted) return;
      setState(() {
        _lastConfirmResult = result;
        _confirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish(context)
                ? 'Importadas: ${result.importedCount} · Omitidas: ${result.skippedCount}'
                : 'Imported: ${result.importedCount} · Skipped: ${result.skippedCount}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _confirming = false;
      });
    }
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isEs = _isSpanish(context);
    final topicMatched = (_preview?['topic'] is Map)
        ? ((_preview!['topic'] as Map)['matched'] != false)
        : true;
    final reviewRequiredCount = _rows.where((row) => row.needsReview).length;
    final invalidRowCount = _rows.where((row) => row.invalid).length;
    final sourceReady = _accountController.text.trim().isNotEmpty &&
        _chatController.text.trim().isNotEmpty &&
        _topicController.text.trim().isNotEmpty;

    return ListView(
      controller: _pageScrollController,
      primary: false,
      padding: const EdgeInsets.all(14),
      children: [
        _importSetupPanel(
          context,
          sourceReady: sourceReady,
          isEs: isEs,
        ),
        if (_candidates.length > 1) ...[
          const SizedBox(height: 10),
          _candidatePicker(context),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          _errorBox(context, _error!),
        ],
        const SizedBox(height: 16),
        if (!topicMatched)
          _warningBox(
            context,
            isEs
                ? 'El tema seleccionado no parece ser Horas_Trabajadores.'
                : 'The selected topic does not look like Horas_Trabajadores.',
          ),
        if (_warnings.isNotEmpty) _warningBox(context, _warnings.join('\n')),
        if (_rows.isEmpty &&
            _preview != null &&
            (_dateFrom != null || _dateTo != null)) ...[
          const SizedBox(height: 12),
          _limitHintBox(context),
        ],
        if (_rows.isNotEmpty)
          _reviewTable(
            context,
            totalRows: _rows.length,
            reviewRequiredCount: reviewRequiredCount,
            invalidRowCount: invalidRowCount,
          ),
        if (_ignoredRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ignoredRowsButton(context),
        ],
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          _confirmOptionsBar(context),
        ],
        if ((_lastConfirmResult?.skippedCount ?? 0) > 0) ...[
          const SizedBox(height: 12),
          _skippedEntriesDetails(context, _lastConfirmResult!),
        ],
      ],
    );
  }

  Widget _importSetupPanel(
    BuildContext context, {
    required bool sourceReady,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
              () => _importSettingsExpanded = !_importSettingsExpanded,
            ),
            child: _heroHeader(context, sourceReady: sourceReady),
          ),
          // Source credentials — collapsible
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: _sourceCard(
                context,
                sourceReady: sourceReady,
                isEs: isEs,
              ),
            ),
            crossFadeState: _importSettingsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
          ),
          // Date controls — always visible
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: _importControls(context),
          ),
        ],
      ),
    );
  }

  Widget _heroHeader(BuildContext context, {required bool sourceReady}) {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final collapsed = !_importSettingsExpanded;
        return Container(
          padding: collapsed
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1D9BF0).withValues(alpha: 0.24),
                const Color(0xFF35D0BA).withValues(alpha: 0.10),
                cs.surfaceContainerHighest.withValues(alpha: 0.36),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Flex(
            direction: isCompact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: collapsed ? 42 : 58,
                height: collapsed ? 42 : 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9BF0),
                  borderRadius: BorderRadius.circular(collapsed ? 15 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D9BF0).withValues(alpha: 0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(Icons.telegram,
                    color: Colors.white, size: collapsed ? 23 : 30),
              ),
              SizedBox(
                  width: isCompact ? 0 : 16,
                  height: isCompact && !collapsed ? 14 : 0),
              Expanded(
                flex: isCompact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEs
                          ? 'Importar horas desde Telegram'
                          : 'Import hours from Telegram',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ) ??
                          t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(height: 6),
                      Text(
                        isEs
                            ? 'Previsualiza el tema Horas_Trabajadores, corrige coincidencias y registra solo las filas aprobadas.'
                            : 'Preview Horas_Trabajadores, fix matches, and import only approved rows.',
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 0 : 14, height: isCompact ? 14 : 0),
              _statusBadge(
                context,
                sourceReady
                    ? (isEs ? 'Fuente lista' : 'Source ready')
                    : (isEs ? 'Buscando fuente' : 'Finding source'),
                sourceReady ? Icons.check_circle_rounded : Icons.manage_search,
                sourceReady ? Colors.green : const Color(0xFF1D9BF0),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: collapsed
                    ? (isEs ? 'Expandir configuración' : 'Expand settings')
                    : (isEs ? 'Contraer configuración' : 'Collapse settings'),
                child: Icon(
                  collapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sourceCard(
    BuildContext context, {
    required bool sourceReady,
    required bool isEs,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.forum_rounded, color: cs.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceReady
                          ? (isEs ? 'Tema encontrado' : 'Topic found')
                          : (isEs ? 'Buscando tema' : 'Finding topic'),
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _telegramDefaultsMessage ??
                          (isEs
                              ? 'Empresa Michel S.L / Horas_Trabajadores'
                              : 'Empresa Michel S.L / Horas_Trabajadores'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: isEs ? 'Autocompletar' : 'Autofill',
                child: IconButton(
                  onPressed: _loadingSource
                      ? null
                      : () => _loadTelegramSource(force: true),
                  icon: _loadingSource
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primary.withValues(alpha: 0.10),
                    foregroundColor: cs.primary,
                    minimumSize: const Size(36, 36),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sourceMetaChip(context, 'account', _accountController.text),
              _sourceMetaChip(context, 'chat', _chatController.text),
              _sourceMetaChip(context, 'topic', _topicController.text),
              _sourceMetaChip(context, 'name', _topicNameController.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sourceMetaChip(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final display = value.trim().isEmpty ? '-' : value.trim();
    return Tooltip(
      message: '$label: $display',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _importControls(BuildContext context) {
    final isEs = _isSpanish(context);
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final filterLabel = _filterSummaryLabel(isEs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Quick filters
            _quickFilterChip(context, isEs ? 'Hoy' : 'Today', 'today',
                _isQuickFilterActive('today')),
            _quickFilterChip(context, isEs ? 'Ayer' : 'Yesterday', 'yesterday',
                _isQuickFilterActive('yesterday')),
            _quickFilterChip(context, isEs ? 'Esta semana' : 'This week',
                'week', _isQuickFilterActive('week')),
            _quickFilterChip(context, isEs ? 'Todo el mes' : 'Full month',
                'month', _isQuickFilterActive('month')),
            // Divider
            Container(
              height: 22,
              width: 1,
              color: cs.outlineVariant.withValues(alpha: 0.55),
            ),
            // Month field
            _compactField(_monthController, isEs ? 'Mes' : 'Month', width: 108),
            // Date pickers
            _datePickerButton(context, isFrom: true, isEs: isEs),
            _datePickerButton(context, isFrom: false, isEs: isEs),
            // Limit
            _compactField(_limitController, 'Limit', width: 72),
            // Generate
            FilledButton.icon(
              onPressed: _loading ? null : _previewTelegram,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.travel_explore_rounded, size: 17),
              label: Text(isEs ? 'Generar' : 'Generate'),
            ),
          ],
        ),
        if (filterLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_outlined, size: 13, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                filterLabel,
                style: t.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: () => setState(() {
                  _dateFrom = null;
                  _dateTo = null;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Icon(Icons.close_rounded,
                    size: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _quickFilterChip(
    BuildContext context,
    String label,
    String type,
    bool active,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return GestureDetector(
      onTap: () => _applyQuickFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? cs.primary.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          label,
          style: t.bodySmall.copyWith(
            color: active ? cs.primary : cs.onSurface,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _datePickerButton(
    BuildContext context, {
    required bool isFrom,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final value = isFrom ? _dateFrom : _dateTo;
    final label = isFrom ? (isEs ? 'Desde' : 'From') : (isEs ? 'Hasta' : 'To');
    final hasValue = value != null;
    return GestureDetector(
      onTap: () => _pickDate(isFrom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? cs.primary.withValues(alpha: 0.10)
              : cs.surfaceContainerHighest.withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasValue ? Icons.event_rounded : Icons.calendar_month_outlined,
              size: 15,
              color: hasValue ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              hasValue ? _fmtShortDate(value, isEs) : label,
              style: t.bodySmall.copyWith(
                color: hasValue ? cs.primary : cs.onSurfaceVariant,
                fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() {
                  if (isFrom) {
                    _dateFrom = null;
                  } else {
                    _dateTo = null;
                  }
                }),
                child: Icon(Icons.close_rounded,
                    size: 13, color: cs.primary.withValues(alpha: 0.70)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _limitHintBox(BuildContext context) {
    final isEs = _isSpanish(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF64B5F6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF64B5F6), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEs
                  ? 'Prueba aumentando el límite si buscas mensajes antiguos.'
                  : 'Try increasing the limit if you are looking for older messages.',
              style: TextStyle(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidatePicker(BuildContext context) {
    final isEs = _isSpanish(context);
    return SizedBox(
      width: 460,
      child: DropdownButtonFormField<int>(
        initialValue: _selectedCandidateIndex,
        decoration: InputDecoration(
          labelText: isEs ? 'Otros temas encontrados' : 'Other matches',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          isDense: true,
          filled: true,
        ),
        items: List<DropdownMenuItem<int>>.generate(
          _candidates.length,
          (index) {
            final item = _candidates[index];
            return DropdownMenuItem<int>(
              value: index,
              child: Text(
                '${item['chatTitle'] ?? item['chatId'] ?? '-'} / ${item['topicName'] ?? item['forumTopicId'] ?? '-'}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        onChanged: (index) {
          if (index == null) return;
          setState(() {
            _selectedCandidateIndex = index;
            _applyTelegramSource(_candidates[index]);
          });
        },
      ),
    );
  }

  Widget _metricsBar(
    BuildContext context, {
    required int totalRows,
    required int reviewRequiredCount,
    required int invalidRowCount,
  }) {
    final isEs = _isSpanish(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricChip(
            context,
            '$totalRows',
            isEs ? 'filas detectadas' : 'detected rows',
            Icons.table_rows_rounded,
            const Color(0xFF42A5F5)),
        _metricChip(
            context,
            '$reviewRequiredCount',
            isEs ? 'requieren revision' : 'need review',
            Icons.warning_amber_rounded,
            Colors.orange),
        _metricChip(context, '$invalidRowCount', isEs ? 'invalidas' : 'invalid',
            Icons.error_outline_rounded, Colors.redAccent),
      ],
    );
  }

  Widget _ignoredRowsButton(BuildContext context) {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.rule_folder_outlined,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEs
                  ? '${_ignoredRows.length} filas no importadas o requieren revisión.'
                  : '${_ignoredRows.length} rows were not imported or need review.',
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showIgnoredRowsDialog(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(isEs ? 'Ver detalle' : 'View details'),
          ),
        ],
      ),
    );
  }

  Widget _confirmOptionsBar(BuildContext context) {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedCount = _rows.where((row) => row.include).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SwitchListTile.adaptive(
              value: _skipExistingEntries,
              onChanged: _confirming
                  ? null
                  : (value) => setState(() => _skipExistingEntries = value),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                isEs
                    ? 'No sobrescribir existentes'
                    : 'Do not overwrite existing',
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                _skipExistingEntries
                    ? (isEs
                        ? 'Las horas ya registradas se omitiran.'
                        : 'Existing time entries will be skipped.')
                    : (isEs
                        ? 'Si existen duplicados, la importacion fallara.'
                        : 'If duplicates exist, the import will fail.'),
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.icon(
            onPressed: _canConfirm ? _confirmImport : null,
            icon: _confirming
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(
              isEs
                  ? 'Importar aprobadas ($selectedCount)'
                  : 'Import approved ($selectedCount)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _skippedEntriesDetails(
    BuildContext context,
    WorkingTimeExcelImportConfirmResult result,
  ) {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final entries = result.skippedEntries;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEs
                      ? '${result.skippedCount} filas existentes omitidas'
                      : '${result.skippedCount} existing rows skipped',
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...entries.take(6).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${_skippedEntryLabel(entry)}',
                      style: t.bodySmall.copyWith(color: cs.onSurface),
                    ),
                  ),
                ),
            if (entries.length > 6)
              Text(
                isEs
                    ? '+ ${entries.length - 6} mas'
                    : '+ ${entries.length - 6} more',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _skippedEntryLabel(Map<String, dynamic> entry) {
    final parts = <String>[
      for (final key in const ['date', 'workerDisplayName', 'workerName'])
        if ((entry[key]?.toString().trim() ?? '').isNotEmpty)
          entry[key].toString().trim(),
      if ((entry['startTime']?.toString().trim() ?? '').isNotEmpty ||
          (entry['endTime']?.toString().trim() ?? '').isNotEmpty)
        '${entry['startTime'] ?? ''}-${entry['endTime'] ?? ''}',
      if ((entry['reason']?.toString().trim() ?? '').isNotEmpty)
        entry['reason'].toString().trim(),
    ];
    return parts.isEmpty ? entry.toString() : parts.join(' · ');
  }

  Future<void> _showIgnoredRowsDialog(BuildContext context) async {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEs ? 'No importado / revisar' : 'Not imported / review',
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          content: SizedBox(
            width: 820,
            height: 520,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                primary: true,
                itemCount: _ignoredRows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final row = _ignoredRows[index];
                  final reasons = row.localizedReasons(isEs);
                  final isInvalid = row.invalid;
                  final color = isInvalid ? Colors.redAccent : Colors.orange;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            isInvalid
                                ? Icons.error_outline_rounded
                                : Icons.warning_amber_rounded,
                            color: color,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${isInvalid ? (isEs ? 'Invalida' : 'Invalid') : (isEs ? 'Revisar' : 'Review')}',
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (row.rawText.trim().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                SelectableText(
                                  row.rawText,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.72),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                              if (reasons.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _ReasonList(reasons: reasons, dense: true),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(isEs ? 'Cerrar' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _statusBadge(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: t.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: t.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.28)),
      ),
      child: Text(message, style: TextStyle(color: cs.error)),
    );
  }

  Widget _compactField(
    TextEditingController controller,
    String label, {
    double width = 180,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        ),
      ),
    );
  }

  Widget _warningBox(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: cs.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _reviewTable(
    BuildContext context, {
    required int totalRows,
    required int reviewRequiredCount,
    required int invalidRowCount,
  }) {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.80)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fact_check_outlined,
                      color: cs.primary, size: 19),
                ),
                const SizedBox(width: 10),
                Text(
                  isEs ? 'Revisar antes de importar' : 'Review before import',
                  style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _metricsBar(
                      context,
                      totalRows: totalRows,
                      reviewRequiredCount: reviewRequiredCount,
                      invalidRowCount: invalidRowCount,
                    ),
                  ),
                ),
                Text(
                  isEs
                      ? '${_rows.where((row) => row.include).length} seleccionadas'
                      : '${_rows.where((row) => row.include).length} selected',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                if (_approvableReviewRowsCount > 0) ...[
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _approveAllReviewRows,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: Text(isEs ? 'Aprobar todas' : 'Approve all'),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            controller: _tableScrollController,
            primary: false,
            scrollDirection: Axis.horizontal,
            child: _telegramReviewDataTable(
              context,
              rows: _rows,
              startIndex: 0,
            ),
          ),
        ],
      ),
    );
  }

  List<DataCell> _buildImportRowCells(
    BuildContext context,
    _TelegramImportRow row, {
    required bool isEs,
    bool isFirstInGroup = true,
  }) {
    final reasons = row.localizedReasons(isEs);
    return [
      DataCell(Checkbox(
        value: row.include,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (value) => setState(() {
          row.include = value ?? false;
          if (row.needsReview) row.confirmed = row.include;
        }),
      )),
      DataCell(Row(children: [
        if (row.invalid)
          _rowStatusPill(context,
              label: isEs ? 'Invalida' : 'Invalid',
              icon: Icons.error_outline_rounded,
              color: Colors.redAccent)
        else if (row.needsReview)
          _rowStatusPill(context,
              label: isEs ? 'Revisar' : 'Review',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange)
        else
          _rowStatusPill(context,
              label: 'OK',
              icon: Icons.check_circle_outline,
              color: Colors.green),
      ])),
      DataCell(_reasonIndicatorCell(context,
          row: row, reasons: reasons, isEs: isEs)),
      DataCell(_smallField(row.dateController, width: 118)),
      DataCell(_workerDropdown(row)),
      DataCell(_smallField(row.startController, width: 78)),
      DataCell(_smallField(row.endController, width: 78)),
      DataCell(_rawTextCell(context, row,
          width: 300, isFirstInGroup: isFirstInGroup)),
      DataCell(_confidenceBar(context, row)),
    ];
  }

  DataTable _telegramReviewDataTable(
    BuildContext context, {
    required List<_TelegramImportRow> rows,
    required int startIndex,
  }) {
    final isEs = _isSpanish(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 68,
      horizontalMargin: 14,
      columnSpacing: 22,
      headingRowColor: WidgetStatePropertyAll(
        cs.surfaceContainerHighest.withValues(alpha: 0.80),
      ),
      headingTextStyle: t.bodySmall.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w900,
      ),
      dataTextStyle: t.bodySmall.copyWith(color: cs.onSurface),
      columns: [
        const DataColumn(label: Text('OK')),
        DataColumn(label: Text(isEs ? 'Estado' : 'Status')),
        DataColumn(label: Text(isEs ? 'Motivo' : 'Reason')),
        DataColumn(label: Text(isEs ? 'Fecha' : 'Date')),
        DataColumn(label: Text(isEs ? 'Trabajador' : 'Worker')),
        const DataColumn(label: Text('Inicio')),
        const DataColumn(label: Text('Fin')),
        DataColumn(label: Text(isEs ? 'Texto original' : 'Raw text')),
        DataColumn(label: Text(isEs ? 'Confianza' : 'Confidence')),
      ],
      rows: () {
        // Build consecutive groups by rawText
        final List<List<_TelegramImportRow>> groups = [];
        for (final row in rows) {
          if (groups.isEmpty ||
              groups.last.first.rawText.trim() != row.rawText.trim()) {
            groups.add([row]);
          } else {
            groups.last.add(row);
          }
        }

        final List<DataRow> dataRows = [];
        for (final group in groups) {
          final groupKey = group.first.rawText.trim();
          final isMulti = group.length > 1;

          if (isMulti) {
            // ── Group header row ──────────────────────────────────────
            final isExpanded = !_collapsedGroups.contains(groupKey);
            final allIncluded = group.every((r) => r.include);
            final noneIncluded = group.every((r) => !r.include);
            final anyInvalid = group.any((r) => r.invalid);
            final anyReview = group.any((r) => r.needsReview);
            final accentColor = anyInvalid
                ? Colors.redAccent
                : anyReview
                    ? Colors.orange
                    : const Color(0xFF1D9BF0);
            final groupHeaderColor = accentColor.withValues(alpha: 0.16);
            final groupChildColor = accentColor.withValues(alpha: 0.075);

            dataRows.add(DataRow(
              color: WidgetStatePropertyAll(groupHeaderColor),
              cells: [
                // OK — select/deselect all in group
                DataCell(Checkbox(
                  value: allIncluded ? true : (noneIncluded ? false : null),
                  tristate: true,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => setState(() {
                    final target = !allIncluded;
                    for (final r in group) {
                      r.include = target;
                      if (r.needsReview) r.confirmed = target;
                    }
                  }),
                )),
                // Estado — count badge
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.30)),
                  ),
                  child: Text(
                    '${group.length}',
                    style: t.bodySmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )),
                // Motivo — empty
                const DataCell(SizedBox()),
                // Fecha — from first row
                DataCell(Text(
                  group.first.dateController.text,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                )),
                // Trabajador — entry count label
                DataCell(Text(
                  isEs ? '${group.length} entradas' : '${group.length} entries',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                )),
                // Inicio — empty
                const DataCell(SizedBox()),
                // Fin — empty
                const DataCell(SizedBox()),
                // Texto original — rawText + expand toggle
                DataCell(
                  onTap: () => setState(() => isExpanded
                      ? _collapsedGroups.add(groupKey)
                      : _collapsedGroups.remove(groupKey)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          groupKey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Confianza — empty
                const DataCell(SizedBox()),
              ],
            ));

            // Data rows — only when expanded
            if (isExpanded) {
              for (final row in group) {
                dataRows.add(DataRow(
                  color: WidgetStatePropertyAll(groupChildColor),
                  selected: row.include,
                  cells: _buildImportRowCells(context, row,
                      isEs: isEs, isFirstInGroup: false),
                ));
              }
            }
          } else {
            // Single row — render normally without a group header
            final row = group.first;
            dataRows.add(DataRow(
              color: WidgetStatePropertyAll(
                cs.surfaceContainerHighest.withValues(alpha: 0.14),
              ),
              selected: row.include,
              cells: _buildImportRowCells(context, row,
                  isEs: isEs, isFirstInGroup: true),
            ));
          }
        }
        return dataRows;
      }(),
    );
  }

  Widget _reasonIndicatorCell(
    BuildContext context, {
    required _TelegramImportRow row,
    required List<String> reasons,
    required bool isEs,
  }) {
    if (reasons.isEmpty) {
      return Text(
        '-',
        style: AppTypography.of(context).bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    final color = row.invalid ? Colors.redAccent : Colors.orange;
    final title = row.invalid
        ? (isEs ? 'Fila invalida' : 'Invalid row')
        : (isEs ? 'Requiere revision' : 'Review required');
    return Tooltip(
      richMessage: WidgetSpan(
        child: _ReasonTooltipContent(
          title: title,
          reasons: reasons,
          color: color,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showRowReasonsDialog(
          context,
          title: title,
          reasons: reasons,
          color: color,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                row.invalid
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                reasons.length == 1 ? '1' : '${reasons.length}',
                style: AppTypography.of(context).bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRowReasonsDialog(
    BuildContext context, {
    required String title,
    required List<String> reasons,
    required Color color,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: _ReasonList(reasons: reasons),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  Widget _smallField(TextEditingController controller,
      {required double width}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        style: AppTypography.of(context).bodySmall.copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        ),
      ),
    );
  }

  Widget _rawTextCell(
    BuildContext context,
    _TelegramImportRow row, {
    required double width,
    bool isFirstInGroup = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    if (!isFirstInGroup) {
      return SizedBox(
        width: width,
        child: Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 4),
            Text(
              '─ ─',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        row.rawText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodySmall.copyWith(fontSize: 12.5),
      ),
    );
  }

  Widget _rowStatusPill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.caption.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceBar(BuildContext context, _TelegramImportRow row) {
    final t = AppTypography.of(context);
    final value =
        (row.workerMatchConfidence ?? 0).toDouble().clamp(0, 1).toDouble();
    final color = value >= 0.85
        ? Colors.green
        : value >= 0.55
            ? Colors.orange
            : Colors.redAccent;
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.confidenceLabel,
            style: t.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workerDropdown(_TelegramImportRow row) {
    final workersById = <String, Worker>{};
    for (final worker in _workers) {
      final id = worker.id.trim();
      if (id.isNotEmpty) workersById.putIfAbsent(id, () => worker);
    }
    final workers = workersById.values.toList(growable: false);
    final selectedWorkerId =
        workersById.containsKey(row.workerId) ? row.workerId : null;

    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        initialValue: selectedWorkerId,
        isExpanded: true,
        style: AppTypography.of(context).bodySmall.copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        ),
        items: workers
            .map(
              (worker) => DropdownMenuItem<String>(
                value: worker.id,
                child: Text(worker.displayName ?? worker.id),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          setState(() {
            row.workerId = value ?? '';
            final match = workersById[row.workerId];
            if (match != null) {
              row.workerDisplayName =
                  match.displayName ?? row.workerDisplayName;
            }
          });
        },
      ),
    );
  }
}

class _ReasonTooltipContent extends StatelessWidget {
  const _ReasonTooltipContent({
    required this.title,
    required this.reasons,
    required this.color,
  });

  final String title;
  final List<String> reasons;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
              fontSize: 12,
              height: 1.25,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ReasonList(reasons: reasons, dense: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonList extends StatelessWidget {
  const _ReasonList({
    required this.reasons,
    this.dense = false,
  });

  final List<String> reasons;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textStyle = dense
        ? const TextStyle(fontSize: 12, height: 1.25)
        : Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final reason in reasons)
          Padding(
            padding: EdgeInsets.only(bottom: dense ? 4 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: SelectableText(
                    reason,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TelegramImportRow {
  _TelegramImportRow({
    required this.workerId,
    required this.workerDisplayName,
    required this.workerAlias,
    required this.rawText,
    required this.workerMatchConfidence,
    required this.issues,
    required this.reasons,
    required this.validationReasons,
    required this.reviewReasons,
    required this.invalid,
    required this.reviewRequired,
    required String date,
    required String startTime,
    required String endTime,
    required this.startedAt,
    required this.endedAt,
    required this.breakMinutes,
    required this.notes,
  })  : dateController = TextEditingController(text: date),
        startController = TextEditingController(text: startTime),
        endController = TextEditingController(text: endTime);

  String workerId;
  String workerDisplayName;
  String workerAlias;
  final String rawText;
  final num? workerMatchConfidence;
  final List<String> issues;
  final List<_TelegramImportReason> reasons;
  final List<_TelegramImportReason> validationReasons;
  final List<_TelegramImportReason> reviewReasons;
  final bool invalid;
  final bool reviewRequired;
  final String? startedAt;
  final String? endedAt;
  final int breakMinutes;
  final String notes;
  bool include = true;
  bool confirmed = false;
  final TextEditingController dateController;
  final TextEditingController startController;
  final TextEditingController endController;

  bool get needsReview => reviewRequired || reviewReasons.isNotEmpty;
  bool get hasReasons => reasons.isNotEmpty || issues.isNotEmpty;

  List<String> localizedReasons(bool isEs) {
    final sourceReasons = reasons.isNotEmpty
        ? reasons
        : <_TelegramImportReason>[
            ...validationReasons,
            ...reviewReasons,
          ];
    final localized = sourceReasons
        .map((reason) => reason.localizedMessage(isEs))
        .where((message) => message.isNotEmpty)
        .toList(growable: false);
    return localized.isNotEmpty ? localized : issues;
  }

  String get confidenceLabel => workerMatchConfidence == null
      ? '-'
      : '${(workerMatchConfidence!.toDouble() * 100).round()}%';

  factory _TelegramImportRow.fromJson(
    Map<String, dynamic> json, {
    required List<Worker> workers,
  }) {
    final displayName = _text(json, const ['workerDisplayName', 'workerName']);
    var workerId = _text(json, const ['workerId']);
    if (workerId.isEmpty && displayName.isNotEmpty) {
      final normalized = displayName.toLowerCase();
      final matches = workers.where(
        (worker) => (worker.displayName ?? '').toLowerCase() == normalized,
      );
      if (matches.isNotEmpty) workerId = matches.first.id;
    }
    final reasons = _TelegramImportReason.listFrom(json['reasons']);
    final validationReasons = _TelegramImportReason.listFrom(
      json['validationReasons'],
    );
    final reviewReasons = _TelegramImportReason.listFrom(
      json['reviewReasons'],
    );
    final effectiveValidationReasons = validationReasons.isNotEmpty
        ? validationReasons
        : reasons
            .where((reason) => reason.severity.toLowerCase() == 'invalid')
            .toList(growable: false);
    final effectiveReviewReasons = reviewReasons.isNotEmpty
        ? reviewReasons
        : reasons
            .where((reason) => reason.severity.toLowerCase() != 'invalid')
            .toList(growable: false);
    final invalid =
        json['invalid'] == true || effectiveValidationReasons.isNotEmpty;

    final row = _TelegramImportRow(
      workerId: workerId,
      workerDisplayName: displayName,
      workerAlias: _text(json, const ['workerAlias', 'alias']),
      rawText: _text(json, const ['rawText', 'text', 'originalText']),
      workerMatchConfidence: json['workerMatchConfidence'] is num
          ? json['workerMatchConfidence'] as num
          : num.tryParse('${json['workerMatchConfidence'] ?? ''}'),
      issues: _stringList(json['issues']),
      reasons: reasons,
      validationReasons: effectiveValidationReasons,
      reviewReasons: effectiveReviewReasons,
      invalid: invalid,
      reviewRequired:
          json['reviewRequired'] == true || effectiveReviewReasons.isNotEmpty,
      date: _text(json, const ['date']),
      startTime: _text(json, const ['startTime']),
      endTime: _text(json, const ['endTime']),
      startedAt: _nullableText(json['startedAt']),
      endedAt: _nullableText(json['endedAt']),
      breakMinutes: int.tryParse('${json['breakMinutes'] ?? 0}') ?? 0,
      notes: _text(json, const ['notes']),
    );
    if (row.invalid) row.include = false;
    if (row.needsReview && row.include) row.confirmed = true;
    return row;
  }

  Map<String, dynamic> toConfirmJson() => <String, dynamic>{
        'workerId': workerId,
        'workerDisplayName': workerDisplayName,
        if (workerAlias.trim().isNotEmpty) 'workerAlias': workerAlias,
        'date': dateController.text.trim(),
        'startTime': startController.text.trim(),
        'endTime': endController.text.trim(),
        if ((startedAt ?? '').trim().isNotEmpty) 'startedAt': startedAt,
        if ((endedAt ?? '').trim().isNotEmpty) 'endedAt': endedAt,
        'breakMinutes': breakMinutes,
        'notes': notes.trim().isNotEmpty ? notes : 'Telegram',
        'tags': const ['telegram'],
      };

  void dispose() {
    dateController.dispose();
    startController.dispose();
    endController.dispose();
  }

  static String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class _TelegramIgnoredRow {
  const _TelegramIgnoredRow({
    required this.rawText,
    required this.issues,
    required this.reasons,
    required this.validationReasons,
    required this.reviewReasons,
    required this.invalid,
    required this.reviewRequired,
  });

  final String rawText;
  final List<String> issues;
  final List<_TelegramImportReason> reasons;
  final List<_TelegramImportReason> validationReasons;
  final List<_TelegramImportReason> reviewReasons;
  final bool invalid;
  final bool reviewRequired;

  bool get needsReview => reviewRequired || reviewReasons.isNotEmpty;

  List<String> localizedReasons(bool isEs) {
    final sourceReasons = reasons.isNotEmpty
        ? reasons
        : <_TelegramImportReason>[
            ...validationReasons,
            ...reviewReasons,
          ];
    final localized = sourceReasons
        .map((reason) => reason.localizedMessage(isEs))
        .where((message) => message.isNotEmpty)
        .toList(growable: false);
    return localized.isNotEmpty ? localized : issues;
  }

  factory _TelegramIgnoredRow.fromValue(dynamic value) {
    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      final reasons = _TelegramImportReason.listFrom(json['reasons']);
      final validationReasons =
          _TelegramImportReason.listFrom(json['validationReasons']);
      final reviewReasons =
          _TelegramImportReason.listFrom(json['reviewReasons']);
      final effectiveValidationReasons = validationReasons.isNotEmpty
          ? validationReasons
          : reasons
              .where((reason) => reason.severity.toLowerCase() == 'invalid')
              .toList(growable: false);
      final effectiveReviewReasons = reviewReasons.isNotEmpty
          ? reviewReasons
          : reasons
              .where((reason) => reason.severity.toLowerCase() != 'invalid')
              .toList(growable: false);
      return _TelegramIgnoredRow(
        rawText: _TelegramImportRow._text(
          json,
          const ['rawText', 'text', 'originalText', 'message'],
        ),
        issues: _TelegramImportRow._stringList(json['issues']),
        reasons: reasons,
        validationReasons: effectiveValidationReasons,
        reviewReasons: effectiveReviewReasons,
        invalid:
            json['invalid'] == true || effectiveValidationReasons.isNotEmpty,
        reviewRequired:
            json['reviewRequired'] == true || effectiveReviewReasons.isNotEmpty,
      );
    }
    final text = value?.toString().trim() ?? '';
    return _TelegramIgnoredRow(
      rawText: text,
      issues: text.isEmpty ? const <String>[] : <String>[text],
      reasons: const <_TelegramImportReason>[],
      validationReasons: const <_TelegramImportReason>[],
      reviewReasons: const <_TelegramImportReason>[],
      invalid: false,
      reviewRequired: false,
    );
  }
}

class _TelegramImportReason {
  const _TelegramImportReason({
    required this.code,
    required this.severity,
    required this.message,
    required this.translations,
  });

  final String code;
  final String severity;
  final String message;
  final Map<String, String> translations;

  String localizedMessage(bool isEs) {
    final lang = isEs ? 'es' : 'en';
    final translated = translations[lang]?.trim();
    if (translated != null && translated.isNotEmpty) return translated;
    final fallback = message.trim();
    if (fallback.isNotEmpty) return fallback;
    return code.trim();
  }

  static List<_TelegramImportReason> listFrom(dynamic value) {
    if (value is! List) return const <_TelegramImportReason>[];
    return value
        .whereType<Map>()
        .map((item) => _TelegramImportReason.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  factory _TelegramImportReason.fromJson(Map<String, dynamic> json) {
    final rawTranslations = json['translations'];
    final translations = rawTranslations is Map
        ? rawTranslations.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          )
        : const <String, String>{};
    return _TelegramImportReason(
      code: json['code']?.toString().trim() ?? '',
      severity: json['severity']?.toString().trim() ?? '',
      message: json['message']?.toString().trim() ?? '',
      translations: translations,
    );
  }
}
