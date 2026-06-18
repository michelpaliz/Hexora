import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef JsonImportFromText = Future<void> Function(
  String rawText, {
  required bool overwrite,
  required double defaultTaxRate,
});

typedef JsonImportFromFile = Future<void> Function({
  required bool overwrite,
  required double defaultTaxRate,
});

class LinesJsonImportPanel extends StatefulWidget {
  const LinesJsonImportPanel({
    super.key,
    required this.loading,
    required this.loadingPrompt,
    required this.disabled,
    required this.fileName,
    required this.errorText,
    required this.onPickFile,
    required this.onClearFile,
    required this.onImportFromText,
    required this.onImportFromFile,
    required this.onCopyPrompt,
    this.onClearError,
    this.textValidator,
  });

  final bool loading;
  final bool loadingPrompt;
  final bool disabled;
  final String? fileName;
  final String? errorText;
  final Future<void> Function() onPickFile;
  final VoidCallback onClearFile;
  final JsonImportFromText onImportFromText;
  final JsonImportFromFile onImportFromFile;
  final Future<void> Function() onCopyPrompt;
  final VoidCallback? onClearError;
  final String? Function(String rawText)? textValidator;

  @override
  State<LinesJsonImportPanel> createState() => _LinesJsonImportPanelState();
}

class _LinesJsonImportPanelState extends State<LinesJsonImportPanel> {
  bool _useJsonFileMode = false;
  bool _overwrite = false;
  bool _promptHovered = false;
  final TextEditingController _jsonTextCtrl = TextEditingController();
  final TextEditingController _defaultTaxRateCtrl =
      TextEditingController(text: '21');

  @override
  void dispose() {
    _jsonTextCtrl.dispose();
    _defaultTaxRateCtrl.dispose();
    super.dispose();
  }

  double _taxRateValue() {
    final parsed =
        double.tryParse(_defaultTaxRateCtrl.text.trim().replaceAll(',', '.'));
    return parsed ?? 21;
  }

  bool _isValidJsonText(String input) {
    return JsonImportService.isValidJsonObjectOrArray(input);
  }

