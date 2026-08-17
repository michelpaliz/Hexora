import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_document_draft_flow.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_pdf_preview_dialog.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:intl/intl.dart';

class PresupuestoTemplateEditorScreen extends StatefulWidget {
  const PresupuestoTemplateEditorScreen({
    super.key,
    required this.api,
    required this.groupId,
    this.presupuestoId,
    this.presupuestoNumber,
    this.initialBudget,
    this.templateOnly = false,
    this.createNewTemplate = false,
    this.createDocumentDraft = false,
    this.onDocumentSaved,
    this.clientSearch,
  }) : assert(templateOnly || createDocumentDraft || presupuestoId != null);

  final PresupuestosApi api;
  final String groupId;
  final String? presupuestoId;
  final String? presupuestoNumber;
  final Map<String, dynamic>? initialBudget;
  final bool templateOnly;
  final bool createNewTemplate;
  final bool createDocumentDraft;
  final Future<void> Function()? onDocumentSaved;
  final Future<List<GroupClient>> Function(String search)? clientSearch;

  @override
  State<PresupuestoTemplateEditorScreen> createState() =>
      _PresupuestoTemplateEditorScreenState();
}

class _EditorStep {
  const _EditorStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
}

class _TemplateVariableField {
  const _TemplateVariableField({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.isAutomatic = false,
    this.isUsedInTemplate = true,
    this.readOnly = false,
    this.calculation,
  });

  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isAutomatic;
  final bool isUsedInTemplate;
  final bool readOnly;
  final _VariableCalculation? calculation;
}

class _VariableCalculation {
  const _VariableCalculation({
    required this.operation,
    required this.operands,
    required this.format,
    required this.currency,
    required this.readOnly,
  });

  factory _VariableCalculation.fromMap(Map<String, dynamic> map) {
    return _VariableCalculation(
      operation: _string(map['operation']) ?? '',
      operands: map['operands'] is List
          ? (map['operands'] as List)
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const [],
      format: _string(map['format']) ?? '',
      currency: _string(map['currency']) ?? 'EUR',
      readOnly: map['readOnly'] == true,
    );
  }

  final String operation;
  final List<String> operands;
  final String format;
  final String currency;
  final bool readOnly;
}

