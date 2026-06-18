import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;

class TelegramWorkerDocumentSelection {
  const TelegramWorkerDocumentSelection({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.workerId,
    required this.documentLabel,
  });

  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final String workerId;
  final String documentLabel;
}

Future<TelegramWorkerDocumentSelection?> showTelegramWorkerDocumentPickerDialog(
  BuildContext context, {
  required String groupId,
}) {
  return showDialog<TelegramWorkerDocumentSelection>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Theme.of(dialogContext).canvasColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 980,
        height: 680,
        child: TelegramWorkerDocumentPickerDialog(groupId: groupId),
      ),
    ),
  );
}

class TelegramWorkerDocumentPickerDialog extends StatefulWidget {
  const TelegramWorkerDocumentPickerDialog({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  State<TelegramWorkerDocumentPickerDialog> createState() =>
      _TelegramWorkerDocumentPickerDialogState();
}

class _TelegramWorkerDocumentPickerDialogState
    extends State<TelegramWorkerDocumentPickerDialog> {
  late final ITimeTrackingRepository _repo;
  late final UserDomain _userDomain;
  final TextEditingController _searchController = TextEditingController();

  bool _isSpanish = false;
  bool _didLoadWorkers = false;

  List<Worker> _workers = const <Worker>[];
  bool _loadingWorkers = true;
  bool _previewing = false;
  bool _attaching = false;
  String? _error;
  String? _monthNotice;
  String? _selectedWorkerId;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isSpanish = Localizations.localeOf(context).languageCode == 'es';
    if (!_didLoadWorkers) {
      _didLoadWorkers = true;
      _loadWorkers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _token() => _userDomain.getAuthToken();

  String get _monthValue =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  DateTime get _fromUtc => DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      ).toUtc();

  DateTime get _toUtc => (_selectedMonth.month < 12
          ? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1)
          : DateTime(_selectedMonth.year + 1, 1, 1))
      .toUtc();

  List<Worker> get _visibleWorkers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _workers;
    return _workers.where((worker) {
      final name = (worker.displayName ?? '').toLowerCase();
      final role = (worker.roleTag ?? '').toLowerCase();
      final id = worker.id.toLowerCase();
      return '$name $role $id'.contains(query);
    }).toList(growable: false);
  }

