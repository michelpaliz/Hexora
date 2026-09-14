part of '../banking_tab.dart';

extension _BankingTabSections on _BankingTabState {
  Widget _buildBankingBody({
    required BuildContext context,
    required EnableBankingController c,
    required TrueLayerController tl,
    required ColorScheme cs,
  }) {
    final hasCaixa = c.banks.any(_looksLikeCaixa);
    final filter = _bankFilter.trim().toLowerCase();
    final banksFiltered = filter.isEmpty
        ? c.banks
        : c.banks.where((b) {
            final a = _aspspName(b).toLowerCase();
            final t = _bankTitle(b).toLowerCase();
            return a.contains(filter) || t.contains(filter);
          }).toList();

    final linkLabel = c.linkStatus.linked == null
        ? 'Unknown'
        : (c.linkStatus.linked! ? 'Linked' : 'Not linked');
    final connectLooksLikeAudienceIssue =
        (c.connectError ?? '').toLowerCase().contains('jwt audience');
    final connectLooksLikeAspspNotFound =
        (c.connectError ?? '').toLowerCase().contains('aspsp not found');

    final now = DateTime.now();
    final defaultFrom = _fmtYmd(DateTime(now.year, now.month, 1));
    final defaultTo = _fmtYmd(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FolderSectionCard(
          label: 'Bancos',
          leftTabOffset: 0,
          rightTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.link),
                            const SizedBox(width: 8),
                            Text('Callback status: $linkLabel',
                                style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            TextButton(
                              onPressed: c.clearLinkStatus,
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        Text(
                          'API base: ${ApiConstants.baseUrl}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (c.linkStatus.sessionId != null &&
                            c.linkStatus.sessionId!.isNotEmpty)
                          Text('session_id: ${c.linkStatus.sessionId!}'),
                        if (c.linkStatus.error != null &&
                            c.linkStatus.error!.isNotEmpty)
                          Text('error: ${c.linkStatus.error!}',
                              style: TextStyle(color: cs.error)),
                        if (c.linkStatus.updatedAt != null)
                          Text('updated: ${c.linkStatus.updatedAt}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined),
                            const SizedBox(width: 8),
                            Text('TrueLayer',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect opens the consent URL in a new tab. After consent, the backend redirects to '
                          '`/#/enablebanking?linked=1` (or `error=...`).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: tl.connecting
                              ? null
                              : () async {
                                  final r = await tl.connect();
                                  final url = r?['url']?.toString();
                                  if (!context.mounted) return;
                                  if (url == null || url.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Backend did not return a consent URL')),
                                    );
                                    return;
                                  }
                                  await _openExternalUrl(context, url);
                                },
                          child: tl.connecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Connect'),
                        ),
                        if (tl.connectError != null) ...[
                          const SizedBox(height: 8),
                          Text(tl.connectError!,
                              style: TextStyle(color: cs.error)),
                        ],
                        if (tl.connectResult != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (tl.connectResult!['state'] != null)
                                'state: ${tl.connectResult!['state']}',
                            ].join('\n'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed:
                                    tl.loadingAccounts ? null : tl.listAccounts,
                                child: tl.loadingAccounts
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('List Accounts'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (tl.accountsCached)
                              Chip(
                                label: const Text('cached'),
                                backgroundColor: cs.tertiaryContainer,
                              ),
                            if (tl.accountsWarning != null &&
                                tl.accountsWarning!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(tl.accountsWarning!),
                                backgroundColor: cs.errorContainer,
                              ),
                            ],
                          ],
                        ),
                        if (tl.accountsError != null) ...[
                          const SizedBox(height: 8),
                          Text(tl.accountsError!,
                              style: TextStyle(color: cs.error)),
                        ],
                        if (tl.accounts.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Accounts: ${tl.accounts.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          ...tl.accounts.map((a) {
                            final id =
                                (a['id'] ?? a['accountId'] ?? '').toString();
                            final isLoading =
                                tl.loadingTransactions[id] == true;
                            final tErr = tl.transactionsError[id];
                            final tRes = tl.transactionsResult[id];
                            final cached = tRes?['cached'] == true;
                            final warning = tRes?['warning']?.toString();
                            final txs = (tRes?['transactions'] is List)
                                ? (tRes!['transactions'] as List)
                                    .whereType<Map>()
                                    .toList()
                                : const <Map>[];

                            final fromC = _ensureDateController(
                              _tlFromControllers,
                              id,
                              initialText: defaultFrom,
                            );
                            final toC = _ensureDateController(
                              _tlToControllers,
                              id,
                              initialText: defaultTo,
                            );

                            return Card(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(_accountTitle(a)),
                                      subtitle: Text(
                                        [
                                          if (a['iban'] != null)
                                            'IBAN: ${a['iban']}',
                                          if (a['currency'] != null)
                                            'Currency: ${a['currency']}',
                                          if (id.isNotEmpty) 'id: $id',
                                        ].join(' • '),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 140,
                                            child: TextField(
                                              controller: fromC,
                                              decoration: const InputDecoration(
                                                labelText: 'From',
                                                hintText: 'YYYY-MM-DD',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 140,
                                            child: TextField(
                                              controller: toC,
                                              decoration: const InputDecoration(
                                                labelText: 'To',
                                                hintText: 'YYYY-MM-DD',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Pick range',
                                            onPressed: () async {
                                              final range =
                                                  await _pickRange(context);
                                              if (range == null) return;
                                              fromC.text = _fmtYmd(range.start);
                                              toC.text = _fmtYmd(range.end);
                                            },
                                            icon: const Icon(Icons.date_range),
                                          ),
                                          const SizedBox(width: 8),
                                          FilledButton.tonal(
                                            onPressed: id.isEmpty || isLoading
                                                ? null
                                                : () async {
                                                    final fromD = _tryParseYmd(
                                                        fromC.text);
                                                    final toD =
                                                        _tryParseYmd(toC.text);
                                                    if (fromD == null ||
                                                        toD == null) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Please enter valid dates: YYYY-MM-DD'),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    if (toD.isBefore(fromD)) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Invalid range: "to" is before "from"'),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    await tl.fetchTransactions(
                                                      accountId: id,
                                                      from: _fmtYmd(fromD),
                                                      to: _fmtYmd(toD),
                                                    );
                                                  },
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  )
                                                : const Text('Transactions'),
                                          ),
                                          const SizedBox(width: 12),
                                          if (cached)
                                            Chip(
                                              label: const Text('cached'),
                                              backgroundColor:
                                                  cs.tertiaryContainer,
                                            ),
                                          if (warning != null &&
                                              warning.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(warning),
                                              backgroundColor:
                                                  cs.errorContainer,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (tErr != null) ...[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(tErr,
                                              style:
                                                  TextStyle(color: cs.error)),
                                        ),
                                      ),
                                    ],
                                    if (txs.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Transactions (${txs.length})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            const SizedBox(height: 8),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxHeight: 320),
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: txs.length,
                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),
                                                itemBuilder: (_, i) {
                                                  final tx =
                                                      Map<String, dynamic>.from(
                                                          txs[i]);
                                                  final title = (tx[
                                                              'merchantName'] ??
                                                          tx['counterpartyName'] ??
                                                          tx['description'] ??
                                                          tx['remittanceInformationUnstructured'] ??
                                                          'Transaction')
                                                      .toString();
                                                  final amount = tx['amount'] ??
                                                      tx['transactionAmount'] ??
                                                      tx['value'];
                                                  final date =
                                                      tx['bookingDate'] ??
                                                          tx['date'] ??
                                                          tx['valueDate'];
                                                  return ListTile(
                                                    dense: true,
                                                    title: Text(title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                    subtitle: Text(
                                                      [
                                                        if (date != null)
                                                          'date: $date',
                                                        if (amount != null)
                                                          'amount: $amount'
                                                      ].join(' • '),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_outlined),
                            const SizedBox(width: 8),
                            Text('Banks',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Country (2-letter)',
                            hintText: 'ES',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          controller: _countryController,
                          onChanged: c.setCountry,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: c.loadingBanks
                              ? null
                              : () => c.listBanks(country: c.country),
                          child: c.loadingBanks
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text('List Banks (country=${c.country})'),
                        ),
                        if (c.banksError != null) ...[
                          const SizedBox(height: 8),
                          Text(c.banksError!,
                              style: TextStyle(color: cs.error)),
                        ],
                        if (c.banks.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Banks loaded: ${c.banks.length}${filter.isEmpty ? '' : ' • showing ${banksFiltered.length}'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bankFilterController,
                            decoration: InputDecoration(
                              labelText: 'Filter banks',
                              hintText: 'Type e.g. Caixa, BBVA…',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: _bankFilter.trim().isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear',
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearBankFilter,
                                    ),
                            ),
                            onChanged: _setBankFilter,
                          ),
                          const SizedBox(height: 12),
                          Autocomplete<String>(
                            key: ValueKey(
                                'aspsp-autocomplete-${c.banks.length}-${c.selectedAspspName ?? ''}'),
                            initialValue: TextEditingValue(
                                text: c.selectedAspspName ?? ''),
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              final q =
                                  textEditingValue.text.trim().toLowerCase();
                              final names = c.banks
                                  .map(_aspspName)
                                  .where((s) => s.isNotEmpty)
                                  .toSet()
                                  .toList()
                                ..sort();
                              if (q.isEmpty) return names.take(50);
                              return names
                                  .where((n) => n.toLowerCase().contains(q))
                                  .take(50);
                            },
                            onSelected: (name) => c.selectAspsp(name),
                            fieldViewBuilder: (context, textController,
                                focusNode, onFieldSubmitted) {
                              return TextFormField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Select bank (aspsp_name)',
                                  border: OutlineInputBorder(),
                                  helperText:
                                      'Start typing to search; pick the exact name returned by EnableBanking.',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          if (!hasCaixa)
                            Text(
                              'Note: “CaixaBank” is not present in the EnableBanking list returned for country ${c.country}. '
                              'Pick a bank from the list (or change country) and use that exact name.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (!hasCaixa) const SizedBox(height: 12),
                          ...banksFiltered.map((b) {
                            final aspspName = _aspspName(b);
                            final title = _bankTitle(b);
                            final isCaixa = _looksLikeCaixa(b);
                            final isSelected = c.selectedAspspName == aspspName;
                            return Card(
                              color: isSelected
                                  ? cs.primaryContainer
                                  : (isCaixa ? cs.secondaryContainer : null),
                              child: ListTile(
                                leading: Icon(
                                  Icons.account_balance,
                                  color: isSelected
                                      ? cs.onPrimaryContainer
                                      : (isCaixa
                                          ? cs.onSecondaryContainer
                                          : null),
                                ),
                                title: Text(
                                  aspspName.isEmpty ? title : aspspName,
                                  style: (isSelected || isCaixa)
                                      ? TextStyle(
                                          color: isSelected
                                              ? cs.onPrimaryContainer
                                              : cs.onSecondaryContainer,
                                          fontWeight: FontWeight.w800,
                                        )
                                      : null,
                                ),
                                subtitle: Text(
                                  [
                                    b['bic'],
                                    b['id'],
                                    b['country'],
                                  ]
                                      .where((v) =>
                                          v != null && v.toString().isNotEmpty)
                                      .join(' • '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: isSelected
                                      ? TextStyle(color: cs.onPrimaryContainer)
                                      : (isCaixa
                                          ? TextStyle(
                                              color: cs.onSecondaryContainer)
                                          : null),
                                ),
                                onTap: aspspName.isEmpty
                                    ? null
                                    : () => c.selectAspsp(aspspName),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.login_rounded),
                            const SizedBox(width: 8),
                            Text('Consent',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.account_balance),
                          onPressed: c.connecting
                              ? null
                              : (c.selectedAspspName == null ||
                                      c.selectedAspspName!.isEmpty)
                                  ? null
                                  : () async {
                                      final r = await c.connect();
                                      final url = r?['url']?.toString();
                                      if (url != null && context.mounted) {
                                        await _openExternalUrl(context, url);
                                      }
                                    },
                          label: c.connecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  c.selectedAspspName == null
                                      ? 'Select a bank first'
                                      : 'Connect: ${c.selectedAspspName}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        if (c.connectError != null) ...[
                          const SizedBox(height: 8),
                          Text(c.connectError!,
                              style: TextStyle(color: cs.error)),
                        ],
                        if (connectLooksLikeAspspNotFound) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ASPSP not found. Pick a bank from the list above (exact name) and retry.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (connectLooksLikeAudienceIssue) ...[
                          const SizedBox(height: 8),
                          Text(
                            'This usually means your saved JWT was issued for a different backend environment '
                            '(audience mismatch). Clear auth tokens and log in again using the same BASE_URL '
                            'you are running now.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Clear auth + go to login'),
                            onPressed: () async {
                              await TokenService.clearTokens();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.loginRoute,
                                (_) => false,
                              );
                            },
                          ),
                        ],
                        if (c.connectResult != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (c.connectResult!['authorization_id'] != null)
                                'authorization_id: ${c.connectResult!['authorization_id']}',
                              if (c.connectResult!['state'] != null)
                                'state: ${c.connectResult!['state']}',
                            ].join('\n'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'After completing consent, you may be redirected to `/#/callback` or back to `/#/enablebanking?linked=1`.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined),
                            const SizedBox(width: 8),
                            Text('Accounts',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: c.loadingAccounts ? null : c.listAccounts,
                          child: c.loadingAccounts
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Fetch Accounts'),
                        ),
                        if (c.accountsError != null) ...[
                          const SizedBox(height: 8),
                          Text(c.accountsError!,
                              style: TextStyle(color: cs.error)),
                        ],
                        if (c.accounts.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...c.accounts.map((a) {
                            final id =
                                (a['id'] ?? a['accountId'] ?? '').toString();
                            final isLoading = c.loadingTransactions[id] == true;
                            final tErr = c.transactionsError[id];
                            final tRes = c.transactionsResult[id];
                            final cached = tRes?['cached'] == true;
                            final warning = tRes?['warning']?.toString();
                            final txs = (tRes?['transactions'] is List)
                                ? (tRes!['transactions'] as List)
                                    .whereType<Map>()
                                    .toList()
                                : const <Map>[];
                            return Card(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(_accountTitle(a)),
                                      subtitle: Text(
                                        [
                                          if (a['iban'] != null)
                                            'IBAN: ${a['iban']}',
                                          if (a['currency'] != null)
                                            'Currency: ${a['currency']}',
                                          if (id.isNotEmpty) 'id: $id',
                                        ].join(' • '),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 8),
                                      child: Row(
                                        children: [
                                          FilledButton.tonal(
                                            onPressed: id.isEmpty || isLoading
                                                ? null
                                                : () async {
                                                    final range =
                                                        await _pickRange(
                                                            context);
                                                    if (range == null) return;
                                                    await c.fetchTransactions(
                                                      accountId: id,
                                                      dateFrom: range.start,
                                                      dateTo: range.end,
                                                    );
                                                  },
                                            child: isLoading
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  )
                                                : const Text(
                                                    'Fetch Transactions'),
                                          ),
                                          const SizedBox(width: 12),
                                          if (cached)
                                            Chip(
                                              label: const Text('cached'),
                                              backgroundColor:
                                                  cs.tertiaryContainer,
                                            ),
                                          if (warning != null &&
                                              warning.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(warning),
                                              backgroundColor:
                                                  cs.errorContainer,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (tErr != null) ...[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(tErr,
                                              style:
                                                  TextStyle(color: cs.error)),
                                        ),
                                      ),
                                    ],
                                    if (txs.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Transactions (${txs.length})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            const SizedBox(height: 8),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxHeight: 320),
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                itemCount: txs.length,
                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),
                                                itemBuilder: (_, i) {
                                                  final tx =
                                                      Map<String, dynamic>.from(
                                                          txs[i]);
                                                  final title = (tx[
                                                              'merchantName'] ??
                                                          tx['counterpartyName'] ??
                                                          tx['description'] ??
                                                          tx['remittanceInformationUnstructured'] ??
                                                          'Transaction')
                                                      .toString();
                                                  final amount = tx['amount'] ??
                                                      tx['transactionAmount'] ??
                                                      tx['value'];
                                                  final date =
                                                      tx['bookingDate'] ??
                                                          tx['date'] ??
                                                          tx['valueDate'];
                                                  return ListTile(
                                                    dense: true,
                                                    title: Text(title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                    subtitle: Text(
                                                      [
                                                        if (date != null)
                                                          'date: $date',
                                                        if (amount != null)
                                                          'amount: $amount'
                                                      ].join(' • '),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