class _PresupuestoTemplateEditorScreenState
    extends State<PresupuestoTemplateEditorScreen> {
  final _name = TextEditingController();
  final _instagram = TextEditingController();
  final _website = TextEditingController();
  final _watermark = TextEditingController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _intro = TextEditingController();
  final _previewHorizontalScrollController = ScrollController();
  final Map<String, TextEditingController> _variables = {};
  final List<_TemplateSectionState> _sections = [];
  final List<_TemplateImageState> _images = [];
  late final PresupuestoDocumentDraftFlow _documentFlow;
  final Map<String, String> _loadedDocumentVariables = {};
  final Map<String, _TemplateVariableField> _variableFieldDefinitions = {};
  dynamic _variableFieldsSource = const <dynamic>[];
  String _variableSchemaKey = 'unselected';

  List<Map<String, dynamic>> _templates = const [];
  List<Map<String, dynamic>> _defaultTemplates = const [];
  Map<String, dynamic> _sourceContent = const {};
  Map<String, dynamic>? _selectedDefaultTemplate;
  String? _selectedDefaultKey;
  String? _selectedTemplateSnapshot;
  String? _templateId;
  String? _logoUrl;
  int _activeStep = 0;
  bool _loading = true;
  bool _saving = false;
  bool _creatingDocumentFromTemplate = false;
  bool _downloading = false;
  bool _previewing = false;
  String? _loadErrorMessage;
  String? _creatingDefaultKey;
  String? _deletingTemplateId;
  String? _previewingDefaultKey;
  String? _previewingSavedTemplateId;
  final ClientsApi _clientsApi = ClientsApi();
  String? _selectedClientId;
  String? _selectedClientName;

  @override
  void initState() {
    super.initState();
    _documentFlow = PresupuestoDocumentDraftFlow(
      api: widget.api,
      presupuestoId: widget.presupuestoId,
    );
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _instagram.dispose();
    _website.dispose();
    _watermark.dispose();
    _title.dispose();
    _subtitle.dispose();
    _intro.dispose();
    _previewHorizontalScrollController.dispose();
    for (final controller in _variables.values) {
      controller.dispose();
    }
    for (final section in _sections) {
      section.dispose();
    }
    for (final image in _images) {
      image.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadErrorMessage = null;
    });
    try {
      if (!widget.templateOnly) {
        final presupuestoId = _documentFlow.presupuestoId;
        if (presupuestoId != null) {
          final responses = await Future.wait<Map<String, dynamic>>([
            widget.api.getTemplateContent(presupuestoId),
            widget.api.getTemplateVariables(presupuestoId),
          ]);
          final payload = responses[0];
          final content = _asMap(payload['content']) ?? const {};
          _templateId =
              _string(content['templateId']) ?? _string(payload['templateId']);
          _hydrate(content);
          _applyLoadedDocumentVariables(responses[1]);
          _selectedClientId = _string(payload['clientId']) ??
              _string(content['clientId']) ??
              _string(widget.initialBudget?['clientId']);
          _selectedClientName = _selectedClientId == null
              ? null
              : _variables['CLIENTE']?.text.trim();
          _variableSchemaKey = 'document:$presupuestoId';
          return;
        }
        if (!widget.createDocumentDraft) {
          throw Exception(
              'Selecciona un presupuesto para editar el documento.');
        }
      }

      if (widget.createDocumentDraft && _documentFlow.presupuestoId == null) {
        final defaultsPayload = await widget.api.listDefaultTemplates();
        final defaults = defaultsPayload['templates'];
        _defaultTemplates = defaults is List
            ? defaults
                .map(_asMap)
                .whereType<Map<String, dynamic>>()
                .toList(growable: false)
            : const [];
        _templateId = null;
        _selectedDefaultKey = null;
        _selectedDefaultTemplate = null;
        _variableSchemaKey = 'unselected';
        _hydrate(_newDocumentSource());
        return;
      }

      final payload = await widget.api.listTemplatesByGroup(widget.groupId);
      final defaultsPayload = await widget.api.listDefaultTemplates();
      final templates = payload['templates'];
      _templates = templates is List
          ? templates
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
          : const [];
      final defaults = defaultsPayload['templates'];
      _defaultTemplates = defaults is List
          ? defaults
              .map(_asMap)
              .whereType<Map<String, dynamic>>()
              .toList(growable: false)
          : const [];
      final defaultTemplate = _asMap(payload['defaultTemplate']);
      final savedContent = _savedContent(widget.initialBudget);
      final firstTemplate = _templates.isNotEmpty ? _templates.first : null;
      final source = <String, dynamic>{
        ...?defaultTemplate,
        ...?firstTemplate,
        ...?savedContent,
      };
      _templateId = _string(source['_id']) ??
          _string(source['id']) ??
          _string(source['templateId']);
      final matchingTemplate = _templateById(_templateId);
      if (matchingTemplate != null && savedContent == null) {
        _hydrate(matchingTemplate);
      } else {
        _hydrate(source);
      }
      if (widget.templateOnly && widget.createNewTemplate) {
        _newTemplate();
      } else if (widget.createDocumentDraft) {
        _templateId = null;
        _hydrate(_newDocumentSource());
      }
    } on PresupuestosApiException catch (e) {
      _loadErrorMessage = e.message;
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      _loadErrorMessage = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        showErrorSnack(context, _loadErrorMessage!);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _templateById(String? id) {
    final needle = id?.trim();
    if (needle == null || needle.isEmpty) return null;
    for (final template in _templates) {
      final value = _string(template['_id']) ?? _string(template['id']);
      if (value == needle) return template;
    }
    return null;
  }

  void _selectTemplate(String? id) {
    final template = _templateById(id);
    if (template == null) return;
    setState(() {
      _templateId = id;
      _hydrate(template);
    });
  }

  Future<void> _useDefaultTemplate(Map<String, dynamic> template) async {
    final key = _string(template['key']);
    if (key == null || key.isEmpty || _creatingDefaultKey != null) return;

    if (!widget.templateOnly) {
      if (_selectedDefaultKey != null &&
          _selectedDefaultKey != key &&
          _hasTemplateEdits()) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cambiar tipo de presupuesto'),
            content: const Text(
              'Los cambios actuales se reemplazaran por el contenido de la nueva plantilla.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Cambiar plantilla'),
              ),
            ],
          ),
        );
        if (replace != true || !mounted) return;
      }

      final content = _templateContent(template);
      final sharedVariables = <String, String>{};
      final currentClient = _variables['CLIENTE']?.text;
      if (_selectedDefaultKey != null &&
          currentClient != null &&
          _readVariableFieldDefinitions(content['variableFields'])
              .containsKey('CLIENTE')) {
        sharedVariables['CLIENTE'] = currentClient;
      }
      setState(() {
        _selectedDefaultKey = key;
        _selectedDefaultTemplate = Map<String, dynamic>.from(template);
        _variableSchemaKey = 'default:$key';
        _templateId = null;
        _hydrate(content, preservedVariables: sharedVariables);
        _activeStep = 0;
        _selectedTemplateSnapshot =
            jsonEncode(_payload(includeTemplateId: false));
      });
      return;
    }

    setState(() => _creatingDefaultKey = key);
    try {
      final created = await widget.api.createTemplateFromDefault(
        key: key,
        groupId: widget.groupId,
      );
      final createdTemplate = _asMap(created['template']) ?? created;
      final id =
          _string(createdTemplate['_id']) ?? _string(createdTemplate['id']);
      setState(() {
        if (id != null && id.isNotEmpty) _templateId = id;
        _variableSchemaKey = 'template:${id ?? key}';
        _templates = [
          createdTemplate,
          ..._templates.where((item) {
            final existingId = _string(item['_id']) ?? _string(item['id']);
            return existingId != id;
          }),
        ];
        _hydrate(createdTemplate);
      });
      if (mounted) showSuccessSnack(context, 'Plantilla creada.');
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _creatingDefaultKey = null);
    }
  }

  bool _hasTemplateEdits() {
    final snapshot = _selectedTemplateSnapshot;
    if (snapshot == null) return false;
    return snapshot != jsonEncode(_payload(includeTemplateId: false));
  }

  Map<String, dynamic> _templateContent(Map<String, dynamic> template) {
    for (final key in const ['content', 'templateContent']) {
      final content = _asMap(template[key]);
      if (content != null) {
        final merged = <String, dynamic>{
          ...template,
          ...content,
          'key': template['key']
        };
        merged.remove('content');
        merged.remove('templateContent');
        return merged;
      }
    }
    return Map<String, dynamic>.from(template);
  }

  Map<String, dynamic>? _savedContent(Map<String, dynamic>? budget) {
    if (budget == null) return null;
    for (final key in const [
      'templateContent',
      'presupuestoTemplateContent',
      'documentTemplateContent',
    ]) {
      final value = _asMap(budget[key]);
      if (value != null) return value;
    }
    return null;
  }

  void _hydrate(
    Map<String, dynamic> source, {
    Map<String, String> preservedVariables = const {},
  }) {
    _sourceContent = Map<String, dynamic>.from(source);
    final cleaningTemplate = _isCleaningTemplateSource(source);
    final sourceName = _string(source['name']);
    final sourceTitle = _string(source['title']);
    _name.text = cleaningTemplate && _isGardenPoolText(sourceName)
        ? 'Limpieza anual de escaleras y zonas comunes'
        : sourceName ?? 'Plantilla presupuesto';
    final header = _asMap(source['header']) ?? const {};
    _instagram.text = _string(header['instagram']) ?? '';
    _website.text = _string(header['website']) ?? '';
    _logoUrl = _string(header['logoUrl']);
    _watermark.text = _string(source['watermark']) ?? '';
    _title.text = cleaningTemplate && _isGardenPoolText(sourceTitle)
        ? 'Limpieza anual de escaleras y zonas comunes'
        : sourceTitle ?? '';
    _subtitle.text = _string(source['subtitle']) ?? '';
    _intro.text = _string(source['intro']) ?? '';

    for (final controller in _variables.values) {
      controller.dispose();
    }
    _variables.clear();
    final variables = _asMap(source['variables']) ?? const {};
    _variableFieldsSource = source['variableFields'] ?? const <dynamic>[];
    _variableFieldDefinitions
      ..clear()
      ..addAll(_readVariableFieldDefinitions(_variableFieldsSource));
    final variableFieldValues = _readVariableFieldValues(_variableFieldsSource);
    for (final key in _variableFieldDefinitions.keys) {
      _variables[key] = TextEditingController(
        text: preservedVariables[key] ??
            variableFieldValues[key] ??
            _string(variables[key]) ??
            '',
      );
    }
    _recalculateVariableFields();

    for (final section in _sections) {
      section.dispose();
    }
    _sections
      ..clear()
      ..addAll(_sectionStates(source['sections']));

    for (final image in _images) {
      image.dispose();
    }
    _images
      ..clear()
      ..addAll(_imageStates(_imageDefinitions(source)));
  }

  dynamic _imageDefinitions(Map<String, dynamic> source) {
    final templateKey = _string(source['key']) ??
        _string(source['templateKey']) ??
        _string(source['presupuestoType']);
    if (_isCleaningTemplateSource(source)) {
      return const <dynamic>[];
    }
    if (source['images'] is List && (source['images'] as List).isNotEmpty) {
      return source['images'];
    }
    if (source['imageSlots'] is List &&
        (source['imageSlots'] as List).isNotEmpty) {
      return source['imageSlots'];
    }
    final pageLayout = _asMap(source['pageLayout']);
    if (pageLayout?['imageSlots'] is List &&
        (pageLayout!['imageSlots'] as List).isNotEmpty) {
      return pageLayout['imageSlots'];
    }
    final variables = _asMap(source['variables']) ?? const {};
    final isGardenTemplate = templateKey == 'garden_pool_annual_maintenance' ||
        variables.containsKey('PRECIO_PISCINA_PRIVADA') ||
        variables.containsKey('DIAS_TEMPORADA_ALTA');
    if (isGardenTemplate) {
      return List.generate(
        6,
        (index) => <String, dynamic>{
          'slot': 'photo_${index + 1}',
          'label': 'Foto ${index + 1}',
          'url': '',
          'blobName': '',
          'enabled': true,
        },
      );
    }
    return const <dynamic>[];
  }

  Map<String, _TemplateVariableField> _readVariableFieldDefinitions(
    dynamic value,
  ) {
    final definitions = <String, _TemplateVariableField>{};

    void add(String rawKey, dynamic rawDefinition) {
      final key = rawKey.trim();
      if (key.isEmpty) return;
      final definition = _asMap(rawDefinition) ?? const {};
      final label = _variableLabel(key, _string(definition['label']));
      final type = (_string(definition['type']) ?? '').toLowerCase();
      final calculationMap = _asMap(definition['calculation']) ??
          (definition['operation'] != null ? definition : null);
      final calculation = calculationMap == null
          ? null
          : _VariableCalculation.fromMap(calculationMap);
      definitions[key] = _TemplateVariableField(
        key: key,
        label: '$label [$key]',
        hint: _string(definition['hint']) ??
            _string(definition['placeholder']) ??
            _variableHint(key),
        icon: _variableIcon(key),
        keyboardType: key == 'ANO' || type == 'year'
            ? TextInputType.number
            : key == 'FECHA' || type == 'date'
                ? TextInputType.datetime
                : TextInputType.text,
        maxLines: type.contains('textarea') ? 3 : 1,
        isAutomatic: definition['isAutomatic'] == true,
        isUsedInTemplate: definition['isUsedInTemplate'] != false,
        readOnly:
            definition['readOnly'] == true || (calculation?.readOnly ?? false),
        calculation: calculation,
      );
    }

    if (value is Map) {
      for (final entry in value.entries) {
        add(entry.key.toString(), entry.value);
      }
    } else if (value is List) {
      for (final item in value) {
        final definition = _asMap(item);
        final key = _string(definition?['key']) ??
            _string(definition?['name']) ??
            _string(definition?['variable']) ??
            (item is String ? _string(item) : null);
        if (key != null) add(key, definition);
      }
    }
    return definitions;
  }

  Map<String, String> _readVariableFieldValues(dynamic value) {
    final values = <String, String>{};

    void add(String rawKey, dynamic rawDefinition) {
      final key = rawKey.trim();
      if (key.isEmpty) return;
      final definition = _asMap(rawDefinition);
      final rawValue = definition == null
          ? rawDefinition
          : _displayedVariableValue(definition);
      if (rawValue != null) values[key] = rawValue.toString();
    }

    if (value is Map) {
      for (final entry in value.entries) {
        add(entry.key.toString(), entry.value);
      }
    } else if (value is List) {
      for (final item in value) {
        final definition = _asMap(item);
        final key = _string(definition?['key']) ??
            _string(definition?['name']) ??
            _string(definition?['variable']) ??
            (item is String ? _string(item) : null);
        if (key != null) add(key, definition);
      }
    }
    return values;
  }

  dynamic _displayedVariableValue(Map<String, dynamic> definition) {
    return definition['value'] ??
        definition['resolvedValue'] ??
        definition['automaticValue'] ??
        '';
  }

  String _variableLabel(String key, String? backendLabel) {
    const localized = <String, String>{
      'CLIENTE': 'Nombre del cliente',
      'FECHA': 'Fecha',
      'MES': 'Mes',
      'ANO': 'Año',
      'FRECUENCIA_MENSUAL': 'Frecuencia mensual',
      'PRECIO_VISITA': 'Precio por visita',
      'TOTAL_MENSUAL': 'Total mensual',
      'DURACION_CONTRATO': 'Duración del contrato',
      'FRECUENCIA_LIMPIEZA_GARAJE': 'Frecuencia de limpieza del garaje',
      'PRECIO_LIMPIEZA_GARAJE': 'Precio de limpieza del garaje',
      'PRECIO_HORA': 'Precio por hora',
      'PRECIO_PISCINA_PRIVADA': 'Precio piscina privada',
      'ZONAS_COMUNES': 'Zonas comunes',
      'PRODUCTOS_INCLUIDOS': 'Productos incluidos',
      'DIAS_TEMPORADA_ALTA': 'Días en temporada alta',
      'FRECUENCIA_TEMPORADA_BAJA': 'Frecuencia en temporada baja',
      'IMPORTE_MENSUAL': 'Importe mensual',
      'PREAVISO': 'Preaviso',
    };
    final candidate = backendLabel?.replaceAll('[$key]', '').trim();
    final backendIsReadable = candidate != null &&
        candidate.isNotEmpty &&
        candidate != key &&
        !candidate.contains('_') &&
        candidate != candidate.toUpperCase();
    return backendIsReadable
        ? candidate
        : localized[key] ?? key.replaceAll('_', ' ');
  }

  String _variableHint(String key) {
    const hints = <String, String>{
      'CLIENTE': 'Ej. Comunidad Las Alondras',
      'FECHA': 'Ej. 31/07/2026',
      'MES': 'Ej. julio',
      'ANO': 'Ej. 2026',
      'FRECUENCIA_MENSUAL': 'Ej. 4 veces al mes',
      'PRECIO_VISITA': 'Ej. 480 €',
      'TOTAL_MENSUAL': 'Ej. 1.920 €',
      'DURACION_CONTRATO': 'Ej. un (1) año',
      'FRECUENCIA_LIMPIEZA_GARAJE': 'Ej. una vez al año',
      'PRECIO_LIMPIEZA_GARAJE': 'Ej. 650 €',
    };
    return hints[key] ?? 'Valor para [$key]';
  }

  IconData _variableIcon(String key) {
    if (key == 'CLIENTE') return Icons.person_outline_rounded;
    if (key == 'FECHA') return Icons.calendar_today_outlined;
    if (key == 'MES') return Icons.calendar_view_month_outlined;
    if (key == 'ANO') return Icons.event_outlined;
    if (key.contains('PRECIO') ||
        key.contains('TOTAL') ||
        key.contains('IMPORTE')) {
      return Icons.euro_rounded;
    }
    if (key.contains('FRECUENCIA')) return Icons.event_repeat_rounded;
    if (key.contains('DURACION')) return Icons.description_outlined;
    return Icons.data_object_rounded;
  }

  List<_TemplateSectionState> _sectionStates(dynamic value) {
    final rows = value is List ? value : const [];
    final states = <_TemplateSectionState>[];
    for (var i = 0; i < rows.length; i++) {
      final row = _asMap(rows[i]) ?? const {};
      states.add(_TemplateSectionState.fromMap(row, fallbackOrder: i + 1));
    }
    states.sort((a, b) => a.order.compareTo(b.order));
    return states;
  }

  List<_TemplateImageState> _imageStates(dynamic value) {
    final bySlot = <String, Map<String, dynamic>>{};
    if (value is List) {
      for (final item in value) {
        final row = _asMap(item);
        final slot = _string(row?['slot']);
        if (row != null && slot != null && slot.isNotEmpty) {
          bySlot[slot] = row;
        }
      }
    }
    if (bySlot.isEmpty) return const [];
    return bySlot.values.map(_TemplateImageState.fromMap).toList();
  }

  Future<void> _save({bool silent = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (widget.templateOnly) {
        await _persistTemplate();
      } else {
        final creating = _documentFlow.presupuestoId == null;
        if (creating && _selectedDefaultKey == null) {
          throw Exception('Selecciona un tipo de presupuesto para continuar.');
        }
        final content = _payload(includeTemplateId: false);
        if (creating && (_selectedClientId ?? '').isNotEmpty) {
          content['clientId'] = _selectedClientId;
        }
        final presupuestoId = creating
            ? (await _documentFlow.createFromDefault(
                key: _selectedDefaultKey!,
                groupId: widget.groupId,
                content: content,
              ))
                .presupuestoId
            : await _documentFlow.save(
                groupId: widget.groupId,
                content: content,
              );
        if (creating) {
          _rememberCurrentDocumentVariables();
          _selectedTemplateSnapshot = jsonEncode(content);
        } else {
          await _saveChangedDocumentVariables(presupuestoId);
        }
        await widget.onDocumentSaved?.call();
      }
      if (!silent && mounted) {
        showSuccessSnack(
          context,
          widget.templateOnly
              ? 'Plantilla guardada.'
              : 'Presupuesto guardado como borrador.',
        );
      }
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
      rethrow;
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _persistTemplate() async {
    final templatePayload = {
      'name': _name.text.trim().isEmpty ? 'Plantilla presupuesto' : _name.text,
      ..._payload(includeTemplateId: false),
    };
    final existing = _templateId?.trim();
    if (existing != null && existing.isNotEmpty) {
      final updated =
          await widget.api.updateTemplate(existing, templatePayload);
      final template = _asMap(updated['template']) ??
          {
            '_id': existing,
            ...templatePayload,
          };
      _upsertTemplate(template);
      return;
    }
    final created = await widget.api.createTemplate({
      'groupId': widget.groupId,
      'isDefault': false,
      ...templatePayload,
    });
    final template = _asMap(created['template']) ?? created;
    final id = _string(template['_id']) ?? _string(template['id']);
    if (id == null || id.isEmpty) {
      throw Exception('No se pudo crear la plantilla.');
    }
    _templateId = id;
    _upsertTemplate(template);
  }

  Future<void> _createDocumentFromCurrentTemplate() async {
    if (_creatingDocumentFromTemplate) return;
    setState(() => _creatingDocumentFromTemplate = true);
    try {
      final draftFlow = PresupuestoDocumentDraftFlow(api: widget.api);
      await draftFlow.save(
        groupId: widget.groupId,
        content: _payload(includeTemplateId: false),
      );
      await widget.onDocumentSaved?.call();
      if (!mounted) return;
      showSuccessSnack(context, 'Presupuesto guardado como borrador.');
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted && _creatingDocumentFromTemplate) {
        setState(() => _creatingDocumentFromTemplate = false);
      }
    }
  }

  void _upsertTemplate(Map<String, dynamic> template) {
    final id = _string(template['_id']) ?? _string(template['id']);
    if (id == null || id.isEmpty) return;
    _templates = [
      template,
      ..._templates.where((item) {
        final existingId = _string(item['_id']) ?? _string(item['id']);
        return existingId != id;
      }),
    ];
  }

  Future<void> _previewPdf() async {
    if (_previewing) return;
    if (_mustSelectDefaultTemplate) {
      showErrorSnack(context, 'Selecciona un tipo de presupuesto primero.');
      return;
    }
    setState(() => _previewing = true);
    try {
      final response = !widget.templateOnly &&
              _documentFlow.presupuestoId == null &&
              _selectedDefaultKey != null
          ? await widget.api.previewDefaultTemplatePdf(
              key: _selectedDefaultKey!,
              groupId: widget.groupId,
            )
          : widget.templateOnly
              ? await widget.api.previewLiveTemplatePdf(
                  groupId: widget.groupId,
                  template: _payload(includeTemplateId: false),
                )
              : await () async {
                  await _save(silent: true);
                  return widget.api.previewTemplatePdf(
                    _documentFlow.presupuestoId!,
                  );
                }();
      final bytes = InvoiceEditorPdf.validatePdf(response);
      if (!mounted) return;
      await PresupuestoPdfPreviewDialog.show(
        context,
        bytes: bytes,
        onDownload: () => launchFileDownload(
          bytes,
          fileName: _fileName('preview'),
          mimeType: 'application/pdf',
        ),
      );
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, _friendlyPdfError(e));
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  String _friendlyPdfError(PresupuestosApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Tu sesion ha caducado. Vuelve a iniciar sesion e intentalo de nuevo.';
      case 403:
        return 'No tienes permiso para previsualizar este presupuesto.';
      case 404:
        return 'No se encontro el presupuesto solicitado.';
      case 500:
        return 'No se pudo generar el PDF en el servidor. Intentalo de nuevo en unos minutos.';
      default:
        return e.message;
    }
  }

  Future<void> _previewDefaultTemplate(Map<String, dynamic> template) async {
    final key = _string(template['key']);
    if (key == null || key.isEmpty || _previewingDefaultKey != null) return;
    setState(() => _previewingDefaultKey = key);
    try {
      final response = await widget.api.previewDefaultTemplatePdf(
        key: key,
        groupId: widget.groupId,
      );
      final bytes = InvoiceEditorPdf.validatePdf(response);
      if (!mounted) return;
      await PresupuestoPdfPreviewDialog.show(
        context,
        bytes: bytes,
        onDownload: () => launchFileDownload(
          bytes,
          fileName: 'presupuesto-plantilla-$key-preview.pdf',
          mimeType: 'application/pdf',
        ),
      );
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _previewingDefaultKey = null);
    }
  }

  Future<void> _previewSavedTemplate(String? templateId) async {
    final id = templateId?.trim();
    if (id == null || id.isEmpty || _previewingSavedTemplateId != null) return;
    setState(() => _previewingSavedTemplateId = id);
    try {
      final response = await widget.api.previewSavedTemplatePdf(id);
      await launchFileDownload(
        response.bodyBytes,
        fileName: 'presupuesto-plantilla-$id-preview.pdf',
        mimeType: 'application/pdf',
      );
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _previewingSavedTemplateId = null);
    }
  }

  Future<void> _deleteSavedTemplate(Map<String, dynamic> template) async {
    final id = _string(template['_id']) ?? _string(template['id']);
    if (id == null || id.isEmpty || _deletingTemplateId != null) return;
    final name = _string(template['name']) ?? 'Plantilla sin nombre';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text(
          'Se eliminara solo la plantilla "$name". Los presupuestos ya creados conservan su contenido y PDF.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar plantilla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingTemplateId = id);
    try {
      final response = await widget.api.deleteTemplate(id);
      setState(() {
        _templates = _templates.where((item) {
          final existingId = _string(item['_id']) ?? _string(item['id']);
          return existingId != id;
        }).toList(growable: false);

        if ((_templateId ?? '').trim() == id) {
          final next = _templates.isNotEmpty ? _templates.first : null;
          _templateId = next == null
              ? null
              : (_string(next['_id']) ?? _string(next['id']));
          _hydrate(next ?? _newTemplateSource());
        }
      });

      final detached = response['detachedPresupuestos'];
      final detachedCount = detached is num ? detached.toInt() : null;
      final message = detachedCount == null
          ? 'Plantilla eliminada.'
          : 'Plantilla eliminada. $detachedCount presupuestos conservan su contenido.';
      if (mounted) showSuccessSnack(context, message);
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _deletingTemplateId = null);
    }
  }

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await _save(silent: true);
      final presupuestoId = _documentFlow.presupuestoId;
      if (presupuestoId == null || presupuestoId.isEmpty) return;
      final response = await widget.api.downloadTemplatePdf(presupuestoId);
      await launchFileDownload(
        response.bodyBytes,
        fileName: _fileName('editable'),
        mimeType: 'application/pdf',
      );
    } catch (_) {
      // Save/API methods already show the relevant error.
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _uploadImage(_TemplateImageState image) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    try {
      final response = widget.templateOnly
          ? await widget.api.uploadTemplateImage(
              templateId: await _ensureTemplate(),
              bytes: bytes,
              fileName: file.name,
              slot: image.slot,
              label: image.label.text,
            )
          : await widget.api.uploadPresupuestoTemplateContentImage(
              presupuestoId: await _ensureDocumentDraft(),
              bytes: bytes,
              fileName: file.name,
              slot: image.slot,
              label: image.label.text,
            );
      final uploaded = _extractImage(response, image.slot);
      if (uploaded != null) {
        setState(() => image.apply(uploaded));
      }
      await _save(silent: true);
      if (mounted) showSuccessSnack(context, 'Imagen actualizada.');
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<String> _ensureTemplate() async {
    final existing = _templateId?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    await _persistTemplate();
    return _templateId!;
  }

  Future<String> _ensureDocumentDraft() async {
    final existing = _documentFlow.presupuestoId;
    if (existing != null) return existing;
    await _save(silent: true);
    final created = _documentFlow.presupuestoId;
    if (created == null) {
      throw Exception('No se pudo crear el presupuesto borrador.');
    }
    return created;
  }

  Map<String, dynamic>? _extractImage(
    Map<String, dynamic> response,
    String slot,
  ) {
    final image = _asMap(response['image']);
    if (image != null) return image;
    final template = _asMap(response['template']);
    final images = template?['images'] ?? response['images'];
    if (images is List) {
      for (final item in images) {
        final row = _asMap(item);
        if (_string(row?['slot']) == slot) return row;
      }
    }
    return null;
  }

  Map<String, dynamic> _payload({bool includeTemplateId = true}) {
    for (var i = 0; i < _sections.length; i++) {
      _sections[i].order = i + 1;
    }
    final scheduleTotal = _scheduleTotal();
    return {
      ..._sourceContent,
      'name': _name.text.trim().isEmpty ? 'Presupuesto' : _name.text.trim(),
      if (includeTemplateId && (_templateId ?? '').trim().isNotEmpty)
        'templateId': _templateId!.trim(),
      'header': {
        'instagram': _instagram.text.trim(),
        'website': _website.text.trim(),
        if ((_logoUrl ?? '').trim().isNotEmpty) 'logoUrl': _logoUrl,
      },
      'watermark': _watermark.text.trim(),
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'intro': _intro.text,
      'variables': {
        for (final entry in _variables.entries) entry.key: entry.value.text,
      },
      'sections': _sections.map((section) => section.toJson()).toList(),
      if (scheduleTotal != null)
        'totals': <String, dynamic>{
          'total': scheduleTotal,
          'grandTotal': scheduleTotal,
          'currency': 'EUR',
        },
      'images': _images.map((image) => image.toJson()).toList(),
    };
  }

  double? _scheduleTotal() {
    var total = 0.0;
    var found = false;
    for (final section in _sections) {
      final sectionTotal = section.table?.totalAmount();
      if (sectionTotal == null) continue;
      total += sectionTotal;
      found = true;
    }
    return found ? total : null;
  }

  void _applyLoadedDocumentVariables(Map<String, dynamic> payload) {
    final rawFields = payload['variableFields'] ??
        (payload['variables'] is List ? payload['variables'] : null);
    final definitions = _readVariableFieldDefinitions(rawFields);
    final fieldValues = _readVariableFieldValues(rawFields);
    final rawVariables = payload['variables'];
    final explicitValues = rawVariables is Map
        ? <String, String>{
            for (final entry in rawVariables.entries)
              entry.key.toString(): entry.value?.toString() ?? '',
          }
        : _readVariableFieldValues(rawVariables);

    for (final controller in _variables.values) {
      controller.dispose();
    }
    _variables.clear();
    _variableFieldDefinitions
      ..clear()
      ..addAll(definitions);
    _variableFieldsSource = rawFields ?? const <dynamic>[];
    _sourceContent = <String, dynamic>{
      ..._sourceContent,
      'variableFields': _variableFieldsSource,
    };
    for (final key in definitions.keys) {
      _variables[key] = TextEditingController(
        text: fieldValues[key] ?? _string(explicitValues[key]) ?? '',
      );
    }
    _recalculateVariableFields();

    final values = <String, String>{
      for (final entry in _variables.entries) entry.key: entry.value.text,
    };
    _loadedDocumentVariables
      ..clear()
      ..addAll(values);
  }

  void _rememberCurrentDocumentVariables() {
    _loadedDocumentVariables
      ..clear()
      ..addEntries(
        _variables.entries.map(
          (entry) => MapEntry(entry.key, entry.value.text.trim()),
        ),
      );
  }

  Future<void> _saveChangedDocumentVariables(String presupuestoId) async {
    final changes = <String, dynamic>{};
    for (final entry in _variables.entries) {
      if (_variableFieldDefinitions[entry.key]?.readOnly == true) continue;
      final value = entry.value.text.trim();
      if (_loadedDocumentVariables[entry.key] == value) continue;
      changes[entry.key] = value.isEmpty ? null : value;
    }
    if (changes.isEmpty) return;
    await widget.api.updateTemplateVariables(
      presupuestoId,
      variables: changes,
    );
    _rememberCurrentDocumentVariables();
  }

  String _fileName(String suffix) {
    final number =
        (widget.presupuestoNumber ?? _documentFlow.presupuestoId ?? 'documento')
            .replaceAll('/', '-')
            .trim();
    return 'presupuesto-$number-$suffix.pdf';
  }

  void _moveSection(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _sections.length) return;
    setState(() {
      final item = _sections.removeAt(index);
      _sections.insert(target, item);
    });
  }

  String? _primaryPriceKey() {
    for (final key in const [
      'TOTAL_MENSUAL',
      'IMPORTE_MENSUAL',
      'PRECIO_VISITA',
      'PRECIO_HORA',
    ]) {
      if (_variables.containsKey(key)) return key;
    }
    return null;
  }

  String _primaryPriceValue() {
    final key = _primaryPriceKey();
    return key == null ? '' : (_variables[key]?.text.trim() ?? '');
  }

  String _variableValue(String key) => _variables[key]?.text.trim() ?? '';

  void _recalculateVariableFields({String? changedKey}) {
    for (final field in _variableFieldDefinitions.values) {
      final calculation = field.calculation;
      final target = _variables[field.key];
      if (calculation == null || target == null) continue;
      if (calculation.operation != 'multiply' || calculation.operands.isEmpty) {
        continue;
      }
      var result = 1.0;
      var valid = true;
      for (final operand in calculation.operands) {
        final value = _parseLocalizedNumber(_variables[operand]?.text ?? '');
        if (value == null) {
          valid = false;
          break;
        }
        result *= value;
      }
      final next = valid
          ? _formatCalculatedValue(
              result,
              format: calculation.format,
              currency: calculation.currency,
            )
          : '';
      if (target.text != next) target.text = next;
    }
    if (changedKey != null) _syncVariableToTables(changedKey);
  }

  void _syncVariableToTables(String key) {
    // Monthly frequencies are intentionally edited row by row. The global
    // visit price, however, is the default price for every monthly row.
    if (key != 'PRECIO_VISITA') return;
    final value = _variables[key]?.text ?? '';
    for (final section in _sections) {
      final table = section.table;
      if (table == null) continue;
      table.applyVariableValue(key, value);
    }
  }

  Future<void> _selectVariableDate(String key) async {
    final controller = _variables[key];
    if (controller == null) return;
    final parts = controller.text.trim().split('/');
    final parsed = parts.length == 3
        ? DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}')
        : DateTime.tryParse(controller.text.trim());
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    controller.text =
        '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    setState(() {});
  }

  Widget _buildVariableInput(_TemplateVariableField field) {
    final allowsManualOverride = field.key == 'CLIENTE';
    final editable = field.isUsedInTemplate &&
        (!field.isAutomatic || allowsManualOverride) &&
        !field.readOnly;
    return _field(
      _variables[field.key]!,
      field.label,
      fieldKey: ValueKey('variable_${field.key}'),
      hint: field.hint,
      prefixIcon: field.icon,
      keyboardType: field.keyboardType,
      maxLines: field.maxLines,
      textCapitalization: field.key == 'CLIENTE'
          ? TextCapitalization.words
          : TextCapitalization.none,
      enabled: editable,
      readOnly: field.key == 'FECHA',
      onTap: editable && field.key == 'FECHA'
          ? () => _selectVariableDate(field.key)
          : null,
      onChanged: (_) => _recalculateVariableFields(changedKey: field.key),
      disabledMessage: field.readOnly
          ? 'Calculado automáticamente'
          : field.isAutomatic && !allowsManualOverride
              ? 'Valor automático'
              : field.isUsedInTemplate
                  ? null
                  : 'No se usa en esta plantilla',
    );
  }

  Future<List<GroupClient>> _searchActiveClients(String search) {
    final override = widget.clientSearch;
    if (override != null) return override(search);
    return _clientsApi.list(
      groupId: widget.groupId,
      search: search,
      active: true,
    );
  }

  Widget _buildClientInput(_TemplateVariableField field) {
    return _ClientAutocompleteField(
      key: const ValueKey('client_autocomplete'),
      fieldKey: ValueKey('variable_${field.key}'),
      controller: _variables[field.key]!,
      label: field.label,
      hint: field.hint,
      selectedClientId: _selectedClientId,
      search: _searchActiveClients,
      onSelected: (client) {
        setState(() {
          _selectedClientId = client.id;
          _selectedClientName = client.name.trim();
          _variables[field.key]!.text = client.name.trim();
          _recalculateVariableFields(changedKey: field.key);
        });
      },
      onChanged: (value) {
        if (_selectedClientId != null &&
            value.trim() != (_selectedClientName ?? '').trim()) {
          _selectedClientId = null;
          _selectedClientName = null;
        }
        _recalculateVariableFields(changedKey: field.key);
        setState(() {});
      },
    );
  }

  void _addSection() {
    setState(() {
      _sections.add(_TemplateSectionState.fromMap({
        'key': 'section_${_sections.length + 1}',
        'order': _sections.length + 1,
        'title': 'Nueva seccion',
        'body': '',
        'items': <String>[],
        'enabled': true,
      }));
    });
  }

  void _removeSection(int index) {
    if (index < 0 || index >= _sections.length) return;
    setState(() {
      final section = _sections.removeAt(index);
      section.dispose();
    });
  }

  void _newTemplate() {
    setState(() {
      _templateId = null;
      _hydrate(_newTemplateSource());
    });
  }

  Map<String, dynamic> _newTemplateSource() => {
        'name': 'Nueva plantilla',
        'header': {'instagram': '', 'website': '', 'logoUrl': _logoUrl},
        'watermark': '',
        'title': 'Presupuesto para [CLIENTE]',
        'subtitle': '[MES] de [ANO]',
        'intro': '',
        'variableFields': <Map<String, dynamic>>[],
        'variables': <String, dynamic>{},
        'sections': <Map<String, dynamic>>[],
        'images': List.generate(
          6,
          (index) => {
            'slot': 'photo_${index + 1}',
            'label': 'Foto ${index + 1}',
            'url': '',
            'blobName': '',
            'enabled': true,
          },
        ),
      };

  Map<String, dynamic> _newDocumentSource() => {
        ..._newTemplateSource(),
        'name': 'Nuevo presupuesto',
        'title': 'Presupuesto para [CLIENTE]',
        'variables': <String, dynamic>{},
        'images': <Map<String, dynamic>>[],
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _editorPageBg(theme),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1080;
                final steps = _editorSteps();
                final activeStep = steps.isEmpty
                    ? 0
                    : _activeStep.clamp(0, steps.length - 1).toInt();
                final previewColumn = <Widget>[
                  _buildLivePreviewCard(),
                  if (!widget.templateOnly) _buildDocumentActionsCard(),
                ];

                final leftPane = ListView(
                  padding: wide
                      ? EdgeInsets.zero
                      : const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    _buildHero(theme),
                    const SizedBox(height: 14),
                    _buildStepSelector(steps, activeStep),
                    if (steps.isNotEmpty) ...steps[activeStep].children,
                    if (!wide) ...previewColumn,
                    _buildStepFooter(theme, steps, activeStep),
                  ],
                );

                if (wide) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1800),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: leftPane),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: previewColumn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1480),
                    child: leftPane,
                  ),
                );
              },
            ),
    );
  }

  bool _isDark(ThemeData theme) => theme.brightness == Brightness.dark;

  Color _editorPageBg(ThemeData theme) =>
      _isDark(theme) ? const Color(0xFF071018) : theme.scaffoldBackgroundColor;

  Color _editorCardBg(ThemeData theme) =>
      _isDark(theme) ? const Color(0xFF101A28) : theme.colorScheme.surface;

  Color _editorPanelBg(ThemeData theme) =>
      _isDark(theme) ? const Color(0xFF132235) : theme.colorScheme.surface;

  Color _editorInsetBg(ThemeData theme) => _isDark(theme)
      ? const Color(0xFF0B1624)
      : theme.colorScheme.surfaceContainerLowest;

  Color _editorSoftAccentBg(ThemeData theme) => _isDark(theme)
      ? const Color(0xFF153044)
      : theme.colorScheme.surfaceContainerHighest;

  Color _editorBorder(ThemeData theme, {double alpha = 1}) => _isDark(theme)
      ? const Color(0xFF3A5F78).withValues(alpha: alpha)
      : theme.colorScheme.outlineVariant.withValues(alpha: alpha);

  bool get _mustSelectDefaultTemplate =>
      !widget.templateOnly &&
      widget.createDocumentDraft &&
      _documentFlow.presupuestoId == null &&
      _selectedDefaultKey == null;

  List<_EditorStep> _editorSteps() {
    final steps = <_EditorStep>[];
    final canChooseTemplate = widget.templateOnly ||
        (widget.createDocumentDraft && _documentFlow.presupuestoId == null);
    final baseChildren = <Widget>[
      if (canChooseTemplate) _buildDefaultTemplatesCard(),
      if (widget.templateOnly && (_templates.isNotEmpty || widget.templateOnly))
        _buildTemplateSelectorCard(),
    ];
    if (baseChildren.isNotEmpty) {
      steps.add(
        _EditorStep(
          title: 'Plantilla base',
          subtitle: 'Elige una plantilla guardada o empieza desde cero.',
          icon: Icons.account_tree_outlined,
          children: baseChildren,
        ),
      );
    }
    steps.addAll([
      _EditorStep(
        title: 'Datos',
        subtitle: 'Nombre, cliente, precio y textos principales.',
        icon: Icons.edit_note_rounded,
        children: [_buildMainCopyCard()],
      ),
      _EditorStep(
        title: 'Secciones',
        subtitle: 'Bloques del PDF, servicios incluidos y condiciones.',
        icon: Icons.view_agenda_outlined,
        children: [_buildSectionsCard()],
      ),
      if (_images.isNotEmpty)
        _EditorStep(
          title: 'Imagenes',
          subtitle: 'Fotos que apareceran en el documento.',
          icon: Icons.collections_outlined,
          children: [_buildImagesCard()],
        ),
    ]);
    return steps;
  }

  Widget _buildStepSelector(List<_EditorStep> steps, int activeStep) {
    final theme = Theme.of(context);
    if (steps.isEmpty) return const SizedBox.shrink();
    final step = steps[activeStep];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: _editorCardBg(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _editorBorder(theme)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(step.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paso ${activeStep + 1} de ${steps.length}: ${step.title}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              step.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < steps.length; i++)
                  ChoiceChip(
                    selected: i == activeStep,
                    label: Text('${i + 1}. ${steps[i].title}'),
                    avatar: Icon(steps[i].icon, size: 16),
                    onSelected: _mustSelectDefaultTemplate && i > 0
                        ? null
                        : (_) => setState(() => _activeStep = i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepFooter(
    ThemeData theme,
    List<_EditorStep> steps,
    int activeStep,
  ) {
    final isLastStep = steps.isEmpty || activeStep >= steps.length - 1;
    final selectionBlocked = _mustSelectDefaultTemplate;
    final saveLabel =
        widget.templateOnly ? 'Guardar como plantilla' : 'Guardar borrador';
    final footerText = widget.templateOnly
        ? 'Crea o actualiza una plantilla reutilizable.'
        : 'Guarda este presupuesto como borrador para continuar editandolo.';
    final info = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_done_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            footerText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: activeStep <= 0
              ? null
              : () => setState(() => _activeStep = activeStep - 1),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Anterior'),
        ),
        if (widget.templateOnly && isLastStep)
          OutlinedButton.icon(
            onPressed: _creatingDocumentFromTemplate || _saving
                ? null
                : _createDocumentFromCurrentTemplate,
            icon: _creatingDocumentFromTemplate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.article_outlined, size: 18),
            label: Text(
              _creatingDocumentFromTemplate
                  ? 'Creando...'
                  : 'Crear presupuesto',
            ),
          ),
        FilledButton.icon(
          onPressed:
              _saving || _creatingDocumentFromTemplate || selectionBlocked
                  ? null
                  : isLastStep
                      ? () => _save()
                      : () => setState(() => _activeStep = activeStep + 1),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isLastStep
                      ? Icons.save_outlined
                      : Icons.arrow_forward_rounded,
                  size: 18,
                ),
          label: Text(
            _saving
                ? 'Guardando...'
                : isLastStep
                    ? saveLabel
                    : selectionBlocked
                        ? 'Selecciona una plantilla'
                        : 'Siguiente',
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _editorPanelBg(theme),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.78),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1100) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    final title = widget.templateOnly ? 'Plantilla PDF' : 'Presupuesto PDF';
    final subtitle = widget.templateOnly
        ? 'Crea una base simple para generar presupuestos con cliente, precio, secciones e imagenes.'
        : 'Crea un presupuesto borrador con cliente, precio, secciones e imagenes.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: _isDark(theme)
              ? const [Color(0xFF173653), Color(0xFF101A28)]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.92,
                  ),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.templateOnly
                      ? Icons.auto_awesome_motion_rounded
                      : Icons.description_outlined,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_selectedDefaultTemplate != null)
                _heroChip(
                  theme,
                  icon: Icons.account_tree_outlined,
                  label: _string(_selectedDefaultTemplate!['name']) ??
                      'Tipo seleccionado',
                ),
              _heroChip(
                theme,
                icon: Icons.person_outline_rounded,
                label: _variableValue('CLIENTE').isEmpty
                    ? 'Cliente'
                    : _variableValue('CLIENTE'),
              ),
              _heroChip(
                theme,
                icon: Icons.euro_rounded,
                label: _primaryPriceValue().isEmpty
                    ? 'Precio'
                    : _primaryPriceValue(),
              ),
              _heroChip(
                theme,
                icon: Icons.segment_rounded,
                label: '${_sections.length} secciones',
              ),
              if (_images.isNotEmpty)
                _heroChip(
                  theme,
                  icon: Icons.photo_library_outlined,
                  label:
                      '${_images.where((img) => img.url.trim().isNotEmpty).length}/${_images.length} imagenes',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark(theme)
            ? const Color(0xFF0B1624).withValues(alpha: 0.86)
            : theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTemplatesCard() {
    final theme = Theme.of(context);
    final templateCount = _defaultTemplates.length;
    return _card(
      title: 'Plantillas recomendadas',
      subtitle: 'Empieza con una estructura preparada y adaptala a tu negocio.',
      icon: Icons.auto_awesome_motion_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '$templateCount ${templateCount == 1 ? 'disponible' : 'disponibles'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: _loadErrorMessage != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_loadErrorMessage!)),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _defaultTemplates.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _editorInsetBg(theme),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _editorBorder(theme)),
                  ),
                  child: const Text(
                    'No hay tipos de presupuesto disponibles. Vuelve a intentarlo mas tarde.',
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _defaultTemplates.length > 1 &&
                            constraints.maxWidth >= 920
                        ? 2
                        : 1;
                    const spacing = 12.0;
                    final itemWidth =
                        (constraints.maxWidth - (spacing * (columns - 1))) /
                            columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final template in _defaultTemplates)
                          SizedBox(
                            width: itemWidth,
                            child: _defaultTemplateQueueItem(theme, template),
                          ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _defaultTemplateQueueItem(
    ThemeData theme,
    Map<String, dynamic> template,
  ) {
    final key = _string(template['key']);
    final creating = _creatingDefaultKey == key;
    final previewing = _previewingDefaultKey == key;
    final selected = key != null && key == _selectedDefaultKey;
    final cs = theme.colorScheme;

    Widget templateInfo() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description_outlined,
              color: cs.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _string(template['name']) ?? 'Plantilla predeterminada',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _string(template['description']) ??
                      'Plantilla preparada para empezar rapidamente.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if ((_string(template['category']) ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _string(template['category'])!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                if (template['editable'] != false)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Totalmente editable',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    }

    Widget templateActions({
      required bool expanded,
      bool stacked = false,
    }) {
      final previewButton = OutlinedButton.icon(
        onPressed: previewing || creating || key == null
            ? null
            : () => _previewDefaultTemplate(template),
        icon: previewing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.visibility_outlined, size: 19),
        label: Text(previewing ? 'Abriendo...' : 'Vista previa'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(138, 44),
          side: BorderSide(color: _editorBorder(theme)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      final useButton = FilledButton.icon(
        onPressed: creating || previewing || key == null || selected
            ? null
            : () => _useDefaultTemplate(template),
        icon: creating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                size: 19,
              ),
        label: Text(
          creating
              ? 'Preparando...'
              : selected
                  ? 'Seleccionada'
                  : 'Usar plantilla',
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(148, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            previewButton,
            const SizedBox(height: 8),
            useButton,
          ],
        );
      }
      if (!expanded) {
        return Row(
          children: [
            Expanded(child: previewButton),
            const SizedBox(width: 8),
            Expanded(child: useButton),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          previewButton,
          const SizedBox(width: 8),
          useButton,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDark(theme)
                ? const Color(0xFF132A3E)
                : cs.primaryContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : _isDark(theme)
                      ? const Color(0xFF3F7596).withValues(alpha: 0.46)
                      : cs.primary.withValues(alpha: 0.18),
              width: selected ? 2 : 1,
            ),
          ),
          child: horizontal
              ? Row(
                  children: [
                    Expanded(child: templateInfo()),
                    const SizedBox(width: 24),
                    templateActions(expanded: true),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    templateInfo(),
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: _editorBorder(theme, alpha: 0.7),
                    ),
                    const SizedBox(height: 14),
                    templateActions(
                      expanded: false,
                      stacked: constraints.maxWidth < 480,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTemplateSelectorCard() {
    final selectedSavedTemplate = _templateById(_templateId);
    final selectedSavedTemplateId = selectedSavedTemplate == null
        ? null
        : (_string(selectedSavedTemplate['_id']) ??
            _string(selectedSavedTemplate['id']));
    final previewingSaved = selectedSavedTemplateId != null &&
        _previewingSavedTemplateId == selectedSavedTemplateId;
    final deletingSaved = selectedSavedTemplateId != null &&
        _deletingTemplateId == selectedSavedTemplateId;
    return _card(
      title: 'Plantilla base',
      subtitle: 'Opcional: parte de una plantilla guardada o crea una nueva.',
      icon: Icons.account_tree_outlined,
      trailing: widget.templateOnly
          ? TextButton.icon(
              onPressed: _newTemplate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear plantilla'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_templateId ?? 'new-template'),
                  initialValue: selectedSavedTemplate == null
                      ? null
                      : selectedSavedTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar plantilla',
                    hintText: 'Elige una base para editar',
                  ),
                  items: [
                    for (final template in _templates)
                      DropdownMenuItem(
                        value:
                            _string(template['_id']) ?? _string(template['id']),
                        child: Text(
                          _string(template['name']) ?? 'Plantilla sin nombre',
                        ),
                      ),
                  ],
                  onChanged: _selectTemplate,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: selectedSavedTemplateId == null ||
                              previewingSaved
                          ? null
                          : () =>
                              _previewSavedTemplate(selectedSavedTemplateId),
                      icon: previewingSaved
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Vista previa'),
                    ),
                    if (selectedSavedTemplate != null &&
                        selectedSavedTemplateId != null)
                      IconButton(
                        tooltip: 'Eliminar plantilla',
                        onPressed: deletingSaved
                            ? null
                            : () => _deleteSavedTemplate(selectedSavedTemplate),
                        icon: deletingSaved
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (selectedSavedTemplate != null) ...[
            const SizedBox(height: 12),
            Text(
              'La seleccion carga el contenido completo de la plantilla elegida para seguir editando sobre ella.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ] else if (widget.templateOnly) ...[
            const SizedBox(height: 12),
            Text(
              'Usa "Previsualizar" en la vista previa para revisar los cambios actuales sin guardarlos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainCopyCard() {
    final priceKey = _primaryPriceKey();
    final clientDefinition = _variableFieldDefinitions['CLIENTE'];
    final clientField =
        clientDefinition == null ? null : _buildClientInput(clientDefinition);
    final priceDefinition =
        priceKey == null ? null : _variableFieldDefinitions[priceKey];
    final priceField =
        priceKey == null ? null : _buildVariableInput(priceDefinition!);
    return _card(
      title: 'Datos del PDF',
      subtitle: 'Lo esencial para que el cliente entienda el presupuesto.',
      icon: Icons.edit_note_rounded,
      child: Column(
        children: [
          _field(
            _name,
            widget.templateOnly
                ? 'Nombre de plantilla'
                : 'Nombre del presupuesto',
            hint: widget.templateOnly
                ? 'Ej. Mantenimiento mensual comunidades'
                : 'Ej. Mantenimiento anual Las Alondras',
            prefixIcon: Icons.description_outlined,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final primaryFields = <Widget>[
                if (clientField != null) clientField,
                if (priceField != null) priceField,
              ];
              if (primaryFields.isEmpty) return const SizedBox.shrink();
              if (primaryFields.length == 1 || constraints.maxWidth < 620) {
                return Column(
                  children: primaryFields,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: primaryFields[0]),
                  const SizedBox(width: 12),
                  Expanded(child: primaryFields[1]),
                ],
              );
            },
          ),
          _buildTagFields(),
          _field(
            _title,
            'Titulo del PDF',
            maxLines: 2,
            hint: 'Ej. Presupuesto para [CLIENTE]',
            prefixIcon: Icons.title_rounded,
            markdown: true,
          ),
          _field(
            _subtitle,
            'Subtitulo',
            maxLines: 2,
            hint: 'Ej. [MES] de [ANO]',
            prefixIcon: Icons.short_text_rounded,
            markdown: true,
          ),
          _field(
            _intro,
            'Texto inicial',
            maxLines: 6,
            minLines: 5,
            hint: 'Explica brevemente el servicio y el precio propuesto.',
            prefixIcon: Icons.notes_rounded,
            textCapitalization: TextCapitalization.sentences,
            markdown: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTagFields() {
    final theme = Theme.of(context);
    final primaryPriceKey = _primaryPriceKey();
    final primaryKeys = {
      'CLIENTE',
      if (primaryPriceKey != null) primaryPriceKey,
    };
    final fields = _variableFieldDefinitions.values
        .where(
          (field) =>
              !primaryKeys.contains(field.key) &&
              _isVariableFieldVisible(field),
        )
        .toList(growable: false);

    if (fields.isEmpty) return const SizedBox.shrink();

    return KeyedSubtree(
      key: ValueKey(_variableSchemaKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Divider(color: _editorBorder(theme, alpha: 0.72)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.data_object_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Text(
                'Valores de etiquetas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Estos valores sustituyen las etiquetas entre corchetes en el documento.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = constraints.maxWidth < 620
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: fieldWidth,
                      child: _buildVariableInput(field),
                    ),
                ],
              );
            },
          ),
          Divider(color: _editorBorder(theme, alpha: 0.72)),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildSectionsCard() {
    return _card(
      title: 'Secciones',
      subtitle:
          'Anade bloques al PDF, por ejemplo alcance, incluidos o condiciones.',
      icon: Icons.view_agenda_outlined,
      trailing: TextButton.icon(
        onPressed: _addSection,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Anadir seccion'),
      ),
      child: _sections.isEmpty
          ? Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _editorInsetBg(Theme.of(context)),
                border: Border.all(
                  color: _editorBorder(Theme.of(context)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anade una seccion para explicar el servicio, lo incluido o las condiciones.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < _sections.length; i++)
                  _sectionTile(_sections[i], i),
              ],
            ),
    );
  }

  bool _isVariableFieldVisible(_TemplateVariableField field) {
    if (field.key != 'FRECUENCIA_LIMPIEZA_GARAJE' &&
        field.key != 'PRECIO_LIMPIEZA_GARAJE') {
      return true;
    }
    final relatedSections = _sections.where(
      (section) =>
          section.isGarageCleaning || section.referencesVariable(field.key),
    );
    return relatedSections.isEmpty ||
        relatedSections.any((section) => section.enabled);
  }

  Widget _buildLivePreviewCard() {
    final theme = Theme.of(context);
    final client = _variableValue('CLIENTE');
    final price = _primaryPriceValue();
    final titleTemplate = _title.text.trim().isEmpty
        ? 'Presupuesto para ${client.isEmpty ? '[CLIENTE]' : client}'
        : _title.text.trim();
    final title = _resolvePreviewTags(titleTemplate);
    final subtitle = _resolvePreviewTags(_subtitle.text.trim());
    final intro = _resolvePreviewTags(_intro.text.trim());
    final enabledSections =
        _sections.where((section) => section.enabled).toList(growable: false);
    final visibleImages = _images
        .where((image) => image.enabled && image.url.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    return _card(
      title: 'Vista previa',
      subtitle: 'Asi se vera el documento mientras editas.',
      icon: Icons.preview_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewWidth =
              constraints.maxWidth < 640 ? 640.0 : constraints.maxWidth;
          return Scrollbar(
            controller: _previewHorizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _previewHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: previewWidth,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isDark(theme)
                          ? const Color(0xFFBFE7FF).withValues(alpha: 0.22)
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: const Color(0xFF20242A),
                      height: 1.35,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.isEmpty
                                        ? 'Nombre del cliente'
                                        : client,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: const Color(0xFF20242A),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (price.isNotEmpty)
                                    Text(
                                      price,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _RestrictedMarkdownText(
                          data: title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _RestrictedMarkdownText(
                            data: subtitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (intro.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _RestrictedMarkdownText(data: intro),
                        ],
                        if (visibleImages.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                visibleImages.first.url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        if (enabledSections.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          for (final section in enabledSections)
                            _previewSection(theme, section),
                        ],
                        if (enabledSections.isEmpty && intro.isEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'Anade texto o secciones para completar la vista previa.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _previewSection(ThemeData theme, _TemplateSectionState section) {
    final title = _resolvePreviewTags(section.title.text.trim());
    final body = _resolvePreviewTags(section.body.text.trim());
    final items = section.items.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(_resolvePreviewTags)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RestrictedMarkdownText(
            data: title.isEmpty ? 'Seccion' : title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            _RestrictedMarkdownText(data: body),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('\u2022  '),
                    Expanded(child: _RestrictedMarkdownText(data: item)),
                  ],
                ),
              ),
          ],
          if (section.table != null) ...[
            const SizedBox(height: 8),
            _previewTable(theme, section.table!),
          ],
        ],
      ),
    );
  }

  Widget _previewTable(ThemeData theme, _TemplateTableState table) {
    if (table.columns.isEmpty) return const SizedBox.shrink();
    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        children: [
          for (final column in table.columns)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                _resolvePreviewTags(column.text),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      for (final row in table.rows)
        TableRow(
          children: [
            for (var i = 0; i < table.columns.length; i++)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  _resolvePreviewTags(i < row.length ? row[i].text : ''),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF344054),
                  ),
                ),
              ),
          ],
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: table.columns.length * 135,
        child: Table(
          border: TableBorder.all(color: const Color(0xFFD0D5DD)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
  }

  String _resolvePreviewTags(String source) {
    var resolved = source;
    for (final entry in _variables.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;
      resolved = resolved.replaceAll('[${entry.key}]', value);
    }
    return resolved;
  }

  Widget _buildImagesCard() {
    return _card(
      title: 'Imagenes',
      subtitle: 'Sube fotos que apareceran en el PDF del presupuesto.',
      icon: Icons.collections_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final image in _images) _imageSlot(image),
        ],
      ),
    );
  }

  Widget _buildDocumentActionsCard() {
    return _card(
      title: 'Salida del documento',
      subtitle:
          'Guarda, revisa y descarga el resultado final antes de compartirlo con el cliente.',
      icon: Icons.picture_as_pdf_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed:
                _previewing || _mustSelectDefaultTemplate ? null : _previewPdf,
            icon: _previewing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined),
            label: const Text('Previsualizar'),
          ),
          FilledButton.icon(
            onPressed: _downloading || _mustSelectDefaultTemplate
                ? null
                : _downloadPdf,
            icon: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Descargar PDF'),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: _editorCardBg(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _editorBorder(theme)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? fieldKey,
    int maxLines = 1,
    int? minLines,
    String? hint,
    bool dense = false,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool markdown = false,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    String? disabledMessage,
    bool showLabel = true,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  if ((!enabled || readOnly) && disabledMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        disabledMessage,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (markdown)
                    _markdownToolbar(
                      theme,
                      controller,
                      allowLineBreak: maxLines != 1,
                    ),
                ],
              ),
            ),
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: (value) {
              onChanged?.call(value);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              prefixIcon: prefixIcon == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(
                        left: 14,
                        right: 11,
                        bottom: maxLines > 3
                            ? 70
                            : maxLines > 1
                                ? 18
                                : 0,
                      ),
                      child: Icon(prefixIcon, size: 20, color: cs.primary),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46),
              filled: true,
              fillColor: _editorInsetBg(theme),
              isDense: dense,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: _editorBorder(theme)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: _editorBorder(theme)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: cs.primary, width: 1.6),
              ),
              hoverColor: cs.primary.withValues(alpha: 0.025),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markdownToolbar(
    ThemeData theme,
    TextEditingController controller, {
    required bool allowLineBreak,
  }) {
    final cs = theme.colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _isDark(theme)
            ? const Color(0xFF16263A)
            : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatButton(
            tooltip: 'Negrita',
            icon: Icons.format_bold_rounded,
            onPressed: () => _wrapSelection(controller, '**'),
          ),
          _formatButton(
            tooltip: 'Cursiva',
            icon: Icons.format_italic_rounded,
            onPressed: () => _wrapSelection(controller, '*'),
          ),
          if (allowLineBreak)
            _formatButton(
              tooltip: 'Salto de linea',
              icon: Icons.keyboard_return_rounded,
              onPressed: () => _insertLineBreak(controller),
            ),
        ],
      ),
    );
  }

  Widget _formatButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }

  void _wrapSelection(TextEditingController controller, String marker) {
    final text = controller.text;
    final selection = controller.selection;
    final hasSelection = selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length;
    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    final selected = text.substring(start, end);
    final markerLength = marker.length;
    final alreadyWrapped = start >= markerLength &&
        end + markerLength <= text.length &&
        text.substring(start - markerLength, start) == marker &&
        text.substring(end, end + markerLength) == marker;

    if (alreadyWrapped) {
      final withoutClosing = text.replaceRange(end, end + markerLength, '');
      final unwrapped =
          withoutClosing.replaceRange(start - markerLength, start, '');
      controller.value = TextEditingValue(
        text: unwrapped,
        selection: TextSelection(
          baseOffset: start - markerLength,
          extentOffset: end - markerLength,
        ),
      );
    } else {
      final replacement = '$marker$selected$marker';
      controller.value = TextEditingValue(
        text: text.replaceRange(start, end, replacement),
        selection: selected.isEmpty
            ? TextSelection.collapsed(offset: start + markerLength)
            : TextSelection(
                baseOffset: start + markerLength,
                extentOffset: end + markerLength,
              ),
      );
    }
    setState(() {});
  }

  void _insertLineBreak(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    final hasSelection = selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length;
    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, '\n'),
      selection: TextSelection.collapsed(offset: start + 1),
    );
    setState(() {});
  }

  Widget _sectionTile(_TemplateSectionState section, int index) {
    final theme = Theme.of(context);
    final itemsCount = section.items.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: _editorPanelBg(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _editorBorder(theme)),
      ),
      child: ExpansionTile(
        initiallyExpanded: index == 0,
        title: Text(
          section.title.text.trim().isEmpty
              ? 'Seccion ${index + 1}'
              : section.title.text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          section.isOptional
              ? section.enabled
                  ? '$itemsCount elementos · Incluida en el PDF'
                  : 'Opcional · No se incluirá en el PDF'
              : section.enabled
                  ? '$itemsCount items activos'
                  : 'Seccion desactivada',
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: section.enabled
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : _editorSoftAccentBg(theme),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            section.enabled ? Icons.checklist_rounded : Icons.pause_circle,
            color: section.enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (section.isOptional)
              Tooltip(
                message: section.enabled
                    ? 'Quitar del presupuesto'
                    : 'Incluir en el presupuesto',
                child: Switch(
                  key: ValueKey('section_enabled_${section.key}'),
                  value: section.enabled,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) => setState(() => section.enabled = value),
                ),
              )
            else
              IconButton(
                tooltip: section.enabled ? 'Desactivar' : 'Activar',
                onPressed: () =>
                    setState(() => section.enabled = !section.enabled),
                icon: Icon(
                  section.enabled
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_outlined,
                ),
              ),
            IconButton(
              tooltip: 'Subir',
              onPressed: index == 0 ? null : () => _moveSection(index, -1),
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: 'Bajar',
              onPressed: index == _sections.length - 1
                  ? null
                  : () => _moveSection(index, 1),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            IconButton(
              tooltip: 'Eliminar seccion',
              onPressed: () => _removeSection(index),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _field(
            section.title,
            'Titulo',
            maxLines: 2,
            hint: 'Ej. Alcance del servicio',
            markdown: true,
          ),
          _field(
            section.body,
            'Texto',
            maxLines: 6,
            minLines: 4,
            hint: 'Explica esta parte del presupuesto con claridad.',
            markdown: true,
          ),
          _field(
            section.items,
            'Items de lista (uno por linea)',
            maxLines: 5,
            minLines: 4,
            hint: 'Cada linea se mostrara como un punto independiente.',
            markdown: true,
          ),
          if (section.table != null) _sectionTableEditor(section.table!),
        ],
      ),
    );
  }

  Widget _sectionTableEditor(_TemplateTableState table) {
    final theme = Theme.of(context);
    double columnWidth(int index) {
      if (table.columns.length == 4) {
        return switch (index) {
          0 => 145,
          1 => 105,
          2 => 145,
          _ => 135,
        };
      }
      return 135;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _editorInsetBg(theme),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _editorBorder(theme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tabla',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(table.addRow),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Anadir fila'),
              ),
            ],
          ),
          if (table.hasComputedColumns) ...[
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in table.bulkValues.entries)
                  SizedBox(
                    width: 190,
                    child: _field(
                      entry.value,
                      entry.key < table.columns.length
                          ? table.columns[entry.key].text
                          : 'Valor',
                      dense: true,
                      fieldKey: ValueKey('table_bulk_${entry.key}'),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: table.selectedRows.isEmpty
                        ? null
                        : () => setState(table.applyToSelectedRows),
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: Text(
                      table.selectedRows.isEmpty
                          ? 'Selecciona meses'
                          : table.selectedRows.length == 1
                              ? 'Aplicar a 1 mes'
                              : 'Aplicar a ${table.selectedRows.length} meses',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Scrollbar(
            controller: table.horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: table.horizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (table.hasComputedColumns)
                        SizedBox(
                          width: 42,
                          child: Checkbox(
                            tristate: true,
                            value: table.selectedRows.isEmpty
                                ? false
                                : table.selectedRows.length == table.rows.length
                                    ? true
                                    : null,
                            onChanged: (value) => setState(
                              () => table.toggleAllRows(value == true),
                            ),
                          ),
                        ),
                      for (var columnIndex = 0;
                          columnIndex < table.columns.length;
                          columnIndex++)
                        SizedBox(
                          width: columnWidth(columnIndex),
                          child: _field(
                            table.columns[columnIndex],
                            'Encabezado',
                            dense: true,
                            showLabel: false,
                          ),
                        ),
                      const SizedBox(width: 42),
                    ],
                  ),
                  for (var rowIndex = 0;
                      rowIndex < table.rows.length;
                      rowIndex++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (table.hasComputedColumns)
                          SizedBox(
                            width: 42,
                            child: Checkbox(
                              value: table.selectedRows.contains(rowIndex),
                              onChanged: (value) => setState(
                                () => table.toggleRow(rowIndex, value == true),
                              ),
                            ),
                          ),
                        for (var columnIndex = 0;
                            columnIndex < table.columns.length;
                            columnIndex++)
                          SizedBox(
                            width: columnWidth(columnIndex),
                            child: _field(
                              table.cell(rowIndex, columnIndex),
                              'Fila ${rowIndex + 1}',
                              fieldKey: ValueKey(
                                'table_cell_${rowIndex}_$columnIndex',
                              ),
                              dense: true,
                              showLabel: false,
                              readOnly: table.isReadOnlyColumn(columnIndex),
                              disabledMessage:
                                  table.isReadOnlyColumn(columnIndex)
                                      ? 'Calculado'
                                      : null,
                              onChanged: (_) => table.recalculateRow(rowIndex),
                            ),
                          ),
                        SizedBox(
                          width: 42,
                          child: IconButton(
                            tooltip: 'Eliminar fila',
                            onPressed: () => setState(
                              () => table.removeRow(rowIndex),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
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
    );
  }

  Widget _imageSlot(_TemplateImageState image) {
    final theme = Theme.of(context);
    final url = image.url.trim();
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        color: _editorPanelBg(theme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _editorBorder(theme)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      image.slot.replaceAll('_', ' ').toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    image.enabled
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: image.enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 118,
                decoration: BoxDecoration(
                  color: _editorSoftAccentBg(theme),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _editorBorder(theme)),
                ),
                clipBehavior: Clip.antiAlias,
                child: url.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin imagen',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Image.network(url, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              _field(
                image.label,
                'Etiqueta',
                dense: true,
                hint: 'Describe brevemente esta imagen',
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _uploadImage(image),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(url.isEmpty ? 'Subir' : 'Reemplazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: image.enabled ? 'Ocultar' : 'Mostrar',
                    onPressed: () =>
                        setState(() => image.enabled = !image.enabled),
                    icon: Icon(
                      image.enabled
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientAutocompleteField extends StatefulWidget {
  const _ClientAutocompleteField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.selectedClientId,
    required this.search,
    required this.onSelected,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? selectedClientId;
  final Future<List<GroupClient>> Function(String search) search;
  final ValueChanged<GroupClient> onSelected;
  final ValueChanged<String> onChanged;

  @override
  State<_ClientAutocompleteField> createState() =>
      _ClientAutocompleteFieldState();
}

class _ClientAutocompleteFieldState extends State<_ClientAutocompleteField> {
  final MenuController _menuController = MenuController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<GroupClient> _results = const [];
  bool _loading = false;
  bool _searched = false;
  int _requestRevision = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      _requestRevision++;
      setState(() {
        _results = const [];
        _loading = false;
        _searched = false;
      });
      if (_menuController.isOpen) _menuController.close();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final revision = ++_requestRevision;
    setState(() {
      _loading = true;
      _searched = false;
    });
    try {
      final clients = await widget.search(query);
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _results = clients.where((client) => client.isActive).toList();
        _loading = false;
        _searched = true;
      });
      _openMenuAfterBuild();
    } catch (_) {
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _results = const [];
        _loading = false;
        _searched = true;
      });
      _openMenuAfterBuild();
    }
  }

  void _searchFromButton() {
    _debounce?.cancel();
    _focusNode.requestFocus();
    _performSearch(widget.controller.text.trim());
  }

  void _openMenuAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _menuController.isOpen) return;
      _menuController.open();
    });
  }

  void _select(GroupClient client) {
    widget.controller.value = TextEditingValue(
      text: client.name.trim(),
      selection: TextSelection.collapsed(offset: client.name.trim().length),
    );
    widget.onSelected(client);
    _menuController.close();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final menuChildren = <Widget>[
      if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Buscando clientes...'),
            ],
          ),
        )
      else if (_searched && _results.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Sin coincidencias · puedes usar el nombre escrito'),
        )
      else
        for (final client in _results)
          MenuItemButton(
            onPressed: () => _select(client),
            leadingIcon: const Icon(Icons.business_outlined, size: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((client.billing?.legalName ?? '').trim().isNotEmpty &&
                      client.billing!.legalName!.trim() != client.name.trim())
                    Text(
                      client.billing!.legalName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              widget.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ),
          MenuAnchor(
            controller: _menuController,
            crossAxisUnconstrained: false,
            menuChildren: menuChildren,
            builder: (context, controller, child) => TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                widget.onChanged(value);
                _scheduleSearch(value);
              },
              onTap: () => _scheduleSearch(widget.controller.text),
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: Icon(
                  Icons.person_search_outlined,
                  size: 20,
                  color: cs.primary,
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : widget.selectedClientId == null
                        ? IconButton(
                            tooltip: 'Buscar clientes',
                            onPressed: _searchFromButton,
                            icon: const Icon(Icons.search_rounded, size: 19),
                          )
                        : Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: cs.primary,
                          ),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.78),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictedMarkdownText extends StatelessWidget {
  const _RestrictedMarkdownText({
    required this.data,
    this.style,
  });

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: _restrictedMarkdownSpans(data),
      ),
    );
  }
}

