part of '../../presupuesto_template_editor_screen.dart';

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
  final Set<String> _libraryImageBusySlots = <String>{};
  late final PresupuestoDocumentDraftFlow _documentFlow;
  final Map<String, String> _loadedDocumentVariables = {};
  final Map<String, _TemplateVariableField> _variableFieldDefinitions = {};
  List<String> _unresolvedKeys = const [];
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
      final isAutomaticDate = const {'FECHA', 'DIA', 'MES', 'ANO', 'AÑO'}
          .contains(key.toUpperCase());
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
        isAutomatic: definition['isAutomatic'] == true || isAutomaticDate,
        isUsedInTemplate: definition['isUsedInTemplate'] != false,
        readOnly: definition['readOnly'] == true ||
            isAutomaticDate ||
            (calculation?.readOnly ?? false),
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
          final refreshed =
              await widget.api.getTemplateVariables(presupuestoId);
          _applyLoadedDocumentVariables(refreshed);
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
      if (!widget.templateOnly) {
        await _save(silent: true);
        if (!mounted || !await _confirmUnresolvedVariables('previsualizar')) {
          return;
        }
      }
      final response = widget.templateOnly
          ? await widget.api.previewLiveTemplatePdf(
              groupId: widget.groupId,
              template: _payload(includeTemplateId: false),
            )
          : await widget.api.previewTemplatePdf(
              _documentFlow.presupuestoId!,
            );
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

  Future<bool> _confirmUnresolvedVariables(String action) async {
    if (_unresolvedKeys.isEmpty) return true;
    final keys = _unresolvedKeys.map((key) => '[$key]').join(', ');
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Variables sin completar'),
            content: Text(
              'Todavía quedan variables sin valor: $keys. Si continúas, aparecerán entre corchetes en el PDF.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Volver a editar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Continuar y $action'),
              ),
            ],
          ),
        ) ??
        false;
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

  Future<void> _chooseLibraryImage(_TemplateImageState image) async {
    if (_libraryImageBusySlots.contains(image.slot)) return;
    final selected = await showPresupuestoImageLibraryPicker(
      context,
      api: widget.api,
      groupId: widget.groupId,
    );
    if (selected == null || !mounted) return;

    setState(() => _libraryImageBusySlots.add(image.slot));
    try {
      final targetId = widget.templateOnly
          ? await _ensureTemplate()
          : await _ensureDocumentDraft();
      final response = await widget.api.attachImageLibraryAsset(
        targetId: targetId,
        imageId: selected.id,
        slot: image.slot,
        label: image.label.text,
        enabled: image.enabled,
      );
      final attached = _extractImage(response, image.slot);
      if (!mounted) return;
      setState(() {
        image.apply(
          attached ??
              <String, dynamic>{
                'url': selected.readUrl,
                'label': image.label.text.trim().isEmpty
                    ? selected.name
                    : image.label.text,
                'enabled': image.enabled,
              },
        );
      });
      showSuccessSnack(context, 'Imagen añadida desde la biblioteca.');
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _libraryImageBusySlots.remove(image.slot));
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
    final image = _asMap(response['image']) ??
        _asMap(response['attachedImage']) ??
        _asMap(response['asset']);
    if (image != null) return image;
    final target = _asMap(response['target']) ??
        _asMap(response['template']) ??
        _asMap(response['presupuesto']);
    final images = target?['images'] ?? response['images'];
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
    final rawVariables = payload['variables'];
    final rawFields = payload['variableFields'] ??
        (payload['variables'] is List ? payload['variables'] : null);
    final definitions = _readVariableFieldDefinitions(rawVariables)
      ..addAll(_readVariableFieldDefinitions(rawFields));
    final fieldValues = _readVariableFieldValues(rawFields);
    final explicitValues = rawVariables is Map
        ? <String, String>{
            for (final entry in rawVariables.entries)
              entry.key.toString(): _asMap(entry.value) == null
                  ? entry.value?.toString() ?? ''
                  : _displayedVariableValue(_asMap(entry.value)!)?.toString() ??
                      '',
          }
        : _readVariableFieldValues(rawVariables);
    final rawUnresolved = payload['unresolvedKeys'];
    _unresolvedKeys = rawUnresolved is List
        ? rawUnresolved
            .map((item) => item.toString().trim())
            .where((key) => key.isNotEmpty)
            .toList(growable: false)
        : const [];
    for (final key in _unresolvedKeys) {
      definitions.putIfAbsent(
        key,
        () => _readVariableFieldDefinitions(<String>[key])[key]!,
      );
    }

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
      final definition = _variableFieldDefinitions[entry.key];
      final key = entry.key.toUpperCase();
      if (definition?.readOnly == true ||
          definition?.isAutomatic == true ||
          const {'FECHA', 'DIA', 'MES', 'ANO', 'AÑO'}.contains(key)) {
        continue;
      }
      final value = entry.value.text.trim();
      if (_loadedDocumentVariables[entry.key] == value) continue;
      changes[entry.key] = value.isEmpty ? null : value;
    }
    if (changes.isEmpty) return;
    await widget.api.updateTemplateVariables(
      presupuestoId,
      variables: changes,
    );
    final refreshed = await widget.api.getTemplateVariables(presupuestoId);
    _applyLoadedDocumentVariables(refreshed);
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

  String _variableDisplayLabel(_TemplateVariableField field) =>
      field.label.replaceAll('[${field.key}]', '').trim();

  Future<List<GroupClient>> _searchActiveClients(String search) {
    final override = widget.clientSearch;
    if (override != null) return override(search);
    return _clientsApi.list(
      groupId: widget.groupId,
      search: search,
      active: true,
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
  Widget build(BuildContext context) =>
      _TemplateEditorLayout(this).build(context);

  bool _isDark(ThemeData theme) => _TemplateEditorLayout(this)._isDark(theme);

  Color _editorCardBg(ThemeData theme) =>
      _TemplateEditorLayout(this)._editorCardBg(theme);

  Color _editorPanelBg(ThemeData theme) =>
      _TemplateEditorLayout(this)._editorPanelBg(theme);

  Color _editorInsetBg(ThemeData theme) =>
      _TemplateEditorLayout(this)._editorInsetBg(theme);

  Color _editorSoftAccentBg(ThemeData theme) =>
      _TemplateEditorLayout(this)._editorSoftAccentBg(theme);

  Color _editorBorder(ThemeData theme, {double alpha = 1}) =>
      _TemplateEditorLayout(this)._editorBorder(theme, alpha: alpha);

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

  Widget _buildDefaultTemplatesCard() =>
      _TemplateSelection(this)._buildDefaultTemplatesCard();

  Widget _buildTemplateSelectorCard() =>
      _TemplateSelection(this)._buildTemplateSelectorCard();

  Widget _buildMainCopyCard() =>
      _TemplateVariableFields(this)._buildMainCopyCard();

  bool _isRedundantPricingField(_TemplateVariableField field) {
    if (!_variables.containsKey('TOTAL_MENSUAL')) return false;
    if (field.key == 'IMPORTE_MENSUAL') return true;
    return !field.isUsedInTemplate &&
        const {'FRECUENCIA_MENSUAL', 'PRECIO_VISITA'}.contains(field.key);
  }

  Widget _buildSectionsCard() =>
      _TemplateSectionEditors(this)._buildSectionsCard();

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

  Widget _buildLivePreviewCard() =>
      _TemplateDocumentPreview(this)._buildLivePreviewCard();

  String _resolvePreviewTags(String source) {
    var resolved = source;
    for (final entry in _variables.entries) {
      final value = entry.value.text.trim();
      if (value.isEmpty) continue;
      resolved = resolved.replaceAll('[${entry.key}]', value);
    }
    return resolved;
  }

  Widget _buildImagesCard() => _TemplateImageEditor(this)._buildImagesCard();

  Widget _buildDocumentActionsCard() =>
      _TemplateDocumentPreview(this)._buildDocumentActionsCard();

  Widget _card({
    required String title,
    required Widget child,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
  }) =>
      _TemplateEditorControls(this)._card(
          title: title,
          child: child,
          subtitle: subtitle,
          icon: icon,
          trailing: trailing);

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
  }) =>
      _TemplateEditorControls(this)._field(controller, label,
          fieldKey: fieldKey,
          maxLines: maxLines,
          minLines: minLines,
          hint: hint,
          dense: dense,
          prefixIcon: prefixIcon,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          markdown: markdown,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          disabledMessage: disabledMessage,
          showLabel: showLabel);

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

  void _duplicateSection(int index) {
    if (index < 0 || index >= _sections.length) return;
    final source = _sections[index];
    final existingKeys = _sections.map((section) => section.key).toSet();
    var newKey = '${source.key}_copy';
    var suffix = 2;
    while (existingKeys.contains(newKey)) {
      newKey = '${source.key}_copy$suffix';
      suffix++;
    }
    final title = source.title.text.trim();
    final duplicated = _TemplateSectionState.fromMap({
      ...source.toJson(),
      'key': newKey,
      'title': title.isEmpty ? 'Seccion (copia)' : '$title (copia)',
    });
    setState(() => _sections.insert(index + 1, duplicated));
  }

  // Keep State.setState calls on the existing lifecycle owner.
  void _updateEditorState(VoidCallback action) => setState(action);
}
