import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_advance_final_flow.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// ── Public enum for callers ───────────────────────────────────────────────────

enum PresupuestoConversionType { advance, final_ }

// ── Entry point ───────────────────────────────────────────────────────────────

class PresupuestoConversionDialog extends StatefulWidget {
  final String groupId;
  final List<GroupClient> clients;
  final PresupuestosApi api;

  /// Pre-selected presupuesto. If null the dialog starts with a browse step.
  final Map<String, dynamic>? initialPresupuesto;

  /// Pre-selected conversion type. If null the user picks in step 2.
  final PresupuestoConversionType? initialType;

  /// Called with the created invoice ID on success.
  final ValueChanged<String>? onInvoiceCreated;

  const PresupuestoConversionDialog({
    super.key,
    required this.groupId,
    required this.clients,
    required this.api,
    this.initialPresupuesto,
    this.initialType,
    this.onInvoiceCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required List<GroupClient> clients,
    required PresupuestosApi api,
    Map<String, dynamic>? initialPresupuesto,
    PresupuestoConversionType? initialType,
    ValueChanged<String>? onInvoiceCreated,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PresupuestoConversionDialog(
        groupId: groupId,
        clients: clients,
        api: api,
        initialPresupuesto: initialPresupuesto,
        initialType: initialType,
        onInvoiceCreated: onInvoiceCreated,
      ),
    );
  }

  @override
  State<PresupuestoConversionDialog> createState() =>
      _PresupuestoConversionDialogState();
}

// ── Internal step enum ────────────────────────────────────────────────────────

enum _Step { browse, actionPick, advance, final_, success }

// ── State ─────────────────────────────────────────────────────────────────────

