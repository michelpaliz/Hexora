import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client_contract.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_contracts_support.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientContractFormResult {
  final Uint8List? fileBytes;
  final String? uploadFileName;
  final String? title;
  final String? contractType;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? renewalDate;
  final DateTime? signedAt;
  final String? notes;
  final List<String> tags;
  final String? version;
  final String? fileName;
  final bool isCurrent;

  const ClientContractFormResult({
    this.fileBytes,
    this.uploadFileName,
    this.title,
    this.contractType,
    this.status,
    this.startDate,
    this.endDate,
    this.renewalDate,
    this.signedAt,
    this.notes,
    this.tags = const <String>[],
    this.version,
    this.fileName,
    this.isCurrent = false,
  });

  Map<String, dynamic> toUpdatePayload() {
    return <String, dynamic>{
      'title': title,
      'contractType': contractType,
      'status': status,
      'startDate': clientContractDateForApi(startDate),
      'endDate': clientContractDateForApi(endDate),
      'renewalDate': clientContractDateForApi(renewalDate),
      'signedAt': clientContractDateForApi(signedAt),
      'notes': notes,
      'tags': tags,
      'version': version,
      'fileName': fileName,
      'isCurrent': isCurrent,
    };
  }
}

class ClientContractSheet extends StatefulWidget {
  final ClientContract? initialContract;
  final Uint8List? initialUploadBytes;
  final String? initialUploadFileName;

  const ClientContractSheet.upload({
    super.key,
    this.initialUploadBytes,
    this.initialUploadFileName,
  }) : initialContract = null;

  const ClientContractSheet.edit({
    super.key,
    required this.initialContract,
  })  : initialUploadBytes = null,
        initialUploadFileName = null;

  bool get isEdit => initialContract != null;

  @override
  State<ClientContractSheet> createState() => _ClientContractSheetState();
}

