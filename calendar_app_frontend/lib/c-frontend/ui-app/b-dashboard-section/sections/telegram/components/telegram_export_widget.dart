import 'package:flutter/material.dart';
import 'package:hexora/a-models/telegram/telegram.dart';

const _kTelegramBlue = Color(0xFF2AABEE);

// ─────────────────────────────────────────────
// Export creation form
// ─────────────────────────────────────────────

class TelegramExportFormWidget extends StatefulWidget {
  const TelegramExportFormWidget({
    super.key,
    required this.accountId,
    required this.chats,
    required this.onSubmit,
    required this.isLoading,
    this.initialChatId,
    this.error,
  });

  final String accountId;
  final List<TelegramChat> chats;
  final Function(TelegramExportRequest) onSubmit;
  final bool isLoading;
  final String? initialChatId;
  final String? error;

  @override
  State<TelegramExportFormWidget> createState() =>
      _TelegramExportFormWidgetState();
}

class _TelegramExportFormWidgetState extends State<TelegramExportFormWidget> {
  String? _selectedChatId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int _messageLimit = 10000;
  bool _customLimit = false;
  final _customLimitController = TextEditingController(text: '10000');
  bool _mediaOnly = false;
  bool _documentsOnly = false;
  bool _downloadFiles = true;
  String _exportFormat = 'json';

  static const _limitPresets = [1000, 5000, 10000, 50000];

  @override
  void initState() {
    super.initState();
    _selectedChatId = _resolveInitialChatId(widget.initialChatId);
  }

  @override
  void didUpdateWidget(covariant TelegramExportFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextChatId = _resolveInitialChatId(widget.initialChatId);
    final initialChanged = widget.initialChatId != oldWidget.initialChatId;
    if (initialChanged && nextChatId != _selectedChatId) {
      setState(() => _selectedChatId = nextChatId);
    } else if (_selectedChatId != null &&
        !widget.chats.any((chat) => chat.id == _selectedChatId)) {
      setState(() => _selectedChatId = nextChatId);
    }
  }

  String? _resolveInitialChatId(String? chatId) {
    if (chatId == null || chatId.trim().isEmpty) return null;
    final normalized = chatId.trim();
    return widget.chats.any((chat) => chat.id == normalized) ? normalized : null;
  }

