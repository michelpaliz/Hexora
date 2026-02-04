import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_app_bar.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

part 'invoice_editor_view.dart';
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

  const InvoiceEditorScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialInvoice,
    this.embedded = false,
    this.onClose,
    this.onDataChanged,
  });

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  late final InvoiceEditorController _c;
  bool _changed = false;
  String? _lastSavedInvoiceId;
  String? _lastSavedInvoiceStatus;
  bool _headerCompact = false;

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
  }

  @override
  void dispose() {
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
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!(_changed);
      return;
    }
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    return _InvoiceEditorView(state: this);
  }
}
