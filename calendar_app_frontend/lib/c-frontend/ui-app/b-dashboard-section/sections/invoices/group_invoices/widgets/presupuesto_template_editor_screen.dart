import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_document_draft_flow.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';

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
  });

  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
}

class _PresupuestoTemplateEditorScreenState
    extends State<PresupuestoTemplateEditorScreen> {
  static const _variableKeys = <String>[
    'CLIENTE',
    'FECHA',
    'MES',
    'ANO',
    'ZONAS_COMUNES',
    'PRODUCTOS_INCLUIDOS',
    'DIAS_TEMPORADA_ALTA',
    'FRECUENCIA_TEMPORADA_BAJA',
    'PRECIO_HORA',
    'PRECIO_PISCINA_PRIVADA',
    'IMPORTE_MENSUAL',
    'DURACION_CONTRATO',
    'PREAVISO',
  ];

  static const _tagFields = <_TemplateVariableField>[
    _TemplateVariableField(
      key: 'FECHA',
      label: 'Fecha [FECHA]',
      hint: 'Ej. 31/07/2026',
      icon: Icons.calendar_today_outlined,
      keyboardType: TextInputType.datetime,
    ),
    _TemplateVariableField(
      key: 'MES',
      label: 'Mes [MES]',
      hint: 'Ej. julio',
      icon: Icons.calendar_view_month_outlined,
    ),
    _TemplateVariableField(
      key: 'ANO',
      label: 'Ano [ANO]',
      hint: 'Ej. 2026',
      icon: Icons.event_outlined,
      keyboardType: TextInputType.number,
    ),
    _TemplateVariableField(
      key: 'PRECIO_HORA',
      label: 'Precio por hora [PRECIO_HORA]',
      hint: 'Ej. 25,00 EUR',
      icon: Icons.euro_rounded,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    ),
    _TemplateVariableField(
      key: 'PRECIO_PISCINA_PRIVADA',
      label: 'Precio piscina privada [PRECIO_PISCINA_PRIVADA]',
      hint: 'Ej. 120,00 EUR / mes',
      icon: Icons.pool_outlined,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    ),
    _TemplateVariableField(
      key: 'ZONAS_COMUNES',
      label: 'Zonas comunes [ZONAS_COMUNES]',
      hint: 'Ej. jardines, accesos y piscina',
      icon: Icons.location_city_outlined,
      maxLines: 2,
    ),
    _TemplateVariableField(
      key: 'PRODUCTOS_INCLUIDOS',
      label: 'Productos incluidos [PRODUCTOS_INCLUIDOS]',
      hint: 'Ej. cloro, regulador de pH y abono',
      icon: Icons.inventory_2_outlined,
      maxLines: 2,
    ),
    _TemplateVariableField(
      key: 'DIAS_TEMPORADA_ALTA',
      label: 'Dias en temporada alta [DIAS_TEMPORADA_ALTA]',
      hint: 'Ej. tres dias por semana',
      icon: Icons.sunny_snowing,
    ),
    _TemplateVariableField(
      key: 'FRECUENCIA_TEMPORADA_BAJA',
      label: 'Frecuencia en temporada baja [FRECUENCIA_TEMPORADA_BAJA]',
      hint: 'Ej. una vez por semana',
      icon: Icons.date_range_outlined,
    ),
    _TemplateVariableField(
      key: 'DURACION_CONTRATO',
      label: 'Duracion del contrato [DURACION_CONTRATO]',
      hint: 'Ej. 12 meses',
      icon: Icons.description_outlined,
    ),
    _TemplateVariableField(
      key: 'PREAVISO',
      label: 'Preaviso [PREAVISO]',
      hint: 'Ej. 30 dias',
      icon: Icons.notifications_active_outlined,
    ),
  ];

  final _name = TextEditingController();
  final _instagram = TextEditingController();
  final _website = TextEditingController();
  final _watermark = TextEditingController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _intro = TextEditingController();
  final Map<String, TextEditingController> _variables = {};
  final List<_TemplateSectionState> _sections = [];
  final List<_TemplateImageState> _images = [];
  late final PresupuestoDocumentDraftFlow _documentFlow;
  final Map<String, String> _loadedDocumentVariables = {};

  List<Map<String, dynamic>> _templates = const [];
  List<Map<String, dynamic>> _defaultTemplates = const [];
  String? _templateId;
  String? _logoUrl;
  int _activeStep = 0;
  bool _loading = true;
  bool _saving = false;
  bool _creatingDocumentFromTemplate = false;
  bool _downloading = false;
  bool _previewing = false;
  String? _creatingDefaultKey;
  String? _deletingTemplateId;
  String? _previewingDefaultKey;
  String? _previewingSavedTemplateId;

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
    setState(() => _loading = true);
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
          return;
        }
        if (!widget.createDocumentDraft) {
          throw Exception(
              'Selecciona un presupuesto para editar el documento.');
        }
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
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _createFromDefault(Map<String, dynamic> template) async {
    final key = _string(template['key']);
    if (key == null || key.isEmpty || _creatingDefaultKey != null) return;
    setState(() => _creatingDefaultKey = key);
    try {
      if (!widget.templateOnly) {
        final requestedContent = _documentContentFromSource(template);
        final created = await _documentFlow.createFromDefault(
          key: key,
          groupId: widget.groupId,
          content: requestedContent,
        );
        final createdContent = _createdDocumentContent(created.response);
        setState(() {
          _templateId = null;
          _hydrate(createdContent ?? requestedContent);
          _rememberCurrentDocumentVariables();
          _activeStep = 0;
        });
        await widget.onDocumentSaved?.call();
        if (mounted) {
          showSuccessSnack(context, 'Presupuesto guardado como borrador.');
        }
        return;
      }

      final created = await widget.api.createTemplateFromDefault(
        key: key,
        groupId: widget.groupId,
      );
      final createdTemplate = _asMap(created['template']) ?? created;
      final id =
          _string(createdTemplate['_id']) ?? _string(createdTemplate['id']);
      setState(() {
        if (id != null && id.isNotEmpty) _templateId = id;
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

  Map<String, dynamic> _documentContentFromSource(
    Map<String, dynamic> source,
  ) {
    final sourceVariables = _asMap(source['variables']) ?? const {};
    final currentClient = _variableController('CLIENTE').text.trim();
    return <String, dynamic>{
      'name': _string(source['name']) ?? 'Presupuesto',
      'header': _asMap(source['header']) ?? const <String, dynamic>{},
      'watermark': _string(source['watermark']) ?? '',
      'title': _string(source['title']) ?? '',
      'subtitle': _string(source['subtitle']) ?? '',
      'intro': _string(source['intro']) ?? '',
      'variables': <String, dynamic>{
        ...sourceVariables,
        if (currentClient.isNotEmpty) 'CLIENTE': currentClient,
      },
      'sections': source['sections'] is List ? source['sections'] : const [],
      'images': source['images'] is List ? source['images'] : const [],
    };
  }

  Map<String, dynamic>? _createdDocumentContent(
    Map<String, dynamic> response,
  ) {
    for (final source in <Map<String, dynamic>>[
      response,
      ...['presupuesto', 'document', 'data']
          .map((key) => response[key])
          .whereType<Map>()
          .map((value) => Map<String, dynamic>.from(value)),
    ]) {
      for (final key in const [
        'content',
        'templateContent',
        'documentTemplateContent',
      ]) {
        final content = _asMap(source[key]);
        if (content != null) return content;
      }
    }
    return null;
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

  void _hydrate(Map<String, dynamic> source) {
    _name.text = _string(source['name']) ?? 'Plantilla presupuesto';
    final header = _asMap(source['header']) ?? const {};
    _instagram.text = _string(header['instagram']) ?? '';
    _website.text = _string(header['website']) ?? '';
    _logoUrl = _string(header['logoUrl']);
    _watermark.text = _string(source['watermark']) ?? '';
    _title.text = _string(source['title']) ?? '';
    _subtitle.text = _string(source['subtitle']) ?? '';
    _intro.text = _string(source['intro']) ?? '';

    for (final controller in _variables.values) {
      controller.dispose();
    }
    _variables.clear();
    final variables = _asMap(source['variables']) ?? const {};
    final keys = {..._variableKeys, ...variables.keys.map((e) => e.toString())};
    for (final key in keys) {
      _variables[key] =
          TextEditingController(text: _string(variables[key]) ?? '');
    }

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
      ..addAll(_imageStates(source['images']));
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
    return List.generate(6, (index) {
      final slot = 'photo_${index + 1}';
      return _TemplateImageState.fromMap(
        bySlot[slot] ?? {'slot': slot, 'label': 'Foto ${index + 1}'},
      );
    });
  }

  Future<void> _save({bool silent = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (widget.templateOnly) {
        await _persistTemplate();
      } else {
        final creating = _documentFlow.presupuestoId == null;
        final presupuestoId = await _documentFlow.save(
          groupId: widget.groupId,
          content: _payload(includeTemplateId: false),
        );
        if (creating) {
          _rememberCurrentDocumentVariables();
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
    setState(() => _previewing = true);
    try {
      final response = widget.templateOnly
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
      await launchFileDownload(
        response.bodyBytes,
        fileName: _fileName('preview'),
        mimeType: 'application/pdf',
      );
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _previewing = false);
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
      await launchFileDownload(
        response.bodyBytes,
        fileName: 'presupuesto-plantilla-$key-preview.pdf',
        mimeType: 'application/pdf',
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
    return {
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
      'images': _images.map((image) => image.toJson()).toList(),
    };
  }

  void _applyLoadedDocumentVariables(Map<String, dynamic> payload) {
    final values = <String, String>{};
    final raw = payload['variables'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        values[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    } else if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final key = (item['key'] ?? '').toString().trim();
        if (key.isEmpty) continue;
        final value = item['value'] ?? item['resolvedValue'] ?? '';
        values[key] = value.toString();
      }
    }
    for (final entry in values.entries) {
      _variableController(entry.key).text = entry.value;
    }
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

  TextEditingController _variableController(String key) {
    return _variables.putIfAbsent(key, () => TextEditingController());
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
        'variables': {for (final key in _variableKeys) key: ''},
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
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
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
                    constraints: const BoxConstraints(maxWidth: 1360),
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

  List<_EditorStep> _editorSteps() {
    final steps = <_EditorStep>[];
    final canChooseTemplate = widget.templateOnly ||
        (widget.createDocumentDraft && _documentFlow.presupuestoId == null);
    final baseChildren = <Widget>[
      if (canChooseTemplate && _defaultTemplates.isNotEmpty)
        _buildDefaultTemplatesCard(),
      if (canChooseTemplate && (_templates.isNotEmpty || widget.templateOnly))
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
                    onSelected: (_) => setState(() => _activeStep = i),
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
          onPressed: _saving || _creatingDocumentFromTemplate
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
              _heroChip(
                theme,
                icon: Icons.person_outline_rounded,
                label: _variableController('CLIENTE').text.trim().isEmpty
                    ? 'Cliente'
                    : _variableController('CLIENTE').text.trim(),
              ),
              _heroChip(
                theme,
                icon: Icons.euro_rounded,
                label:
                    _variableController('IMPORTE_MENSUAL').text.trim().isEmpty
                        ? 'Precio'
                        : _variableController('IMPORTE_MENSUAL').text.trim(),
              ),
              _heroChip(
                theme,
                icon: Icons.segment_rounded,
                label: '${_sections.length} secciones',
              ),
              _heroChip(
                theme,
                icon: Icons.photo_library_outlined,
                label:
                    '${_images.where((img) => img.url.trim().isNotEmpty).length}/6 imagenes',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              _defaultTemplates.length > 1 && constraints.maxWidth >= 920
                  ? 2
                  : 1;
          const spacing = 12.0;
          final itemWidth =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;
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
                const SizedBox(height: 9),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Totalmente editable',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
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
        onPressed: creating || previewing || key == null
            ? null
            : () => _createFromDefault(template),
        icon: creating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded, size: 19),
        label: Text(creating ? 'Preparando...' : 'Usar plantilla'),
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
              color: _isDark(theme)
                  ? const Color(0xFF3F7596).withValues(alpha: 0.46)
                  : cs.primary.withValues(alpha: 0.18),
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
              final clientField = _field(
                _variableController('CLIENTE'),
                'Nombre del cliente [CLIENTE]',
                hint: 'Ej. Comunidad Las Alondras',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              );
              final priceField = _field(
                _variableController('IMPORTE_MENSUAL'),
                'Importe mensual [IMPORTE_MENSUAL]',
                hint: 'Ej. 714,48 EUR / mes',
                prefixIcon: Icons.euro_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              );

              if (constraints.maxWidth < 620) {
                return Column(children: [clientField, priceField]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: clientField),
                  const SizedBox(width: 12),
                  Expanded(child: priceField),
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
    final knownKeys = {
      'CLIENTE',
      'IMPORTE_MENSUAL',
      for (final field in _tagFields) field.key,
    };
    final customFields = _variables.keys
        .where((key) => !knownKeys.contains(key))
        .map(
          (key) => _TemplateVariableField(
            key: key,
            label: '${key.replaceAll('_', ' ')} [$key]',
            hint: 'Valor para [$key]',
            icon: Icons.data_object_rounded,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final fields = [..._tagFields, ...customFields];

    return Column(
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
                    child: _field(
                      _variableController(field.key),
                      field.label,
                      hint: field.hint,
                      prefixIcon: field.icon,
                      keyboardType: field.keyboardType,
                      maxLines: field.maxLines,
                    ),
                  ),
              ],
            );
          },
        ),
        Divider(color: _editorBorder(theme, alpha: 0.72)),
        const SizedBox(height: 14),
      ],
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

  Widget _buildLivePreviewCard() {
    final theme = Theme.of(context);
    final client = _variableController('CLIENTE').text.trim();
    final price = _variableController('IMPORTE_MENSUAL').text.trim();
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
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isDark(theme)
                ? const Color(0xFFBFE7FF).withValues(alpha: 0.22)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
                          client.isEmpty ? 'Nombre del cliente' : client,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF20242A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (price.isNotEmpty)
                          Text(
                            price,
                            style: theme.textTheme.bodySmall?.copyWith(
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
        ],
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
            onPressed: _previewing ? null : _previewPdf,
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
            onPressed: _downloading ? null : _downloadPdf,
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
    int maxLines = 1,
    int? minLines,
    String? hint,
    bool dense = false,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool markdown = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: (_) => setState(() {}),
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
          section.enabled ? '$itemsCount items activos' : 'Seccion desactivada',
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
    required this.key,
    required this.order,
    required this.enabled,
    required this.title,
    required this.body,
    required this.items,
  });

  factory _TemplateSectionState.fromMap(
    Map<String, dynamic> map, {
    int fallbackOrder = 1,
  }) {
    final items = map['items'] is List
        ? (map['items'] as List).map((e) => e.toString()).join('\n')
        : '';
    return _TemplateSectionState(
      key: _string(map['key']) ?? 'section_$fallbackOrder',
      order: _int(map['order']) ?? fallbackOrder,
      enabled: map['enabled'] != false,
      title: TextEditingController(text: _string(map['title']) ?? ''),
      body: TextEditingController(text: _string(map['body']) ?? ''),
      items: TextEditingController(text: items),
    );
  }

  final String key;
  int order;
  bool enabled;
  final TextEditingController title;
  final TextEditingController body;
  final TextEditingController items;

  Map<String, dynamic> toJson() => {
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
      };

  void dispose() {
    title.dispose();
    body.dispose();
    items.dispose();
  }
}

class _TemplateImageState {
  _TemplateImageState({
    required this.slot,
    required this.enabled,
    required this.label,
    this.url = '',
    this.blobName = '',
  });

  factory _TemplateImageState.fromMap(Map<String, dynamic> map) {
    return _TemplateImageState(
      slot: _string(map['slot']) ?? 'photo_1',
      enabled: map['enabled'] != false,
      label: TextEditingController(text: _string(map['label']) ?? ''),
      url: _string(map['url']) ?? '',
      blobName: _string(map['blobName']) ?? '',
    );
  }

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
