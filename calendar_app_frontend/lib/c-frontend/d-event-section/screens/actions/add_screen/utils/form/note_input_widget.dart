import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NoteInputWidget extends StatelessWidget {
  final TextEditingController noteController;

  /// If true, show the field's own label; if false, rely on the outer section title.
  final bool showFieldLabel;

  /// Visible placeholder; if null we use l.noteHint.
  final String? hintText;

  /// Hard limit in WORDS (not characters).
  final int maxWords;

  const NoteInputWidget({
    super.key,
    required this.noteController,
    this.showFieldLabel = false,
    this.hintText,
    this.maxWords = 50,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: noteController,
      builder: (context, value, _) {
        final wordCount = _countWords(value.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: noteController,
              style: typo.bodyMedium,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              inputFormatters: [WordsLimitFormatter(maxWords)],
              decoration: InputDecoration(
                // Avoid duplicate title if the card already shows one:
                labelText: showFieldLabel ? l.note(maxWords) : null,
                labelStyle: typo.bodySmall,
                // Ensure a visible hint:
                hintText: hintText,
                hintStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Live word counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$wordCount/$maxWords',
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }

  int _countWords(String text) {
    final words =
        text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return words.length;
  }
}

/// InputFormatter that blocks additional words once [maxWords] is reached.
class WordsLimitFormatter extends TextInputFormatter {
  final int maxWords;
  WordsLimitFormatter(this.maxWords);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final words = newValue.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.length <= maxWords) return newValue;

    // If exceeding, revert to old (prevents adding more words).
    return oldValue;
  }
}