List<InlineSpan> _restrictedMarkdownSpans(String text) {
  final spans = <InlineSpan>[];
  var index = 0;
  var plainStart = 0;

  void addPlain(int end) {
    if (end > plainStart) {
      spans.add(TextSpan(text: text.substring(plainStart, end)));
    }
  }

  while (index < text.length) {
    if (text.startsWith('**', index)) {
      final closing = text.indexOf('**', index + 2);
      if (closing > index + 2) {
        addPlain(index);
        spans.add(
          TextSpan(
            text: text.substring(index + 2, closing),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
        index = closing + 2;
        plainStart = index;
        continue;
      }
    } else if (text[index] == '*') {
      final closing = text.indexOf('*', index + 1);
      if (closing > index + 1) {
        addPlain(index);
        spans.add(
          TextSpan(
            text: text.substring(index + 1, closing),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
        index = closing + 1;
        plainStart = index;
        continue;
      }
    }
    index++;
  }

  addPlain(text.length);
  return spans;
}

class _TemplateSectionState {
  _TemplateSectionState({
    required this.original,
    required this.key,
    required this.order,
    required this.enabled,
    required this.title,
    required this.body,
    required this.items,
    this.table,
  });

  factory _TemplateSectionState.fromMap(
    Map<String, dynamic> map, {
    int fallbackOrder = 1,
  }) {
    final items = map['items'] is List
        ? (map['items'] as List).map((e) => e.toString()).join('\n')
        : '';
    return _TemplateSectionState(
      original: Map<String, dynamic>.from(map),
      key: _string(map['key']) ?? 'section_$fallbackOrder',
      order: _int(map['order']) ?? fallbackOrder,
      enabled: map['enabled'] != false,
      title: TextEditingController(text: _string(map['title']) ?? ''),
      body: TextEditingController(text: _string(map['body']) ?? ''),
      items: TextEditingController(text: items),
      table: _asMap(map['table']) == null
          ? null
          : _TemplateTableState.fromMap(_asMap(map['table'])!),
    );
  }

  final Map<String, dynamic> original;
  final String key;
  int order;
  bool enabled;
  final TextEditingController title;
  final TextEditingController body;
  final TextEditingController items;
  final _TemplateTableState? table;

  bool get isGarageCleaning {
    final normalizedKey = key.toLowerCase();
    final normalizedTitle = title.text.toLowerCase();
    return normalizedKey.contains('garage') ||
        normalizedKey.contains('garaje') ||
        normalizedTitle.contains('garaje');
  }

  bool get isOptional =>
      original['optional'] == true ||
      original['isOptional'] == true ||
      isGarageCleaning;

  bool referencesVariable(String variableKey) {
    final marker = '[$variableKey]';
    if (title.text.contains(marker) ||
        body.text.contains(marker) ||
        items.text.contains(marker)) {
      return true;
    }
    return jsonEncode(<String, dynamic>{
      ...original,
      if (table != null) 'table': table!.toJson(),
    }).contains(variableKey);
  }

  Map<String, dynamic> toJson() => {
        ...original,
        'key': key,
        'order': order,
        'title': title.text,
        'body': body.text,
        'items': items.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        'enabled': enabled,
        if (table != null) 'table': table!.toJson(),
      };

  void dispose() {
    title.dispose();
    body.dispose();
    items.dispose();
    table?.dispose();
  }
}

class _TemplateComputedColumn {
  const _TemplateComputedColumn({
    required this.targetIndex,
    required this.operation,
    required this.sourceIndexes,
    required this.format,
    required this.currency,
    required this.readOnly,
  });

  factory _TemplateComputedColumn.fromMap(Map<String, dynamic> map) {
    return _TemplateComputedColumn(
      targetIndex: _int(map['targetIndex']) ?? -1,
      operation: _string(map['operation']) ?? '',
      sourceIndexes: map['sourceIndexes'] is List
          ? (map['sourceIndexes'] as List)
              .map(_int)
              .whereType<int>()
              .toList(growable: false)
          : const [],
      format: _string(map['format']) ?? '',
      currency: _string(map['currency']) ?? 'EUR',
      readOnly: map['readOnly'] == true,
    );
  }

  final int targetIndex;
  final String operation;
  final List<int> sourceIndexes;
  final String format;
  final String currency;
  final bool readOnly;
}

class _TemplateTableState {
  _TemplateTableState({
    required this.original,
    required this.columns,
    required this.rows,
    required this.computedColumns,
    required this.bulkValues,
  });

  factory _TemplateTableState.fromMap(Map<String, dynamic> map) {
    final rawColumns =
        map['columns'] is List ? map['columns'] as List : const <dynamic>[];
    final columns = rawColumns
        .map((value) => TextEditingController(text: value?.toString() ?? ''))
        .toList();
    final rows = <List<TextEditingController>>[];
    if (map['rows'] is List) {
      for (final rawRow in map['rows'] as List) {
        final values = rawRow is List ? rawRow : const <dynamic>[];
        rows.add([
          for (var i = 0; i < values.length || i < columns.length; i++)
            TextEditingController(
              text: i < values.length ? values[i]?.toString() ?? '' : '',
            ),
        ]);
      }
    }
    var computedColumns = map['computedColumns'] is List
        ? (map['computedColumns'] as List)
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .map(_TemplateComputedColumn.fromMap)
            .where((value) => value.targetIndex >= 0)
            .toList(growable: false)
        : const <_TemplateComputedColumn>[];
    if (computedColumns.isEmpty) {
      final frequencyIndex = _tableColumnIndex(
        columns,
        const ['FRECUENCIA', 'FRECUENCIA MENSUAL'],
      );
      final priceIndex = _tableColumnIndex(
        columns,
        const [
          'VALOR POR LIMPIEZA',
          'PRECIO POR LIMPIEZA',
          'PRECIO POR VISITA',
          'PRECIO VISITA',
        ],
      );
      final totalIndex = _tableColumnIndex(
        columns,
        const ['TOTAL MENSUAL', 'IMPORTE MENSUAL'],
      );
      if (frequencyIndex != null && priceIndex != null && totalIndex != null) {
        computedColumns = <_TemplateComputedColumn>[
          _TemplateComputedColumn(
            targetIndex: totalIndex,
            operation: 'multiply',
            sourceIndexes: <int>[frequencyIndex, priceIndex],
            format: 'currency',
            currency: 'EUR',
            readOnly: true,
          ),
        ];
      }
    }
    final sourceIndexes = <int>{
      for (final computed in computedColumns) ...computed.sourceIndexes,
    };
    final state = _TemplateTableState(
      original: Map<String, dynamic>.from(map),
      columns: columns,
      rows: rows,
      computedColumns: computedColumns,
      bulkValues: <int, TextEditingController>{
        for (final index in sourceIndexes)
          index: TextEditingController(
            text: rows.isNotEmpty && index < rows.first.length
                ? rows.first[index].text
                : '',
          ),
      },
    );
    state.recalculateAll();
    return state;
  }

  final Map<String, dynamic> original;
  final List<TextEditingController> columns;
  final List<List<TextEditingController>> rows;
  final List<_TemplateComputedColumn> computedColumns;
  final Map<int, TextEditingController> bulkValues;
  final Set<int> selectedRows = <int>{};
  final ScrollController horizontalScrollController = ScrollController();

  bool get hasComputedColumns => computedColumns.isNotEmpty;

  bool isReadOnlyColumn(int index) => computedColumns.any(
        (computed) => computed.targetIndex == index && computed.readOnly,
      );

  void toggleAllRows(bool selected) {
    selectedRows
      ..clear()
      ..addAll(selected ? List.generate(rows.length, (index) => index) : []);
  }

  void toggleRow(int index, bool selected) {
    if (selected) {
      selectedRows.add(index);
    } else {
      selectedRows.remove(index);
    }
  }

  void applyToSelectedRows() {
    for (final rowIndex in selectedRows) {
      if (rowIndex < 0 || rowIndex >= rows.length) continue;
      for (final entry in bulkValues.entries) {
        cell(rowIndex, entry.key).text = entry.value.text;
      }
      recalculateRow(rowIndex);
    }
  }

  void applyVariableValue(String key, String value) {
    if (key != 'PRECIO_VISITA') return;
    final headerIndex = _tableColumnIndex(
      columns,
      const [
        'VALOR POR LIMPIEZA',
        'PRECIO POR LIMPIEZA',
        'PRECIO POR VISITA',
        'PRECIO VISITA',
      ],
    );
    final calculatedIndex = computedColumns
        .where((computed) => computed.sourceIndexes.length >= 2)
        .map((computed) => computed.sourceIndexes[1])
        .firstOrNull;
    final columnIndex = headerIndex ?? calculatedIndex;
    if (columnIndex != null) applyGlobalValue(columnIndex, value);
  }

  void applyGlobalValue(int columnIndex, String value) {
    if (columnIndex < 0 || columnIndex >= columns.length) return;
    bulkValues[columnIndex]?.text = value;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      cell(rowIndex, columnIndex).text = value;
    }
    recalculateAll();
  }

  double? totalAmount() {
    final totalColumn = _tableColumnIndex(
          columns,
          const ['TOTAL MENSUAL', 'IMPORTE MENSUAL', 'TOTAL'],
        ) ??
        computedColumns.map((computed) => computed.targetIndex).firstOrNull;
    if (totalColumn == null) return null;
    var total = 0.0;
    var found = false;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final value = _parseLocalizedNumber(cell(rowIndex, totalColumn).text);
      if (value == null) continue;
      total += value;
      found = true;
    }
    return found ? total : null;
  }

  void recalculateAll() {
    for (var index = 0; index < rows.length; index++) {
      recalculateRow(index);
    }
  }

  void recalculateRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= rows.length) return;
    for (final computed in computedColumns) {
      if (computed.operation != 'multiply' || computed.sourceIndexes.isEmpty) {
        continue;
      }
      var result = 1.0;
      var valid = true;
      for (final sourceIndex in computed.sourceIndexes) {
        final value = _parseLocalizedNumber(cell(rowIndex, sourceIndex).text);
        if (value == null) {
          valid = false;
          break;
        }
        result *= value;
      }
      cell(rowIndex, computed.targetIndex).text = valid
          ? _formatCalculatedValue(
              result,
              format: computed.format,
              currency: computed.currency,
            )
          : '';
    }
  }

  TextEditingController cell(int rowIndex, int columnIndex) {
    final row = rows[rowIndex];
    while (row.length < columns.length) {
      row.add(TextEditingController());
    }
    return row[columnIndex];
  }

  void addRow() {
    rows.add(List.generate(columns.length, (_) => TextEditingController()));
  }

  void removeRow(int index) {
    if (index < 0 || index >= rows.length) return;
    final removed = rows.removeAt(index);
    for (final controller in removed) {
      controller.dispose();
    }
    final nextSelection = <int>{};
    for (final selected in selectedRows) {
      if (selected < index) nextSelection.add(selected);
      if (selected > index) nextSelection.add(selected - 1);
    }
    selectedRows
      ..clear()
      ..addAll(nextSelection);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        ...original,
        'columns': columns.map((controller) => controller.text).toList(),
        'rows': [
          for (final row in rows)
            row.map((controller) => controller.text).toList(),
        ],
      };

  void dispose() {
    horizontalScrollController.dispose();
    for (final controller in columns) {
      controller.dispose();
    }
    for (final row in rows) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in bulkValues.values) {
      controller.dispose();
    }
  }
}

