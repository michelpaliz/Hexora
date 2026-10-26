import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum _SavedClientEmailState { valid, missing, invalid }

class _SavedClientEmail {
  const _SavedClientEmail(this.value, this.state);

  final String value;
  final _SavedClientEmailState state;
}

@immutable
class ClientUnsentDocumentCounts {
  const ClientUnsentDocumentCounts({
    this.invoices = 0,
    this.receipts = 0,
  });

  final int invoices;
  final int receipts;

  int get total => invoices + receipts;
}

class ClientSearchSelect extends StatefulWidget {
  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final bool useDefaultPropertyKind;
  final String defaultPropertyKind;
  final double maxListHeight;
  final bool showAdvancedFilters;
  final bool compact;
  final Map<String, ClientUnsentDocumentCounts> unsentDocumentCounts;
  final bool unsentDocumentCountsLoading;
  final String? unsentDocumentCountsError;

  const ClientSearchSelect({
    super.key,
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    this.useDefaultPropertyKind = true,
    this.defaultPropertyKind = 'comunidad de propietarios',
    this.maxListHeight = 520,
    this.showAdvancedFilters = true,
    this.compact = false,
    this.unsentDocumentCounts = const {},
    this.unsentDocumentCountsLoading = false,
    this.unsentDocumentCountsError,
  });

  @override
  State<ClientSearchSelect> createState() => _ClientSearchSelectState();
}

