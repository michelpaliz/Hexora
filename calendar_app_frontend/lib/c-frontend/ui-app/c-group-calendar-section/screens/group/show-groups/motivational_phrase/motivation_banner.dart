import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import 'quotes/quotes_en.dart';
import 'quotes/quotes_es.dart';

class MotivationBanner extends StatefulWidget {
  final bool dailyRotate;

  /// Fixed height in pixels. Pass `null` to let the widget fill
  /// whatever height its parent provides (for example inside an
  /// [IntrinsicHeight] row).
  final double? height;

  const MotivationBanner({
    super.key,
    this.dailyRotate = true,
    this.height = 180,
  });

  @override
  State<MotivationBanner> createState() => _MotivationBannerState();
}

class _MotivationBannerState extends State<MotivationBanner> {
  late final String _seed;
  late final int _quoteIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.dailyRotate) {
      _seed =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      _quoteIndex = int.parse(_seed);
    } else {
      final random = Random();
      _seed = random.nextInt(1 << 31).toString();
      _quoteIndex = random.nextInt(1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final list = lang.startsWith('es') ? quotesEs : quotesEn;
    final (quote, author) = list[_quoteIndex % list.length];
    final imageUrl = 'https://picsum.photos/seed/$_seed/1600/700';

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueGrey.shade400,
                        Colors.blueGrey.shade700,
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueGrey.shade300,
                      Colors.blueGrey.shade600,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                  stops: const [0.1, 0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                final compact = maxHeight < 132;
                final veryCompact = maxHeight < 104;
                final horizontalPadding =
                    veryCompact ? 12.0 : (compact ? 16.0 : 20.0);
                final verticalPadding =
                    veryCompact ? 6.0 : (compact ? 14.0 : 22.0);
                final showAuthor = maxHeight >= 112;
                final quoteMaxLines = veryCompact ? 1 : 2;
                final quoteFontSize =
                    veryCompact ? 22.0 : (compact ? 36.0 : 42.0);
                final quoteMinFont =
                    veryCompact ? 10.0 : (compact ? 16.0 : 18.0);
                final quoteLineHeight = veryCompact ? 1.0 : 1.2;
                final authorFontSize = compact ? 14.0 : 16.0;
                final maxQuoteWidth = max(
                  0.0,
                  min(620.0, constraints.maxWidth - (horizontalPadding * 2)),
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxQuoteWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            '"$quote"',
                            maxLines: quoteMaxLines,
                            minFontSize: quoteMinFont,
                            stepGranularity: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: quoteFontSize,
                              height: quoteLineHeight,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (showAuthor) ...[
                            SizedBox(height: compact ? 4 : 8),
                            AutoSizeText(
                              '- $author',
                              maxLines: 1,
                              minFontSize: 11,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: authorFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.94),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height!, child: inner);
    }
    return inner;
  }
}
