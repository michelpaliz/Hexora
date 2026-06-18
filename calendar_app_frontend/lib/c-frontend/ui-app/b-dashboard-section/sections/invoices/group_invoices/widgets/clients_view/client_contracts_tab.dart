import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/client/client_contract.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_contracts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_contract_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_contracts_support.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientContractsTab extends StatefulWidget {
  final GroupClient client;
  final bool compact;
  final ValueChanged<int>? onCountChanged;

  const ClientContractsTab({
    super.key,
    required this.client,
    this.compact = false,
    this.onCountChanged,
  });

  @override
  State<ClientContractsTab> createState() => _ClientContractsTabState();
}

class _ClientContractsTabState extends State<ClientContractsTab> {
  final ClientContractsApi _api = ClientContractsApi();

  List<ClientContract> _contracts = const <ClientContract>[];
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  @override
  void didUpdateWidget(covariant ClientContractsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client.id != widget.client.id) {
      _contracts = const <ClientContract>[];
      _error = null;
      _loading = true;
      _loadContracts();
    }
  }

  Future<void> _loadContracts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final contracts = await _api.list(widget.client.id);
      if (!mounted) return;
      setState(() {
        _contracts = sortClientContracts(contracts);
        _error = null;
      });
      widget.onCountChanged?.call(_contracts.length);
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', '').trim());
    } finally {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  Future<ClientContractFormResult?> _openSheet({
    ClientContract? contract,
    Uint8List? initialUploadBytes,
    String? initialUploadFileName,
  }) async {
    try {
      return await showModalBottomSheet<ClientContractFormResult>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => contract == null
            ? ClientContractSheet.upload(
                initialUploadBytes: initialUploadBytes,
                initialUploadFileName: initialUploadFileName,
              )
            : ClientContractSheet.edit(initialContract: contract),
      );
    } finally {}
  }

  Future<void> _handleUpload() async {
    final result = await _openSheet();
    if (result == null) return;
    await _submitUploadResult(result);
  }

  Future<void> _submitUploadResult(ClientContractFormResult result) async {
    final l = AppLocalizations.of(context)!;
    if (result.fileBytes == null ||
        (result.uploadFileName ?? '').trim().isEmpty) {
      _showSnack(l.contractFileRequired, error: true);
      return;
    }
    setState(() => _uploading = true);
    try {
      await _api.upload(
        clientId: widget.client.id,
        fileBytes: result.fileBytes!,
        fileName: result.uploadFileName!,
        title: result.title,
        contractType: result.contractType,
        status: result.status,
        startDate: clientContractDateForApi(result.startDate),
        endDate: clientContractDateForApi(result.endDate),
        renewalDate: clientContractDateForApi(result.renewalDate),
        signedAt: clientContractDateForApi(result.signedAt),
        notes: result.notes,
        tags: result.tags,
        version: result.version,
        isCurrent: result.isCurrent,
      );
      await _loadContracts(silent: true);
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(l.contractUploadSuccess);
    } catch (e) {
      _showSnack(l.contractUploadFailed(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildContractsContent(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    if (_loading && _contracts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if ((_error ?? '').isNotEmpty && _contracts.isEmpty) {
      return _ContractsErrorState(
        message: _error!,
        onRetry: _loadContracts,
      );
    }
    if (_contracts.isEmpty) {
      return EmptyView(
        icon: Icons.description_outlined,
        title: l.contractsEmptyTitle,
        subtitle: l.contractsEmptySubtitle,
      );
    }

    return Column(
      children: [
        if ((_error ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.errorContainer.withValues(alpha: 0.45),
                border: Border.all(
                  color: cs.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: t.bodySmall.copyWith(color: cs.error),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadContracts,
                    child: Text(l.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadContracts,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemBuilder: (context, index) {
                final contract = _contracts[index];
                return _ClientContractCard(
                  contract: contract,
                  compact: widget.compact,
                  busy: _busyIds.contains(contract.id),
                  onView: () => _openContractUrl(contract, download: false),
                  onDownload: () => _openContractUrl(contract, download: true),
                  onEdit: () => _handleEdit(contract),
                  onDelete: () => _handleDelete(contract),
                  onMarkCurrent: contract.isCurrent
                      ? null
                      : () => _handleMarkCurrent(contract),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: _contracts.length,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEdit(ClientContract contract) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busyIds.add(contract.id));
    try {
      final fresh = await _api.getById(widget.client.id, contract.id);
      if (!mounted) return;
      setState(() => _busyIds.remove(contract.id));
      final result = await _openSheet(contract: fresh);
      if (result == null) return;
      setState(() => _busyIds.add(contract.id));
      await _api.update(
        clientId: widget.client.id,
        contractId: contract.id,
        fields: result.toUpdatePayload(),
      );
      await _loadContracts(silent: true);
      _showSnack(l.contractUpdateSuccess);
    } catch (e) {
      _showSnack(l.contractUpdateFailed(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(contract.id));
    }
  }

  Future<void> _handleDelete(ClientContract contract) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.contractDeleteTitle),
        content: Text(l.contractDeleteBody(contract.displayTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyIds.add(contract.id));
    try {
      await _api.delete(widget.client.id, contract.id);
      await _loadContracts(silent: true);
      _showSnack(l.contractDeleteSuccess);
    } catch (e) {
      _showSnack(l.contractDeleteFailed(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(contract.id));
    }
  }

  Future<void> _handleMarkCurrent(ClientContract contract) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busyIds.add(contract.id));
    try {
      await _api.update(
        clientId: widget.client.id,
        contractId: contract.id,
        fields: const <String, dynamic>{'isCurrent': true},
      );
      await _loadContracts(silent: true);
      _showSnack(l.contractMarkedCurrentSuccess);
    } catch (e) {
      _showSnack(l.contractUpdateFailed(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(contract.id));
    }
  }

  Future<void> _openContractUrl(
    ClientContract contract, {
    required bool download,
  }) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busyIds.add(contract.id));
    try {
      final file = await _api.getFile(widget.client.id, contract.id);
      final uri = Uri.tryParse(file.url);
      if (uri == null) throw Exception(l.contractOpenFailedGeneric);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched) throw Exception(l.contractOpenFailedGeneric);
    } catch (e) {
      final message = download
          ? l.contractDownloadFailed(e.toString())
          : l.contractOpenFailed(e.toString());
      _showSnack(message, error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(contract.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.contractsTitle,
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.contractsForClient(widget.client.name),
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              );

              final actions = Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: l.tryAgain,
                    onPressed: _loading ? null : _loadContracts,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _uploading ? null : _handleUpload,
                    icon: _uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(l.contractUploadAction),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  actions,
                ],
              );
            },
          ),
        ),
        if (_uploading || _loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  Expanded(
                    child: _buildContractsContent(l, t, cs),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContractsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ContractsErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 52, color: cs.error),
            const SizedBox(height: 12),
            Text(
              l.contractsLoadFailedTitle,
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientContractCard extends StatefulWidget {
  final ClientContract contract;
  final bool compact;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMarkCurrent;

  const _ClientContractCard({
    required this.contract,
    required this.compact,
    required this.busy,
    required this.onView,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkCurrent,
  });

  @override
  State<_ClientContractCard> createState() => _ClientContractCardState();
}

class _ClientContractCardState extends State<_ClientContractCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final contract = widget.contract;
    final compact = widget.compact;
    final busy = widget.busy;
    final expired = isClientContractExpired(contract);
    final expiringSoon = !expired && isClientContractExpiringSoon(contract);
    final borderColor = expired
        ? cs.error.withValues(alpha: 0.4)
        : contract.isCurrent
            ? cs.primary.withValues(alpha: 0.35)
            : cs.outlineVariant.withValues(alpha: 0.35);
    final backgroundColor = expired
        ? cs.errorContainer.withValues(alpha: 0.22)
        : contract.isCurrent
            ? cs.primaryContainer.withValues(alpha: 0.14)
            : Colors.transparent;

    final uploadedLabel = contract.createdAt == null
        ? '—'
        : DateFormat.yMMMd(l.localeName)
            .add_Hm()
            .format(contract.createdAt!.toLocal());

    final actionButtons = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _ContractIconAction(
          tooltip: l.contractViewPdfAction,
          icon: Icons.picture_as_pdf_outlined,
          onPressed: busy ? null : widget.onView,
        ),
        _ContractIconAction(
          tooltip: l.contractDownloadAction,
          icon: Icons.download_rounded,
          onPressed: busy ? null : widget.onDownload,
        ),
        _ContractIconAction(
          tooltip: l.edit,
          icon: Icons.edit_outlined,
          onPressed: busy ? null : widget.onEdit,
        ),
        _ContractIconAction(
          tooltip: widget.onMarkCurrent == null
              ? l.contractCurrentBadge
              : l.contractMarkCurrentAction,
          icon: widget.onMarkCurrent == null
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          onPressed: busy ? null : widget.onMarkCurrent,
        ),
        _ContractIconAction(
          tooltip: l.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onPressed: busy ? null : widget.onDelete,
        ),
        _ContractIconAction(
          tooltip: _expanded
              ? l.clientDetailsCollapseTooltip
              : l.clientDetailsExpandTooltip,
          icon:
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contract.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodyLarge.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          contract.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final chips = <Widget>[
      _ContractMetaChip(
        label: clientContractStatusLabel(l, contract.status),
        icon: Icons.circle,
      ),
      if ((contract.contractType ?? '').trim().isNotEmpty)
        _ContractMetaChip(
          label: clientContractTypeLabel(l, contract.contractType),
          icon: Icons.description_outlined,
        ),
      if ((contract.version ?? '').trim().isNotEmpty)
        _ContractMetaChip(
          label: '${l.contractVersionLabel}: ${contract.version!.trim()}',
          icon: Icons.layers_outlined,
        ),
      _ContractMetaChip(
        label:
            '${l.startDate}: ${formatClientContractDate(l, contract.startDate)}',
        icon: Icons.play_circle_outline_rounded,
      ),
      _ContractMetaChip(
        label: '${l.endDate}: ${formatClientContractDate(l, contract.endDate)}',
        icon: Icons.stop_circle_outlined,
      ),
      _ContractMetaChip(
        label:
            '${l.contractRenewalDateLabel}: ${formatClientContractDate(l, contract.renewalDate)}',
        icon: Icons.autorenew_rounded,
      ),
      _ContractMetaChip(
        label: '${l.contractUploadedAtLabel}: $uploadedLabel',
        icon: Icons.upload_file_outlined,
      ),
      _ContractMetaChip(
        label: formatClientContractSize(contract.size),
        icon: Icons.sd_storage_outlined,
      ),
      if (contract.isCurrent)
        _StatusPill(
          label: l.contractCurrentBadge,
          background: cs.primaryContainer,
          foreground: cs.onPrimaryContainer,
          icon: Icons.verified_rounded,
        ),
      if (expired)
        _StatusPill(
          label: l.contractExpiredBadge,
          background: cs.errorContainer,
          foreground: cs.onErrorContainer,
          icon: Icons.warning_amber_rounded,
        ),
      if (expiringSoon)
        _StatusPill(
          label: l.contractExpiringSoonBadge,
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
          icon: Icons.schedule_rounded,
        ),
    ];

    final leadingAvatar = Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: expired
            ? cs.errorContainer.withValues(alpha: 0.45)
            : contract.isCurrent
                ? cs.primaryContainer.withValues(alpha: 0.55)
                : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Icon(
        Icons.picture_as_pdf_outlined,
        size: 20,
        color: expired
            ? cs.error
            : contract.isCurrent
                ? cs.primary
                : cs.onSurfaceVariant,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        color: backgroundColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = compact || constraints.maxWidth < 720;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stacked) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leadingAvatar,
                    const SizedBox(width: 12),
                    Expanded(child: titleBlock),
                    if (busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                actionButtons,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leadingAvatar,
                    const SizedBox(width: 12),
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      actionButtons,
                  ],
                ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: chips,
                          ),
                          if (contract.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: contract.tags
                                  .map((tag) => _TagChip(label: tag))
                                  .toList(growable: false),
                            ),
                          ],
                          if ((contract.notes ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              contract.notes!.trim(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium
                                  .copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContractIconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool destructive;
  final VoidCallback? onPressed;

  const _ContractIconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: destructive
              ? cs.errorContainer.withValues(alpha: 0.35)
              : cs.surfaceContainerHighest.withValues(alpha: 0.55),
          foregroundColor: destructive ? cs.error : cs.primary,
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _ContractMetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ContractMetaChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