  Future<void> _loadWorkers() async {
    final isEs = _isSpanish;
    setState(() {
      _loadingWorkers = true;
      _error = null;
      _monthNotice = null;
    });
    try {
      final token = await _token();
      List<Worker> workers;
      try {
        workers = await _repo.getWorkers(
          widget.groupId,
          token,
          status: WorkerStatus.active,
          month: _monthValue,
        );
      } on BackendApiException catch (e) {
        if (!_isNoEntriesForMonthError(e)) rethrow;
        workers = await _repo.getWorkers(
          widget.groupId,
          token,
          status: WorkerStatus.active,
        );
        _monthNotice = isEs
            ? 'No se encontraron horas para ${_monthLabel()}. Puedes cambiar el mes o elegir un trabajador y probar las acciones de PDF.'
            : 'No hours were found for ${_monthLabel()}. You can switch months or still choose a worker and try the PDF actions.';
      }
      workers.sort((a, b) {
        final left = (a.displayName ?? a.id).toLowerCase();
        final right = (b.displayName ?? b.id).toLowerCase();
        return left.compareTo(right);
      });
      if (!mounted) return;
      setState(() {
        _workers = workers;
        if (_selectedWorkerId == null ||
            !workers.any((w) => w.id == _selectedWorkerId)) {
          _selectedWorkerId = workers.isNotEmpty ? workers.first.id : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', '').trim());
    } finally {
      if (mounted) {
        setState(() => _loadingWorkers = false);
      }
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
    await _loadWorkers();
  }

  String _workerLabel(Worker worker) {
    final name = (worker.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    return worker.id;
  }

  String _monthLabel() {
    return DateFormat.yMMMM().format(_selectedMonth);
  }

  bool _isNoEntriesForMonthError(BackendApiException e) {
    if (e.statusCode != 404) return false;
    final message = e.message.toLowerCase();
    return message.contains('no time entries found');
  }

  String _safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    return cleaned.isEmpty ? 'worker-hours' : cleaned;
  }

  Future<Uint8List> _loadPdfBytes(Worker worker) async {
    final lang =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es'
            ? 'es'
            : 'en';
    final token = await _token();
    double? advanceAmount = worker.advanceAmount;
    try {
      final totals = await _repo.getWorkerTotals(
        widget.groupId,
        token,
        workerId: worker.id,
        month: _monthValue,
        from: _fromUtc,
        to: _toUtc,
      );
      final rawAdvance = totals['advanceAmount'] ?? worker.advanceAmount;
      advanceAmount = rawAdvance is num
          ? rawAdvance.toDouble()
          : double.tryParse(rawAdvance?.toString() ?? '');
    } on BackendApiException catch (e) {
      if (!_isNoEntriesForMonthError(e)) rethrow;
    }
    return _repo.previewPayrollPdf(
      widget.groupId,
      token,
      from: _fromUtc,
      to: _toUtc,
      workerId: worker.id,
      lang: lang,
      advanceAmount: advanceAmount,
    );
  }

  Future<void> _handlePreview() async {
    Worker? worker;
    for (final item in _workers) {
      if (item.id == _selectedWorkerId) {
        worker = item;
        break;
      }
    }
    if (worker == null || _previewing) return;
    setState(() => _previewing = true);
    try {
      final bytes = await _loadPdfBytes(worker);
      if (!mounted) return;
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName:
            'worker-hours-${_safeFileName(_workerLabel(worker))}-$_monthValue.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '').trim())),
      );
    } finally {
      if (mounted) {
        setState(() => _previewing = false);
      }
    }
  }

  Future<void> _handleAttach() async {
    Worker? worker;
    for (final item in _workers) {
      if (item.id == _selectedWorkerId) {
        worker = item;
        break;
      }
    }
    if (worker == null || _attaching) return;
    setState(() {
      _attaching = true;
      _error = null;
    });
    try {
      final bytes = await _loadPdfBytes(worker);
      if (!mounted) return;
      Navigator.of(context).pop(
        TelegramWorkerDocumentSelection(
          fileName:
              'worker-hours-${_safeFileName(_workerLabel(worker))}-$_monthValue.pdf',
          bytes: bytes,
          mimeType: 'application/pdf',
          workerId: worker.id,
          documentLabel: '${_workerLabel(worker)} · $_monthValue',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attaching = false;
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    Worker? selectedWorker;
    for (final item in _workers) {
      if (item.id == _selectedWorkerId) {
        selectedWorker = item;
        break;
      }
    }
    final visibleWorkers = _visibleWorkers;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSpanish
                          ? 'Adjuntar PDF de horas de trabajador'
                          : 'Attach worker-hours PDF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSpanish
                          ? 'Elige un trabajador y un mes, luego adjunta el PDF de horas a Telegram.'
                          : 'Choose a worker and month, then attach the hours PDF into Telegram.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.64),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadingWorkers ? null : _loadWorkers,
                tooltip:
                    _isSpanish ? 'Recargar trabajadores' : 'Reload workers',
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: l.close,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.26),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isSpanish ? 'Trabajadores' : 'Workers',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickMonth,
                              icon: const Icon(Icons.calendar_month_outlined,
                                  size: 16),
                              label: Text(_monthLabel()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: _isSpanish
                                        ? 'Buscar trabajadores...'
                                        : 'Search workers...',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_monthNotice != null) ...[
                          _WorkerPickerInfoCard(message: _monthNotice!),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: _loadingWorkers
                              ? const Center(child: CircularProgressIndicator())
                              : _error != null
                                  ? _WorkerPickerErrorCard(
                                      message: _error!,
                                      onRetry: _loadWorkers,
                                    )
                                  : visibleWorkers.isEmpty
                                      ? _WorkerPickerEmptyCard(
                                          icon: Icons.badge_outlined,
                                          title: _isSpanish
                                              ? 'Sin trabajadores'
                                              : 'No workers found',
                                          message: _isSpanish
                                              ? 'No hay trabajadores activos disponibles en este momento.'
                                              : 'There are no active workers available to attach right now.',
                                        )
                                      : ListView.separated(
                                          itemCount: visibleWorkers.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final worker =
                                                visibleWorkers[index];
                                            final selected =
                                                worker.id == _selectedWorkerId;
                                            return _WorkerTile(
                                              worker: worker,
                                              selected: selected,
                                              onTap: () => setState(
                                                () => _selectedWorkerId =
                                                    worker.id,
                                              ),
                                            );
                                          },
                                        ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.26),
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedWorker == null
                              ? (_isSpanish
                                  ? 'PDF de trabajador'
                                  : 'Worker PDF')
                              : (_isSpanish
                                  ? 'PDF de ${_workerLabel(selectedWorker)}'
                                  : 'Worker PDF for ${_workerLabel(selectedWorker)}'),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selectedWorker == null
                              ? (_isSpanish
                                  ? 'Elige un trabajador para previsualizar o adjuntar el PDF de horas mensual.'
                                  : 'Pick one worker to preview or attach the monthly hours PDF.')
                              : (_isSpanish
                                  ? 'Previsualiza el PDF de horas o adjúntalo al chat de Telegram.'
                                  : 'Preview the worker-hours PDF or attach it into the current Telegram chat.'),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.58),
                                  ),
                        ),
                        const SizedBox(height: 18),
                        if (selectedWorker == null)
                          Expanded(
                            child: _WorkerPickerEmptyCard(
                              icon: Icons.picture_as_pdf_outlined,
                              title: _isSpanish
                                  ? 'Elige un trabajador primero'
                                  : 'Choose a worker first',
                              message: _isSpanish
                                  ? 'Las acciones de PDF aparecerán aquí al seleccionar un trabajador.'
                                  : 'The selected worker PDF actions will appear here.',
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _workerLabel(selectedWorker),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isSpanish
                                        ? 'Período: $_monthValue'
                                        : 'Period: $_monthValue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.72),
                                        ),
                                  ),
                                  if ((selectedWorker.roleTag ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _isSpanish
                                          ? 'Rol: ${selectedWorker.roleTag!.trim()}'
                                          : 'Role: ${selectedWorker.roleTag!.trim()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.62),
                                          ),
                                    ),
                                  ],
                                  if (_monthNotice != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _monthNotice!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.62),
                                          ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _previewing || _attaching
                                            ? null
                                            : _handlePreview,
                                        icon: _previewing
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.visibility_outlined),
                                        label: Text(_isSpanish
                                            ? 'Vista previa PDF'
                                            : 'Preview PDF'),
                                      ),
                                      FilledButton.icon(
                                        onPressed: _attaching || _previewing
                                            ? null
                                            : _handleAttach,
                                        icon: _attaching
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.attach_file_rounded),
                                        label: Text(
                                          _attaching
                                              ? (_isSpanish
                                                  ? 'Adjuntando...'
                                                  : 'Attaching...')
                                              : (_isSpanish
                                                  ? 'Adjuntar PDF'
                                                  : 'Attach PDF'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkerPickerInfoCard extends StatelessWidget {
  const _WorkerPickerInfoCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child:
                Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.74),
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({
    required this.worker,
    required this.selected,
    required this.onTap,
  });

  final Worker worker;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.16)
                : cs.surfaceContainerHighest.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.24),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.badge_outlined, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (worker.displayName ?? worker.id).trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (worker.roleTag ?? '').trim().isEmpty
                          ? worker.id
                          : '${worker.roleTag}  ·  ${worker.id}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.62),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerPickerEmptyCard extends StatelessWidget {
  const _WorkerPickerEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerPickerErrorCard extends StatelessWidget {
  const _WorkerPickerErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(
              Localizations.localeOf(context).languageCode == 'es'
                  ? 'No se pudieron cargar los PDFs'
                  : 'Could not load worker PDFs',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                Localizations.localeOf(context).languageCode == 'es'
                    ? 'Reintentar'
                    : 'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