  void _repairJsonText(BuildContext context) {
    final repaired = JsonImportService.repairJsonText(_jsonTextCtrl.text);
    if (repaired == null || repaired.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pude reparar este JSON automaticamente. Revisa llaves, comas y corchetes.',
          ),
        ),
      );
      return;
    }

    _jsonTextCtrl.text = repaired;
    _jsonTextCtrl.selection = TextSelection.collapsed(
      offset: repaired.length,
    );
    setState(() {});
    widget.onClearError?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON reparado. Revisa el resultado antes de importarlo.'),
      ),
    );
  }

  int? _detectLineCount(String input) {
    if (!_isValidJsonText(input)) return null;
    try {
      final decoded = jsonDecode(input.trim());
      if (decoded is Map && decoded['draftLines'] is List) {
        return (decoded['draftLines'] as List).length;
      }
      if (decoded is List) return decoded.length;
    } catch (_) {}
    return null;
  }

  Widget _segmentBtn(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(7) : Radius.zero,
              right: isLast ? const Radius.circular(7) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 12, color: cs.primary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final canSubmit = !widget.disabled && !widget.loading;
    final hasJsonFile = (widget.fileName ?? '').trim().isNotEmpty;
    final hasJsonText = _jsonTextCtrl.text.trim().isNotEmpty;
    final isJsonTextValid = _isValidJsonText(_jsonTextCtrl.text);
    final textValidationError = !hasJsonText
        ? null
        : (!isJsonTextValid
            ? 'JSON inválido. Revisa llaves, comas y estructura.'
            : widget.textValidator?.call(_jsonTextCtrl.text));
    final lineCount = _useJsonFileMode
        ? null
        : _detectLineCount(_jsonTextCtrl.text);
    final canSubmitCurrentMode = _useJsonFileMode
        ? (canSubmit && hasJsonFile)
        : (canSubmit &&
            hasJsonText &&
            isJsonTextValid &&
            (textValidationError == null ||
                textValidationError.trim().isEmpty));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.invoiceLinesJsonImportTitle,
                      style: t.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.invoiceLinesJsonImportSubtitle,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Source segmented control ─────────────────────────────────
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                _segmentBtn(
                  context,
                  label: l.invoiceLinesJsonImportModePaste,
                  selected: !_useJsonFileMode,
                  isFirst: true,
                  onTap: () {
                    setState(() => _useJsonFileMode = false);
                    widget.onClearError?.call();
                  },
                ),
                Container(
                    width: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
                _segmentBtn(
                  context,
                  label: l.invoiceLinesJsonImportModeFile,
                  selected: _useJsonFileMode,
                  isLast: true,
                  onTap: () {
                    setState(() => _useJsonFileMode = true);
                    widget.onClearError?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Input area ───────────────────────────────────────────────
          if (_useJsonFileMode) ...[
            Row(
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  onPressed: canSubmit ? widget.onPickFile : null,
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: Text(l.invoiceLinesJsonImportPickFile,
                      style: const TextStyle(fontSize: 13)),
                ),
                if (hasJsonFile) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.fileName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.remove,
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    onPressed: canSubmit ? widget.onClearFile : null,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            if (!hasJsonFile) ...[
              const SizedBox(height: 6),
              Text(
                l.invoiceLinesJsonImportNoFile,
                style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ] else ...[
            // Code-editor textarea
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.45)),
              ),
              child: TextField(
                controller: _jsonTextCtrl,
                enabled: canSubmit,
                minLines: 5,
                maxLines: 8,
                onChanged: (_) {
                  setState(() {});
                  widget.onClearError?.call();
                },
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.55,
                  color: cs.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l.invoiceLinesJsonImportInputHint,
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Helper row: format hint + LLM link OR line count
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Formato: {"draftLines": [...]}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (lineCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$lineCount líneas',
                      style: t.bodySmall.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  MouseRegion(
                    cursor: widget.loadingPrompt
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _promptHovered = true),
                    onExit: (_) => setState(() => _promptHovered = false),
                    child: GestureDetector(
                      onTap: widget.loadingPrompt ? null : widget.onCopyPrompt,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _promptHovered
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(
                                alpha: _promptHovered ? 0.45 : 0.25,
                              ),
                              blurRadius: _promptHovered ? 8 : 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            widget.loadingPrompt
                                ? const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5),
                                  )
                                : const Icon(Icons.bolt,
                                    size: 13, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(
                              l.invoiceLinesJsonImportGetPrompt,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Validation error
            if (hasJsonText &&
                textValidationError != null &&
                textValidationError.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 13, color: cs.error),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          textValidationError,
                          style: t.bodySmall.copyWith(
                              color: cs.error, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed:
                          canSubmit ? () => _repairJsonText(context) : null,
                      icon: const Icon(Icons.auto_fix_high, size: 14),
                      label: const Text('Reparar JSON'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 10),

          // ── Options row ──────────────────────────────────────────────
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _defaultTaxRateCtrl,
                  enabled: canSubmit,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: t.bodySmall,
                  decoration: InputDecoration(
                    labelText: l.invoiceLinesJsonImportDefaultTaxRate,
                    labelStyle: const TextStyle(fontSize: 11),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l.invoiceLinesJsonImportOverwrite,
                style: t.bodySmall
                    .copyWith(color: cs.onSurface, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.78,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: _overwrite,
                  onChanged: canSubmit
                      ? (v) => setState(() => _overwrite = v)
                      : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Primary action ───────────────────────────────────────────
          Row(
            children: [
              FilledButton.icon(
                onPressed: !canSubmitCurrentMode
                    ? null
                    : () {
                        widget.onClearError?.call();
                        if (_useJsonFileMode) {
                          widget.onImportFromFile(
                            overwrite: _overwrite,
                            defaultTaxRate: _taxRateValue(),
                          );
                        } else {
                          widget.onImportFromText(
                            _jsonTextCtrl.text,
                            overwrite: _overwrite,
                            defaultTaxRate: _taxRateValue(),
                          );
                        }
                      },
                icon: widget.loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add_check_circle_outlined),
                label: Text(l.invoiceLinesJsonImportApply),
              ),
              // Show LLM button only in file mode (in text mode it's in helper row)
              if (_useJsonFileMode) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: widget.loadingPrompt
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _promptHovered = true),
                  onExit: (_) => setState(() => _promptHovered = false),
                  child: GestureDetector(
                    onTap: widget.loadingPrompt ? null : widget.onCopyPrompt,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _promptHovered
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(
                              alpha: _promptHovered ? 0.45 : 0.25,
                            ),
                            blurRadius: _promptHovered ? 8 : 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.loadingPrompt
                              ? const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5),
                                )
                              : const Icon(Icons.bolt,
                                  size: 15, color: Color(0xFFD97706)),
                          const SizedBox(width: 5),
                          Text(
                            l.invoiceLinesJsonImportGetPrompt,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Import error
          if ((widget.errorText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: cs.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: t.bodySmall.copyWith(color: cs.error),
                  ),
                ),
              ],
            ),
          ],
            ],
          );
          if (!constraints.hasBoundedHeight) {
            return content;
          }
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: content,
          );
        },
      ),
    );
  }
}
