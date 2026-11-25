import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';

import '../insights_chat_message.dart';
import '../insights_markdown.dart';

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
    this.onStructuredTableTap,
    this.onOpenNewInvoice,
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
  final VoidCallback? onStructuredTableTap;
  final VoidCallback? onOpenNewInvoice;
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

  bool get _suggestsNewInvoice {
    if (widget.message.isUser || widget.onOpenNewInvoice == null) return false;
    final normalized = _visibleText.toLowerCase();
    final namesNewInvoice = normalized.contains('new invoice') ||
        normalized.contains('nueva factura') ||
        normalized.contains('crear una factura');
    final givesDirection = normalized.contains('income >') ||
        normalized.contains('ingresos >') ||
        normalized.contains('ve a ') ||
        normalized.contains('go to ');
    return namesNewInvoice && givesDirection;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = widget.message;
    final isUser = message.isUser;
    final bg = isUser
        ? cs.primary
        : (isDark ? cs.surfaceContainerHighest : cs.surface);
    final fg = isUser ? cs.onPrimary : cs.onSurface;
    final l = AppLocalizations.of(context)!;
    final showCopyAction = _hovering || _copied;
    final showExportAction = !isUser && widget.canExportToExcel;
    final showActions =
        showCopyAction || showExportAction || widget.isExporting;
    final hasMenuActions = widget.showInlineMenuActions &&
        !isUser &&
        (messageHasMenu(message) || (message.followUps?.isNotEmpty ?? false));
    final visibleText =
        isUser ? _visibleText : formatAssistantProse(_visibleText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _MessageIdentityAvatar(isUser: false, isEs: widget.isEs),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: widget.isStructuredTableResponse ? 620 : 520,
                ),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: widget.isStructuredTableResponse
                          ? EdgeInsets.zero
                          : EdgeInsets.symmetric(
                              horizontal: isUser ? 11 : 13,
                              vertical: isUser ? 8 : 9,
                            ),
                      decoration: BoxDecoration(
                        color: widget.isStructuredTableResponse
                            ? Colors.transparent
                            : bg,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isUser ? 12 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 12),
                        ),
                        border: isUser || widget.isStructuredTableResponse
                            ? null
                            : Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: isDark ? 0.28 : 0.55,
                                ),
                              ),
                      ),
                      child: !isUser && widget.isStructuredTableResponse
                          ? Semantics(
                              button: true,
                              label: widget.isEs
                                  ? 'Abrir resultado'
                                  : 'Open result',
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: widget.onStructuredTableTap,
                                  borderRadius: BorderRadius.circular(14),
                                  child: widget.buildStructuredTable(
                                      context, message),
                                ),
                              ),
                            )
                          : !isUser && messageHasEventAssistant(message)
                              ? widget.buildEventPreview(context, message)
                              : visibleText.trim().isEmpty
                                  ? const SizedBox.shrink()
                                  : RichText(
                                      text: TextSpan(
                                        children: widget.markdownBoldSpans(
                                          text: visibleText,
                                          baseStyle: t.bodySmall.copyWith(
                                            color: fg,
                                            height: 1.45,
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
                    if (_suggestsNewInvoice)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: _NavigationActionButton(
                          label: widget.isEs
                              ? 'Abrir nueva factura'
                              : 'Open new invoice',
                          onTap: widget.onOpenNewInvoice!,
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
                      duration:
                          HexoraMotion.duration(context, HexoraMotion.fast),
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
                                      tooltip: _copied
                                          ? (widget.isEs ? 'Copiado' : 'Copied')
                                          : (widget.isEs ? 'Copiar' : 'Copy'),
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
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _MessageIdentityAvatar(isUser: true, isEs: widget.isEs),
          ],
        ],
      ),
    );
  }
}

class _MessageIdentityAvatar extends StatelessWidget {
  const _MessageIdentityAvatar({
    required this.isUser,
    required this.isEs,
  });

  final bool isUser;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userPhotoUrl =
        isUser ? context.watch<UserDomain?>()?.user?.photoUrl : null;
    final label = isUser
        ? (isEs ? 'Tú' : 'You')
        : (isEs ? 'Asistente IA' : 'AI assistant');

    return Tooltip(
      message: label,
      child: Semantics(
        image: true,
        label: label,
        child: isUser
            ? AvatarUtils.profileAvatar(
                context,
                userPhotoUrl,
                radius: 13,
                icon: Icons.person_outline_rounded,
                backgroundColor: cs.surfaceContainerHighest,
                borderColor: cs.outlineVariant.withValues(alpha: 0.6),
                borderWidth: 1,
              )
            : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.18),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 15,
                  color: cs.primary,
                ),
              ),
      ),
    );
  }
}

class _NavigationActionButton extends StatelessWidget {
  const _NavigationActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: cs.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
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
