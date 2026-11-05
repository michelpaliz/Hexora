import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/controller/worker_time_tracking_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/appbar_title.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/stats_header.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/time_entry_list.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/time_tracking_excel_import_dialog.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/build_context_locale.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // keep only if added to pubspec

class WorkerTimeTrackingScreen extends StatelessWidget {
  final Group group;
  final Worker worker;
  final int? initialYear;
  final int? initialMonth;
  final bool embedded;
  final VoidCallback? onDataChanged;

  const WorkerTimeTrackingScreen({
    super.key,
    required this.group,
    required this.worker,
    this.initialYear,
    this.initialMonth,
    this.embedded = false,
    this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ITimeTrackingRepository>();
    final userDomain = context.read<UserDomain>();

    return ChangeNotifierProvider(
      create: (_) => WorkerTimeTrackingController(
        group: group,
        worker: worker,
        repo: repo,
        userDomain: userDomain,
        initialYear: initialYear,
        initialMonth: initialMonth,
      )..load(),
      child: _WorkerTimeTrackingView(
        embedded: embedded,
        onDataChanged: onDataChanged,
      ),
    );
  }
}

enum _WorkerHoursAction {
  toggleMissingDays,
  exportExcel,
  importExcel,
  calendarPdf,
  previewPayrollPdf,
  downloadPayrollPdf,
}

class _OptionsMenuRow extends StatelessWidget {
  const _OptionsMenuRow({
    required this.icon,
    required this.label,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: loading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Icon(icon, size: 19),
        ),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _WorkerTimeTrackingView extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onDataChanged;

  const _WorkerTimeTrackingView({
    required this.embedded,
    this.onDataChanged,
  });

  @override
  State<_WorkerTimeTrackingView> createState() =>
      _WorkerTimeTrackingViewState();
}

class _WorkerTimeTrackingViewState extends State<_WorkerTimeTrackingView> {
  bool _showMissingDays = false;
  bool _showCreateEntry = false;
  bool _previewingPayrollPdf = false;
  bool _previewingMonthlyCalendarPdf = false;
  bool _downloadingPayrollPdf = false;
  Timer? _advanceDebounce;

  @override
  void dispose() {
    _advanceDebounce?.cancel();
    super.dispose();
  }

  bool _isSpanish(BuildContext context) => context.isSpanishLocale;

  String _advanceInputErrorText(BuildContext context) => _isSpanish(context)
      ? 'El anticipo debe ser un número mayor o igual a 0.'
      : 'Advance must be a number greater than or equal to 0.';

  String _apiFailedAdvanceText(BuildContext context) => _isSpanish(context)
      ? 'No se pudo guardar el anticipo del trabajador.'
      : 'Could not save the worker advance.';

  Future<void> _openAdvanceDialog(BuildContext context) async {
    final c = context.read<WorkerTimeTrackingController>();
    final initial = c.advanceAmount.toStringAsFixed(2);
    final textCtrl = TextEditingController(text: initial);
    String? fieldError;

    final result = await showHexoraDialog<double>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            title: Text(_isSpanish(context) ? 'Anticipo' : 'Advance'),
            content: TextField(
              controller: textCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _isSpanish(context)
                    ? 'Importe del anticipo'
                    : 'Advance amount',
                hintText: '0',
                errorText: fieldError,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final raw = textCtrl.text.trim().replaceAll(',', '.');
                  final value = raw.isEmpty ? 0 : double.tryParse(raw);
                  if (value == null || value < 0) {
                    setDialogState(() {
                      fieldError = _advanceInputErrorText(context);
                    });
                    return;
                  }
                  Navigator.pop(dialogCtx, value);
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        );
      },
    );

