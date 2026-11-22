import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_enums.dart';
import '../insights_chat_message.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsComposer on InsightsChatSheetStateBase {
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
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            if (!sending) submitTypedMessage();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: inputCtrl,
              focusNode: chatComposerFocusNode,
              enabled: !sending,
              minLines: 1,
              maxLines: MediaQuery.viewInsetsOf(context).bottom > 0 ? 2 : 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: runtime.interactionMode ==
                        InsightsInteractionMode.openQuestions
                    ? isEs
                        ? 'Pregunta sobre este negocio…'
                        : 'Ask about this business…'
                    : isEs
                        ? 'Escribe un mensaje…'
                        : 'Write a message…',
                hintMaxLines: 1,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                constraints: const BoxConstraints(minHeight: 52),
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
                contentPadding: const EdgeInsets.fromLTRB(14, 12, 56, 12),
              ),
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: 13,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: IconButton.filled(
                tooltip: isEs ? 'Enviar' : 'Send',
                onPressed: sending ? null : submitTypedMessage,
                icon: sending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  maximumSize: const Size(40, 40),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  disabledBackgroundColor: cs.primary.withValues(alpha: 0.45),
                  disabledForegroundColor: cs.onPrimary.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
