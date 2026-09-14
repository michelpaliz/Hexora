class ManualEditorActionCapability {
  final String id;
  final String label;
  final String description;
  final String mode; // 'native' | 'frontend_helper'
  final String? whenToUse;
  final List<String> examples;

  const ManualEditorActionCapability({
    required this.id,
    required this.label,
    required this.description,
    required this.mode,
    this.whenToUse,
    required this.examples,
  });

  bool get isNative => mode == 'native';
  bool get isFrontendHelper => mode == 'frontend_helper';

  factory ManualEditorActionCapability.fromJson(Map<String, dynamic> j) {
    return ManualEditorActionCapability(
      id: j['id']?.toString() ?? '',
      label: j['label']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      mode: j['mode']?.toString() ?? 'native',
      whenToUse: j['whenToUse']?.toString(),
      examples: (j['examples'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

class ManualEditorUnsupportedItem {
  final String id;
  final String label;
  final String reason;

  const ManualEditorUnsupportedItem({
    required this.id,
    required this.label,
    required this.reason,
  });

  factory ManualEditorUnsupportedItem.fromJson(Map<String, dynamic> j) {
    return ManualEditorUnsupportedItem(
      id: j['id']?.toString() ?? '',
      label: j['label']?.toString() ?? '',
      reason: j['reason']?.toString() ?? '',
    );
  }
}

class ManualEditorLocalizedText {
  final String? es;
  final String? en;

  const ManualEditorLocalizedText({this.es, this.en});

  factory ManualEditorLocalizedText.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return ManualEditorLocalizedText(
        es: map['es']?.toString(),
        en: map['en']?.toString(),
      );
    }
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) {
      return const ManualEditorLocalizedText();
    }
    return ManualEditorLocalizedText(es: text, en: text);
  }

  String resolve(String lang, {String fallback = ''}) {
    final normalized = lang.trim().toLowerCase();
    final primary = normalized.startsWith('es') ? es : en;
    final secondary = normalized.startsWith('es') ? en : es;
    final resolved = (primary ?? '').trim().isNotEmpty
        ? primary!.trim()
        : (secondary ?? '').trim();
    return resolved.isNotEmpty ? resolved : fallback;
  }
}

class ManualEditorBlockTypeCapability {
  final String id;
  final bool enabled;
  final bool recommended;
  final bool billable;
  final int sortOrder;
  final ManualEditorLocalizedText label;
  final ManualEditorLocalizedText description;
  final ManualEditorLocalizedText tooltip;
  final ManualEditorLocalizedText example;

  const ManualEditorBlockTypeCapability({
    required this.id,
    required this.enabled,
    required this.recommended,
    required this.billable,
    required this.sortOrder,
    required this.label,
    required this.description,
    required this.tooltip,
    required this.example,
  });

  factory ManualEditorBlockTypeCapability.fromJson(Map<String, dynamic> j) {
    int parseInt(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return ManualEditorBlockTypeCapability(
      id: j['id']?.toString() ?? '',
      enabled: j['enabled'] != false,
      recommended: j['recommended'] == true,
      billable: j['billable'] == true,
      sortOrder: parseInt(j['sortOrder'], 999),
      label: ManualEditorLocalizedText.fromDynamic(j['label']),
      description: ManualEditorLocalizedText.fromDynamic(j['description']),
      tooltip: ManualEditorLocalizedText.fromDynamic(j['tooltip']),
      example: ManualEditorLocalizedText.fromDynamic(j['example']),
    );
  }
}

class ManualEditorCapabilities {
  final String title;
  final String summary;
  final List<ManualEditorActionCapability> actions;
  final List<ManualEditorUnsupportedItem> unsupported;
  final List<String> rules;
  final int version;
  final String? groupId;
  final String lang;
  final String source;
  final String fallbackBlockTypeId;
  final List<ManualEditorBlockTypeCapability> blockTypes;

  const ManualEditorCapabilities({
    required this.title,
    required this.summary,
    required this.actions,
    required this.unsupported,
    required this.rules,
    required this.version,
    required this.groupId,
    required this.lang,
    required this.source,
    required this.fallbackBlockTypeId,
    required this.blockTypes,
  });

  factory ManualEditorCapabilities.fromJson(Map<String, dynamic> j) {
    final root = j['invoiceEditor'] is Map
        ? Map<String, dynamic>.from(j['invoiceEditor'] as Map)
        : j;
    final scope = root['scope'] is Map
        ? Map<String, dynamic>.from(root['scope'] as Map)
        : const <String, dynamic>{};
    final defaults = root['defaults'] is Map
        ? Map<String, dynamic>.from(root['defaults'] as Map)
        : const <String, dynamic>{};
    final rawBlockTypes = root['blockTypes'] as List?;
    final parsedBlockTypes = rawBlockTypes == null
        ? const <ManualEditorBlockTypeCapability>[]
        : rawBlockTypes
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(ManualEditorBlockTypeCapability.fromJson)
            .where((item) => item.id.trim().isNotEmpty)
            .toList(growable: false);

    final legacyActions = (root['actions'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .map(ManualEditorActionCapability.fromJson)
            .toList() ??
        const <ManualEditorActionCapability>[];

    final actions = parsedBlockTypes.isNotEmpty
        ? parsedBlockTypes
            .map(
              (item) => ManualEditorActionCapability(
                id: item.id,
                label: item.label.resolve(
                  scope['lang']?.toString() ?? '',
                  fallback: item.id,
                ),
                description: item.description.resolve(
                  scope['lang']?.toString() ?? '',
                  fallback: item.tooltip.resolve(
                    scope['lang']?.toString() ?? '',
                  ),
                ),
                mode: item.billable ? 'native' : 'frontend_helper',
                whenToUse: item.tooltip
                        .resolve(scope['lang']?.toString() ?? '')
                        .trim()
                        .isEmpty
                    ? null
                    : item.tooltip.resolve(scope['lang']?.toString() ?? ''),
                examples: [
                  item.example.resolve(scope['lang']?.toString() ?? ''),
                ].where((e) => e.trim().isNotEmpty).toList(growable: false),
              ),
            )
            .toList(growable: false)
        : legacyActions;

    return ManualEditorCapabilities(
      title: root['title']?.toString() ?? '',
      summary: root['summary']?.toString() ?? '',
      actions: actions,
      unsupported: (root['unsupported'] as List?)
              ?.whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .map(ManualEditorUnsupportedItem.fromJson)
              .toList() ??
          const <ManualEditorUnsupportedItem>[],
      rules: (root['rules'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[],
      version: root['version'] is num ? (root['version'] as num).toInt() : 1,
      groupId: scope['groupId']?.toString(),
      lang: scope['lang']?.toString() ?? '',
      source: scope['source']?.toString() ?? '',
      fallbackBlockTypeId:
          defaults['fallbackBlockTypeId']?.toString().trim().isNotEmpty == true
              ? defaults['fallbackBlockTypeId'].toString().trim()
              : 'item',
      blockTypes: parsedBlockTypes,
    );
  }

  factory ManualEditorCapabilities.fallback() {
    // Used when the capabilities endpoint is unavailable (e.g. not yet deployed).
    // Once the server endpoint is live, these are replaced by server-driven values.
    const blockTypes = <ManualEditorBlockTypeCapability>[
      ManualEditorBlockTypeCapability(
        id: 'item',
        enabled: true,
        recommended: true,
        billable: true,
        sortOrder: 1,
        label: ManualEditorLocalizedText(es: 'Ítem', en: 'Item'),
        description: ManualEditorLocalizedText(
          es: 'Línea facturable con cantidad, precio e impuesto.',
          en: 'Billable line with quantity, price, and tax.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Usa cantidad, precio unitario e impuesto.',
          en: 'Uses quantity, unit price, and tax rate.',
        ),
        example: ManualEditorLocalizedText(
          es: 'Mantenimiento jardín mensual - 2 h - 45,00 EUR',
          en: 'Monthly garden maintenance - 2 h - 45.00 EUR',
        ),
      ),
      ManualEditorBlockTypeCapability(
        id: 'note',
        enabled: true,
        recommended: false,
        billable: false,
        sortOrder: 2,
        label: ManualEditorLocalizedText(es: 'Nota', en: 'Note'),
        description: ManualEditorLocalizedText(
          es: 'Texto libre informativo, no facturable.',
          en: 'Free-form informational text, not billable.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Añade aclaraciones o comentarios a la factura.',
          en: 'Add clarifications or comments to the invoice.',
        ),
        example: ManualEditorLocalizedText(
          es: 'Pago a 30 días desde la fecha de emisión.',
          en: 'Payment due 30 days from issue date.',
        ),
      ),
      ManualEditorBlockTypeCapability(
        id: 'checklist',
        enabled: true,
        recommended: false,
        billable: false,
        sortOrder: 3,
        label: ManualEditorLocalizedText(es: 'Lista de tareas', en: 'Checklist'),
        description: ManualEditorLocalizedText(
          es: 'Lista de ítems con casillas de verificación.',
          en: 'List of items with checkboxes.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Útil para detallar entregables o tareas completadas.',
          en: 'Useful for listing deliverables or completed tasks.',
        ),
        example: ManualEditorLocalizedText(
          es: 'Revisión de código, Despliegue, Documentación',
          en: 'Code review, Deployment, Documentation',
        ),
      ),
      ManualEditorBlockTypeCapability(
        id: 'date',
        enabled: true,
        recommended: false,
        billable: false,
        sortOrder: 4,
        label: ManualEditorLocalizedText(es: 'Fecha', en: 'Date'),
        description: ManualEditorLocalizedText(
          es: 'Agrupa bloques bajo una fecha específica.',
          en: 'Groups blocks under a specific date.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Organiza el trabajo por día.',
          en: 'Organize work by day.',
        ),
        example: ManualEditorLocalizedText(
          es: '12 de marzo de 2025',
          en: 'March 12, 2025',
        ),
      ),
      ManualEditorBlockTypeCapability(
        id: 'section',
        enabled: true,
        recommended: false,
        billable: false,
        sortOrder: 5,
        label: ManualEditorLocalizedText(es: 'Sección', en: 'Section'),
        description: ManualEditorLocalizedText(
          es: 'Encabezado principal para agrupar bloques relacionados.',
          en: 'Top-level heading to group related blocks.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Divide la factura en secciones temáticas.',
          en: 'Divide the invoice into thematic sections.',
        ),
        example: ManualEditorLocalizedText(
          es: 'Desarrollo web',
          en: 'Web development',
        ),
      ),
      ManualEditorBlockTypeCapability(
        id: 'subsection',
        enabled: true,
        recommended: false,
        billable: false,
        sortOrder: 6,
        label: ManualEditorLocalizedText(es: 'Subsección', en: 'Subsection'),
        description: ManualEditorLocalizedText(
          es: 'Encabezado secundario dentro de una sección.',
          en: 'Secondary heading within a section.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Subdivide una sección en partes más detalladas.',
          en: 'Subdivide a section into more detailed parts.',
        ),
        example: ManualEditorLocalizedText(
          es: 'Frontend / Backend',
          en: 'Frontend / Backend',
        ),
      ),
      ManualEditorBlockTypeCapability(
        id: 'divider',
        enabled: true,
        recommended: false,
        billable: false,
        sortOrder: 7,
        label: ManualEditorLocalizedText(es: 'Separador', en: 'Divider'),
        description: ManualEditorLocalizedText(
          es: 'Línea horizontal para separar visualmente bloques.',
          en: 'Horizontal line to visually separate blocks.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Mejora la legibilidad de la factura.',
          en: 'Improves invoice readability.',
        ),
        example: ManualEditorLocalizedText(es: '—', en: '—'),
      ),
      ManualEditorBlockTypeCapability(
        id: 'worker',
        enabled: true,
        recommended: false,
        billable: true,
        sortOrder: 8,
        label: ManualEditorLocalizedText(es: 'Trabajador', en: 'Worker'),
        description: ManualEditorLocalizedText(
          es: 'Línea facturable asociada a un trabajador específico.',
          en: 'Billable line associated with a specific worker.',
        ),
        tooltip: ManualEditorLocalizedText(
          es: 'Asocia horas o servicios a un miembro del equipo.',
          en: 'Associate hours or services to a team member.',
        ),
        example: ManualEditorLocalizedText(
          es: 'Juan García - 8 h - 35,00 EUR/h',
          en: 'John Smith - 8 h - 35.00 EUR/h',
        ),
      ),
    ];
    return const ManualEditorCapabilities(
      title: '',
      summary: '',
      actions: [],
      unsupported: <ManualEditorUnsupportedItem>[],
      rules: <String>[],
      version: 1,
      groupId: null,
      lang: 'es',
      source: 'frontend-fallback',
      fallbackBlockTypeId: 'item',
      blockTypes: blockTypes,
    );
  }

  List<ManualEditorBlockTypeCapability> enabledBlockTypes({
    required String lang,
  }) {
    final enabled = blockTypes
        .where((item) => item.enabled && item.id.trim().isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.label
            .resolve(lang, fallback: a.id)
            .compareTo(b.label.resolve(lang, fallback: b.id));
      });
    if (enabled.isNotEmpty) return enabled;
    return ManualEditorCapabilities.fallback().blockTypes;
  }

  String? labelFor(String blockTypeId, {String lang = 'es'}) {
    for (final item in blockTypes) {
      if (item.id == blockTypeId) {
        return item.label.resolve(lang, fallback: blockTypeId);
      }
    }
    for (final a in actions) {
      if (a.id == blockTypeId) return a.label;
    }
    return null;
  }

  bool isUnsupported(String blockTypeId) =>
      unsupported.any((u) => u.id == blockTypeId);

  String? unsupportedReason(String blockTypeId) {
    for (final u in unsupported) {
      if (u.id == blockTypeId) return u.reason;
    }
    return null;
  }
}
