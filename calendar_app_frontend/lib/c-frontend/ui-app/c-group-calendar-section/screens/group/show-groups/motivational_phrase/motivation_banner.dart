// motivation_banner.dart
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

// import the two lists
import 'quotes/quotes_en.dart';
import 'quotes/quotes_es.dart';

class MotivationBanner extends StatefulWidget {
  final bool dailyRotate;
  final double height;

  const MotivationBanner(
      {super.key, this.dailyRotate = true, this.height = 180});

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
      final r = Random();
      _seed = r.nextInt(1 << 31).toString();
      _quoteIndex = r.nextInt(1000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    final list = lang.startsWith('es') ? quotesEs : quotesEn;
    final (quote, author) = list[_quoteIndex % list.length];

    final imageUrl = 'https://picsum.photos/seed/$_seed/1600/700';

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueGrey.shade300,
                        Colors.blueGrey.shade600
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.45)
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          '“$quote”',
                          maxLines: 3,
                          minFontSize: 14,
                          stepGranularity: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AutoSizeText(
                          author,
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
                    ),
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
