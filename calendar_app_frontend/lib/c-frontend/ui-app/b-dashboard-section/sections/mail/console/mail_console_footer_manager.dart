part of '../mail_console_screen.dart';

class _FooterManagerPanel extends StatelessWidget {
  const _FooterManagerPanel({required this.state});

  final _MailConsoleScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final previewName = state._footerPreviewName;
    final previewText = state._footerPreviewText;
    final previewHtml = state._footerPreviewHtml;
    final previewedAt = state._footerPreviewedAt;

    Widget previewCard() {
      return Card(
        elevation: 0,
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.mailFooterCurrentTitle,
                            style: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (state._footerPreviewDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.mailFooterDefaultBadge,
                              style: t.bodySmall.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.mailFooterPreviewBody,
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                        if (previewedAt != null)
                          Text(
                            DateFormat.Hm(l.localeName).format(previewedAt),
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (state._footerPreviewLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state._footerPreviewError != null)
                      Text(
                        state._footerPreviewError!,
                        style: t.bodySmall.copyWith(color: cs.error),
                      )
                    else if (previewHtml != null && previewHtml.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: SingleChildScrollView(
                          child: HtmlWidget(previewHtml),
                        ),
                      )
                    else if (previewName == null &&
                        (previewText == null || previewText.isEmpty))
                      Text(
                        l.mailFooterSystemDefault,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previewName ?? l.mailFooterUnnamed,
                              style: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            if (previewText != null && previewText.isNotEmpty)
                              Text(
                                previewText,
                                style: t.bodySmall
                                    .copyWith(color: cs.onSurfaceVariant),
                              ),
                            if (previewHtml != null && previewHtml.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  l.mailFooterHtmlPreview,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(color: cs.outlineVariant.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: state._createFooter,
                          child: Text(l.mailFooterUseThis),
                        ),
                        TextButton(
                          onPressed: () => state.setState(
                            () => state._footerFormExpanded = true,
                          ),
                          child: Text(l.mailFooterEdit),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              state._previewFooter(useSystemDefault: true),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: Text(l.mailFooterPreviewSystemCta),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    Widget formPanel() {
      return Card(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.mailFooterCreateTitle,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l.mailFooterBody,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _FooterFormSection(
                state: state,
                title: l.mailFooterFormTitle,
                expanded: state._footerFormExpanded,
                onToggle: () => state.setState(
                  () => state._footerFormExpanded = !state._footerFormExpanded,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: state._previewFooter,
                    child: Text(l.mailFooterPreviewCta),
                  ),
                  FilledButton(
                    onPressed: state._createFooter,
                    child: Text(l.mailFooterSaveCta),
                  ),
                  OutlinedButton(
                    onPressed: () => state.setState(() {
                      state._footerNameCtrl.clear();
                      state._footerTextCtrl.clear();
                      state._footerHtmlCtrl.clear();
                      state._footerDefault = true;
                    }),
                    child: Text(l.mailFooterUseSystemDefault),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: previewCard()),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: formPanel()),
        ],
      ),
    );
  }
}

class _FooterFormSection extends StatelessWidget {
  const _FooterFormSection({
    required this.state,
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  final _MailConsoleScreenState state;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surface,
      labelStyle: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      hintStyle: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                TextField(
                  controller: state._footerNameCtrl,
                  decoration: inputDecoration.copyWith(
                    labelText: l.mailFooterNameLabel,
                    hintText: l.mailFooterNameHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state._footerTextCtrl,
                  maxLines: 4,
                  decoration: inputDecoration.copyWith(
                    labelText: l.mailFooterTextLabel,
                    hintText: l.mailFooterTextHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: state._footerHtmlCtrl,
                  maxLines: 4,
                  decoration: inputDecoration.copyWith(
                    labelText: l.mailFooterHtmlLabel,
                    hintText: l.mailFooterHtmlHint,
                  ),
                ),
                const SizedBox(height: 6),
                SwitchListTile.adaptive(
                  value: state._footerDefault,
                  onChanged: (value) =>
                      state.setState(() => state._footerDefault = value),
                  title: Text(l.mailFooterDefaultLabel),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 4),
                Text(
                  l.mailFooterHelperTextOnly,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  l.mailFooterHelperHtmlOverrides,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
