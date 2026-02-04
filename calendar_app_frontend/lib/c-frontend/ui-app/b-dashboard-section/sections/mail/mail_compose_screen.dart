import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

part 'compose/mail_compose_utils.dart';
part 'compose/mail_compose_view.dart';
part 'compose/mail_compose_widgets.dart';

class MailComposeScreen extends StatefulWidget {
  const MailComposeScreen({
    super.key,
    this.embedded = false,
    this.onSent,
    this.onClose,
  });

  final bool embedded;
  final VoidCallback? onSent;
  final VoidCallback? onClose;

  @override
  State<MailComposeScreen> createState() => _MailComposeScreenState();
}

class _MailComposeScreenState extends State<MailComposeScreen> {
  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _bccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _invoiceIdsCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  final _bodyScroll = ScrollController();
  late final quill.QuillController _quillController =
      quill.QuillController.basic();

  final List<String> _toList = [];
  final List<String> _ccList = [];
  final List<String> _bccList = [];

  bool _attachInvoicePdf = false;
  bool _includeInvoiceLinks = false;
  bool _applyDefaultFooter = true;
  bool _sending = false;
  bool _uploadingAttachment = false;
  bool _showCc = false;
  bool _showBcc = false;
  bool _attachmentsExpanded = false;
  bool _invoiceExpanded = false;

  final List<MailOutgoingAttachment> _attachments = [];

  void update(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _subjectCtrl.dispose();
    _invoiceIdsCtrl.dispose();
    _bodyFocus.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MailComposeView(state: this);
  }

