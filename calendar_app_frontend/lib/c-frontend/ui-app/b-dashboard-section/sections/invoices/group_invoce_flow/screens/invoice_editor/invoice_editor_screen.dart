import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_app_bar.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/shared/widgets/wizard_steps_header.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

part 'invoice_editor_view.dart';
part 'view_sections/invoice_editor_header_section.dart';
part 'view_sections/draft_banner.dart';
part 'view_sections/header_compact_summary.dart';
part 'view_sections/pending_drafts_list.dart';
part 'view_sections/step_widgets.dart';

class InvoiceEditorScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  final Invoice? initialInvoice;
  final bool embedded;
  final ValueChanged<bool>? onClose;
  final VoidCallback? onDataChanged;
  final ValueChanged<bool>? onUnsavedStateChanged;

  const InvoiceEditorScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialInvoice,
    this.embedded = false,
    this.onClose,
    this.onDataChanged,
    this.onUnsavedStateChanged,
  });

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen>
    with SingleTickerProviderStateMixin {
  late final InvoiceEditorController _c;
  bool _changed = false;
  String? _lastSavedInvoiceId;
  String? _lastSavedInvoiceStatus;
  bool _lastReportedUnsaved = false;
  final bool _headerCompact = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _c = InvoiceEditorController(
      group: widget.group,
      clients: widget.clients,
      initialClientId: widget.initialClientId,
      initialInvoice: widget.initialInvoice,
    );
    _c.addListener(_handleControllerChange);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _c.currentStepIndex.clamp(0, 3),
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _c.removeListener(_handleControllerChange);
    _c.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final saved = _c.savedInvoice;
    if (!_changed && saved != null) {
      _changed = true;
    }
    if (saved != null && widget.onDataChanged != null) {
      if (saved.id != _lastSavedInvoiceId ||
          saved.status != _lastSavedInvoiceStatus) {
        _lastSavedInvoiceId = saved.id;
        _lastSavedInvoiceStatus = saved.status;
        widget.onDataChanged!();
      }
    }
    if (_lastReportedUnsaved != _c.draftDirty) {
      _lastReportedUnsaved = _c.draftDirty;
      widget.onUnsavedStateChanged?.call(_c.draftDirty);
    }
  }

  void _handleClose() {
    _closeNow();
  }

  void _closeNow() {
    if (widget.onClose != null) {
      widget.onClose!(_changed);
      return;
    }
    Navigator.of(context).pop(_changed);
  }

  Future<void> _requestClose() async {
    if (!_c.draftDirty || _c.saving) {
      _closeNow();
      return;
    }
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Tienes cambios sin guardar' : 'Unsaved changes'),
        content: Text(
          isEs
              ? 'Puedes quedarte, salir sin guardar o guardar el borrador antes de salir.'
              : 'You can stay, leave without saving, or save the draft before leaving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('stay'),
            child: Text(isEs ? 'Quedarme' : 'Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('leave'),
            child: Text(isEs ? 'Salir sin guardar' : 'Leave without saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(isEs ? 'Guardar y salir' : 'Save & leave'),
          ),
        ],
      ),
    );
    if (!mounted || result == null || result == 'stay') return;
    if (result == 'save') {
      await _c.handleSaveDraft(context, confirmIfEditing: false);
      if (!mounted || _c.draftDirty) return;
    }
    _closeNow();
  }

  void _handleTabChange() {
    _c.setCurrentStepIndex(_tabController.index);
    if (kIsWeb && _tabController.index != 3) {
      _c.releasePreviewSurface();
    }
    if (_tabController.index == 3 &&
        _c.canPreviewDraft &&
        !_c.previewedPdf &&
        mounted) {
      _c.previewPdf(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InvoiceEditorView(state: this);
  }
}