class _PresupuestoConversionDialogState
    extends State<PresupuestoConversionDialog> {
  late _Step _step;
  Map<String, dynamic>? _presupuesto;

  // Browse step
  bool _browseLoading = false;
  String? _browseError;
  List<Map<String, dynamic>> _browseItems = const [];
  final TextEditingController _searchCtrl = TextEditingController();

  // Advance form
  final _advanceFormKey = GlobalKey<FormState>();
  late TextEditingController _percentCtrl;
  late TextEditingController _baseAmountCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _advDescCtrl;
  late TextEditingController _advNotesCtrl;

  // Final form
  List<AdvanceInvoiceCandidate> _advanceCandidates = const [];
  bool _candidatesLoading = false;
  AdvanceInvoiceCandidate? _selectedCandidate;
  final TextEditingController _finalNotesCtrl = TextEditingController();

  // Submission
  bool _submitting = false;
  String? _submitError;

  // Success
  String? _createdInvoiceId;
  String? _createdInvoiceType;

  @override
  void initState() {
    super.initState();

    _percentCtrl = TextEditingController(text: '70');
    _baseAmountCtrl = TextEditingController();
    _taxRateCtrl = TextEditingController(text: '21');
    _advDescCtrl = TextEditingController();
    _advNotesCtrl = TextEditingController();

    if (widget.initialPresupuesto != null) {
      _presupuesto = widget.initialPresupuesto;
      _prefillAdvanceForm(_presupuesto!);
      if (widget.initialType != null) {
        _step = widget.initialType == PresupuestoConversionType.advance
            ? _Step.advance
            : _Step.final_;
        if (_step == _Step.final_) _loadCandidates();
      } else {
        _step = _Step.actionPick;
      }
    } else {
      _step = _Step.browse;
      _loadBrowseItems();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _percentCtrl.dispose();
    _baseAmountCtrl.dispose();
    _taxRateCtrl.dispose();
    _advDescCtrl.dispose();
    _advNotesCtrl.dispose();
    _finalNotesCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _id(Map<String, dynamic> p) =>
      (p['_id'] ?? p['id'] ?? '').toString().trim();

  String _number(Map<String, dynamic> p) {
    final n =
        (p['presupuestoNumber'] ?? p['budgetNumber'] ?? '').toString().trim();
    return n.isEmpty ? '-' : n;
  }

  String _clientName(Map<String, dynamic> p) {
    final direct = (p['clientName'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final nested = p['client'];
    if (nested is Map) {
      final n = (nested['name'] ?? '').toString().trim();
      if (n.isNotEmpty) return n;
    }
    final clientId = (p['clientId'] ?? '').toString().trim();
    if (clientId.isNotEmpty) {
      final match = widget.clients.cast<GroupClient?>().firstWhere(
            (c) => c?.id == clientId,
            orElse: () => null,
          );
      if (match != null && match.name.trim().isNotEmpty) return match.name;
    }
    return '—';
  }

  double _total(Map<String, dynamic> p) {
    for (final key in ['total', 'totalAmount', 'amount']) {
      final v = p[key];
      if (v is num) return v.toDouble();
      final parsed =
          double.tryParse((v ?? '').toString().replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
    return 0;
  }

  double _baseAmount(Map<String, dynamic> p) {
    for (final key in ['subtotal', 'baseAmount', 'taxableBase']) {
      final v = p[key];
      if (v is num) return v.toDouble();
      final parsed =
          double.tryParse((v ?? '').toString().replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
    return 0;
  }

  double _defaultTax(Map<String, dynamic> p) {
    double? tryParse(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse((v ?? '').toString().replaceAll(',', '.'));
    }

    for (final bucket in [p['lines'], p['blocks']]) {
      if (bucket is List) {
        for (final row in bucket.whereType<Map>()) {
          final t = tryParse(
              row['taxRate'] ?? row['tax'] ?? row['vat'] ?? row['iva']);
          if (t != null && t >= 0) return t;
        }
      }
    }
    return 21;
  }

  DateTime? _date(Map<String, dynamic> p) {
    final raw = p['issueDate'] ??
        p['registeredAt'] ??
        p['createdAt'] ??
        p['occurrenceDate'];
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  bool _isIssued(Map<String, dynamic> p) {
    final s = (p['status'] ?? '').toString().trim().toLowerCase();
    return s == 'issued' || s.endsWith('.issued') || s.contains('accept');
  }

  void _prefillAdvanceForm(Map<String, dynamic> p) {
    final base = _baseAmount(p);
    if (base > 0) _baseAmountCtrl.text = base.toStringAsFixed(2);
    _taxRateCtrl.text = _defaultTax(p).toStringAsFixed(0);
    _advDescCtrl.text =
        'Anticipo ${_percentCtrl.text}% – Presupuesto ${_number(p)}';
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadBrowseItems() async {
    if (!mounted) return;
    setState(() {
      _browseLoading = true;
      _browseError = null;
    });
    try {
      final items =
          await widget.api.listByGroup(groupId: widget.groupId);
      if (!mounted) return;
      setState(() {
        _browseItems =
            items.where((e) => _isIssued(e)).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _browseError = e.toString());
    } finally {
      if (mounted) setState(() => _browseLoading = false);
    }
  }

  Future<void> _loadCandidates() async {
    if (_presupuesto == null || !mounted) return;
    setState(() => _candidatesLoading = true);
    try {
      final detail = await widget.api.getById(_id(_presupuesto!));
      if (!mounted) return;
      final candidates =
          extractAdvanceInvoiceCandidatesFromPresupuesto(detail);
      setState(() {
        _advanceCandidates = candidates;
        _selectedCandidate = candidates.isEmpty
            ? null
            : candidates.firstWhere(
                (c) => c.isIssued,
                orElse: () => candidates.first,
              );
      });
    } catch (_) {
      // silently fall through — candidates list will be empty
    } finally {
      if (mounted) setState(() => _candidatesLoading = false);
    }
  }

  // ── Submission ───────────────────────────────────────────────────────────────

  Future<void> _submitAdvance() async {
    if (!(_advanceFormKey.currentState?.validate() ?? false)) return;
    final p = _presupuesto!;
    final presupuestoId = _id(p);
    if (presupuestoId.isEmpty) return;

    final percent = double.tryParse(_percentCtrl.text.trim()) ?? 70;
    final base = double.tryParse(_baseAmountCtrl.text.trim());
    final tax = double.tryParse(_taxRateCtrl.text.trim());
    final desc = _advDescCtrl.text.trim();

    final input = AdvanceInvoiceConfigInput(
      percent: percent,
      description: desc.isEmpty ? null : desc,
    );

    final validation = validateAdvanceConfig(input);
    if (!validation.isValid) {
      setState(() => _submitError = validation.message);
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final request = buildAdvanceInvoiceRequest(input);
      final response = await widget.api.createAdvanceInvoiceFromPresupuesto(
        presupuestoId,
        payload: request,
      );
      if (!mounted) return;
      final invoiceId = response.invoiceId ??
          (response.invoice?['_id'] ?? response.invoice?['id'])?.toString();
      setState(() {
        _createdInvoiceId = invoiceId;
        _createdInvoiceType = 'advance';
        _step = _Step.success;
      });
      if (invoiceId != null) widget.onInvoiceCreated?.call(invoiceId);
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitFinal() async {
    final p = _presupuesto!;
    final presupuestoId = _id(p);
    if (presupuestoId.isEmpty) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final request = buildFinalInvoiceRequest(
        advanceInvoiceId: _selectedCandidate?.id,
      );
      final response = await widget.api.createFinalInvoiceFromPresupuesto(
        presupuestoId,
        payload: request,
      );
      if (!mounted) return;
      final invoiceId = response.invoiceId ??
          (response.invoice?['_id'] ?? response.invoice?['id'])?.toString();
      setState(() {
        _createdInvoiceId = invoiceId;
        _createdInvoiceType = 'final';
        _step = _Step.success;
      });
      if (invoiceId != null) widget.onInvoiceCreated?.call(invoiceId);
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _selectPresupuesto(Map<String, dynamic> item) {
    setState(() {
      _presupuesto = item;
      _submitError = null;
    });
    _prefillAdvanceForm(item);
    setState(() => _step = _Step.actionPick);
  }

  void _pickAdvance() {
    setState(() {
      _step = _Step.advance;
      _submitError = null;
    });
  }

  void _pickFinal() {
    setState(() {
      _step = _Step.final_;
      _submitError = null;
    });
    _loadCandidates();
  }

  void _back() {
    setState(() {
      _submitError = null;
      switch (_step) {
        case _Step.actionPick:
          _step = widget.initialPresupuesto != null
              ? _Step.actionPick
              : _Step.browse;
          break;
        case _Step.advance:
        case _Step.final_:
          _step = _Step.actionPick;
          break;
        default:
          break;
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _DialogHeader(
              step: _step,
              presupuesto: _presupuesto,
              number: _presupuesto != null ? _number(_presupuesto!) : null,
              clientName:
                  _presupuesto != null ? _clientName(_presupuesto!) : null,
              isSpanish: isSpanish,
              onClose: () => Navigator.of(context).pop(),
              cs: cs,
              t: t,
            ),

            // ── Step indicator ───────────────────────────────────────────────
            if (_step != _Step.success)
              _StepIndicator(
                step: _step,
                hasBrowse: widget.initialPresupuesto == null,
                cs: cs,
              ),

            // ── Body ─────────────────────────────────────────────────────────
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildBody(l, t, cs, isSpanish),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            if (_step != _Step.success)
              _DialogFooter(
                step: _step,
                hasInitialPresupuesto: widget.initialPresupuesto != null,
                submitting: _submitting,
                isSpanish: isSpanish,
                onBack: _canGoBack ? _back : null,
                onSubmitAdvance:
                    _step == _Step.advance ? _submitAdvance : null,
                onSubmitFinal: _step == _Step.final_ ? _submitFinal : null,
                cs: cs,
                t: t,
              ),
          ],
        ),
      ),
    );
  }

  bool get _canGoBack =>
      _step == _Step.advance ||
      _step == _Step.final_ ||
      (_step == _Step.actionPick && widget.initialPresupuesto == null);

  Widget _buildBody(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    switch (_step) {
      case _Step.browse:
        return _BrowseStep(
          key: const ValueKey('browse'),
          loading: _browseLoading,
          error: _browseError,
          items: _browseItems,
          searchCtrl: _searchCtrl,
          clientName: _clientName,
          number: _number,
          total: _total,
          date: _date,
          isSpanish: isSpanish,
          onSelect: _selectPresupuesto,
          onRetry: _loadBrowseItems,
          cs: cs,
          t: t,
          l: l,
        );

      case _Step.actionPick:
        return _ActionPickStep(
          key: const ValueKey('actionPick'),
          presupuesto: _presupuesto!,
          clientName: _clientName(_presupuesto!),
          number: _number(_presupuesto!),
          total: _total(_presupuesto!),
          date: _date(_presupuesto!),
          isSpanish: isSpanish,
          onAdvance: _pickAdvance,
          onFinal: _pickFinal,
          cs: cs,
          t: t,
          l: l,
        );

      case _Step.advance:
        return _AdvanceFormStep(
          key: const ValueKey('advance'),
          formKey: _advanceFormKey,
          percentCtrl: _percentCtrl,
          baseAmountCtrl: _baseAmountCtrl,
          taxRateCtrl: _taxRateCtrl,
          descCtrl: _advDescCtrl,
          notesCtrl: _advNotesCtrl,
          presupuestoNumber: _number(_presupuesto!),
          total: _total(_presupuesto!),
          error: _submitError,
          isSpanish: isSpanish,
          cs: cs,
          t: t,
          l: l,
        );

      case _Step.final_:
        return _FinalFormStep(
          key: const ValueKey('final'),
          loading: _candidatesLoading,
          candidates: _advanceCandidates,
          selectedCandidate: _selectedCandidate,
          notesCtrl: _finalNotesCtrl,
          presupuestoNumber: _number(_presupuesto!),
          clientName: _clientName(_presupuesto!),
          total: _total(_presupuesto!),
          error: _submitError,
          isSpanish: isSpanish,
          onCandidateChanged: (c) => setState(() => _selectedCandidate = c),
          cs: cs,
          t: t,
          l: l,
        );

      case _Step.success:
        return _SuccessStep(
          key: const ValueKey('success'),
          invoiceType: _createdInvoiceType,
          invoiceId: _createdInvoiceId,
          presupuestoNumber: _number(_presupuesto!),
          clientName: _clientName(_presupuesto!),
          isSpanish: isSpanish,
          onDone: () => Navigator.of(context).pop(),
          cs: cs,
          t: t,
        );
    }
  }
}

// ── Dialog Header ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final _Step step;
  final Map<String, dynamic>? presupuesto;
  final String? number;
  final String? clientName;
  final bool isSpanish;
  final VoidCallback onClose;
  final ColorScheme cs;
  final AppTypography t;

  const _DialogHeader({
    required this.step,
    required this.presupuesto,
    required this.number,
    required this.clientName,
    required this.isSpanish,
    required this.onClose,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    switch (step) {
      case _Step.browse:
        title = isSpanish ? 'Seleccionar Presupuesto' : 'Select Presupuesto';
        subtitle = isSpanish
            ? 'Elige el presupuesto a convertir'
            : 'Choose the presupuesto to convert';
        break;
      case _Step.actionPick:
        title = isSpanish ? 'Tipo de Factura' : 'Invoice Type';
        subtitle = isSpanish
            ? 'Elige qué tipo de factura crear'
            : 'Choose what type of invoice to create';
        break;
      case _Step.advance:
        title = isSpanish ? 'Factura Anticipo' : 'Advance Invoice';
        subtitle = isSpanish
            ? 'Configura el anticipo'
            : 'Configure the advance amount';
        break;
      case _Step.final_:
        title = isSpanish ? 'Factura Final' : 'Final Invoice';
        subtitle = isSpanish
            ? 'Cierre del presupuesto'
            : 'Close out the presupuesto';
        break;
      case _Step.success:
        title = isSpanish ? '¡Factura Creada!' : 'Invoice Created!';
        subtitle = isSpanish
            ? 'Se ha generado un borrador'
            : 'A draft has been generated';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              step == _Step.success
                  ? Icons.check_circle_outline_rounded
                  : Icons.request_quote_outlined,
              size: 20,
              color: step == _Step.success ? cs.tertiary : cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        t.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: t.bodySmall
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final _Step step;
  final bool hasBrowse;
  final ColorScheme cs;

  const _StepIndicator({
    required this.step,
    required this.hasBrowse,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      if (hasBrowse) _Step.browse,
      _Step.actionPick,
      _Step.advance, // shown as the "form" step
    ];
    final activeIndex = steps.indexOf(step == _Step.final_ ? _Step.advance : step);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 1.5,
                  color: i <= activeIndex
                      ? cs.primary.withValues(alpha: 0.6)
                      : cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            _Dot(active: i == activeIndex, done: i < activeIndex, cs: cs),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final bool done;
  final ColorScheme cs;
  const _Dot({required this.active, required this.done, required this.cs});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? cs.primary
            : active
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
        border: active
            ? Border.all(color: cs.primary.withValues(alpha: 0.4), width: 2.5)
            : null,
      ),
      child: done
          ? null
          : null,
    );
  }
}

// ── Dialog Footer ─────────────────────────────────────────────────────────────

class _DialogFooter extends StatelessWidget {
  final _Step step;
  final bool hasInitialPresupuesto;
  final bool submitting;
  final bool isSpanish;
  final VoidCallback? onBack;
  final Future<void> Function()? onSubmitAdvance;
  final Future<void> Function()? onSubmitFinal;
  final ColorScheme cs;
  final AppTypography t;

  const _DialogFooter({
    required this.step,
    required this.hasInitialPresupuesto,
    required this.submitting,
    required this.isSpanish,
    required this.onBack,
    required this.onSubmitAdvance,
    required this.onSubmitFinal,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final showBack = onBack != null;
    final isSubmitStep = step == _Step.advance || step == _Step.final_;
    final submitLabel = step == _Step.advance
        ? (isSpanish ? 'Crear Anticipo' : 'Create Advance Invoice')
        : step == _Step.final_
            ? (isSpanish ? 'Crear Factura Final' : 'Create Final Invoice')
            : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showBack) ...[
            OutlinedButton(
              onPressed: submitting ? null : onBack,
              style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              child: Text(isSpanish ? 'Atrás' : 'Back'),
            ),
            const SizedBox(width: 8),
          ],
          if (isSubmitStep)
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : (step == _Step.advance ? onSubmitAdvance : onSubmitFinal),
              icon: submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      step == _Step.advance
                          ? Icons.percent_outlined
                          : Icons.receipt_long_outlined,
                      size: 16,
                    ),
              label: Text(submitLabel),
            ),
        ],
      ),
    );
  }
}

// ── Step: Browse ──────────────────────────────────────────────────────────────

class _BrowseStep extends StatefulWidget {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
  final TextEditingController searchCtrl;
  final String Function(Map<String, dynamic>) clientName;
  final String Function(Map<String, dynamic>) number;
  final double Function(Map<String, dynamic>) total;
  final DateTime? Function(Map<String, dynamic>) date;
  final bool isSpanish;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onRetry;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations l;

  const _BrowseStep({
    super.key,
    required this.loading,
    required this.error,
    required this.items,
    required this.searchCtrl,
    required this.clientName,
    required this.number,
    required this.total,
    required this.date,
    required this.isSpanish,
    required this.onSelect,
    required this.onRetry,
    required this.cs,
    required this.t,
    required this.l,
  });

  @override
  State<_BrowseStep> createState() => _BrowseStepState();
}

class _BrowseStepState extends State<_BrowseStep> {
  @override
  void initState() {
    super.initState();
    widget.searchCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.items
        : widget.items.where((p) {
            return widget.clientName(p).toLowerCase().contains(query) ||
                widget.number(p).toLowerCase().contains(query);
          }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: widget.searchCtrl,
            decoration: InputDecoration(
              hintText: widget.isSpanish
                  ? 'Buscar por cliente o número…'
                  : 'Search by client or number…',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : widget.error != null
                    ? _ErrorRetry(
                        error: widget.error!,
                        onRetry: widget.onRetry,
                        isSpanish: widget.isSpanish,
                        cs: widget.cs,
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              widget.isSpanish
                                  ? 'No hay presupuestos emitidos'
                                  : 'No issued presupuestos found',
                              style: widget.t.bodySmall.copyWith(
                                  color: widget.cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final p = filtered[i];
                              final dt = widget.date(p);
                              final dateLabel = dt == null
                                  ? '—'
                                  : DateFormat.yMMMd(widget.isSpanish
                                          ? 'es'
                                          : 'en')
                                      .format(dt.toLocal());
                              final totalFmt = NumberFormat.currency(
                                locale: widget.isSpanish ? 'es' : 'en',
                                symbol: '€',
                              ).format(widget.total(p));

                              return InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => widget.onSelect(p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.cs.outlineVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                        color: widget.cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.clientName(p),
                                              style: widget.t.bodySmall
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w800),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${widget.number(p)} · $dateLabel',
                                              style: widget.t.bodySmall
                                                  .copyWith(
                                                color:
                                                    widget.cs.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        totalFmt,
                                        style: widget.t.bodySmall.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: widget.cs.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Step: Action Pick ─────────────────────────────────────────────────────────

class _ActionPickStep extends StatelessWidget {
  final Map<String, dynamic> presupuesto;
  final String clientName;
  final String number;
  final double total;
  final DateTime? date;
  final bool isSpanish;
  final VoidCallback onAdvance;
  final VoidCallback onFinal;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations l;

  const _ActionPickStep({
    super.key,
    required this.presupuesto,
    required this.clientName,
    required this.number,
    required this.total,
    required this.date,
    required this.isSpanish,
    required this.onAdvance,
    required this.onFinal,
    required this.cs,
    required this.t,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final actionState = resolvePresupuestoInvoiceActionState(presupuesto);
    final totalFmt = NumberFormat.currency(
      locale: isSpanish ? 'es' : 'en',
      symbol: '€',
    ).format(total);
    final dateLabel = date == null
        ? '—'
        : DateFormat.yMMMd(isSpanish ? 'es' : 'en').format(date!.toLocal());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Presupuesto summary card
          _PresupuestoSummaryCard(
            clientName: clientName,
            number: number,
            totalFmt: totalFmt,
            dateLabel: dateLabel,
            actionState: actionState,
            isSpanish: isSpanish,
            cs: cs,
            t: t,
          ),
          const SizedBox(height: 14),
          Text(
            isSpanish ? 'Elige tipo de factura:' : 'Choose invoice type:',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Advance button
          _ActionCard(
            icon: Icons.percent_outlined,
            title: isSpanish ? 'Factura Anticipo' : 'Advance Invoice',
            subtitle: isSpanish
                ? 'Crea un anticipo parcial (p.ej. 70%)'
                : 'Create a partial advance (e.g. 70%)',
            disabled: !actionState.canCreateAdvance,
            disabledReason: actionState.hasAdvance
                ? (isSpanish ? 'Ya existe un anticipo' : 'Advance already exists')
                : (isSpanish
                    ? 'El presupuesto debe estar emitido'
                    : 'Presupuesto must be issued'),
            onTap: actionState.canCreateAdvance ? onAdvance : null,
            cs: cs,
            t: t,
          ),
          const SizedBox(height: 8),
          // Final button
          _ActionCard(
            icon: Icons.receipt_long_outlined,
            title: isSpanish ? 'Factura Final' : 'Final Invoice',
            subtitle: isSpanish
                ? 'Cierra el presupuesto. Si hay anticipo, se descuenta automáticamente.'
                : 'Close out the presupuesto. If there is an advance, it is deducted automatically.',
            disabled: !actionState.canCreateFinal,
            disabledReason: actionState.hasFinal
                ? (isSpanish ? 'Ya existe factura final' : 'Final invoice already exists')
                : (isSpanish
                    ? 'El presupuesto debe estar emitido'
                    : 'Presupuesto must be issued'),
            onTap: actionState.canCreateFinal ? onFinal : null,
            cs: cs,
            t: t,
          ),
        ],
      ),
    );
  }
}

// ── Presupuesto Summary Card ──────────────────────────────────────────────────

class _PresupuestoSummaryCard extends StatelessWidget {
  final String clientName;
  final String number;
  final String totalFmt;
  final String dateLabel;
  final PresupuestoInvoiceActionState actionState;
  final bool isSpanish;
  final ColorScheme cs;
  final AppTypography t;

  const _PresupuestoSummaryCard({
    required this.clientName,
    required this.number,
    required this.totalFmt,
    required this.dateLabel,
    required this.actionState,
    required this.isSpanish,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: t.bodyMedium
                          .copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$number · $dateLabel',
                      style: t.bodySmall
                          .copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                totalFmt,
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          if (actionState.hasAdvance || actionState.hasFinal) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (actionState.hasAdvance)
                  _StatusBadge(
                    icon: Icons.percent_outlined,
                    label: isSpanish ? 'Anticipo creado' : 'Advance created',
                    color: cs.tertiary,
                    bg: cs.tertiaryContainer.withValues(alpha: 0.35),
                  ),
                if (actionState.hasFinal)
                  _StatusBadge(
                    icon: Icons.receipt_long_outlined,
                    label: isSpanish ? 'Factura final creada' : 'Final created',
                    color: cs.secondary,
                    bg: cs.secondaryContainer.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool disabled;
  final String disabledReason;
  final VoidCallback? onTap;
  final ColorScheme cs;
  final AppTypography t;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.disabled,
    required this.disabledReason,
    required this.onTap,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAlpha = disabled ? 0.4 : 1.0;
    return Tooltip(
      message: disabled ? disabledReason : '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: disabled
                ? cs.surfaceContainerHighest.withValues(alpha: 0.2)
                : cs.primaryContainer.withValues(alpha: 0.15),
            border: Border.all(
              color: disabled
                  ? cs.outlineVariant.withValues(alpha: 0.2)
                  : cs.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    (disabled ? cs.onSurfaceVariant : cs.primary).withValues(
                  alpha: effectiveAlpha,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: (disabled ? cs.onSurfaceVariant : cs.onSurface)
                            .withValues(alpha: effectiveAlpha),
                      ),
                    ),
                    Text(
                      disabled ? disabledReason : subtitle,
                      style: t.bodySmall.copyWith(
                        color: (disabled
                                ? cs.onSurfaceVariant
                                : cs.onSurfaceVariant)
                            .withValues(alpha: effectiveAlpha),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (!disabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: cs.primary.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step: Advance Form ────────────────────────────────────────────────────────

class _AdvanceFormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController percentCtrl;
  final TextEditingController baseAmountCtrl;
  final TextEditingController taxRateCtrl;
  final TextEditingController descCtrl;
  final TextEditingController notesCtrl;
  final String presupuestoNumber;
  final double total;
  final String? error;
  final bool isSpanish;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations l;

  const _AdvanceFormStep({
    super.key,
    required this.formKey,
    required this.percentCtrl,
    required this.baseAmountCtrl,
    required this.taxRateCtrl,
    required this.descCtrl,
    required this.notesCtrl,
    required this.presupuestoNumber,
    required this.total,
    required this.error,
    required this.isSpanish,
    required this.cs,
    required this.t,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final totalFmt =
        NumberFormat.currency(locale: isSpanish ? 'es' : 'en', symbol: '€')
            .format(total);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info strip
            _InfoStrip(
              icon: Icons.info_outline_rounded,
              text: isSpanish
                  ? 'Presupuesto $presupuestoNumber · Total $totalFmt'
                  : 'Presupuesto $presupuestoNumber · Total $totalFmt',
              cs: cs,
              t: t,
            ),
            const SizedBox(height: 12),
            // Percent + Tax row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormField(
                    controller: percentCtrl,
                    label: isSpanish ? 'Porcentaje (%)' : 'Percent (%)',
                    hint: '70',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) {
                      final n = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (n == null || n <= 0 || n > 100) {
                        return isSpanish
                            ? 'Entre 1 y 100'
                            : 'Between 1 and 100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FormField(
                    controller: taxRateCtrl,
                    label: isSpanish ? 'IVA (%)' : 'VAT (%)',
                    hint: '21',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return null;
                      final n = double.tryParse(
                          v!.trim().replaceAll(',', '.'));
                      if (n == null || n < 0) {
                        return isSpanish ? 'Debe ser ≥ 0' : 'Must be ≥ 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Base amount (optional)
            _FormField(
              controller: baseAmountCtrl,
              label: isSpanish
                  ? 'Base del proyecto (opcional)'
                  : 'Project base amount (optional)',
              hint: isSpanish ? 'Ej: 1000.00' : 'e.g. 1000.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 8),
            // Description
            _FormField(
              controller: descCtrl,
              label: isSpanish ? 'Descripción' : 'Description',
              hint: isSpanish
                  ? 'Anticipo 70% – Presupuesto $presupuestoNumber'
                  : 'Advance 70% – Presupuesto $presupuestoNumber',
            ),
            const SizedBox(height: 8),
            // Notes
            _FormField(
              controller: notesCtrl,
              label: isSpanish ? 'Notas (opcional)' : 'Notes (optional)',
              hint: isSpanish ? 'Notas adicionales…' : 'Additional notes…',
              maxLines: 2,
            ),
            if (error != null && error!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ErrorBanner(error: error!, cs: cs, t: t),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Step: Final Form ──────────────────────────────────────────────────────────

class _FinalFormStep extends StatelessWidget {
  final bool loading;
  final List<AdvanceInvoiceCandidate> candidates;
  final AdvanceInvoiceCandidate? selectedCandidate;
  final TextEditingController notesCtrl;
  final String presupuestoNumber;
  final String clientName;
  final double total;
  final String? error;
  final bool isSpanish;
  final ValueChanged<AdvanceInvoiceCandidate?> onCandidateChanged;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations l;

  const _FinalFormStep({
    super.key,
    required this.loading,
    required this.candidates,
    required this.selectedCandidate,
    required this.notesCtrl,
    required this.presupuestoNumber,
    required this.clientName,
    required this.total,
    required this.error,
    required this.isSpanish,
    required this.onCandidateChanged,
    required this.cs,
    required this.t,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final totalFmt =
        NumberFormat.currency(locale: isSpanish ? 'es' : 'en', symbol: '€')
            .format(total);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoStrip(
            icon: Icons.info_outline_rounded,
            text: isSpanish
                ? 'Presupuesto $presupuestoNumber · $clientName · $totalFmt'
                : 'Presupuesto $presupuestoNumber · $clientName · $totalFmt',
            cs: cs,
            t: t,
          ),
          const SizedBox(height: 12),
          // Advance invoice selector
          Text(
            isSpanish
                ? 'Factura anticipo vinculada (opcional)'
                : 'Linked advance invoice (optional)',
            style: t.bodySmall
                .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            _AdvanceCandidateDropdown(
              candidates: candidates,
              selected: selectedCandidate,
              isSpanish: isSpanish,
              onChanged: onCandidateChanged,
              cs: cs,
              t: t,
            ),
          const SizedBox(height: 8),
          // Explanation note
          _InfoStrip(
            icon: Icons.auto_awesome_outlined,
            text: isSpanish
                ? 'Si seleccionas un anticipo, el importe restante se calcula automáticamente al emitir la factura final.'
                : 'If you select an advance invoice, the remaining amount will be calculated automatically when the final invoice is issued.',
            cs: cs,
            t: t,
            subtle: true,
          ),
          const SizedBox(height: 8),
          _FormField(
            controller: notesCtrl,
            label: isSpanish ? 'Notas (opcional)' : 'Notes (optional)',
            hint: isSpanish ? 'Notas adicionales…' : 'Additional notes…',
            maxLines: 2,
          ),
          if (error != null && error!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ErrorBanner(error: error!, cs: cs, t: t),
          ],
        ],
      ),
    );
  }
}

class _AdvanceCandidateDropdown extends StatelessWidget {
  final List<AdvanceInvoiceCandidate> candidates;
  final AdvanceInvoiceCandidate? selected;
  final bool isSpanish;
  final ValueChanged<AdvanceInvoiceCandidate?> onChanged;
  final ColorScheme cs;
  final AppTypography t;

  const _AdvanceCandidateDropdown({
    required this.candidates,
    required this.selected,
    required this.isSpanish,
    required this.onChanged,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final noneLabel =
        isSpanish ? 'Sin anticipo vinculado' : 'No advance invoice';

    return DropdownButtonFormField<AdvanceInvoiceCandidate?>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: [
        DropdownMenuItem<AdvanceInvoiceCandidate?>(
          value: null,
          child: Text(
            noneLabel,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        ...candidates.map(
          (c) => DropdownMenuItem<AdvanceInvoiceCandidate?>(
            value: c,
            child: Row(
              children: [
                Icon(
                  c.isIssued
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked,
                  size: 14,
                  color: c.isIssued ? cs.tertiary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  c.number,
                  style: t.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                if (c.isIssued) ...[
                  const SizedBox(width: 6),
                  Text(
                    isSpanish ? '(emitida)' : '(issued)',
                    style: t.bodySmall.copyWith(
                      color: cs.tertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Step: Success ─────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  final String? invoiceType;
  final String? invoiceId;
  final String presupuestoNumber;
  final String clientName;
  final bool isSpanish;
  final VoidCallback onDone;
  final ColorScheme cs;
  final AppTypography t;

  const _SuccessStep({
    super.key,
    required this.invoiceType,
    required this.invoiceId,
    required this.presupuestoNumber,
    required this.clientName,
    required this.isSpanish,
    required this.onDone,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isAdvance = invoiceType == 'advance';
    final typeLabel = isAdvance
        ? (isSpanish ? 'Factura Anticipo' : 'Advance Invoice')
        : (isSpanish ? 'Factura Final' : 'Final Invoice');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: cs.tertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSpanish ? '¡Borrador creado!' : 'Draft created!',
            style:
                t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$typeLabel – $clientName',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isSpanish
                ? 'Desde presupuesto $presupuestoNumber'
                : 'From presupuesto $presupuestoNumber',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _InfoStrip(
            icon: Icons.edit_outlined,
            text: isSpanish
                ? 'La factura se ha creado como borrador. Revísala y emítela cuando esté lista.'
                : 'The invoice was created as a draft. Review and issue it when ready.',
            cs: cs,
            t: t,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDone,
              child: Text(isSpanish ? 'Cerrar' : 'Close'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  final AppTypography t;
  final bool subtle;

  const _InfoStrip({
    required this.icon,
    required this.text,
    required this.cs,
    required this.t,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: subtle
            ? cs.surfaceContainerHighest.withValues(alpha: 0.25)
            : cs.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subtle
              ? cs.outlineVariant.withValues(alpha: 0.25)
              : cs.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                subtle ? cs.onSurfaceVariant : cs.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: t.bodySmall.copyWith(
                color: subtle ? cs.onSurfaceVariant : cs.onSurface,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final ColorScheme cs;
  final AppTypography t;

  const _ErrorBanner({
    required this.error,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: cs.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error,
              style: t.bodySmall.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isSpanish;
  final ColorScheme cs;

  const _ErrorRetry({
    required this.error,
    required this.onRetry,
    required this.isSpanish,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 28, color: cs.error),
          const SizedBox(height: 6),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(isSpanish ? 'Reintentar' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
