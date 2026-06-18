import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/working_time_excel_import.dart';
import 'package:hexora/a-models/group_model/worker/working_time_import_instructions.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _ImportMode { excel, json }

class TimeTrackingExcelImportDialog extends StatefulWidget {
  const TimeTrackingExcelImportDialog({
    super.key,
    required this.group,
    this.initialWorker,
    this.initialMonth,
    this.embedded = false,
    this.onImported,
  });

  final Group group;
  final Worker? initialWorker;
  final DateTime? initialMonth;
  final bool embedded;
  final Future<void> Function()? onImported;

  static Future<bool> show(
    BuildContext context, {
    required Group group,
    Worker? initialWorker,
    DateTime? initialMonth,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimeTrackingExcelImportDialog(
        group: group,
        initialWorker: initialWorker,
        initialMonth: initialMonth,
      ),
    );
    return result == true;
  }

  @override
  State<TimeTrackingExcelImportDialog> createState() =>
      _TimeTrackingExcelImportDialogState();
}

class _TimeTrackingExcelImportDialogState
    extends State<TimeTrackingExcelImportDialog> {
  late final ITimeTrackingRepository _repo;
  late final UserDomain _userDomain;
  late final TextEditingController _jsonController;

  bool _workersLoading = true;
  bool _templateLoading = false;
  bool _previewLoading = false;
  bool _confirming = false;
  bool _instructionsLoading = false;
  bool _replaceExistingEntries = false;

  String? _workersError;
  String? _excelFlowError;
  String? _jsonFlowError;

  List<Worker> _workers = const <Worker>[];
  WorkingTimeImportInstructions? _instructions;

  _ImportMode _mode = _ImportMode.excel;
  String? _selectedWorkerId;
  late DateTime _selectedMonthDate;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  WorkingTimeExcelImportPreview? _excelPreview;
  WorkingTimeExcelImportPreview? _jsonPreview;
  String? _jsonPreviewMonth;
  String? _jsonPreviewWorkerId;
  int? _editingJsonRowIndex;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
    _jsonController = TextEditingController();
    final now = DateTime.now();
    final initial = widget.initialMonth ?? now;
    _selectedMonthDate = DateTime(initial.year, initial.month, 1);
    _selectedWorkerId = widget.initialWorker?.id;
    _loadWorkers();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<String> _token() => _userDomain.getAuthToken();

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  String get _monthValue =>
      '${_selectedMonthDate.year}-${_selectedMonthDate.month.toString().padLeft(2, '0')}';

  WorkingTimeExcelImportPreview? get _activePreview =>
      _mode == _ImportMode.excel ? _excelPreview : _jsonPreview;

  String? get _activeFlowError =>
      _mode == _ImportMode.excel ? _excelFlowError : _jsonFlowError;

  bool get _canPreviewExcel =>
      !_previewLoading &&
      !_confirming &&
      _selectedWorkerId != null &&
      _selectedFileBytes != null &&
      _selectedFileName != null;

  bool get _canPreviewJson =>
      !_previewLoading &&
      !_confirming &&
      _jsonController.text.trim().isNotEmpty;

  bool get _canConfirmExcel =>
      !_confirming &&
      !_previewLoading &&
      _excelPreview != null &&
      !_excelPreview!.hasInvalidRows &&
      _excelPreview!.entries.isNotEmpty;

  bool get _canConfirmJson =>
      !_confirming &&
      !_previewLoading &&
      _jsonPreview != null &&
      !_jsonPreview!.hasInvalidRows &&
      _jsonPreview!.entries.isNotEmpty;

  String? get _jsonReplaceWorkerId {
    final selected = _normalizedText(_selectedWorkerId);
    if (selected != null) return selected;
    try {
      return _parseJsonPayload().workerId;
    } catch (_) {
      return null;
    }
  }

  bool get _canReplaceJsonEntries => _jsonReplaceWorkerId != null;

  WorkingTimeImportMode? get _excelInstructions => _instructions?.excelMode;
  WorkingTimeImportMode? get _jsonInstructions => _instructions?.jsonMode;

  WorkingTimeImportExample? get _firstJsonExample {
    final examples = _jsonInstructions?.examples ?? const <WorkingTimeImportExample>[];
    return examples.isEmpty ? null : examples.first;
  }

  String _workerLabel(Worker worker) {
    final name = (worker.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    final id = worker.id.trim();
    if (id.isEmpty) return _isSpanish ? 'Trabajador' : 'Worker';
    final suffix = id.length <= 6 ? id : id.substring(id.length - 6);
    return '${_isSpanish ? 'Trabajador' : 'Worker'} $suffix';
  }

  String _cleanError(Object error) {
    final raw = error is BackendApiException
        ? error.message
        : error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('overlap') &&
        (lower.contains('existing entry') || lower.contains('existing entries'))) {
      return _isSpanish
          ? 'Las filas se solapan con horas ya registradas para este trabajador. Activa "Reemplazar horas existentes" si quieres sustituir ese mes antes de importar.'
          : 'The rows overlap with time entries already saved for this worker. Turn on "Replace existing entries" if you want to replace that month before importing.';
    }

    if (lower.contains('missing required columns')) {
      return _isSpanish
          ? 'Al Excel le faltan columnas obligatorias. Revisa que incluya Fecha, Hora inicio y Hora fin.'
          : 'The Excel file is missing required columns. Make sure it includes Fecha, Hora inicio, and Hora fin.';
    }

    if (lower.contains('invalid worker')) {
      return _isSpanish
          ? 'El trabajador seleccionado no es valido para esta importacion.'
          : 'The selected worker is not valid for this import.';
    }

    if (lower.contains('invalid month')) {
      return _isSpanish
          ? 'El mes seleccionado no es valido para esta importacion.'
          : 'The selected month is not valid for this import.';
    }

    return raw;
  }

  String _monthLabel() {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(_selectedMonthDate);
  }

  bool _isOverlapMessage(String? message) {
    if (message == null || message.trim().isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('overlap') ||
        lower.contains('existing entry') ||
        lower.contains('existing entries') ||
        lower.contains('solapa') ||
        lower.contains('registradas');
  }

  DateTime get _monthStart =>
      DateTime(_selectedMonthDate.year, _selectedMonthDate.month, 1);

  DateTime get _monthEnd =>
      DateTime(_selectedMonthDate.year, _selectedMonthDate.month + 1, 1)
          .subtract(const Duration(milliseconds: 1));

  Future<void> _loadWorkers() async {
    setState(() {
      _workersLoading = true;
      _workersError = null;
    });
    try {
      final token = await _token();
      final workers = await _repo.getWorkers(
        widget.group.id,
        token,
        status: WorkerStatus.active,
      );
      workers.sort((a, b) => _workerLabel(a).compareTo(_workerLabel(b)));
      if (!mounted) return;
      setState(() {
        _workers = workers;
        if (_selectedWorkerId == null && workers.length == 1) {
          _selectedWorkerId = workers.first.id;
        } else if (_selectedWorkerId != null &&
            !workers.any((worker) => worker.id == _selectedWorkerId)) {
          _selectedWorkerId = workers.isEmpty ? null : workers.first.id;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _workersError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _workersLoading = false);
      }
    }
  }

  void _clearExcelPreviewState() {
    _excelPreview = null;
    _excelFlowError = null;
    _replaceExistingEntries = false;
  }

  void _clearJsonPreviewState() {
    _jsonPreview = null;
    _jsonPreviewMonth = null;
    _jsonPreviewWorkerId = null;
    _jsonFlowError = null;
    _editingJsonRowIndex = null;
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonthDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: _isSpanish ? 'Seleccionar mes' : 'Select month',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _selectedMonthDate = DateTime(picked.year, picked.month, 1);
      _clearExcelPreviewState();
      _clearJsonPreviewState();
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? 'No se pudo leer el archivo Excel seleccionado.'
                : 'Could not read the selected Excel file.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileName = file.name;
      _clearExcelPreviewState();
    });
    if (_selectedWorkerId != null) {
      await _previewExcelImport();
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() {
      _templateLoading = true;
      _excelFlowError = null;
    });
    try {
      final token = await _token();
      final bytes = await _repo.downloadExcelImportTemplate(
        widget.group.id,
        token,
        month: _monthValue,
      );
      await launchFileDownload(
        bytes,
        fileName: 'time_tracking_import_$_monthValue.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _excelFlowError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _templateLoading = false);
      }
    }
  }

  Future<void> _openInstructions() async {
    setState(() => _instructionsLoading = true);
    try {
      final token = await _token();
      final instructions = await _repo.getImportInstructions(
        widget.group.id,
        token,
      );
      if (!mounted) return;
      setState(() => _instructions = instructions);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _ImportInstructionsDialog(
          isSpanish: _isSpanish,
          instructions: instructions,
          monthLabel: _monthLabel(),
          monthValue: _monthValue,
          onDownloadTemplate: () async {
            Navigator.of(dialogContext).pop();
            await _downloadTemplate();
          },
          onCopyJsonExample: _copyJsonExample,
          onUseJsonExample: _useJsonExample,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _cleanError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _instructionsLoading = false);
      }
    }
  }

  Future<void> _previewExcelImport() async {
    final workerId = _selectedWorkerId;
    final fileBytes = _selectedFileBytes;
    final fileName = _selectedFileName;
    if (workerId == null || fileBytes == null || fileName == null) return;

    setState(() {
      _previewLoading = true;
      _excelFlowError = null;
      _excelPreview = null;
    });
    try {
      final token = await _token();
      final preview = await _repo.previewExcelImport(
        widget.group.id,
        token,
        workerId: workerId,
        month: _monthValue,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      if (!mounted) return;
      setState(() => _excelPreview = preview);
    } catch (error) {
      if (!mounted) return;
      setState(() => _excelFlowError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _confirmExcelImport() async {
    final workerId = _selectedWorkerId;
    final preview = _excelPreview;
    if (workerId == null || preview == null || preview.hasInvalidRows) return;

    if (_replaceExistingEntries) {
      final approved = await _confirmReplaceExistingEntries();
      if (!approved) return;
    }

    setState(() {
      _confirming = true;
      _excelFlowError = null;
    });
    try {
      final token = await _token();
      var deletedCount = 0;
      if (_replaceExistingEntries) {
        deletedCount = await _repo.purgeTimeEntries(
          widget.group.id,
          token,
          from: _monthStart,
          to: _monthEnd,
          workerId: workerId,
        );
      }
      final result = await _repo.confirmExcelImport(
        widget.group.id,
        token,
        workerId: workerId,
        month: _monthValue,
        entries: preview.entries,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? _replaceExistingEntries
                    ? 'Importadas ${result.importedCount} filas. Se reemplazaron $deletedCount registros previos.'
                    : 'Importadas ${result.importedCount} filas correctamente.'
                : _replaceExistingEntries
                    ? 'Imported ${result.importedCount} rows. Replaced $deletedCount previous entries.'
                    : 'Imported ${result.importedCount} rows successfully.',
          ),
        ),
      );
      await _finishImportSuccess(clearExcel: true, clearJson: false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _excelFlowError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> _previewJsonImport() async {
    _ParsedJsonPayload payload;
    try {
      payload = _parseJsonPayload();
    } catch (error) {
      setState(() => _jsonFlowError = _cleanError(error));
      return;
    }

    setState(() {
      _previewLoading = true;
      _jsonFlowError = null;
      _jsonPreview = null;
      _jsonPreviewMonth = null;
      _jsonPreviewWorkerId = null;
    });
    try {
      final token = await _token();
      final effectiveWorkerId = _selectedWorkerId ?? payload.workerId;
      final preview = await _repo.previewJsonImport(
        widget.group.id,
        token,
        month: _monthValue,
        workerId: effectiveWorkerId,
        entries: payload.entries,
      );
      if (!mounted) return;
      setState(() {
        _jsonPreview = preview;
        _jsonPreviewMonth = _monthValue;
        _jsonPreviewWorkerId = effectiveWorkerId;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _jsonFlowError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _confirmJsonImport() async {
    final preview = _jsonPreview;
    final month = _jsonPreviewMonth;
    if (preview == null || month == null || preview.hasInvalidRows) return;

    final replaceWorkerId = _jsonReplaceWorkerId;
    if (_replaceExistingEntries && replaceWorkerId == null) {
      setState(() {
        _jsonFlowError = _isSpanish
            ? 'Para reemplazar horas existentes en JSON debes indicar un trabajador global o un workerId fijo en el payload.'
            : 'To replace existing hours in JSON, choose a global worker or provide a fixed workerId in the payload.';
      });
      return;
    }

    setState(() {
      _confirming = true;
      _jsonFlowError = null;
    });
    try {
      final token = await _token();
      var deletedCount = 0;
      if (_replaceExistingEntries && replaceWorkerId != null) {
        final approved = await _confirmReplaceExistingEntries();
        if (!approved) {
          if (mounted) {
            setState(() => _confirming = false);
          }
          return;
        }
        deletedCount = await _repo.purgeTimeEntries(
          widget.group.id,
          token,
          from: _monthStart,
          to: _monthEnd,
          workerId: replaceWorkerId,
        );
      }
      final result = await _repo.confirmJsonImport(
        widget.group.id,
        token,
        month: month,
        workerId: _jsonPreviewWorkerId,
        entries: preview.entries
            .map((entry) => entry.toJson())
            .toList(growable: false),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSpanish
                ? _replaceExistingEntries
                    ? 'Importadas ${result.importedCount} filas. Se reemplazaron $deletedCount registros previos.'
                    : 'Importadas ${result.importedCount} filas correctamente.'
                : _replaceExistingEntries
                    ? 'Imported ${result.importedCount} rows. Replaced $deletedCount previous entries.'
                    : 'Imported ${result.importedCount} rows successfully.',
          ),
        ),
      );
      await _finishImportSuccess(clearExcel: false, clearJson: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _jsonFlowError = _cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> _finishImportSuccess({
    required bool clearExcel,
    required bool clearJson,
  }) async {
    if (widget.embedded) {
      setState(() {
        if (clearExcel) {
          _selectedFileBytes = null;
          _selectedFileName = null;
          _clearExcelPreviewState();
        }
        if (clearJson) {
          _jsonController.clear();
          _clearJsonPreviewState();
        }
      });
      await widget.onImported?.call();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirmReplaceExistingEntries() async {
    Worker? worker;
    for (final item in _workers) {
      if (item.id == _selectedWorkerId) {
        worker = item;
        break;
      }
    }
    final workerName = worker == null ? null : _workerLabel(worker);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final t = AppTypography.of(dialogContext);
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).canvasColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _isSpanish
                ? 'Reemplazar horas existentes'
                : 'Replace existing entries',
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
          ),
          content: Text(
            _isSpanish
                ? 'Se eliminaran las horas ya registradas para ${workerName ?? 'el trabajador seleccionado'} en ${_monthLabel()} antes de importar el archivo. Esta accion no se puede deshacer.'
                : 'Existing time entries for ${workerName ?? 'the selected worker'} in ${_monthLabel()} will be deleted before importing the file. This action cannot be undone.',
            style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child:
                  Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                _isSpanish ? 'Si, reemplazar' : 'Yes, replace',
              ),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  _ParsedJsonPayload _parseJsonPayload() {
    return _parseJsonRoot().payload;
  }

  _ParsedJsonRoot _parseJsonRoot() {
    final rawText = _jsonController.text.trim();
    if (rawText.isEmpty) {
      throw FormatException(
        _isSpanish
            ? 'Pega un JSON valido antes de previsualizar.'
            : 'Paste a valid JSON payload before previewing.',
      );
    }
    final decoded = jsonDecode(rawText);
    late final Map<String, dynamic> root;
    if (decoded is List) {
      root = <String, dynamic>{'entries': decoded};
    } else if (decoded is Map) {
      root = Map<String, dynamic>.from(decoded);
    } else {
      throw FormatException(
        _isSpanish
            ? 'El contenido JSON debe ser un objeto o una lista.'
            : 'The JSON content must be an object or a list.',
      );
    }

    final rawEntries = root['entries'];
    if (rawEntries is! List || rawEntries.isEmpty) {
      throw FormatException(
        _isSpanish
            ? 'El JSON debe incluir un array "entries" con al menos una fila.'
            : 'The JSON must include an "entries" array with at least one row.',
      );
    }

    final entries = rawEntries.map<Map<String, dynamic>>((entry) {
      if (entry is Map) return Map<String, dynamic>.from(entry);
      throw FormatException(
        _isSpanish
            ? 'Cada entrada debe ser un objeto JSON.'
            : 'Each entry must be a JSON object.',
      );
    }).toList(growable: false);

    return _ParsedJsonRoot(
      root: root,
      payload: _ParsedJsonPayload(
        workerId: _normalizedText(root['workerId']?.toString()),
        entries: entries,
      ),
    );
  }

  Future<void> _copyJsonExample() async {
    final example = _firstJsonExample;
    if (example == null) return;
    await Clipboard.setData(ClipboardData(text: _prettyJson(example.body)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSpanish ? 'Ejemplo copiado al portapapeles.' : 'Example copied.',
        ),
      ),
    );
  }

  void _useJsonExample() {
    final example = _firstJsonExample;
    if (example == null) return;
    final month = _parseMonthString(example.body['month']?.toString());
    final workerId = _normalizedText(example.body['workerId']?.toString());
    setState(() {
      _mode = _ImportMode.json;
      _jsonController.text = _prettyJson(example.body);
      if (month != null) {
        _selectedMonthDate = month;
      }
      if (workerId != null &&
          _workers.any((worker) => worker.id == workerId)) {
        _selectedWorkerId = workerId;
      }
      _clearJsonPreviewState();
      _clearExcelPreviewState();
    });
  }

  DateTime? _parseMonthString(String? value) {
    final raw = _normalizedText(value);
    if (raw == null) return null;
    final parts = raw.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }
    return DateTime(year, month, 1);
  }

  String _prettyJson(Object value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  Future<void> _editJsonEntry(int index, WorkingTimeExcelImportEntry entry) async {
    _ParsedJsonRoot parsed;
    try {
      parsed = _parseJsonRoot();
    } catch (error) {
      if (!mounted) return;
      setState(() => _jsonFlowError = _cleanError(error));
      return;
    }

    if (index < 0 || index >= parsed.payload.entries.length) return;
    setState(() => _editingJsonRowIndex = index);
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _JsonEntryEditorDialog(
        isSpanish: _isSpanish,
        entry: parsed.payload.entries[index],
        fallbackEntry: entry,
      ),
    );
    if (!mounted) return;
    setState(() => _editingJsonRowIndex = null);
    if (updated == null) return;

    final rawEntries = parsed.root['entries'];
    if (rawEntries is! List || index >= rawEntries.length) return;
    rawEntries[index] = _normalizeEditedJsonEntry(updated);

    setState(() {
      _jsonController.text = _prettyJson(parsed.root);
      _clearJsonPreviewState();
    });
  }

  Map<String, dynamic> _normalizeEditedJsonEntry(Map<String, dynamic> entry) {
    final normalized = Map<String, dynamic>.from(entry);
    final date = _normalizedText(normalized['date']?.toString());
    final startTime = _normalizedText(normalized['startTime']?.toString());
    final endTime = _normalizedText(normalized['endTime']?.toString());
    final breakMinutes =
        int.tryParse(normalized['breakMinutes']?.toString().trim() ?? '') ?? 0;
    final notes = _normalizedText(normalized['notes']?.toString());

    if (date != null && startTime != null && endTime != null) {
      final derived = _deriveDateTimes(
        date: date,
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
      );
      normalized['date'] = date;
      normalized['startTime'] = startTime;
      normalized['endTime'] = endTime;
      normalized['breakMinutes'] = breakMinutes;
      normalized['startedAt'] = derived.startedAt.toUtc().toIso8601String();
      normalized['endedAt'] = derived.endedAt.toUtc().toIso8601String();
      normalized['durationMinutes'] = derived.durationMinutes;
    }

    normalized['notes'] = notes;

    for (final key in const [
      'workerId',
      'workerAlias',
      'workerDisplayName',
      'sheetName',
    ]) {
      final text = _normalizedText(normalized[key]?.toString());
      if (text == null) {
        normalized.remove(key);
      } else {
        normalized[key] = text;
      }
    }

    return normalized;
  }

  _DerivedTimes _deriveDateTimes({
    required String date,
    required String startTime,
    required String endTime,
    required int breakMinutes,
  }) {
    final start = _combineDateAndTime(date, startTime);
    var end = _combineDateAndTime(date, endTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    final totalMinutes = end.difference(start).inMinutes - breakMinutes;
    return _DerivedTimes(
      startedAt: start,
      endedAt: end,
      durationMinutes: totalMinutes < 0 ? 0 : totalMinutes,
    );
  }

  DateTime _combineDateAndTime(String date, String time) {
    final dateParts = date.split('-');
    final timeParts = time.split(':');
    if (dateParts.length != 3 || timeParts.length != 2) {
      throw FormatException(
        _isSpanish
            ? 'La fecha u hora no tienen el formato esperado.'
            : 'The date or time format is invalid.',
      );
    }
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  String? _normalizedText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      alignment: widget.embedded ? Alignment.topCenter : null,
      insetPadding: widget.embedded
          ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
          : const EdgeInsets.all(24),
      backgroundColor: Theme.of(context).canvasColor,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 790,
        ),
        child: Padding(
          padding: widget.embedded
              ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
              : const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSpanish ? 'Importar horas' : 'Import working hours',
                          style: t.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSpanish
                              ? 'Usa Excel por trabajador o el nuevo JSON estructurado. Revisa la vista previa antes de confirmar.'
                              : 'Use worker-by-worker Excel or the new structured JSON flow. Review the preview before confirming.',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _isSpanish ? 'Actualizar trabajadores' : 'Refresh workers',
                    onPressed: _workersLoading ? null : _loadWorkers,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _instructionsLoading ? null : _openInstructions,
                    icon: _instructionsLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.menu_book_rounded),
                    label: Text(
                      _isSpanish
                          ? 'Ver instrucciones de importacion'
                          : 'View import instructions',
                    ),
                  ),
                  if (!widget.embedded) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: _confirming
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ],
              ),
              SizedBox(height: widget.embedded ? 8 : 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModePill(
                    label: _isSpanish ? 'Excel' : 'Excel',
                    selected: _mode == _ImportMode.excel,
                    onTap: () => setState(() => _mode = _ImportMode.excel),
                  ),
                  _ModePill(
                    label: _isSpanish ? 'JSON' : 'JSON',
                    selected: _mode == _ImportMode.json,
                    onTap: () => setState(() => _mode = _ImportMode.json),
                  ),
                ],
              ),
              SizedBox(height: widget.embedded ? 8 : 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 360,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_mode == _ImportMode.excel)
                              _buildExcelControls(context)
                            else
                              _buildJsonControls(context),
                            if (_workersError != null) ...[
                              const SizedBox(height: 10),
                              _InlineNotice(
                                color: cs.errorContainer,
                                borderColor: cs.error.withValues(alpha: 0.35),
                                icon: Icons.error_outline_rounded,
                                text: _workersError!,
                              ),
                            ],
                            if (_activeFlowError != null) ...[
                              const SizedBox(height: 10),
                              _InlineNotice(
                                color: cs.errorContainer,
                                borderColor: cs.error.withValues(alpha: 0.35),
                                icon: Icons.error_outline_rounded,
                                text: _activeFlowError!,
                              ),
                            ],
                            if (_mode == _ImportMode.excel &&
                                _isOverlapMessage(_excelFlowError) &&
                                !_replaceExistingEntries) ...[
                              const SizedBox(height: 8),
                              _InlineNotice(
                                color: Colors.orange.withValues(alpha: 0.10),
                                borderColor:
                                    Colors.orange.withValues(alpha: 0.28),
                                icon: Icons.swap_horiz_rounded,
                                text: _isSpanish
                                    ? 'Activa "Reemplazar" antes de confirmar.'
                                    : 'Turn on "Replace" before confirming.',
                              ),
                            ],
                            if (_mode == _ImportMode.json &&
                                _isOverlapMessage(_jsonFlowError) &&
                                !_replaceExistingEntries) ...[
                              const SizedBox(height: 8),
                              _InlineNotice(
                                color: Colors.orange.withValues(alpha: 0.10),
                                borderColor:
                                    Colors.orange.withValues(alpha: 0.28),
                                icon: Icons.swap_horiz_rounded,
                                text: _canReplaceJsonEntries
                                    ? (_isSpanish
                                        ? 'Activa "Reemplazar horas existentes" antes de confirmar.'
                                        : 'Turn on "Replace existing entries" before confirming.')
                                    : (_isSpanish
                                        ? 'No se puede reemplazar hasta fijar un trabajador global o un workerId en el payload.'
                                        : 'Replacement stays unavailable until you set a global worker or a payload workerId.'),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _mode == _ImportMode.excel
                                  ? (_isSpanish
                                      ? 'Excel: una persona por archivo. Elige trabajador, mes y revisa la vista previa.'
                                      : 'Excel: one worker per file. Choose a worker, month, and review the preview.')
                                  : (_isSpanish
                                      ? 'JSON: puedes importar varias filas y varios trabajadores en una sola peticion.'
                                      : 'JSON: you can import multiple rows and workers in a single request.'),
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!widget.embedded) ...[
                              OutlinedButton(
                                onPressed: _confirming
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                                child: Text(
                                  MaterialLocalizations.of(context)
                                      .cancelButtonLabel,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            FilledButton.icon(
                              onPressed: _mode == _ImportMode.excel
                                  ? (_canConfirmExcel ? _confirmExcelImport : null)
                                  : (_canConfirmJson ? _confirmJsonImport : null),
                              icon: _confirming
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded),
                              label: Text(
                                _isSpanish
                                    ? 'Confirmar importacion'
                                    : 'Confirm import',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPreviewArea(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcelControls(BuildContext context) {
    final mode = _excelInstructions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mode?.label ?? (_isSpanish ? 'Excel por trabajador' : 'Worker Excel'),
          style: AppTypography.of(context).bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          mode?.description ??
              (_isSpanish
                  ? 'Importa un solo trabajador por archivo Excel.'
                  : 'Import a single worker per Excel file.'),
          style: AppTypography.of(context).bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'excel-worker-${_selectedWorkerId ?? 'none'}-${_workers.length}',
          ),
          initialValue: _selectedWorkerId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _isSpanish ? 'Trabajador' : 'Worker',
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          items: _workers
              .map(
                (worker) => DropdownMenuItem<String>(
                  value: worker.id,
                  child: Text(
                    _workerLabel(worker),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: _workersLoading || _previewLoading || _confirming
              ? null
              : (value) {
                  setState(() {
                    _selectedWorkerId = value;
                    _clearExcelPreviewState();
                  });
                },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _previewLoading || _confirming ? null : _pickMonth,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(_monthLabel()),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _templateLoading || _confirming ? null : _downloadTemplate,
          icon: _templateLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_for_offline_outlined),
          label: Text(
            _isSpanish ? 'Descargar plantilla' : 'Download template',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _previewLoading || _confirming ? null : _pickFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(
            _selectedFileName == null
                ? (_isSpanish ? 'Subir Excel' : 'Upload Excel')
                : (_isSpanish ? 'Cambiar Excel' : 'Change Excel'),
          ),
        ),
        if (_selectedFileName != null) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _canPreviewExcel ? _previewExcelImport : null,
            icon: _previewLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.preview_outlined),
            label:
                Text(_isSpanish ? 'Actualizar vista previa' : 'Refresh preview'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedFileName\n${_formatFileSize(_selectedFileBytes?.length ?? 0)}',
                    style: AppTypography.of(context).bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  onPressed: _previewLoading || _confirming
                      ? null
                      : () {
                          setState(() {
                            _selectedFileBytes = null;
                            _selectedFileName = null;
                            _clearExcelPreviewState();
                          });
                        },
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 14,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: _isSpanish ? 'Quitar' : 'Remove',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: _isSpanish
                ? 'Borra las horas del trabajador en ${_monthLabel()} antes de importar.'
                : 'Delete worker hours for ${_monthLabel()} before importing.',
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              decoration: BoxDecoration(
                color: _replaceExistingEntries
                    ? Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.35)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _replaceExistingEntries
                      ? Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.4)
                      : Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: _replaceExistingEntries
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isSpanish
                          ? 'Reemplazar horas existentes'
                          : 'Replace existing entries',
                      style: AppTypography.of(context).bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _replaceExistingEntries
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _replaceExistingEntries,
                    onChanged: _confirming || _previewLoading
                        ? null
                        : (value) => setState(
                              () => _replaceExistingEntries = value,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJsonControls(BuildContext context) {
    final mode = _jsonInstructions;
    final example = _firstJsonExample;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mode?.label ?? (_isSpanish ? 'JSON estructurado' : 'Structured JSON'),
          style: AppTypography.of(context).bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          mode?.description ??
              (_isSpanish
                  ? 'Importa varias filas y varios trabajadores en una sola peticion JSON.'
                  : 'Import multiple rows and workers in a single JSON request.'),
          style: AppTypography.of(context).bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _previewLoading || _confirming ? null : _pickMonth,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(_monthLabel()),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          key: ValueKey(
            'json-worker-${_selectedWorkerId ?? 'none'}-${_workers.length}',
          ),
          initialValue: _selectedWorkerId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _isSpanish
                ? 'Trabajador global opcional'
                : 'Optional global worker',
            prefixIcon: const Icon(Icons.group_outlined),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                _isSpanish
                    ? 'Resolver por fila (workerId / alias / nombre)'
                    : 'Resolve per row (workerId / alias / name)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ..._workers.map(
              (worker) => DropdownMenuItem<String?>(
                value: worker.id,
                child: Text(
                  _workerLabel(worker),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _previewLoading || _confirming
              ? null
              : (value) {
                  setState(() {
                    _selectedWorkerId = value;
                    _clearJsonPreviewState();
                  });
                },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: example == null ? null : _copyJsonExample,
                icon: const Icon(Icons.copy_all_rounded),
                label: Text(_isSpanish ? 'Copiar ejemplo' : 'Copy example'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: example == null ? null : _useJsonExample,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: Text(_isSpanish ? 'Usar ejemplo' : 'Use example'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _jsonController,
          enabled: !_previewLoading && !_confirming,
          minLines: 12,
          maxLines: 16,
          onChanged: (_) {
            setState(() {
              if (_jsonPreview != null || _jsonFlowError != null) {
                _clearJsonPreviewState();
              }
            });
          },
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 12.5,
          ),
          decoration: InputDecoration(
            alignLabelWithHint: true,
            labelText: _isSpanish ? 'Payload JSON' : 'JSON payload',
            hintText: _isSpanish
                ? '{\n  "month": "2026-04",\n  "entries": [ ... ]\n}'
                : '{\n  "month": "2026-04",\n  "entries": [ ... ]\n}',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSpanish
              ? 'Puedes pegar un objeto con "entries" o una lista directa de filas. El mes y el trabajador global se toman desde esta pantalla.'
              : 'You can paste an object with "entries" or a direct row list. Month and global worker come from this screen.',
          style: AppTypography.of(context).bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: _canReplaceJsonEntries
              ? (_isSpanish
                  ? 'Borra las horas del trabajador en ${_monthLabel()} antes de importar este JSON.'
                  : 'Delete the worker hours in ${_monthLabel()} before importing this JSON.')
              : (_isSpanish
                  ? 'Para reemplazar horas en JSON necesitas un trabajador global o un workerId fijo en el payload.'
                  : 'To replace hours in JSON you need a global worker or a fixed workerId in the payload.'),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            decoration: BoxDecoration(
              color: _replaceExistingEntries
                  ? Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.35)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _replaceExistingEntries
                    ? Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.4)
                    : Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 14,
                  color: _replaceExistingEntries
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isSpanish
                        ? 'Reemplazar horas existentes'
                        : 'Replace existing entries',
                    style: AppTypography.of(context).bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _replaceExistingEntries
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                Switch.adaptive(
                  value: _replaceExistingEntries,
                  onChanged: !_canReplaceJsonEntries || _confirming || _previewLoading
                      ? null
                      : (value) => setState(
                            () => _replaceExistingEntries = value,
                          ),
                ),
              ],
            ),
          ),
        ),
        if (!_canReplaceJsonEntries) ...[
          const SizedBox(height: 8),
          Text(
            _isSpanish
                ? 'Define un trabajador global o un workerId fijo para poder reemplazar el mes completo antes de importar.'
                : 'Set a global worker or a fixed workerId to replace the full month before importing.',
            style: AppTypography.of(context).bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _canPreviewJson ? _previewJsonImport : null,
          icon: _previewLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.preview_outlined),
          label: Text(_isSpanish ? 'Previsualizar JSON' : 'Preview JSON'),
        ),
      ],
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final preview = _activePreview;

    if (_workersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (preview == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _mode == _ImportMode.excel
                  ? (_isSpanish
                      ? 'Sube un Excel y pulsa vista previa para revisar las filas antes de importarlas.'
                      : 'Upload an Excel file and preview it before importing the rows.')
                  : (_isSpanish
                      ? 'Pega el JSON y pulsa previsualizar para validar las filas antes de importarlas.'
                      : 'Paste the JSON payload and preview it before importing the rows.'),
              style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 13,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${preview.validRowCount}',
                style: t.bodySmall.copyWith(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                _isSpanish ? 'validas' : 'valid',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              if (preview.invalidRowCount > 0) ...[
                const SizedBox(width: 12),
                Icon(Icons.error_outline_rounded, size: 13, color: cs.error),
                const SizedBox(width: 4),
                Text(
                  '${preview.invalidRowCount}',
                  style: t.bodySmall.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  _isSpanish ? 'invalidas' : 'invalid',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                '·',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${preview.rowCount} ${_isSpanish ? 'filas' : 'rows'}',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              if ((preview.timeZone ?? '').trim().isNotEmpty) ...[
                Icon(
                  Icons.schedule_outlined,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  preview.timeZone!,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 10),
              ],
              if ((preview.sheetName ?? '').trim().isNotEmpty) ...[
                Icon(
                  _mode == _ImportMode.excel
                      ? Icons.table_chart_outlined
                      : Icons.data_object_rounded,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    preview.sheetName!,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (preview.warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          _InlineNotice(
            color: Colors.amber.withValues(alpha: 0.12),
            borderColor: Colors.amber.withValues(alpha: 0.35),
            icon: Icons.warning_amber_rounded,
            text: preview.warnings.join('\n'),
          ),
        ],
        if (preview.hasInvalidRows) ...[
          const SizedBox(height: 8),
          _InlineNotice(
            color: cs.errorContainer,
            borderColor: cs.error.withValues(alpha: 0.35),
            icon: Icons.rule_folder_outlined,
            text: _isSpanish
                ? 'Hay filas invalidas. Corrige el origen y vuelve a previsualizar.'
                : 'Some rows are invalid. Fix the source data and preview again.',
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: preview.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 3),
              itemBuilder: (context, index) => _PreviewEntryCard(
                entry: preview.entries[index],
                isSpanish: _isSpanish,
                canEdit: _mode == _ImportMode.json,
                isEditing: _editingJsonRowIndex == index,
                onTap: _mode == _ImportMode.json
                    ? () => _editJsonEntry(index, preview.entries[index])
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParsedJsonPayload {
  const _ParsedJsonPayload({
    required this.entries,
    this.workerId,
  });

  final String? workerId;
  final List<Map<String, dynamic>> entries;
}

class _ParsedJsonRoot {
  const _ParsedJsonRoot({
    required this.root,
    required this.payload,
  });

  final Map<String, dynamic> root;
  final _ParsedJsonPayload payload;
}

class _DerivedTimes {
  const _DerivedTimes({
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.16) : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.of(context).bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _ImportInstructionsDialog extends StatelessWidget {
  const _ImportInstructionsDialog({
    required this.isSpanish,
    required this.instructions,
    required this.monthLabel,
    required this.monthValue,
    required this.onDownloadTemplate,
    required this.onCopyJsonExample,
    required this.onUseJsonExample,
  });

  final bool isSpanish;
  final WorkingTimeImportInstructions instructions;
  final String monthLabel;
  final String monthValue;
  final Future<void> Function() onDownloadTemplate;
  final Future<void> Function() onCopyJsonExample;
  final VoidCallback onUseJsonExample;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final excel = instructions.excelMode;
    final jsonMode = instructions.jsonMode;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Theme.of(context).canvasColor,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpanish
                                ? 'Instrucciones de importacion'
                                : 'Import instructions',
                            style: t.titleLarge.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSpanish
                                ? 'Datos cargados desde el servidor para los formatos soportados.'
                                : 'Server-provided guidance for the supported import formats.',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: excel?.label ?? 'Excel'),
                    Tab(text: jsonMode?.label ?? 'JSON'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _InstructionModeView(
                        isSpanish: isSpanish,
                        mode: excel,
                        workers: instructions.workers,
                        monthLabel: monthLabel,
                        monthValue: monthValue,
                        showTemplateButton: true,
                        onDownloadTemplate: onDownloadTemplate,
                        onCopyJsonExample: null,
                        onUseJsonExample: null,
                      ),
                      _InstructionModeView(
                        isSpanish: isSpanish,
                        mode: jsonMode,
                        workers: instructions.workers,
                        monthLabel: monthLabel,
                        monthValue: monthValue,
                        showTemplateButton: false,
                        onDownloadTemplate: null,
                        onCopyJsonExample: onCopyJsonExample,
                        onUseJsonExample: onUseJsonExample,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionModeView extends StatelessWidget {
  const _InstructionModeView({
    required this.isSpanish,
    required this.mode,
    required this.workers,
    required this.monthLabel,
    required this.monthValue,
    required this.showTemplateButton,
    this.onDownloadTemplate,
    this.onCopyJsonExample,
    this.onUseJsonExample,
  });

  final bool isSpanish;
  final WorkingTimeImportMode? mode;
  final List<WorkingTimeImportWorkerRef> workers;
  final String monthLabel;
  final String monthValue;
  final bool showTemplateButton;
  final Future<void> Function()? onDownloadTemplate;
  final Future<void> Function()? onCopyJsonExample;
  final VoidCallback? onUseJsonExample;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final effectiveMode = mode;
    if (effectiveMode == null) {
      return Center(
        child: Text(
          isSpanish
              ? 'No hay instrucciones disponibles para este modo.'
              : 'No instructions are available for this mode.',
          style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    final example = effectiveMode.examples.isEmpty ? null : effectiveMode.examples.first;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            effectiveMode.description,
            style: t.bodyMedium.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (showTemplateButton && onDownloadTemplate != null) ...[
            FilledButton.tonalIcon(
              onPressed: onDownloadTemplate,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text(
                isSpanish
                    ? 'Descargar plantilla para $monthValue'
                    : 'Download template for $monthValue',
              ),
            ),
            const SizedBox(height: 12),
          ],
          _InfoBlock(
            title: isSpanish ? 'Reglas' : 'Rules',
            child: _BulletedTextList(items: effectiveMode.rules),
          ),
          const SizedBox(height: 12),
          _InfoBlock(
            title: isSpanish ? 'Campos de subida' : 'Upload fields',
            child: _FieldList(fields: effectiveMode.upload.fields),
          ),
          if (effectiveMode.sheetFormat != null) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              title: isSpanish ? 'Formato de hoja' : 'Sheet format',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effectiveMode.sheetFormat!.oneWorkerPerFile
                        ? (isSpanish
                            ? 'Un trabajador por archivo Excel. Una hoja de horas por archivo.'
                            : 'One worker per Excel file. One timesheet per file.')
                        : (isSpanish
                            ? 'El servidor acepta varios trabajadores por archivo.'
                            : 'The server accepts multiple workers per file.'),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...effectiveMode.sheetFormat!.headerAliases.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${entry.key}: ${entry.value.join(', ')}',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (effectiveMode.entryFields.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              title: isSpanish ? 'Campos por fila' : 'Entry fields',
              child: _FieldList(fields: effectiveMode.entryFields),
            ),
          ],
          if (example != null) ...[
            const SizedBox(height: 12),
            _InfoBlock(
              title: isSpanish ? 'Ejemplo' : 'Example',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example.title,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(example.body),
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (onCopyJsonExample != null || onUseJsonExample != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onCopyJsonExample != null)
                          FilledButton.tonalIcon(
                            onPressed: onCopyJsonExample,
                            icon: const Icon(Icons.copy_all_rounded),
                            label: Text(
                              isSpanish ? 'Copiar ejemplo' : 'Copy example',
                            ),
                          ),
                        if (onUseJsonExample != null)
                          FilledButton.tonalIcon(
                            onPressed: onUseJsonExample,
                            icon: const Icon(Icons.auto_fix_high_rounded),
                            label: Text(
                              isSpanish ? 'Usar ejemplo' : 'Use example',
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _InfoBlock(
            title: isSpanish ? 'Trabajadores disponibles' : 'Workers available',
            child: workers.isEmpty
                ? Text(
                    isSpanish
                        ? 'No hay trabajadores devueltos por el servidor.'
                        : 'The server did not return workers.',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workers
                        .map(
                          (worker) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              worker.alias == null || worker.alias!.trim().isEmpty
                                  ? worker.displayName
                                  : '${worker.displayName} (alias: ${worker.alias})',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _InfoBlock(
            title: isSpanish ? 'Endpoints' : 'Endpoints',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (effectiveMode.endpoint.preview != null)
                  Text(
                    'Preview: ${effectiveMode.endpoint.preview}',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (effectiveMode.endpoint.confirm != null)
                  Text(
                    'Confirm: ${effectiveMode.endpoint.confirm}',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (effectiveMode.endpoint.template != null)
                  Text(
                    'Template: ${effectiveMode.endpoint.template}',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                const SizedBox(height: 6),
                Text(
                  isSpanish
                      ? 'Mes activo: $monthLabel'
                      : 'Active month: $monthLabel',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletedTextList extends StatelessWidget {
  const _BulletedTextList({
    required this.items,
  });

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Text(
        '-',
        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _FieldList extends StatelessWidget {
  const _FieldList({
    required this.fields,
  });

  final List<WorkingTimeImportField> fields;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (fields.isEmpty) {
      return Text(
        '-',
        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${field.required ? '* ' : ''}${field.name} (${field.type}): ${field.description}',
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PreviewEntryCard extends StatelessWidget {
  const _PreviewEntryCard({
    required this.entry,
    required this.isSpanish,
    this.canEdit = false,
    this.isEditing = false,
    this.onTap,
  });

  final WorkingTimeExcelImportEntry entry;
  final bool isSpanish;
  final bool canEdit;
  final bool isEditing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasIssues = entry.issues.isNotEmpty;

    final notesText = (entry.notes ?? '').trim();
    final breakMins = entry.breakMinutes;
    final durationMins = entry.durationMinutes;

    final trailingStats = [
      if (breakMins > 0) '${breakMins}m ${isSpanish ? 'pausa' : 'break'}',
      '${durationMins}min',
      if (notesText.isNotEmpty) notesText,
    ].join('  ·  ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: hasIssues
              ? cs.errorContainer.withValues(alpha: 0.20)
              : cs.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasIssues
                ? cs.error.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${isSpanish ? 'Fila' : 'Row'} ${entry.rowNumber}',
                  style: t.bodySmall.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.date}  ·  ${entry.startTime} - ${entry.endTime}',
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingStats.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    trailingStats,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                hasIssues
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: hasIssues ? cs.error : Colors.green.shade600,
                size: 15,
              ),
              if (canEdit) ...[
                const SizedBox(width: 8),
                if (isEditing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.edit_outlined,
                    color: cs.primary,
                    size: 15,
                  ),
              ],
            ],
          ),
          if (hasIssues) ...entry.issues.map(
            (issue) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: cs.error, size: 13),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      issue,
                      style: t.bodySmall.copyWith(
                        color: cs.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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
    );
  }
}

class _JsonEntryEditorDialog extends StatefulWidget {
  const _JsonEntryEditorDialog({
    required this.isSpanish,
    required this.entry,
    required this.fallbackEntry,
  });

  final bool isSpanish;
  final Map<String, dynamic> entry;
  final WorkingTimeExcelImportEntry fallbackEntry;

  @override
  State<_JsonEntryEditorDialog> createState() => _JsonEntryEditorDialogState();
}

class _JsonEntryEditorDialogState extends State<_JsonEntryEditorDialog> {
  late final TextEditingController _workerIdCtrl;
  late final TextEditingController _workerAliasCtrl;
  late final TextEditingController _workerDisplayNameCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _breakCtrl;
  late final TextEditingController _notesCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _workerIdCtrl =
        TextEditingController(text: entry['workerId']?.toString() ?? '');
    _workerAliasCtrl =
        TextEditingController(text: entry['workerAlias']?.toString() ?? '');
    _workerDisplayNameCtrl = TextEditingController(
      text: entry['workerDisplayName']?.toString() ?? '',
    );
    _dateCtrl = TextEditingController(
      text: entry['date']?.toString() ?? widget.fallbackEntry.date,
    );
    _startCtrl = TextEditingController(
      text: entry['startTime']?.toString() ?? widget.fallbackEntry.startTime,
    );
    _endCtrl = TextEditingController(
      text: entry['endTime']?.toString() ?? widget.fallbackEntry.endTime,
    );
    _breakCtrl = TextEditingController(
      text:
          (entry['breakMinutes'] ?? widget.fallbackEntry.breakMinutes).toString(),
    );
    _notesCtrl =
        TextEditingController(text: entry['notes']?.toString() ?? '');
  }

  @override
  void dispose() {
    _workerIdCtrl.dispose();
    _workerAliasCtrl.dispose();
    _workerDisplayNameCtrl.dispose();
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _breakCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final date = _dateCtrl.text.trim();
    final start = _startCtrl.text.trim();
    final end = _endCtrl.text.trim();
    final breakMinutes = int.tryParse(_breakCtrl.text.trim());
    if (!_validDate(date) || !_validTime(start) || !_validTime(end)) {
      setState(() {
        _error = widget.isSpanish
            ? 'Usa Fecha YYYY-MM-DD y horas HH:mm.'
            : 'Use date YYYY-MM-DD and times HH:mm.';
      });
      return;
    }
    if (breakMinutes == null || breakMinutes < 0) {
      setState(() {
        _error = widget.isSpanish
            ? 'El descanso debe ser un numero valido.'
            : 'Break minutes must be a valid number.';
      });
      return;
    }

    final updated = Map<String, dynamic>.from(widget.entry)
      ..['workerId'] = _workerIdCtrl.text.trim()
      ..['workerAlias'] = _workerAliasCtrl.text.trim()
      ..['workerDisplayName'] = _workerDisplayNameCtrl.text.trim()
      ..['date'] = date
      ..['startTime'] = start
      ..['endTime'] = end
      ..['breakMinutes'] = breakMinutes
      ..['notes'] = _notesCtrl.text.trim();
    Navigator.of(context).pop(updated);
  }

  bool _validDate(String value) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

  bool _validTime(String value) =>
      RegExp(r'^\d{2}:\d{2}$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: Theme.of(context).canvasColor,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.isSpanish ? 'Editar fila JSON' : 'Edit JSON row',
        style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _workerIdCtrl,
                      decoration: const InputDecoration(labelText: 'workerId'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _workerAliasCtrl,
                      decoration: const InputDecoration(labelText: 'workerAlias'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _workerDisplayNameCtrl,
                decoration:
                    const InputDecoration(labelText: 'workerDisplayName'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateCtrl,
                      decoration: InputDecoration(
                        labelText: widget.isSpanish ? 'Fecha' : 'Date',
                        hintText: '2026-04-01',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _startCtrl,
                      decoration: InputDecoration(
                        labelText: widget.isSpanish ? 'Inicio' : 'Start',
                        hintText: '08:00',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _endCtrl,
                      decoration: InputDecoration(
                        labelText: widget.isSpanish ? 'Fin' : 'End',
                        hintText: '15:20',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _breakCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      widget.isSpanish ? 'Descanso (min)' : 'Break minutes',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.isSpanish ? 'Notas' : 'Notes',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: t.bodySmall.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.isSpanish ? 'Guardar' : 'Save'),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.text,
  });

  final Color color;
  final Color borderColor;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
