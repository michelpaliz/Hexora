import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

class PresupuestoTemplateVariablesView extends StatefulWidget {
  const PresupuestoTemplateVariablesView({
    super.key,
    required this.groupId,
    required this.clients,
  });

  final String groupId;
  final List<GroupClient> clients;

  @override
  State<PresupuestoTemplateVariablesView> createState() =>
      _PresupuestoTemplateVariablesViewState();
}

class _PresupuestoTemplateVariablesViewState
    extends State<PresupuestoTemplateVariablesView> {
  final _api = PresupuestosApi();
  final _reason = TextEditingController();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _budgets = const [];
  List<_TemplateVariableState> _variables = const [];
  List<String> _unresolvedKeys = const [];
  String? _selectedId;
  _VariableFilter _filter = _VariableFilter.pending;
  bool _loadingBudgets = true;
  bool _loadingVariables = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _loadBudgets();
  }

  @override
  void dispose() {
    _reason.dispose();
    _search.dispose();
    for (final variable in _variables) {
      variable.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _loadingBudgets = true;
      _error = null;
    });
    try {
      final list = await _api.listDocumentsByGroup(widget.groupId);
      final selected = list.isEmpty ? null : _budgetId(list.first);
      setState(() {
        _budgets = list;
        _selectedId = selected;
      });
      if (selected != null && selected.isNotEmpty) {
        await _loadVariables(selected);
      }
    } on PresupuestosApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingBudgets = false);
    }
  }

  Future<void> _loadVariables(String presupuestoId) async {
    for (final variable in _variables) {
      variable.dispose();
    }
    setState(() {
      _loadingVariables = true;
      _error = null;
      _variables = const [];
      _unresolvedKeys = const [];
      _reason.clear();
    });
    try {
      final payload = await _api.getTemplateVariables(presupuestoId);
      final rawVariables = payload['variables'];
      final rawUnresolved = payload['unresolvedKeys'];
      final variables = rawVariables is List
          ? rawVariables
              .whereType<Map>()
              .map((item) => _TemplateVariableState.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const <_TemplateVariableState>[];
      setState(() {
        _variables = variables;
        _unresolvedKeys = rawUnresolved is List
            ? rawUnresolved.map((item) => item.toString()).toList()
            : const [];
      });
    } on PresupuestosApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loadingVariables = false);
    }
  }

  Map<String, dynamic>? get _selectedBudget {
    final id = (_selectedId ?? '').trim();
    if (id.isEmpty) return null;
    for (final budget in _budgets) {
      if (_budgetId(budget) == id) return budget;
    }
    return null;
  }

  bool get _selectedBudgetIsIssued {
    final status = (_selectedBudget?['status'] ?? '').toString().toLowerCase();
    return status.contains('issue') ||
        status.contains('emit') ||
        status.contains('accept') ||
        status.contains('aprob');
  }

  bool get _hasChanges => _changedVariables().isNotEmpty;

  List<_TemplateVariableState> get _visibleVariables {
    final query = _search.text.trim().toLowerCase();
    final unresolved = _unresolvedKeys.map((key) => key.toUpperCase()).toSet();
    final list = _variables.where((variable) {
      final isPending = unresolved.contains(variable.key.toUpperCase());
      final isCustom = variable.originalValue?.trim().isNotEmpty == true;
      final matchesFilter = switch (_filter) {
        _VariableFilter.all => true,
        _VariableFilter.pending => isPending,
        _VariableFilter.custom => isCustom,
        _VariableFilter.automatic => variable.isAutomatic,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return variable.key.toLowerCase().contains(query) ||
          variable.label.toLowerCase().contains(query) ||
          variable.resolvedValue.toLowerCase().contains(query) ||
          variable.automaticValue.toLowerCase().contains(query);
    }).toList();
    list.sort((a, b) {
      final aPending = unresolved.contains(a.key.toUpperCase());
      final bPending = unresolved.contains(b.key.toUpperCase());
      if (aPending != bPending) return aPending ? -1 : 1;
      return a.label.compareTo(b.label);
    });
    return list;
  }

  Map<String, dynamic> _changedVariables() {
    final changes = <String, dynamic>{};
    for (final variable in _variables) {
      if (variable.clearCustom) {
        changes[variable.key] = null;
        continue;
      }
      final value = variable.controller.text.trim();
      final original = variable.originalValue?.trim() ?? '';
      if (value != original) {
        changes[variable.key] = value.isEmpty ? null : value;
      }
    }
    return changes;
  }

  Future<void> _save() async {
    final id = (_selectedId ?? '').trim();
    if (id.isEmpty || _saving) return;
    final changes = _changedVariables();
    if (changes.isEmpty) {
      showSuccessSnack(context, 'No hay cambios pendientes.');
      return;
    }
    if (_selectedBudgetIsIssued && _reason.text.trim().isEmpty) {
      showErrorSnack(
        context,
        'Indica el motivo para actualizar un presupuesto emitido.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.updateTemplateVariables(
        id,
        variables: changes,
        reason: _reason.text,
      );
      if (mounted) showSuccessSnack(context, 'Variables actualizadas.');
      await _loadVariables(id);
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _screenTheme(Theme.of(context));
    if (_loadingBudgets) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _budgets.isEmpty) {
      return _ErrorState(message: _error!, onRetry: _loadBudgets);
    }
    return Theme(
      data: theme,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 18),
          if (_budgets.isEmpty)
            const _EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'Sin presupuestos',
              message: 'Crea o emite un presupuesto para editar sus variables.',
            )
          else if (_loadingVariables)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildSummary(theme),
            const SizedBox(height: 12),
            _buildFilterBar(theme),
            const SizedBox(height: 14),
            if (_selectedBudgetIsIssued) ...[
              _buildReasonField(theme),
              const SizedBox(height: 16),
            ],
            if (_variables.isEmpty)
              const _EmptyState(
                icon: Icons.data_object_rounded,
                title: 'Sin variables detectadas',
                message:
                    'La plantilla de este presupuesto no contiene placeholders.',
              )
            else if (_visibleVariables.isEmpty)
              _EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Sin resultados',
                message: _filter == _VariableFilter.pending
                    ? 'No quedan variables pendientes para este presupuesto.'
                    : 'Cambia el filtro o la busqueda para ver mas variables.',
              )
            else
              _buildVariableGrid(theme),
            if (_variables.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFooter(theme),
            ],
            const SizedBox(height: 74),
          ],
        ],
      ),
    );
  }

  ThemeData _screenTheme(ThemeData base) {
    final appTypography = base.extension<AppTypography>();
    if (appTypography == null) return base;
    final current = base.textTheme;

    TextStyle inherit(TextStyle appStyle, TextStyle? currentStyle) {
      return appStyle.copyWith(
        fontSize: currentStyle?.fontSize ?? appStyle.fontSize,
        fontWeight: currentStyle?.fontWeight ?? appStyle.fontWeight,
        color: currentStyle?.color ?? appStyle.color,
        height: currentStyle?.height,
        letterSpacing: 0,
      );
    }

    return base.copyWith(
      textTheme: current.copyWith(
        displayLarge: inherit(appTypography.displayLarge, current.displayLarge),
        displayMedium:
            inherit(appTypography.displayMedium, current.displayMedium),
        titleLarge: inherit(appTypography.titleLarge, current.titleLarge),
        titleMedium: inherit(appTypography.titleLarge, current.titleMedium),
        titleSmall: inherit(appTypography.titleLarge, current.titleSmall),
        bodyLarge: inherit(appTypography.bodyLarge, current.bodyLarge),
        bodyMedium: inherit(appTypography.bodyMedium, current.bodyMedium),
        bodySmall: inherit(appTypography.bodySmall, current.bodySmall),
        labelLarge: inherit(appTypography.bodyMedium, current.labelLarge),
        labelMedium: inherit(appTypography.bodySmall, current.labelMedium),
        labelSmall: inherit(appTypography.bodySmall, current.labelSmall),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final cs = theme.colorScheme;
    final selected = _selectedBudget;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withValues(alpha: 0.95),
                    cs.tertiaryContainer.withValues(alpha: 0.72),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.data_object_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Variables del documento',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Revisa placeholders, completa los pendientes y sustituye valores automaticos solo cuando haga falta.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                titleBlock,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSaveButton(compact: true),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    _buildSaveButton(compact: true),
                  ],
                ),
              const SizedBox(height: 16),
              DropdownMenu<String>(
                key: ValueKey(_selectedId),
                initialSelection: _selectedId,
                expandedInsets: EdgeInsets.zero,
                enableFilter: true,
                enableSearch: true,
                requestFocusOnTap: true,
                menuHeight: 360,
                label: Text(
                  'Presupuesto',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leadingIcon: Icon(
                  Icons.description_outlined,
                  color: cs.primary,
                ),
                trailingIcon: const Icon(Icons.expand_more_rounded),
                selectedTrailingIcon: const Icon(Icons.expand_less_rounded),
                textStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.34),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.52),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 1.6),
                  ),
                ),
                menuStyle: MenuStyle(
                  elevation: const WidgetStatePropertyAll(8),
                  backgroundColor:
                      WidgetStatePropertyAll(cs.surfaceContainerLowest),
                  surfaceTintColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 6),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                dropdownMenuEntries: [
                  for (final budget in _budgets)
                    DropdownMenuEntry(
                      value: _budgetId(budget),
                      label: _budgetLabel(budget),
                      leadingIcon: Icon(
                        _budgetId(budget) == _selectedId
                            ? Icons.check_circle_rounded
                            : Icons.description_outlined,
                        color: _budgetId(budget) == _selectedId
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        size: 20,
                      ),
                      style: ButtonStyle(
                        textStyle: WidgetStatePropertyAll(
                          theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        foregroundColor: WidgetStatePropertyAll(cs.onSurface),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
                onSelected: (value) async {
                  final id = value?.trim();
                  if (id == null || id.isEmpty) return;
                  setState(() => _selectedId = id);
                  await _loadVariables(id);
                },
              ),
              if (selected != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SoftLabel(
                      icon: Icons.person_outline_rounded,
                      label: _clientName(selected),
                    ),
                    _SoftLabel(
                      icon: Icons.tag_rounded,
                      label: _budgetNumber(selected),
                    ),
                    if (_selectedBudgetIsIssued)
                      _SoftLabel(
                        icon: Icons.history_rounded,
                        label: 'Requiere motivo',
                        color: cs.error,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final automaticCount = _variables.where((item) => item.isAutomatic).length;
    final customCount = _variables
        .where((item) => item.originalValue?.trim().isNotEmpty == true)
        .length;
    final unresolvedCount = _unresolvedKeys.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryChip(
            icon: Icons.data_object_rounded,
            label: 'Variables',
            value: _variables.length.toString(),
          ),
          _SummaryChip(
            icon: Icons.auto_awesome_rounded,
            label: 'Automaticas',
            value: automaticCount.toString(),
          ),
          _SummaryChip(
            icon: Icons.edit_note_rounded,
            label: 'Personalizadas',
            value: customCount.toString(),
          ),
          _SummaryChip(
            icon: unresolvedCount == 0
                ? Icons.check_circle_outline
                : Icons.error_outline_rounded,
            label: 'Pendientes',
            value: unresolvedCount.toString(),
            color: unresolvedCount == 0
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    final cs = theme.colorScheme;
    final unresolved = _unresolvedKeys.length;
    final customCount = _variables
        .where((item) => item.originalValue?.trim().isNotEmpty == true)
        .length;
    final automaticCount = _variables.where((item) => item.isAutomatic).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final search = SearchBar(
          controller: _search,
          hintText: 'Buscar por nombre, clave o valor...',
          leading: Icon(Icons.search_rounded, color: cs.primary, size: 21),
          trailing: [
            if (_search.text.trim().isNotEmpty)
              IconButton(
                tooltip: 'Limpiar busqueda',
                onPressed: _search.clear,
                icon: const Icon(Icons.close_rounded, size: 19),
                style: IconButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  backgroundColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  minimumSize: const Size(32, 32),
                  maximumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
          constraints: const BoxConstraints(minHeight: 50, maxHeight: 50),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14),
          ),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(
            cs.surfaceContainerHighest.withValues(alpha: 0.34),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStateProperty.resolveWith((states) {
            final focused = states.contains(WidgetState.focused);
            return BorderSide(
              color: focused
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.45),
              width: focused ? 1.6 : 1,
            );
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: WidgetStatePropertyAll(
            theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          hintStyle: WidgetStatePropertyAll(
            theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.78),
            ),
          ),
        );
        final filters = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterButton(
                selected: _filter == _VariableFilter.pending,
                label: 'Pendientes',
                count: unresolved,
                icon: Icons.error_outline_rounded,
                color: unresolved == 0 ? cs.primary : cs.error,
                onTap: () => setState(() {
                  _filter = _VariableFilter.pending;
                }),
              ),
              _FilterButton(
                selected: _filter == _VariableFilter.all,
                label: 'Todas',
                count: _variables.length,
                icon: Icons.list_alt_rounded,
                onTap: () => setState(() {
                  _filter = _VariableFilter.all;
                }),
              ),
              _FilterButton(
                selected: _filter == _VariableFilter.custom,
                label: 'Personalizadas',
                count: customCount,
                icon: Icons.edit_note_rounded,
                onTap: () => setState(() {
                  _filter = _VariableFilter.custom;
                }),
              ),
              _FilterButton(
                selected: _filter == _VariableFilter.automatic,
                label: 'Automaticas',
                count: automaticCount,
                icon: Icons.auto_awesome_rounded,
                onTap: () => setState(() {
                  _filter = _VariableFilter.automatic;
                }),
              ),
            ],
          ),
        );
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: compact
              ? Column(
                  children: [
                    search,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: filters),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 10),
                    Flexible(child: filters),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final cs = theme.colorScheme;
    final changes = _changedVariables().length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final status = Row(
          children: [
            Icon(
              changes == 0
                  ? Icons.check_circle_outline
                  : Icons.edit_note_rounded,
              color: changes == 0 ? cs.primary : cs.tertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                changes == 0
                    ? 'No hay cambios pendientes.'
                    : '$changes cambio${changes == 1 ? '' : 's'} sin guardar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    status,
                    const SizedBox(height: 10),
                    _buildSaveButton(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 12),
                    _buildSaveButton(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildReasonField(ThemeData theme) {
    final cs = theme.colorScheme;
    return TextField(
      controller: _reason,
      decoration: InputDecoration(
        labelText: 'Motivo del cambio',
        hintText: 'Ej. Actualizacion de condiciones',
        helperText: 'Se guardara en el historial del presupuesto emitido.',
        prefixIcon: Icon(Icons.history_rounded, color: cs.error),
        filled: true,
        fillColor: cs.errorContainer.withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.4),
        ),
      ),
      minLines: 1,
      maxLines: 2,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildSaveButton({bool compact = false}) {
    final cs = Theme.of(context).colorScheme;
    final enabled = _hasChanges && !_saving;
    return FilledButton.icon(
      onPressed: enabled ? _save : null,
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: Text(_saving ? 'Guardando...' : 'Guardar'),
      style: FilledButton.styleFrom(
        minimumSize: compact ? const Size(118, 42) : null,
        backgroundColor: enabled ? cs.primary : cs.surfaceContainerHighest,
        disabledBackgroundColor: cs.surfaceContainerHighest,
        disabledForegroundColor: cs.onSurfaceVariant.withValues(alpha: 0.62),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVariableGrid(ThemeData theme) {
    final unresolved = _unresolvedKeys.map((key) => key.toUpperCase()).toSet();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1320
            ? 3
            : width >= 820
                ? 2
                : 1;
        const spacing = 12.0;
        final itemWidth = (width - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final variable in _visibleVariables)
              SizedBox(
                width: itemWidth,
                child: _buildVariableCard(
                  variable,
                  unresolved: unresolved.contains(variable.key.toUpperCase()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVariableCard(
    _TemplateVariableState variable, {
    required bool unresolved,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasCustomValue = variable.originalValue?.trim().isNotEmpty == true;
    final accent = unresolved
        ? cs.error
        : hasCustomValue
            ? cs.primary
            : cs.outline;
    final leadingIcon = unresolved
        ? Icons.priority_high_rounded
        : variable.isAutomatic
            ? Icons.auto_awesome_rounded
            : hasCustomValue
                ? Icons.edit_note_rounded
                : Icons.data_object_rounded;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unresolved
            ? cs.errorContainer.withValues(alpha: 0.08)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: unresolved ? 0.34 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Icon(leadingIcon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variable.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '[${variable.key}]',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (hasCustomValue)
                      _Pill(
                        label: 'Personalizada',
                        color: cs.primary,
                        icon: Icons.edit_rounded,
                      ),
                    if (variable.isAutomatic)
                      _Pill(
                        label: 'Automatica',
                        color: cs.tertiary,
                        icon: Icons.auto_awesome_rounded,
                      ),
                    if (unresolved)
                      _Pill(
                        label: 'Pendiente',
                        color: cs.error,
                        icon: Icons.error_outline_rounded,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (variable.resolvedValue.trim().isNotEmpty ||
              variable.automaticValue.trim().isNotEmpty) ...[
            _ResolvedValueBox(
              label: variable.isAutomatic
                  ? 'Valor automatico'
                  : 'Valor actual en el documento',
              value: variable.resolvedValue.trim().isNotEmpty
                  ? variable.resolvedValue
                  : variable.automaticValue,
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: variable.controller,
            enabled: !variable.clearCustom,
            decoration: InputDecoration(
              labelText: variable.isAutomatic
                  ? 'Sobrescribir valor automatico'
                  : 'Valor personalizado',
              hintText: unresolved ? 'Completa este valor' : 'Sin sobrescribir',
              prefixIcon: Icon(
                unresolved ? Icons.priority_high_rounded : Icons.edit_rounded,
                color: unresolved ? cs.error : cs.onSurfaceVariant,
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.42),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.35),
              ),
            ),
            onChanged: (_) => setState(() {
              variable.clearCustom = false;
            }),
          ),
          if (variable.occurrences.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Usos: ${variable.occurrences.take(3).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (variable.originalValue != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message: variable.clearCustom
                    ? 'Mantener valor personalizado'
                    : 'Usar valor de la plantilla',
                child: IconButton(
                  onPressed: () => setState(() {
                    variable.clearCustom = !variable.clearCustom;
                    if (!variable.clearCustom) {
                      variable.controller.text = variable.originalValue ?? '';
                    }
                  }),
                  icon: Icon(
                    variable.clearCustom
                        ? Icons.undo_rounded
                        : Icons.restore_rounded,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.surfaceContainerHighest
                        .withValues(alpha: variable.clearCustom ? 0.6 : 0.35),
                    foregroundColor:
                        variable.clearCustom ? cs.primary : cs.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _budgetLabel(Map<String, dynamic> item) {
    final number = _budgetNumber(item);
    final client = _clientName(item);
    final date = _budgetDate(item);
    final dateLabel =
        date == null ? '' : ' - ${DateFormat.yMMMd('es').format(date)}';
    return '$number - $client$dateLabel';
  }

  String _clientName(Map<String, dynamic> item) {
    final direct =
        (item['clientName'] ?? item['customerName'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final clientId = (item['clientId'] ?? '').toString().trim();
    for (final client in widget.clients) {
      if (client.id == clientId) return client.name;
    }
    return 'Sin cliente';
  }

  DateTime? _budgetDate(Map<String, dynamic> item) {
    final raw = item['issueDate'] ??
        item['date'] ??
        item['issuedAt'] ??
        item['createdAt'];
    return DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
  }

  String _budgetId(Map<String, dynamic> item) =>
      (item['_id'] ?? item['id'] ?? '').toString().trim();

  String _budgetNumber(Map<String, dynamic> item) {
    final value = (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
    return value.isEmpty ? _budgetId(item) : value;
  }
}

enum _VariableFilter { pending, all, custom, automatic }

class _SoftLabel extends StatelessWidget {
  const _SoftLabel({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.selected,
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final bool selected;
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = color ?? cs.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? fg.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? fg.withValues(alpha: 0.36)
                      : cs.outlineVariant.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : icon,
                    size: 16,
                    color: selected ? fg : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$label $count',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? fg : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolvedValueBox extends StatelessWidget {
  const _ResolvedValueBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateVariableState {
  _TemplateVariableState({
    required this.key,
    required this.label,
    required this.originalValue,
    required this.resolvedValue,
    required this.automaticValue,
    required this.isSet,
    required this.isAutomatic,
    required this.occurrences,
  }) : controller = TextEditingController(text: originalValue ?? '');

  factory _TemplateVariableState.fromMap(Map<String, dynamic> map) {
    return _TemplateVariableState(
      key: (map['key'] ?? '').toString(),
      label: (map['label'] ?? map['key'] ?? '').toString(),
      originalValue: map['value']?.toString(),
      resolvedValue: (map['resolvedValue'] ?? '').toString(),
      automaticValue: (map['automaticValue'] ?? '').toString(),
      isSet: map['isSet'] == true,
      isAutomatic: map['isAutomatic'] == true,
      occurrences: map['occurrences'] is List
          ? (map['occurrences'] as List).map((item) => item.toString()).toList()
          : const [],
    );
  }

  final String key;
  final String label;
  final String? originalValue;
  final String resolvedValue;
  final String automaticValue;
  final bool isSet;
  final bool isAutomatic;
  final List<String> occurrences;
  final TextEditingController controller;
  bool clearCustom = false;

  void dispose() => controller.dispose();
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fg = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: fg),
          ),
          const SizedBox(width: 8),
          Text(
            '$label $value',
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
