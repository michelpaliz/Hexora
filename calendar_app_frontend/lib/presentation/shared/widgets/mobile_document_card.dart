import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared mobile document hierarchy: client, amount, reference/date, status.
class MobileDocumentCard extends StatelessWidget {
  const MobileDocumentCard(
      {super.key,
      required this.title,
      required this.amount,
      required this.metadata,
      required this.isDraft,
      required this.statusLabel,
      this.onTap,
      this.trailing,
      this.badges = const []});
  final String title;
  final String amount;
  final String metadata;
  final bool isDraft;
  final String statusLabel;
  final VoidCallback? onTap;
  final Widget? trailing;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = theme.textTheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 8, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tooltip(
                  message: statusLabel,
                  child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: isDraft
                              ? cs.tertiaryContainer
                              : cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(
                          isDraft
                              ? Icons.description_outlined
                              : Icons.task_alt_outlined,
                          size: 22,
                          color: isDraft
                              ? cs.onTertiaryContainer
                              : cs.onPrimaryContainer))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(
                            color: cs.onSurface, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(amount,
                        style: t.bodyLarge?.copyWith(
                            color: cs.primary, fontWeight: FontWeight.w800)),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(metadata,
                          style:
                              t.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                    ],
                    if (isDraft || badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isDraft)
                              Text(statusLabel,
                                  style: t.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                            ...badges
                          ])
                    ],
                  ])),
              trailing ??
                  IconButton(
                      onPressed: onTap,
                      icon: const Icon(Icons.chevron_right_rounded)),
            ]),
          )),
    );
  }
}

/// All document tabs share newest-first sorting, month headers, and spacing.
class MobileDocumentList<T> extends StatelessWidget {
  const MobileDocumentList(
      {super.key,
      required this.items,
      required this.dateOf,
      required this.itemBuilder});
  final List<T> items;
  final DateTime? Function(T) dateOf;
  final Widget Function(BuildContext, T) itemBuilder;
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final sorted = items.indexed.toList()
      ..sort((a, b) {
        final ad = dateOf(a.$2);
        final bd = dateOf(b.$2);
        final order = ad == null
            ? (bd == null ? 0 : 1)
            : bd == null
                ? -1
                : bd.compareTo(ad);
        return order == 0 ? a.$1.compareTo(b.$1) : order;
      });
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index].$2;
        final date = dateOf(item)?.toLocal();
        final previous =
            index == 0 ? null : dateOf(sorted[index - 1].$2)?.toLocal();
        final header = index == 0 ||
            previous?.year != date?.year ||
            previous?.month != date?.month;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header)
                Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 10),
                    child: Text(
                        date == null
                            ? (locale.languageCode == 'es'
                                ? 'Sin fecha'
                                : 'No date')
                            : DateFormat.yMMMM(locale.toString())
                                .format(date)
                                .toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant))),
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: itemBuilder(context, item)),
            ]);
      },
    );
  }
}