    textCtrl.dispose();
    if (result == null) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorText = _apiFailedAdvanceText(context);
    _advanceDebounce?.cancel();
    _advanceDebounce = Timer(const Duration(milliseconds: 150), () async {
      try {
        await c.saveAdvanceAmount(result);
      } catch (_) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(errorText)),
        );
        return;
      }
      if (!mounted) return;
      if (c.totalsError != null && c.totalsError!.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(errorText)),
        );
      }
    });
  }

  Future<void> _addEntry(BuildContext context) async {
    final c = context.read<WorkerTimeTrackingController>();
    if (widget.embedded) {
      setState(() => _showCreateEntry = true);
      return;
    }
    final created = await showModalBottomSheet<bool>(
      sheetAnimationStyle: HexoraMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: CreateTimeEntryScreen(
          group: c.group,
          workers: [c.worker],
        ),
      ),
    );
    if (created == true) {
      await c.load();
      widget.onDataChanged?.call();
    }
  }

  Future<void> _reloadAfterEntryChange(BuildContext context) async {
    final c = context.read<WorkerTimeTrackingController>();
    await c.load();
    widget.onDataChanged?.call();
  }

  Future<void> _exportExcel(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final c = context.read<WorkerTimeTrackingController>();
    try {
      final bytes = await c.exportExcelFiltered();
      final fileName =
          'time_entries_${c.group.id}_${c.year}-${c.month.toString().padLeft(2, '0')}_${c.worker.id}.xlsx';
      final xfile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await Share.shareXFiles([xfile], text: l.exportReady);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
    }
  }

  Future<void> _openExcelImport(BuildContext context) async {
    final c = context.read<WorkerTimeTrackingController>();
    final imported = await TimeTrackingExcelImportDialog.show(
      context,
      group: c.group,
      initialWorker: c.worker,
      initialMonth: DateTime(c.year, c.month, 1),
    );
    if (imported) {
      await c.load();
      widget.onDataChanged?.call();
    }
  }

  String _langCode(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'es' ? 'es' : 'en';
  }

  String _previewPdfErrorMessage(Object error) {
    if (error is BackendApiException) {
      if (error.statusCode == 404) {
        final code = (error.code ?? '').toLowerCase();
        final message = error.message.toLowerCase();

        final isNoEntries = code.contains('no_entries') ||
            code.contains('time_entries_not_found') ||
            (message.contains('no') && message.contains('entries'));

        if (isNoEntries) {
          return 'No time entries found for this period.';
        }

        return 'Payroll PDF preview is not available on this server yet.';
      }
      if (error.statusCode == 403) {
        return 'You don\'t have a worker profile in this group.';
      }
    }
    return 'Could not preview payroll PDF. Please try again.';
  }

  Future<void> _previewPayrollPdf(BuildContext context) async {
    if (_previewingPayrollPdf) return;
    final c = context.read<WorkerTimeTrackingController>();
    setState(() => _previewingPayrollPdf = true);
    try {
      final bytes = await c.previewPayrollPdf(lang: _langCode(context));
      final fileName =
          'payroll_preview_${c.group.id}_${c.year}-${c.month.toString().padLeft(2, '0')}_${c.worker.id}.pdf';
      await launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_previewPdfErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _previewingPayrollPdf = false);
    }
  }

  Future<void> _previewMonthlyCalendarPdf(BuildContext context) async {
    if (_previewingMonthlyCalendarPdf) return;
    final c = context.read<WorkerTimeTrackingController>();
    setState(() => _previewingMonthlyCalendarPdf = true);
    try {
      final bytes = await c.exportMonthlyCalendarPdf(lang: _langCode(context));
      final fileName =
          'monthly_calendar_${c.group.id}_${c.year}-${c.month.toString().padLeft(2, '0')}_${c.worker.id}.pdf';
      await launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!context.mounted) return;
      final isSpanish = _isSpanish(context);
      final message = e is BackendApiException && e.statusCode == 403
          ? (isSpanish
              ? 'No tienes permiso para exportar este informe.'
              : 'You do not have permission to export this report.')
          : (isSpanish
              ? 'No se pudo generar el PDF del calendario mensual.'
              : 'Could not generate the monthly calendar PDF.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _previewingMonthlyCalendarPdf = false);
    }
  }

  Future<void> _downloadPayrollPdf(BuildContext context) async {
    if (_downloadingPayrollPdf) return;
    final c = context.read<WorkerTimeTrackingController>();
    setState(() => _downloadingPayrollPdf = true);
    try {
      final bytes = await c.previewPayrollPdf(lang: _langCode(context));
      final fileName =
          'payroll_${c.group.id}_${c.year}-${c.month.toString().padLeft(2, '0')}_${c.worker.id}.pdf';
      await launchFileDownload(
        bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e is UnsupportedError
          ? 'PDF download is not supported on this platform yet.'
          : _previewPdfErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _downloadingPayrollPdf = false);
    }
  }

  Widget _optionsMenu(
    BuildContext context, {
    required AppLocalizations l,
    required bool isSpanish,
    bool compact = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<_WorkerHoursAction>(
      tooltip: isSpanish ? 'Opciones' : 'Options',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      onSelected: (action) {
        switch (action) {
          case _WorkerHoursAction.toggleMissingDays:
            setState(() => _showMissingDays = !_showMissingDays);
          case _WorkerHoursAction.exportExcel:
            _exportExcel(context);
          case _WorkerHoursAction.importExcel:
            _openExcelImport(context);
          case _WorkerHoursAction.calendarPdf:
            _previewMonthlyCalendarPdf(context);
          case _WorkerHoursAction.previewPayrollPdf:
            _previewPayrollPdf(context);
          case _WorkerHoursAction.downloadPayrollPdf:
            _downloadPayrollPdf(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _WorkerHoursAction.toggleMissingDays,
          child: _OptionsMenuRow(
            icon: _showMissingDays
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: l.toggleEmptyDays,
          ),
        ),
        PopupMenuItem(
          value: _WorkerHoursAction.exportExcel,
          child: _OptionsMenuRow(
            icon: Icons.grid_on_rounded,
            label: l.exportExcel,
          ),
        ),
        PopupMenuItem(
          value: _WorkerHoursAction.importExcel,
          child: _OptionsMenuRow(
            icon: Icons.upload_file_outlined,
            label: isSpanish ? 'Importar Excel' : 'Import Excel',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _WorkerHoursAction.calendarPdf,
          enabled: !_previewingMonthlyCalendarPdf,
          child: _OptionsMenuRow(
            icon: Icons.calendar_month_outlined,
            label: isSpanish ? 'Calendario mensual' : 'Monthly calendar',
            loading: _previewingMonthlyCalendarPdf,
          ),
        ),
        PopupMenuItem(
          value: _WorkerHoursAction.previewPayrollPdf,
          enabled: !_previewingPayrollPdf,
          child: _OptionsMenuRow(
            icon: Icons.picture_as_pdf_outlined,
            label: isSpanish ? 'Vista previa del PDF' : 'Preview PDF',
            loading: _previewingPayrollPdf,
          ),
        ),
        PopupMenuItem(
          value: _WorkerHoursAction.downloadPayrollPdf,
          enabled: !_downloadingPayrollPdf,
          child: _OptionsMenuRow(
            icon: Icons.file_download_outlined,
            label: isSpanish ? 'Descargar PDF' : 'Download PDF',
            loading: _downloadingPayrollPdf,
          ),
        ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 18, color: colors.primary),
            if (!compact) ...[
              const SizedBox(width: 7),
              Text(
                isSpanish ? 'Opciones' : 'Options',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = context.isSpanishLocale;
    return Consumer<WorkerTimeTrackingController>(
      builder: (context, c, _) {
        final completedDuration = c.entries.fold<Duration>(
          Duration.zero,
          (total, entry) => entry.end == null
              ? total
              : total + entry.end!.difference(entry.start),
        );
        final durationHours = completedDuration.inMinutes / 60;
        final durationLabel = durationHours == durationHours.roundToDouble()
            ? durationHours.toStringAsFixed(0)
            : durationHours.toStringAsFixed(1).replaceAll('.', ',');
        final entriesFooter = Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: isSpanish
                            ? '${c.entries.length} registros · '
                            : '${c.entries.length} entries · ',
                      ),
                      TextSpan(
                        text: isSpanish
                            ? '$durationLabel h totales'
                            : '$durationLabel total hours',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _addEntry(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.addTimeEntryCta),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
        );

        final content = _showCreateEntry
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showCreateEntry = false),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l.back),
                    ),
                  ),
                  Expanded(
                    child: CreateTimeEntryScreen(
                      key: ValueKey('inline-time-entry-${c.worker.id}'),
                      group: c.group,
                      workers: [c.worker],
                      embedded: true,
                      showHeader: false,
                      initialSelectedIds: {c.worker.id},
                      onCancel: () => setState(() => _showCreateEntry = false),
                      onCreated: () async {
                        if (mounted) {
                          setState(() => _showCreateEntry = false);
                        }
                        await c.load();
                        widget.onDataChanged?.call();
                      },
                    ),
                  ),
                ],
              )
            : c.loading
                ? const Center(child: CircularProgressIndicator())
                : c.error
                    ? Center(child: Text(l.errorLoadingData))
                    : c.entries.isEmpty
                        ? EmptyView(
                            icon: Icons.timer_outlined,
                            title: l.noTimeEntriesYetTitle,
                            subtitle: l.noTimeEntriesYetSubtitle,
                            cta: l.addTimeEntryCta,
                            onPressed: () => _addEntry(context),
                          )
                        : RefreshIndicator(
                            onRefresh: c.load,
                            child: Column(
                              children: [
                                StatsHeader(
                                  entries: c.entries,
                                  totals: c.totals,
                                  worker: c.worker,
                                  totalsLoading: c.totalsLoading,
                                  totalsError: c.totalsError,
                                ),
                                Expanded(
                                  child: TimeEntriesList(
                                    entries: c.entries,
                                    groupId: c.group.id,
                                    repo:
                                        context.read<ITimeTrackingRepository>(),
                                    getToken: () => context
                                        .read<UserDomain>()
                                        .getAuthToken(),
                                    onUpdated: () =>
                                        _reloadAfterEntryChange(context),
                                    worker: c.worker,
                                    showMissingDays: _showMissingDays,
                                  ),
                                ),
                                entriesFooter,
                              ],
                            ),
                          );
        if (widget.embedded) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    if (_showCreateEntry) ...[
                      TextButton.icon(
                        key: const ValueKey('embedded-time-entry-back'),
                        onPressed: () =>
                            setState(() => _showCreateEntry = false),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(l.back),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.addTimeEntryCta,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: isSpanish
                            ? 'Selecciona los trabajadores y el horario que quieres registrar.'
                            : 'Select the workers and schedule you want to register.',
                        child: Icon(Icons.info_outline_rounded,
                            size: 17,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (_showCreateEntry)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                c.worker.displayName ??
                                    c.worker.userId ??
                                    l.unknownWorker,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ThemeColors.success(context)
                                    .withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c.worker.status == WorkerStatus.active
                                    ? l.statusActive
                                    : l.statusInactive,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: c.worker.status == WorkerStatus.active
                                      ? ThemeColors.success(context)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final narrow = constraints.maxWidth < 700;
                            final identity = WorkerAppBarTitle(
                              group: c.group,
                              worker: c.worker,
                              year: c.year,
                              month: c.month,
                              totals: c.totals,
                              compact: true,
                              identityOnly: true,
                              advanceAmount: c.advanceAmount,
                              currency:
                                  (c.totals?['currency'] ?? c.worker.currency)
                                      ?.toString(),
                            );
                            final financial = WorkerAppBarTitle(
                              group: c.group,
                              worker: c.worker,
                              year: c.year,
                              month: c.month,
                              totals: c.totals,
                              compact: true,
                              financialOnly: true,
                              showAdvance: !narrow,
                              advanceAmount: c.advanceAmount,
                              currency:
                                  (c.totals?['currency'] ?? c.worker.currency)
                                      ?.toString(),
                              onOpenAdvanceDialog: () =>
                                  _openAdvanceDialog(context),
                            );
                            final options = _optionsMenu(
                              context,
                              l: l,
                              isSpanish: isSpanish,
                              compact: narrow,
                            );
                            if (narrow) {
                              return Row(
                                children: [
                                  Expanded(child: identity),
                                  const SizedBox(width: 8),
                                  financial,
                                  const SizedBox(width: 8),
                                  options,
                                ],
                              );
                            }
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 230),
                                    child: identity,
                                  ),
                                ),
                                Center(child: financial),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: options,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
            title: WorkerAppBarTitle(
              group: c.group,
              worker: c.worker,
              year: c.year,
              month: c.month,
              totals: c.totals,
              compact: true,
              showAdvance: MediaQuery.sizeOf(context).width >= 760,
              advanceAmount: c.advanceAmount,
              currency:
                  (c.totals?['currency'] ?? c.worker.currency)?.toString(),
              onOpenAdvanceDialog: () => _openAdvanceDialog(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _optionsMenu(
                  context,
                  l: l,
                  isSpanish: isSpanish,
                  compact: MediaQuery.sizeOf(context).width < 760,
                ),
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }
}
