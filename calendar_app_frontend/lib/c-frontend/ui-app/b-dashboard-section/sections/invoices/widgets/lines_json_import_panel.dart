import 'dart:convert';

import 'package:flutter/material.dart';
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
    final raw = input.trim();
    if (raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map || decoded is List;
    } catch (_) {
      return false;
    }
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
            ? 'JSON invalido. Revisa llaves, comas y estructura.'
            : widget.textValidator?.call(_jsonTextCtrl.text));
    final canSubmitCurrentMode = _useJsonFileMode
        ? (canSubmit && hasJsonFile)
        : (canSubmit &&
            hasJsonText &&
            isJsonTextValid &&
            (textValidationError == null ||
                textValidationError.trim().isEmpty));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.invoiceLinesJsonImportTitle,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l.invoiceLinesJsonImportSubtitle,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l.invoiceLinesJsonImportModePaste),
                selected: !_useJsonFileMode,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _useJsonFileMode = false);
                  widget.onClearError?.call();
                },
              ),
              ChoiceChip(
                label: Text(l.invoiceLinesJsonImportModeFile),
                selected: _useJsonFileMode,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => _useJsonFileMode = true);
                  widget.onClearError?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_useJsonFileMode) ...[
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: canSubmit ? widget.onPickFile : null,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(l.invoiceLinesJsonImportPickFile),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.remove,
                    onPressed: canSubmit ? widget.onClearFile : null,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            if (!hasJsonFile) ...[
              const SizedBox(height: 8),
              Text(
                l.invoiceLinesJsonImportNoFile,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ] else ...[
            TextField(
              controller: _jsonTextCtrl,
              enabled: canSubmit,
              minLines: 6,
              maxLines: 10,
              onChanged: (_) {
                setState(() {});
                widget.onClearError?.call();
              },
              style: t.bodySmall,
              decoration: InputDecoration(
                hintText: l.invoiceLinesJsonImportInputHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (hasJsonText &&
                textValidationError != null &&
                textValidationError.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                textValidationError,
                style: t.bodySmall.copyWith(color: cs.error),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _defaultTaxRateCtrl,
                  enabled: canSubmit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: t.bodySmall,
                  decoration: InputDecoration(
                    labelText: l.invoiceLinesJsonImportDefaultTaxRate,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _overwrite,
                  onChanged: canSubmit
                      ? (v) => setState(() => _overwrite = v == true)
                      : null,
                  title: Text(
                    l.invoiceLinesJsonImportOverwrite,
                    style: t.bodySmall,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: widget.loadingPrompt ? null : widget.onCopyPrompt,
                icon: widget.loadingPrompt
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.content_copy_outlined),
                label: Text(l.invoiceLinesJsonImportGetPrompt),
              ),
            ],
          ),
          if ((widget.errorText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorText!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}
