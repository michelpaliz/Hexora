import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_message.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsComposer on InsightsChatSheetStateBase {
  bool _composerFocused = false;

  @override
  Widget buildIncomeAmountPromptInput(
    BuildContext context, {
    required ChatMessage promptMessage,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final sending = runtime.sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: TextField(
        controller: inputCtrl,
        enabled: !sending,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => submitIncomeAmountPrompt(promptMessage),
        decoration: InputDecoration(
          hintText: isEs
              ? 'Escribe el importe, ej. 742,70'
              : 'Enter amount, e.g. 742.70',
          prefixIcon: const Icon(Icons.payments_outlined, size: 18),
          suffixIcon: IconButton(
            tooltip: isEs ? 'Enviar importe' : 'Send amount',
            onPressed:
                sending ? null : () => submitIncomeAmountPrompt(promptMessage),
            icon: const Icon(Icons.send_rounded, size: 18),
          ),
          filled: true,
          fillColor: cs.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary, width: 1.4),
          ),
        ),
        style: t.bodySmall.copyWith(
          color: cs.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget buildChatComposer(
    BuildContext context, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final sending = runtime.sending;
    final hasText = inputCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            onFocusChange: (focused) {
              if (_composerFocused == focused || !mounted) return;
              setState(() => _composerFocused = focused);
            },
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                if (!sending) submitTypedMessage();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 58, maxHeight: 190),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _composerFocused
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: TextField(
                      controller: inputCtrl,
                      focusNode: chatComposerFocusNode,
                      enabled: !sending,
                      minLines: 1,
                      maxLines: MediaQuery.sizeOf(context).height -
                                  MediaQuery.viewInsetsOf(context).bottom <
                              320
                          ? 2
                          : MediaQuery.sizeOf(context).width < 360
                              ? 3
                              : 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: isEs
                            ? 'Pregunta algo o pide ayuda con una tarea…'
                            : 'Ask something or get help with a task…',
                        hintMaxLines: 1,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintStyle: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 14.5,
                        ),
                        contentPadding:
                            const EdgeInsets.fromLTRB(15, 13, 15, 6),
                      ),
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 7),
                      child: IconButton(
                        tooltip: isEs ? 'Enviar' : 'Send',
                        onPressed:
                            sending || !hasText ? null : submitTypedMessage,
                        icon: sending
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onSurfaceVariant,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded, size: 19),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(36, 36),
                          minimumSize: const Size(36, 36),
                          maximumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: hasText
                              ? cs.primary
                              : cs.onSurfaceVariant.withValues(alpha: 0.14),
                          foregroundColor:
                              hasText ? cs.onPrimary : cs.onSurfaceVariant,
                          disabledBackgroundColor:
                              cs.onSurfaceVariant.withValues(alpha: 0.14),
                          disabledForegroundColor: cs.onSurfaceVariant,
                          shape: const CircleBorder(),
                          animationDuration: const Duration(milliseconds: 140),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Keep guidance outside the input surface so it does not compete
          // with the prompt or create another border.
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              isEs
                  ? 'El asistente IA puede cometer errores. Verifica la información importante.'
                  : 'The AI assistant can make mistakes. Verify important information.',
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.72),
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