class _ClientContractSheetState extends State<ClientContractSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _versionCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _fileNameCtrl;

  Uint8List? _fileBytes;
  String? _uploadFileName;
  String? _contractType;
  String? _status;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _renewalDate;
  DateTime? _signedAt;
  bool _isCurrent = false;
  bool _submitting = false;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    final contract = widget.initialContract;
    _titleCtrl = TextEditingController(text: contract?.title ?? '');
    _versionCtrl = TextEditingController(text: contract?.version ?? '');
    _notesCtrl = TextEditingController(text: contract?.notes ?? '');
    _tagsCtrl = TextEditingController(text: contract?.tags.join(', ') ?? '');
    _fileNameCtrl = TextEditingController(text: contract?.fileName ?? '');
    _contractType = contract?.contractType;
    _status = contract?.status;
    _startDate = contract?.startDate;
    _endDate = contract?.endDate;
    _renewalDate = contract?.renewalDate;
    _signedAt = contract?.signedAt;
    _isCurrent = contract?.isCurrent ?? false;
    if (!widget.isEdit &&
        widget.initialUploadBytes != null &&
        (widget.initialUploadFileName ?? '').trim().isNotEmpty) {
      _applyPickedFile(
        widget.initialUploadBytes!,
        widget.initialUploadFileName!.trim(),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _versionCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    _fileNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final l = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final file = result?.files.single;
    if (file == null) return;
    if (file.bytes == null || file.bytes!.isEmpty) {
      setState(() => _fileError = l.contractFileReadError);
      return;
    }
    final lowerName = file.name.trim().toLowerCase();
    if (!lowerName.endsWith('.pdf')) {
      setState(() => _fileError = l.contractPdfOnlyHint);
      return;
    }
    _applyPickedFile(Uint8List.fromList(file.bytes!), file.name);
  }

  void _applyPickedFile(Uint8List bytes, String fileName) {
    setState(() {
      _fileBytes = bytes;
      _uploadFileName = fileName;
      _fileError = null;
      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = fileName.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
      }
    });
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) return;
    setState(() => onChanged(picked));
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!widget.isEdit &&
        (_fileBytes == null || (_uploadFileName ?? '').isEmpty)) {
      setState(() => _fileError = l.contractFileRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _fileError = null;
    });
    Navigator.of(context).pop(
      ClientContractFormResult(
        fileBytes: _fileBytes,
        uploadFileName: _uploadFileName,
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        contractType: _contractType,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        renewalDate: _renewalDate,
        signedAt: _signedAt,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        tags: parseClientContractTags(_tagsCtrl.text),
        version:
            _versionCtrl.text.trim().isEmpty ? null : _versionCtrl.text.trim(),
        fileName: widget.isEdit
            ? (_fileNameCtrl.text.trim().isEmpty
                ? null
                : _fileNameCtrl.text.trim())
            : null,
        isCurrent: _isCurrent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.isEdit;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? l.contractEditTitle : l.contractUploadTitle,
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  isEdit ? l.contractEditSubtitle : l.contractUploadSubtitle,
                  style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (!isEdit) ...[
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _fileBytes != null
                              ? cs.primaryContainer.withValues(alpha: 0.55)
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _fileBytes != null
                                ? cs.primary.withValues(alpha: 0.35)
                                : cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                          color: _fileBytes != null
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_uploadFileName ?? '').isEmpty
                                  ? l.contractNoFileSelected
                                  : _uploadFileName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _fileBytes != null
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              l.contractPdfOnlyHint,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickPdf,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.folder_open_outlined, size: 16),
                        label: Text(l.contractPickPdf,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  if ((_fileError ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        _fileError!,
                        style: t.bodySmall.copyWith(color: cs.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 680;
                    final fields = <Widget>[
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: l.contractTitleLabel,
                          isDense: true,
                        ),
                      ),
                      if (isEdit)
                        TextField(
                          controller: _fileNameCtrl,
                          decoration: InputDecoration(
                            labelText: l.contractFileNameLabel,
                            isDense: true,
                          ),
                        )
                      else
                        TextField(
                          controller: _versionCtrl,
                          decoration: InputDecoration(
                            labelText: l.contractVersionLabel,
                            isDense: true,
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        initialValue: _contractType != null &&
                                kClientContractTypeValues.contains(_contractType)
                            ? _contractType
                            : null,
                        decoration: InputDecoration(
                          labelText: l.clientContractTypeLabel,
                          isDense: true,
                        ),
                        items: kClientContractTypeValues
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  clientContractTypeLabel(l, value),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _contractType = value),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _status != null &&
                                kClientContractStatusValues.contains(_status)
                            ? _status
                            : null,
                        decoration: InputDecoration(
                          labelText: l.contractStatusLabel,
                          isDense: true,
                        ),
                        items: kClientContractStatusValues
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  clientContractStatusLabel(l, value),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _status = value),
                      ),
                      if (isEdit)
                        TextField(
                          controller: _versionCtrl,
                          decoration: InputDecoration(
                            labelText: l.contractVersionLabel,
                            isDense: true,
                          ),
                        ),
                    ];

                    if (compact) {
                      return Column(
                        children: fields
                            .expand(
                              (field) =>
                                  <Widget>[field, const SizedBox(height: 8)],
                            )
                            .toList()
                          ..removeLast(),
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: fields[0]),
                            const SizedBox(width: 10),
                            Expanded(child: fields[1]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: fields[2]),
                            const SizedBox(width: 10),
                            Expanded(child: fields[3]),
                          ],
                        ),
                        if (fields.length > 4) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: fields[4]),
                              const SizedBox(width: 10),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _CompactDateChip(
                      label: l.startDate,
                      icon: Icons.play_circle_outline_rounded,
                      value: _startDate,
                      onPick: () => _pickDate(
                        _startDate,
                        (value) => _startDate = value,
                      ),
                      onClear: _startDate == null
                          ? null
                          : () => setState(() => _startDate = null),
                    ),
                    _CompactDateChip(
                      label: l.endDate,
                      icon: Icons.stop_circle_outlined,
                      value: _endDate,
                      onPick: () => _pickDate(
                        _endDate,
                        (value) => _endDate = value,
                      ),
                      onClear: _endDate == null
                          ? null
                          : () => setState(() => _endDate = null),
                    ),
                    _CompactDateChip(
                      label: l.contractRenewalDateLabel,
                      icon: Icons.autorenew_rounded,
                      value: _renewalDate,
                      onPick: () => _pickDate(
                        _renewalDate,
                        (value) => _renewalDate = value,
                      ),
                      onClear: _renewalDate == null
                          ? null
                          : () => setState(() => _renewalDate = null),
                    ),
                    _CompactDateChip(
                      label: l.contractSignedDateLabel,
                      icon: Icons.draw_outlined,
                      value: _signedAt,
                      onPick: () => _pickDate(
                        _signedAt,
                        (value) => _signedAt = value,
                      ),
                      onClear: _signedAt == null
                          ? null
                          : () => setState(() => _signedAt = null),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsCtrl,
                  decoration: InputDecoration(
                    labelText: l.contractTagsLabel,
                    hintText: l.contractTagsHint,
                    isDense: true,
                    prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l.contractNotesLabel,
                    isDense: true,
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isCurrent
                        ? cs.primaryContainer.withValues(alpha: 0.3)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCurrent
                          ? cs.primary.withValues(alpha: 0.35)
                          : cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCurrent
                            ? Icons.verified_rounded
                            : Icons.verified_outlined,
                        size: 18,
                        color: _isCurrent ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.contractCurrentBadge,
                              style: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              l.contractCurrentHint,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isCurrent,
                        onChanged: (value) =>
                            setState(() => _isCurrent = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        child: Text(l.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          isEdit ? l.saveChanges : l.contractUploadAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactDateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _CompactDateChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasValue = value != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: EdgeInsets.only(
            left: 10,
            top: 6,
            bottom: 6,
            right: hasValue ? 4 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: hasValue
                ? cs.primaryContainer.withValues(alpha: 0.4)
                : cs.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border.all(
              color: hasValue
                  ? cs.primary.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: hasValue ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '$label: ${formatClientContractDate(l, value)}',
                style: t.bodySmall.copyWith(
                  color: hasValue ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                  fontWeight:
                      hasValue ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (hasValue && onClear != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