  @override
  void dispose() {
    _customLimitController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedChatId != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = widget.isLoading;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error banner
          if (widget.error != null) ...[
            _ErrorBanner(message: widget.error!),
            const SizedBox(height: 16),
          ],

          // ── Chat ──────────────────────────────────
          const _SectionLabel('Chat'),
          const SizedBox(height: 8),
          _StyledDropdown<String>(
            value: _selectedChatId,
            hint: widget.chats.isEmpty
                ? 'No chats loaded'
                : 'Select a chat to export',
            items: widget.chats
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          Icon(
                            c.isChannel
                                ? Icons.campaign_rounded
                                : c.isGroup
                                    ? Icons.group_rounded
                                    : Icons.person_rounded,
                            size: 15,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: disabled
                ? null
                : (v) => setState(() => _selectedChatId = v),
          ),

          const SizedBox(height: 20),

          // ── Date range ───────────────────────────
          const _SectionLabel('Date range'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From',
                  value: _dateFrom,
                  lastDate: _dateTo ?? DateTime.now(),
                  enabled: !disabled,
                  onChanged: (v) => setState(() => _dateFrom = v),
                  onClear: _dateFrom != null
                      ? () => setState(() => _dateFrom = null)
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Expanded(
                child: _DateField(
                  label: 'To',
                  value: _dateTo,
                  firstDate: _dateFrom,
                  lastDate: DateTime.now(),
                  enabled: !disabled,
                  onChanged: (v) => setState(() => _dateTo = v),
                  onClear: _dateTo != null
                      ? () => setState(() => _dateTo = null)
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Message limit ─────────────────────────
          const _SectionLabel('Message limit'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._limitPresets.map((limit) {
                final selected = !_customLimit && _messageLimit == limit;
                return _ChoiceChip(
                  label: _fmtNum(limit),
                  selected: selected,
                  enabled: !disabled,
                  onTap: () => setState(() {
                    _customLimit = false;
                    _messageLimit = limit;
                  }),
                );
              }),
              _ChoiceChip(
                label: 'Custom',
                selected: _customLimit,
                enabled: !disabled,
                onTap: () => setState(() => _customLimit = true),
              ),
            ],
          ),
          if (_customLimit) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 160,
              child: _StyledTextField(
                controller: _customLimitController,
                hint: 'e.g. 25000',
                keyboardType: TextInputType.number,
                enabled: !disabled,
                onChanged: (v) =>
                    _messageLimit = int.tryParse(v) ?? _messageLimit,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Export format ─────────────────────────
          const _SectionLabel('Export format'),
          const SizedBox(height: 8),
          _FormatSelector(
            value: _exportFormat,
            enabled: !disabled,
            onChanged: (v) => setState(() => _exportFormat = v),
          ),

          const SizedBox(height: 20),

          // ── Content filters ───────────────────────
          const _SectionLabel('Content filters'),
          const SizedBox(height: 8),
          _ToggleRow(
            icon: Icons.image_outlined,
            label: 'Media only',
            subtitle: 'Skip text-only messages',
            value: _mediaOnly,
            enabled: !disabled && !_documentsOnly,
            onChanged: (v) => setState(() => _mediaOnly = v),
          ),
          const SizedBox(height: 6),
          _ToggleRow(
            icon: Icons.insert_drive_file_outlined,
            label: 'Documents only',
            subtitle: 'Files and attachments',
            value: _documentsOnly,
            enabled: !disabled && !_mediaOnly,
            onChanged: (v) => setState(() => _documentsOnly = v),
          ),
          const SizedBox(height: 6),
          _ToggleRow(
            icon: Icons.download_rounded,
            label: 'Download files',
            subtitle: 'Save media to export archive',
            value: _downloadFiles,
            enabled: !disabled,
            onChanged: (v) => setState(() => _downloadFiles = v),
          ),

          const SizedBox(height: 28),

          // ── Submit ────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download_outlined, size: 18),
              label: Text(
                widget.isLoading ? 'Starting export…' : 'Start Export',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kTelegramBlue,
                disabledBackgroundColor:
                    _kTelegramBlue.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    widget.onSubmit(TelegramExportRequest(
      chatId: _selectedChatId!,
      accountId: widget.accountId,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      messageLimit: _messageLimit,
      mediaOnly: _mediaOnly,
      documentsOnly: _documentsOnly,
      downloadFiles: _downloadFiles,
      exportFormat: _exportFormat,
    ));
  }

  static String _fmtNum(int n) {
    if (n >= 1000) return '${n ~/ 1000}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────
// Export progress widget
// ─────────────────────────────────────────────

class TelegramExportProgressWidget extends StatelessWidget {
  const TelegramExportProgressWidget({
    super.key,
    required this.export,
    required this.onCancel,
    required this.onDownload,
    this.isCancelling = false,
  });

  final TelegramExport export;
  final VoidCallback onCancel;
  final VoidCallback onDownload;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status header
        Row(
          children: [
            _statusIcon(export.status),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    export.progressText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
            _ExportStatusBadge(status: export.status),
          ],
        ),

        const SizedBox(height: 16),

        // Progress bar
        if (export.isRunning || export.isPending) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: export.progressPercent > 0
                  ? export.progressPercent / 100
                  : null,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(_kTelegramBlue),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${export.progressPercent.toStringAsFixed(0)}% complete',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
              ),
              if (export.totalMessages != null)
                Text(
                  '${export.messagesScanned} / ${export.totalMessages}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Stats
        _ExportStatsGrid(export: export),

        // Error message
        if (export.isError && export.errorMessage != null) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: export.errorMessage!),
        ],

        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            if (export.canCancel)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCancelling ? null : onCancel,
                  icon: isCancelling
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: cs.error,
                          ),
                        )
                      : Icon(Icons.cancel_outlined,
                          size: 16, color: cs.error),
                  label: Text(
                    isCancelling ? 'Cancelling…' : 'Cancel Export',
                    style: TextStyle(color: cs.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            if (export.isCompleted) ...[
              if (export.canCancel) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String get _statusTitle => switch (export.status) {
        'pending' => 'Preparing export…',
        'running' => 'Export in progress',
        'completed' => 'Export complete',
        'error' => 'Export failed',
        'cancelled' => 'Export cancelled',
        _ => 'Export ${export.statusLabel}',
      };

  Widget _statusIcon(String status) {
    final (icon, color) = switch (status) {
      'pending' => (Icons.hourglass_empty_rounded, Colors.orange),
      'running' => (Icons.sync_rounded, _kTelegramBlue),
      'completed' => (Icons.check_circle_outline_rounded, Colors.green),
      'error' => (Icons.error_outline_rounded, Colors.red),
      'cancelled' => (Icons.cancel_outlined, Colors.grey),
      _ => (Icons.info_outline_rounded, Colors.grey),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ─────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kTelegramBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      hint: hint != null
          ? Text(
              hint!,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            )
          : null,
      items: items,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      isExpanded: true,
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kTelegramBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? _kTelegramBlue.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _kTelegramBlue.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? _kTelegramBlue
                : cs.onSurface.withValues(alpha: enabled ? 0.7 : 0.35),
          ),
        ),
      ),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  const _FormatSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const _formats = [
    (id: 'json', label: 'JSON', icon: Icons.data_object_rounded,
      desc: 'Structured data'),
    (id: 'json_with_media', label: 'JSON + Media',
      icon: Icons.perm_media_outlined, desc: 'Data with files'),
    (id: 'html', label: 'HTML', icon: Icons.code_rounded,
      desc: 'Readable page'),
    (id: 'csv', label: 'CSV', icon: Icons.table_chart_outlined,
      desc: 'Spreadsheet'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _formats.map((f) {
        final selected = value == f.id;
        final cs = Theme.of(context).colorScheme;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: f.id != _formats.last.id ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: enabled ? () => onChanged(f.id) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? _kTelegramBlue.withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? _kTelegramBlue.withValues(alpha: 0.5)
                        : cs.outline.withValues(alpha: 0.15),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.icon,
                      size: 18,
                      color: selected
                          ? _kTelegramBlue
                          : cs.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? _kTelegramBlue
                            : cs.onSurface
                                .withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      f.desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.38),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value
                ? _kTelegramBlue.withValues(alpha: 0.06)
                : cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: value
                  ? _kTelegramBlue.withValues(alpha: 0.3)
                  : cs.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: value
                    ? _kTelegramBlue
                    : cs.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: value
                                ? cs.onSurface
                                : cs.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: _kTelegramBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = value != null;

    return GestureDetector(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2013),
                lastDate: lastDate ?? DateTime.now(),
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? _kTelegramBlue.withValues(alpha: 0.4)
                : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: hasValue
                  ? _kTelegramBlue
                  : cs.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                hasValue ? _fmt(value!) : label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasValue
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
              ),
            ),
            if (hasValue && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} '
      '${_months[d.month - 1]} '
      '${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _ExportStatusBadge extends StatelessWidget {
  const _ExportStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'pending' => (Colors.orange[700]!, Colors.orange.withValues(alpha: 0.1)),
      'running' => (_kTelegramBlue, _kTelegramBlue.withValues(alpha: 0.1)),
      'completed' => (Colors.green[700]!, Colors.green.withValues(alpha: 0.1)),
      'error' => (Colors.red[700]!, Colors.red.withValues(alpha: 0.1)),
      'cancelled' => (Colors.grey[600]!, Colors.grey.withValues(alpha: 0.1)),
      _ => (Colors.grey[600]!, Colors.grey.withValues(alpha: 0.1)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExportStatsGrid extends StatelessWidget {
  const _ExportStatsGrid({required this.export});

  final TelegramExport export;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (label: 'Scanned', value: export.messagesScanned, error: false),
      (label: 'Exported', value: export.messagesExported, error: false),
      (label: 'Files DL', value: export.filesDownloaded, error: false),
      (label: 'Failed', value: export.filesFailed,
        error: export.filesFailed > 0),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item.label != items.last.label ? 8 : 0,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: item.error
                    ? Colors.red.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: item.error
                    ? Border.all(
                        color: Colors.red.withValues(alpha: 0.25))
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    _fmt(item.value),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.error ? Colors.red[600] : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
