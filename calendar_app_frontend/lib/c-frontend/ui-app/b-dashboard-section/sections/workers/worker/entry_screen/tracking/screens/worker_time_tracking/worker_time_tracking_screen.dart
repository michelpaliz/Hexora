import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/controller/worker_time_tracking_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/appbar_title.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/stats_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/time_entry_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/time_tracking_excel_import_dialog.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // keep only if added to pubspec

class WorkerTimeTrackingScreen extends StatelessWidget {
  final Group group;
  final Worker worker;
  final int? initialYear;
  final int? initialMonth;
  final bool embedded;

  const WorkerTimeTrackingScreen({
    super.key,
    required this.group,
    required this.worker,
    this.initialYear,
    this.initialMonth,
    this.embedded = false,
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
      child: _WorkerTimeTrackingView(embedded: embedded),
    );
  }
}

class _WorkerTimeTrackingView extends StatefulWidget {
  final bool embedded;
  const _WorkerTimeTrackingView({required this.embedded});

  @override
  State<_WorkerTimeTrackingView> createState() =>
      _WorkerTimeTrackingViewState();
}

class _WorkerTimeTrackingViewState extends State<_WorkerTimeTrackingView> {
  bool _showMissingDays = false;
  bool _previewingPayrollPdf = false;
  bool _downloadingPayrollPdf = false;
  Timer? _advanceDebounce;

  @override
  void dispose() {
    _advanceDebounce?.cancel();
    super.dispose();
  }

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

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

    final result = await showDialog<double>(
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
    final created = await showModalBottomSheet<bool>(
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
    if (created == true) await c.load();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final previewPdfLabel = isSpanish ? 'Ver PDF' : 'Preview PDF';
    final downloadPdfLabel = isSpanish ? 'Descargar PDF' : 'Download PDF';
    return Consumer<WorkerTimeTrackingController>(
      builder: (context, c, _) {
        final addButton = Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _addEntry(context),
              icon: const Icon(Icons.add),
              label: Text(l.addTimeEntryCta),
            ),
          ),
        );

        final content = c.loading
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
                                repo: context.read<ITimeTrackingRepository>(),
                                getToken: () =>
                                    context.read<UserDomain>().getAuthToken(),
                                onUpdated: c.load,
                                worker: c.worker,
                                showMissingDays: _showMissingDays,
                              ),
                            ),
                            addButton,
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
                    Expanded(
                      child: WorkerAppBarTitle(
                        group: c.group,
                        worker: c.worker,
                        year: c.year,
                        month: c.month,
                        totals: c.totals,
                        compact: true,
                        advanceAmount: c.advanceAmount,
                        currency: (c.totals?['currency'] ?? c.worker.currency)
                            ?.toString(),
                        onOpenAdvanceDialog: () =>
                            _openAdvanceDialog(context),
                      ),
                    ),
                    IconButton(
                      tooltip: l.toggleEmptyDays,
                      iconSize: 20,
                      onPressed: () =>
                          setState(() => _showMissingDays = !_showMissingDays),
                      icon: Icon(
                        _showMissingDays
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    IconButton(
                      tooltip: l.exportExcel,
                      iconSize: 20,
                      onPressed: () => _exportExcel(context),
                      icon: const Icon(Icons.table_chart_outlined),
                    ),
                    IconButton(
                      tooltip: isSpanish ? 'Importar Excel' : 'Import Excel',
                      iconSize: 20,
                      onPressed: () => _openExcelImport(context),
                      icon: const Icon(Icons.upload_file_rounded),
                    ),
                    IconButton(
                      tooltip: previewPdfLabel,
                      iconSize: 20,
                      onPressed: _previewingPayrollPdf
                          ? null
                          : () => _previewPayrollPdf(context),
                      icon: _previewingPayrollPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFC62828),
                            ),
                    ),
                    IconButton(
                      tooltip: downloadPdfLabel,
                      iconSize: 20,
                      onPressed: _downloadingPayrollPdf
                          ? null
                          : () => _downloadPayrollPdf(context),
                      icon: _downloadingPayrollPdf
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
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
              advanceAmount: c.advanceAmount,
              currency: (c.totals?['currency'] ?? c.worker.currency)
                  ?.toString(),
            ),
            actions: [
              IconButton(
                tooltip: l.toggleEmptyDays,
                onPressed: () =>
                    setState(() => _showMissingDays = !_showMissingDays),
                icon: Icon(
                  _showMissingDays ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              IconButton(
                tooltip: l.exportExcel,
                onPressed: () => _exportExcel(context),
                icon: const Icon(Icons.download),
              ),
              IconButton(
                tooltip: isSpanish ? 'Importar Excel' : 'Import Excel',
                onPressed: () => _openExcelImport(context),
                icon: const Icon(Icons.upload_file_rounded),
              ),
              IconButton(
                tooltip: '$previewPdfLabel - monthly payroll (hours and pay).',
                onPressed: _previewingPayrollPdf
                    ? null
                    : () => _previewPayrollPdf(context),
                icon: _previewingPayrollPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Color(0xFFC62828),
                      ),
              ),
              IconButton(
                tooltip: '$downloadPdfLabel - monthly payroll (hours and pay).',
                onPressed: _downloadingPayrollPdf
                    ? null
                    : () => _downloadPayrollPdf(context),
                icon: _downloadingPayrollPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }
}