class _ClientSearchSelectState extends State<ClientSearchSelect> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showInactive = false;
  String? _entityFilter;
  String? _propertyFilter;
  bool _onlyWithUnsentDocuments = false;

  @override
  void initState() {
    super.initState();
    _syncDefaultPropertyFilter();
  }

  @override
  void didUpdateWidget(covariant ClientSearchSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clients != oldWidget.clients ||
        widget.useDefaultPropertyKind != oldWidget.useDefaultPropertyKind ||
        widget.defaultPropertyKind != oldWidget.defaultPropertyKind) {
      _syncDefaultPropertyFilter(useSetState: true);
    }
  }

  String? _resolveDefaultPropertyKind() {
    if (!widget.useDefaultPropertyKind) return null;
    final match =
        widget.clients.map((c) => (c.propertyKind ?? '').trim()).firstWhere(
              (v) => v.toLowerCase() == widget.defaultPropertyKind,
              orElse: () => '',
            );
    return match.isEmpty ? null : match;
  }

  void _applyDefaultPropertyFilter({bool useSetState = false}) {
    if ((_propertyFilter ?? '').trim().isNotEmpty) return;
    final match = _resolveDefaultPropertyKind();
    if (match == null || match.isEmpty) return;
    if (useSetState) {
      setState(() => _propertyFilter = match);
    } else {
      _propertyFilter = match;
    }
  }

  void _syncDefaultPropertyFilter({bool useSetState = false}) {
    if (!widget.useDefaultPropertyKind) {
      if ((_propertyFilter ?? '').trim().isEmpty) return;
      if (useSetState) {
        setState(() => _propertyFilter = null);
      } else {
        _propertyFilter = null;
      }
      return;
    }
    _applyDefaultPropertyFilter(useSetState: useSetState);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(GroupClient c) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = <String>[
      c.name,
      c.email ?? '',
      c.billing?.email ?? '',
      c.phone ?? '',
      c.billing?.legalName ?? '',
      c.entityType ?? '',
      c.propertyKind ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  _SavedClientEmail _savedEmail(GroupClient client) {
    final candidates = <String>[
      (client.billing?.email ?? '').trim(),
      (client.email ?? '').trim(),
    ];
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    for (final candidate in candidates) {
      if (candidate.isNotEmpty && emailPattern.hasMatch(candidate)) {
        return _SavedClientEmail(candidate, _SavedClientEmailState.valid);
      }
    }
    String? invalid;
    for (final candidate in candidates) {
      if (candidate.isNotEmpty) {
        invalid = candidate;
        break;
      }
    }
    return invalid == null
        ? const _SavedClientEmail('', _SavedClientEmailState.missing)
        : _SavedClientEmail(invalid, _SavedClientEmailState.invalid);
  }

  String _unsentSummary(
    ClientUnsentDocumentCounts counts, {
    required bool isSpanish,
  }) {
    String invoices() => isSpanish
        ? '${counts.invoices} ${counts.invoices == 1 ? 'factura' : 'facturas'}'
        : '${counts.invoices} ${counts.invoices == 1 ? 'invoice' : 'invoices'}';
    String receipts() => isSpanish
        ? '${counts.receipts} ${counts.receipts == 1 ? 'recibo' : 'recibos'}'
        : '${counts.receipts} ${counts.receipts == 1 ? 'receipt' : 'receipts'}';

    final documents = <String>[
      if (counts.invoices > 0) invoices(),
      if (counts.receipts > 0) receipts(),
    ].join(' · ');
    return isSpanish ? '$documents sin enviar' : '$documents unsent';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final entityOptions = widget.showAdvancedFilters
        ? (widget.clients
            .map((c) => (c.entityType ?? '').trim())
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort())
        : const <String>[];
    final propertyOptions = widget.showAdvancedFilters
        ? (widget.clients
            .map((c) => (c.propertyKind ?? '').trim())
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort())
        : const <String>[];
    final filtered = widget.clients.where((c) {
      if (!_showInactive && c.isActive == false) return false;
      if ((_entityFilter ?? '').trim().isNotEmpty &&
          (c.entityType ?? '').trim() != (_entityFilter ?? '').trim()) {
        return false;
      }
      if ((_propertyFilter ?? '').trim().isNotEmpty &&
          (c.propertyKind ?? '').trim() != (_propertyFilter ?? '').trim()) {
        return false;
      }
      if (_onlyWithUnsentDocuments &&
          (widget.unsentDocumentCounts[c.id]?.total ?? 0) == 0) {
        return false;
      }
      return _matchesSearch(c);
    }).toList();

    final listContent = filtered.isEmpty
        ? Center(
            child: Text(
              l.noClientsYet,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          )
        : ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final client = filtered[i];
              final selected = client.id == widget.selectedClientId;
              final savedEmail = _savedEmail(client);
              final email = savedEmail.state == _SavedClientEmailState.valid
                  ? savedEmail.value
                  : '';
              final unsent = widget.unsentDocumentCounts[client.id];
              final hasUnsent = (unsent?.total ?? 0) > 0;
              final meta = <String>[
                if (email.isNotEmpty) email,
                if ((client.phone ?? '').isNotEmpty) client.phone!,
                if ((client.propertyKind ?? '').isNotEmpty)
                  client.propertyKind!,
              ].join(' - ');
              return SizedBox(
                key: ValueKey('client-select-row-${client.id}'),
                height: widget.compact ? (hasUnsent ? 56 : 44) : 52,
                child: ListItemCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: widget.compact ? 3 : 5,
                  ),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    child: Text(
                      client.name.trim().isEmpty
                          ? '?'
                          : client.name.trim()[0].toUpperCase(),
                      style: t.bodySmall.copyWith(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  titleWidget: widget.compact
                      ? _CompactClientIdentity(
                          name: client.name,
                          email: email,
                          emailWarning: switch (savedEmail.state) {
                            _SavedClientEmailState.missing => isSpanish
                                ? 'Sin correo registrado'
                                : 'No email registered',
                            _SavedClientEmailState.invalid =>
                              isSpanish ? 'Correo no válido' : 'Invalid email',
                            _SavedClientEmailState.valid => null,
                          },
                        )
                      : Tooltip(
                          message: client.name,
                          child: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                  titleStyle: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: cs.onSurface,
                  ),
                  subtitleWidget: (widget.compact || meta.isEmpty) && !hasUnsent
                      ? null
                      : widget.compact
                          ? Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _unsentSummary(
                                      unsent!,
                                      isSpanish: isSpanish,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall.copyWith(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (meta.isNotEmpty)
                                  Tooltip(
                                    message: meta,
                                    child: Text(
                                      meta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodySmall.copyWith(
                                        fontSize: 10,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (hasUnsent)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.mark_email_unread_outlined,
                                          size: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _unsentSummary(
                                              unsent!,
                                              isSpanish: isSpanish,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.bodySmall.copyWith(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                  subtitleStyle: t.bodySmall.copyWith(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  selected: selected,
                  showLeadingStripe: true,
                  borderRadius: BorderRadius.circular(8),
                  trailing: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: cs.primary,
                          size: 18,
                        )
                      : null,
                  onTap: () => widget.onClientChanged(client.id),
                ),
              );
            },
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final listSlot = constraints.maxHeight.isFinite
            ? Expanded(child: listContent)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxListHeight),
                child: listContent,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                chipTheme: ChipTheme.of(context).copyWith(
                  selectedColor: cs.primaryContainer.withValues(alpha: 0.45),
                  checkmarkColor: cs.primary,
                  labelStyle: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  secondaryLabelStyle: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: ClientsSearchFilters(
                searchController: _searchCtrl,
                onSearchChanged: () => setState(() {}),
                searchHint: l.clientSearchHint,
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                clientsForCounts:
                    widget.showAdvancedFilters ? widget.clients : null,
                activeCountLabel:
                    widget.showAdvancedFilters ? l.activeClientsSection : null,
                inactiveCountLabel:
                    widget.showAdvancedFilters ? l.statusInactive : null,
                inactiveValue:
                    widget.showAdvancedFilters ? _showInactive : null,
                onInactiveChanged: widget.showAdvancedFilters
                    ? (v) => setState(() => _showInactive = v)
                    : null,
                inactiveLabelOn:
                    widget.showAdvancedFilters ? l.hideInactiveClients : null,
                inactiveLabelOff:
                    widget.showAdvancedFilters ? l.showInactiveClients : null,
                entityLabel:
                    widget.showAdvancedFilters ? l.clientEntityTypeLabel : null,
                entityOptions: entityOptions,
                entityFilter: widget.showAdvancedFilters ? _entityFilter : null,
                onToggleEntity: widget.showAdvancedFilters
                    ? (v) => setState(() => _entityFilter = v)
                    : null,
                onClearEntity: widget.showAdvancedFilters
                    ? () => setState(() => _entityFilter = null)
                    : null,
                propertyLabel: widget.showAdvancedFilters
                    ? l.clientPropertyKindLabel
                    : null,
                propertyOptions: propertyOptions,
                propertyFilter:
                    widget.showAdvancedFilters ? _propertyFilter : null,
                onToggleProperty: widget.showAdvancedFilters
                    ? (v) => setState(() => _propertyFilter = v)
                    : null,
                onClearProperty: widget.showAdvancedFilters
                    ? () => setState(() => _propertyFilter = null)
                    : null,
                onClearFilters: widget.showAdvancedFilters
                    ? () {
                        final defaultKind = _resolveDefaultPropertyKind();
                        setState(() {
                          _showInactive = false;
                          _entityFilter = null;
                          _propertyFilter = defaultKind;
                          _onlyWithUnsentDocuments = false;
                        });
                      }
                    : null,
                additionalFilters: widget.showAdvancedFilters
                    ? CheckboxListTile(
                        key: const ValueKey(
                            'client-filter-with-unsent-documents'),
                        value: _onlyWithUnsentDocuments,
                        onChanged: widget.unsentDocumentCountsLoading
                            ? null
                            : (value) => setState(() =>
                                _onlyWithUnsentDocuments = value ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        visualDensity: VisualDensity.compact,
                        secondary: widget.unsentDocumentCountsLoading
                            ? const SizedBox.square(
                                dimension: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : (widget.unsentDocumentCountsError ?? '')
                                    .trim()
                                    .isNotEmpty
                                ? Tooltip(
                                    message: widget.unsentDocumentCountsError!,
                                    child: Icon(Icons.info_outline_rounded,
                                        size: 16, color: cs.onSurfaceVariant),
                                  )
                                : null,
                        title: Text(
                          isSpanish
                              ? 'Con documentos sin enviar'
                              : 'With unsent documents',
                          style: t.bodySmall.copyWith(fontSize: 12),
                        ),
                      )
                    : null,
                extraActiveFilterCount: _onlyWithUnsentDocuments ? 1 : 0,
                moveSummaryIntoFilters: widget.compact,
              ),
            ),
            SizedBox(height: widget.compact ? 2 : 6),
            listSlot,
          ],
        );
      },
    );
  }
}

class _CompactClientIdentity extends StatelessWidget {
  const _CompactClientIdentity({
    required this.name,
    required this.email,
    required this.emailWarning,
  });

  final String name;
  final String email;
  final String? emailWarning;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final nameWidget = Tooltip(
      message: name,
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodySmall.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: cs.onSurface,
        ),
      ),
    );
    final warning = (emailWarning ?? '').trim();
    final secondaryWidget = warning.isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: ThemeColors.warning(context),
              ),
              const SizedBox(width: 3),
              Text(
                warning,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: ThemeColors.warning(context),
                ),
              ),
            ],
          )
        : Tooltip(
            message: email,
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          );
    if (email.isEmpty && warning.isEmpty) return nameWidget;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameWidget,
              const SizedBox(height: 1),
              secondaryWidget,
            ],
          );
        }
        return Row(
          children: [
            Flexible(child: nameWidget),
            const SizedBox(width: 10),
            if (warning.isNotEmpty)
              secondaryWidget
            else
              Flexible(child: secondaryWidget),
          ],
        );
      },
    );
  }
}