int? _tableColumnIndex(
  List<TextEditingController> columns,
  List<String> candidates,
) {
  final normalizedCandidates = candidates.map(_normalizeTableColumn).toSet();
  for (var index = 0; index < columns.length; index++) {
    if (normalizedCandidates.contains(
      _normalizeTableColumn(columns[index].text),
    )) {
      return index;
    }
  }
  return null;
}

String _normalizeTableColumn(String value) => value
    .trim()
    .toUpperCase()
    .replaceAll('_', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('Á', 'A')
    .replaceAll('É', 'E')
    .replaceAll('Í', 'I')
    .replaceAll('Ó', 'O')
    .replaceAll('Ú', 'U');

bool _isCleaningTemplateSource(Map<String, dynamic> source) {
  final templateKey = _string(source['key']) ??
      _string(source['templateKey']) ??
      _string(source['presupuestoType']);
  final rawPageLayout = source['pageLayout'];
  final pageLayout = _asMap(rawPageLayout);
  final pageLayoutName = pageLayout == null
      ? _string(rawPageLayout)
      : _string(pageLayout['key']) ?? _string(pageLayout['name']);
  return templateKey == 'stair_cleaning_annual_maintenance' ||
      pageLayoutName == 'cleaning_three_page';
}

bool _isGardenPoolText(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  return normalized.contains('jardin') || normalized.contains('piscina');
}

class _TemplateImageState {
  _TemplateImageState({
    required this.original,
    required this.slot,
    required this.enabled,
    required this.label,
    this.url = '',
    this.blobName = '',
  });

  factory _TemplateImageState.fromMap(Map<String, dynamic> map) {
    return _TemplateImageState(
      original: Map<String, dynamic>.from(map),
      slot: _string(map['slot']) ?? 'photo_1',
      enabled: map['enabled'] != false,
      label: TextEditingController(text: _string(map['label']) ?? ''),
      url: _string(map['url']) ?? '',
      blobName: _string(map['blobName']) ?? '',
    );
  }

  final Map<String, dynamic> original;
  final String slot;
  bool enabled;
  final TextEditingController label;
  String url;
  String blobName;

  void apply(Map<String, dynamic> map) {
    url = _string(map['url']) ?? url;
    blobName = _string(map['blobName']) ?? blobName;
    final nextLabel = _string(map['label']);
    if (nextLabel != null) label.text = nextLabel;
    enabled = map['enabled'] != false;
  }

  Map<String, dynamic> toJson() => {
        ...original,
        'slot': slot,
        'label': label.text,
        'url': url,
        'blobName': blobName,
        'enabled': enabled,
      };

  void dispose() => label.dispose();
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _string(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _int(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _parseLocalizedNumber(String source) {
  final match = RegExp(r'-?[\d.,]+').firstMatch(source.trim());
  if (match == null) return null;
  var normalized = match.group(0)!;
  final hasComma = normalized.contains(',');
  final hasDot = normalized.contains('.');
  if (hasComma && hasDot) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    normalized = normalized.replaceAll(',', '.');
  } else if (hasDot) {
    final parts = normalized.split('.');
    if (parts.length > 1 && parts.last.length == 3) {
      normalized = parts.join();
    }
  }
  return double.tryParse(normalized);
}

String _formatCalculatedValue(
  double value, {
  required String format,
  required String currency,
}) {
  if (format == 'currency') {
    final digits = value == value.roundToDouble() ? 0 : 2;
    final symbol = currency == 'EUR' ? '€' : currency;
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: symbol,
      decimalDigits: digits,
    ).format(value).replaceAll('\u00a0', ' ');
  }
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
