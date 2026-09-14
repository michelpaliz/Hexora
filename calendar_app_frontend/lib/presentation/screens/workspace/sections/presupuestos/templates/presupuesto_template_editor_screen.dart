import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/group_model/client/client.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/documents/presupuesto_document_draft_flow.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/templates/presupuesto_image_library_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/widgets/presupuesto_pdf_preview_dialog.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:intl/intl.dart';

part 'editor/sections/editor_layout.dart';
part 'editor/sections/template_selection.dart';
part 'editor/sections/variable_fields.dart';
part 'editor/sections/document_preview.dart';
part 'editor/sections/section_editors.dart';
part 'editor/sections/image_editor.dart';
part 'editor/sections/editor_controls.dart';
part 'editor/controller/template_editor_controller.dart';
part 'editor/models/template_editor_models.dart';
part 'editor/widgets/client_autocomplete.dart';
part 'editor/widgets/restricted_markdown.dart';

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
