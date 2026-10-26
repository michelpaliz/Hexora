part of '../../mail_compose_screen.dart';

Widget _composeRecipientsCard(
        {required _MailComposeScreenState state,
        required BuildContext context,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact,
        required List<GroupClient> recipientClients,
        required InputDecoration inputDecoration,
        required Widget recipientInput,
        required Widget recipientMode}) =>
    Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── To row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 8, 3),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        Text(l.mailComposeToLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        recipientMode,
                        const SizedBox(height: 6),
                        recipientInput,
                      ])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // "Para" label
                      SizedBox(
                        width: 42,
                        child: Text(
                          l.mailComposeToLabel,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // Input area
                      Expanded(
                          child: Container(
                              key: const ValueKey(
                                  'mail-compose-recipient-input-surface'),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: .5))),
                              child: recipientInput)),
                      const SizedBox(width: 6),
                      // Compact mode toggle
                      recipientMode,
                    ],
                  ),
          ),
          // Sub-hints for email / client mode
          if (!state._useClientMode && state._toList.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 12 : 56, 0, 12, 5),
              child: Text(
                l.mailComposeToHelper,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: compact ? 13 : 11,
                ),
              ),
            ),
          if (state._useClientMode) ...[
            if ((state._recipientClientError ?? '').isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(compact ? 12 : 56, 0, 12, 5),
                child: Row(children: [
                  Icon(Icons.error_outline, size: 13, color: cs.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(state._recipientClientError!,
                        style: t.bodySmall
                            .copyWith(color: cs.error, fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: state._loadingRecipientClients
                        ? null
                        : state._loadRecipientClientsIfNeeded,
                    child:
                        Text(state._isSpanishLocale ? 'Reintentar' : 'Retry'),
                  ),
                ]),
              ),
            if (!state._loadingRecipientClients &&
                state._recipientClientError == null &&
                recipientClients.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(compact ? 12 : 56, 0, 12, 5),
                child: Text(
                  state._pickerClients.isEmpty
                      ? l.noClientsYet
                      : (state._isSpanishLocale
                          ? 'No hay clientes con correo electrónico.'
                          : 'No clients have an email address.'),
                  style: t.bodySmall
                      .copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ),
            if (state._selectedRecipientClientEmail() != null)
              Padding(
                padding: EdgeInsets.fromLTRB(compact ? 12 : 56, 0, 12, 5),
                child: Row(children: [
                  Icon(
                    Icons.alternate_email_rounded,
                    size: 12,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      state._selectedRecipientClientEmail()!,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ]),
              ),
            if (state._selectedRecipientClient() case final client?)
              if (state._clientEmailIssue(client).isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(compact ? 12 : 56, 0, 8, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: ThemeColors.warning(context),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          state._clientEmailIssue(client) == 'invalid'
                              ? (state._isSpanishLocale
                                  ? 'Correo no válido'
                                  : 'Invalid email')
                              : (state._isSpanishLocale
                                  ? 'Sin correo registrado'
                                  : 'No email registered'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                            color: ThemeColors.warning(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: state._sending
                            ? null
                            : state._enterRecipientManually,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          textStyle: t.bodySmall.copyWith(fontSize: 11),
                        ),
                        child: Text(state._isSpanishLocale
                            ? 'Introducir correo'
                            : 'Enter email'),
                      ),
                      if (state._canEditClients)
                        TextButton(
                          onPressed: state._sending
                              ? null
                              : state._editSelectedRecipientClient,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            textStyle: t.bodySmall.copyWith(fontSize: 11),
                          ),
                          child: Text(state._isSpanishLocale
                              ? 'Actualizar cliente'
                              : 'Update client'),
                        ),
                    ],
                  ),
                ),
          ],
          // ── CC / BCC expanded fields ──────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state._showCc) ...[
                  Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.35)),
                  _InlineRecipientRow(
                    label: l.mailComposeCcLabel,
                    controller: state._ccCtrl,
                    values: state._ccList,
                    hint: l.mailComposeCcHint,
                    enabled: !state._sending,
                    inputDecoration: inputDecoration,
                    onChanged: (next) => state.update(() => state._ccList
                      ..clear()
                      ..addAll(next)),
                    onRemove: () => state.update(() => state._showCc = false),
                  ),
                ],
                if (state._showBcc) ...[
                  Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.35)),
                  _InlineRecipientRow(
                    label: l.mailComposeBccLabel,
                    controller: state._bccCtrl,
                    values: state._bccList,
                    hint: l.mailComposeBccHint,
                    enabled: !state._sending,
                    inputDecoration: inputDecoration,
                    onChanged: (next) => state.update(() => state._bccList
                      ..clear()
                      ..addAll(next)),
                    onRemove: () => state.update(() => state._showBcc = false),
                  ),
                ],
              ],
            ),
          ),
          // ── CC / BCC toggle footer ────────────────────────────────
          if (!state._showCc || !state._showBcc) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Wrap(
                children: [
                  if (!state._showCc)
                    TextButton(
                      onPressed: state._sending
                          ? null
                          : () => state.update(() => state._showCc = true),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: cs.onSurfaceVariant,
                        textStyle: t.bodySmall.copyWith(
                            fontSize: 11, fontWeight: FontWeight.w500),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      child: Text(l.mailComposeAddCc),
                    ),
                  if (!state._showBcc)
                    TextButton(
                      onPressed: state._sending
                          ? null
                          : () => state.update(() => state._showBcc = true),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: cs.onSurfaceVariant,
                        textStyle: t.bodySmall.copyWith(
                            fontSize: 11, fontWeight: FontWeight.w500),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                      child: Text(l.mailComposeAddBcc),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