  Future<void> _addAttachment() async {
    final l = AppLocalizations.of(context)!;
    final storageKeyCtrl = TextEditingController();
    final filenameCtrl = TextEditingController();
    final contentTypeCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();

    final result = await showDialog<MailOutgoingAttachment>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.mailComposeAddAttachment),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: storageKeyCtrl,
                  decoration: InputDecoration(
                    labelText: l.mailComposeStorageKeyLabel,
                    hintText: l.mailComposeStorageKeyHint,
                  ),
                ),
                TextField(
                  controller: filenameCtrl,
                  decoration: InputDecoration(
                    labelText: l.mailComposeFilenameLabel,
                    hintText: l.mailComposeFilenameHint,
                  ),
                ),
                TextField(
                  controller: contentTypeCtrl,
                  decoration: InputDecoration(
                    labelText: l.mailComposeContentTypeLabel,
                    hintText: l.mailComposeContentTypeHint,
                  ),
                ),
                TextField(
                  controller: sizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l.mailComposeSizeLabel,
                    hintText: l.mailComposeSizeHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.mailComposeCancel),
            ),
            FilledButton(
              onPressed: () {
                final key = storageKeyCtrl.text.trim();
                if (key.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.mailComposeStorageKeyRequired)),
                  );
                  return;
                }
                final size = int.tryParse(sizeCtrl.text.trim());
                Navigator.of(context).pop(
                  MailOutgoingAttachment(
                    storageKey: key,
                    filename: filenameCtrl.text.trim().isEmpty
                        ? null
                        : filenameCtrl.text.trim(),
                    contentType: contentTypeCtrl.text.trim().isEmpty
                        ? null
                        : contentTypeCtrl.text.trim(),
                    size: size,
                  ),
                );
              },
              child: Text(l.mailComposeAddAttachment),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _attachments.add(result);
        _attachmentsExpanded = true;
      });
    }
  }

  Future<void> _pickAndUploadAttachment() async {
    final l = AppLocalizations.of(context)!;
    final token = await TokenService.loadToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      _showError(l.notAuthenticatedOrUserMissing);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (!mounted) return;
    final file = result?.files.single;
    if (file == null) return;

    if (!kIsWeb && (file.path == null || file.path!.isEmpty)) {
      _showError(l.mailComposeFileReadError);
      return;
    }
    if (kIsWeb && file.bytes == null) {
      _showError(l.mailComposeFileReadError);
      return;
    }

    setState(() => _uploadingAttachment = true);
    try {
      final mimeType = _inferMimeType(file);
      final uploadResult = await uploadImageToAzure(
        scope: 'users',
        accessToken: token,
        file: kIsWeb ? null : File(file.path!),
        bytes: kIsWeb ? file.bytes : null,
        mimeType: mimeType,
      );

      setState(() {
        _attachments.add(
          MailOutgoingAttachment(
            storageKey: uploadResult.blobName,
            filename: file.name,
            contentType: mimeType,
            size: file.size,
          ),
        );
        _attachmentsExpanded = true;
      });
    } catch (e) {
      _showError(l.mailComposeUploadFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    _flushRecipientInputs();
    final to = _toList;
    if (to.isEmpty) {
      _showError(l.mailComposeToRequired);
      return;
    }

    final cc = _ccList;
    final bcc = _bccList;
    final subject = _subjectCtrl.text.trim();
    final body = _quillController.document.toPlainText().trim();
    if (subject.isEmpty) {
      _showError(l.mailComposeSubjectRequired);
      return;
    }
    if (body.isEmpty) {
      _showError(l.mailComposeBodyRequired);
      return;
    }

    final invoiceIds = _splitValues(_normalizeInvoiceIds(_invoiceIdsCtrl.text));

    setState(() => _sending = true);
    try {
    final request = MailSendRequest(
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      textBody: body,
      htmlBody: _quillToHtml(_quillController.document),
      attachments: _attachments,
      invoiceIds: invoiceIds,
      attachInvoicePdf: invoiceIds.isEmpty ? null : _attachInvoicePdf,
      includeInvoiceLinks: invoiceIds.isEmpty ? null : _includeInvoiceLinks,
      applyDefaultFooter: _applyDefaultFooter,
    );
      await context.read<MailDomain>().sendMessage(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.mailComposeSentToast)),
      );
      _resetForm();
      if (widget.embedded) {
        widget.onSent?.call();
      } else {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      _showError(l.mailComposeSendFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _resetForm() {
    _toCtrl.clear();
    _ccCtrl.clear();
    _bccCtrl.clear();
    _subjectCtrl.clear();
    _quillController.replaceText(
      0,
      _quillController.document.length,
      '',
      const TextSelection.collapsed(offset: 0),
    );
    _invoiceIdsCtrl.clear();
    setState(() {
      _attachInvoicePdf = false;
      _includeInvoiceLinks = false;
      _applyDefaultFooter = true;
      _showCc = false;
      _showBcc = false;
      _attachmentsExpanded = false;
      _invoiceExpanded = false;
      _toList.clear();
      _ccList.clear();
      _bccList.clear();
      _attachments.clear();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> _splitValues(String raw) {
    return raw
        .split(RegExp(r'[;,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _flushRecipientInputs() {
    _consumeAddresses(_toCtrl, _toList);
    _consumeAddresses(_ccCtrl, _ccList);
    _consumeAddresses(_bccCtrl, _bccList);
  }

  void _consumeAddresses(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final parts = text.split(RegExp(r'[;,\s]'));
    final added = <String>[];
    for (final raw in parts) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (_isValidEmail(value) && !list.contains(value)) {
        added.add(value);
      }
    }
    if (added.isNotEmpty) {
      list.addAll(added);
      controller.clear();
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _normalizeInvoiceIds(String raw) {
    return raw.replaceAll(RegExp(r'[\s;]+'), ',');
  }

  Future<void> _promptLink() async {
    final l = AppLocalizations.of(context)!;
    final selection = _quillController.selection;
    final selectedText = selection.isCollapsed
        ? ''
        : _quillController.document
            .getPlainText(selection.start, selection.end - selection.start)
            .trim();
    final labelCtrl = TextEditingController(text: selectedText);
    final urlCtrl = TextEditingController(text: 'https://');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.mailComposeAddAttachment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: l.mailComposeSubjectLabel,
                hintText: l.mailComposeSubjectHint,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.mailComposeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.mailComposeAddAttachment),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final url = urlCtrl.text.trim();
    if (url.isEmpty) return;
    final label = labelCtrl.text.trim().isEmpty ? url : labelCtrl.text.trim();

    final index = selection.start;
    final length = selection.end - selection.start;
    _quillController.replaceText(
      index,
      length,
      label,
      TextSelection.collapsed(offset: index + label.length),
    );
    _quillController.formatSelection(quill.LinkAttribute(url));
  }

  Future<void> _showAttachmentActions() async {
    final l = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: Text(l.mailComposeUploadAttachment),
                onTap: () => Navigator.of(context).pop('upload'),
              ),
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(l.mailComposeAddAttachment),
                onTap: () => Navigator.of(context).pop('manual'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'upload') {
      await _pickAndUploadAttachment();
    } else {
      await _addAttachment();
    }
  }
}
