import 'package:flutter/material.dart';

/// Theme-aware calendar illustration built from the existing Material shapes.
class CalendarDetailsIllustration extends StatelessWidget {
  const CalendarDetailsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: 144,
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 6,
              child: Container(
                width: 138,
                height: 65,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(48),
                ),
              ),
            ),
            Transform.rotate(
              angle: -.06,
              child: Container(
                width: 88,
                height: 84,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(3, 5),
                    )
                  ],
                ),
                child: Column(children: [
                  Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: .85),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                          2,
                          (_) => Container(
                                width: 6,
                                height: 15,
                                decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(4)),
                              )),
                    ),
                  ),
                  const SizedBox(height: 7),
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            4,
                            (column) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  width: 13,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(
                                        alpha: row == 1 && column == 2
                                            ? .45
                                            : .13),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                )),
                      ),
                    ),
                ]),
              ),
            ),
            Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.auto_awesome,
                    size: 23, color: cs.primary.withValues(alpha: .65))),
          ],
        ),
      ),
    );
  }
}
