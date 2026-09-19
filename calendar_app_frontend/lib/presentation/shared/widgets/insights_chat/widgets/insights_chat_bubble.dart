import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_message.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.markdownBoldSpans,
    required this.isEs,
    required this.sending,
    required this.buildMenuActions,
    required this.buildEventPreview,
    required this.buildStructuredTable,
    this.isStructuredTableResponse = false,
    this.canExportToExcel = false,
    this.isExporting = false,
    this.onExportExcel,
    this.showInlineMenuActions = true,
  });

  final ChatMessage message;
  final List<InlineSpan> Function({
    required String text,
    required TextStyle baseStyle,
  }) markdownBoldSpans;
  final bool isEs;
  final bool sending;
  final bool isStructuredTableResponse;
  final Widget Function(
    BuildContext context,
    ChatMessage message,
  ) buildEventPreview;
  final Widget Function(
    BuildContext context, {
    required ChatMessage message,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
    bool compact,
    bool selected,
  }) buildMenuActions;
  final Widget Function(BuildContext context, ChatMessage message)
      buildStructuredTable;
  final bool canExportToExcel;
  final bool isExporting;
  final VoidCallback? onExportExcel;
  final bool showInlineMenuActions;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _hovering = false;
  bool _copied = false;

  String get _visibleText {
    return visibleMessageText(
      widget.message,
      isEs: Localizations.localeOf(context)
          .languageCode
          .toLowerCase()
          .startsWith('es'),
      preserveStructuredAssistantText: widget.isStructuredTableResponse,
    );
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _visibleText));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = widget.message;
    final isUser = message.isUser;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    // AI bubble uses a clearly distinct surface so text is always legible
    // in both dark and light themes.
    final bg = isUser
        ? cs.primary
        : (isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHigh);
    final fg = isUser ? cs.onPrimary : cs.onSurface;
    final l = AppLocalizations.of(context)!;
    final showCopyAction = _hovering || _copied;
    final showExportAction = !isUser && widget.canExportToExcel;
    final showActions =
        showCopyAction || showExportAction || widget.isExporting;
    final hasMenuActions = widget.showInlineMenuActions &&
        !isUser &&
        (messageHasMenu(message) || (message.followUps?.isNotEmpty ?? false));
    final visibleText = _visibleText;

    return Align(
      alignment: align,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: widget.isStructuredTableResponse ? 620 : 520,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isUser ? 11 : 13,
                  vertical: isUser ? 9 : 11,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isUser ? 14 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: isDark ? 0.18 : 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: !isUser && widget.isStructuredTableResponse
                    ? widget.buildStructuredTable(context, message)
                    : !isUser && messageHasEventAssistant(message)
                        ? widget.buildEventPreview(context, message)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  isUser
                                      ? Icons.person_rounded
                                      : Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: isUser
                                      ? fg.withValues(alpha: 0.85)
                                      : cs.primary.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: visibleText.trim().isEmpty
                                    ? const SizedBox.shrink()
                                    : RichText(
                                        text: TextSpan(
                                          children: widget.markdownBoldSpans(
                                            text: visibleText,
                                            baseStyle: t.bodySmall.copyWith(
                                              color: fg,
                                              height: 1.55,
                                              fontSize: isUser ? 12.5 : 13,
                                              fontWeight: isUser
                                                  ? FontWeight.w500
                                                  : FontWeight.w400,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
              ),
              if (hasMenuActions)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: widget.buildMenuActions(
                    context,
                    message: message,
                    cs: cs,
                    t: t,
                    isEs: widget.isEs,
                    compact: true,
                  ),
                ),
              // Action row: copy button appears on hover or after tap
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: showActions
                    ? Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (showExportAction)
                              _BubbleActionButton(
                                icon: widget.isExporting
                                    ? Icons.hourglass_top_rounded
                                    : Icons.table_view_rounded,
                                tooltip: l.insightsChatExportExcelTooltip,
                                label: l.insightsChatExportExcel,
                                loading: widget.isExporting,
                                onTap: widget.isExporting
                                    ? null
                                    : widget.onExportExcel,
                                color: cs.primary,
                              ),
                            if (showCopyAction)
                              _BubbleActionButton(
                                icon: _copied
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                tooltip: _copied ? 'Copiado' : 'Copiar',
                                onTap: _copied ? null : _copyText,
                                color: _copied
                                    ? cs.primary
                                    : cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                              ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleActionButton extends StatelessWidget {
  const _BubbleActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.label,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final String? label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim() ?? '';
    final hasLabel = text.isNotEmpty;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: hasLabel || loading
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    else
                      Icon(icon, size: 14, color: color),
                    if (hasLabel) ...[
                      const SizedBox(width: 5),
                      Text(
                        text,
                        style: AppTypography.of(context).caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(icon, size: 14, color: color),
              ),
      ),
    );
  }
}
