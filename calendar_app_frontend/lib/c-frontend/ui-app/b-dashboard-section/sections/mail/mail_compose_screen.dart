import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MailComposeScreen extends StatefulWidget {
  const MailComposeScreen({super.key});

  @override
  State<MailComposeScreen> createState() => _MailComposeScreenState();
}

class _MailComposeScreenState extends State<MailComposeScreen> {
  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _bccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _invoiceIdsCtrl = TextEditingController();

  bool _useHtml = false;
  bool _attachInvoicePdf = false;
  bool _includeInvoiceLinks = false;
  bool _sending = false;
  bool _uploadingAttachment = false;

  final List<MailOutgoingAttachment> _attachments = [];

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _invoiceIdsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailComposeTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LabeledField(
            label: l.mailComposeToLabel,
            controller: _toCtrl,
            hint: l.mailComposeToHint,
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: l.mailComposeCcLabel,
            controller: _ccCtrl,
            hint: l.mailComposeCcHint,
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: l.mailComposeBccLabel,
            controller: _bccCtrl,
            hint: l.mailComposeBccHint,
          ),
          const SizedBox(height: 12),
          _LabeledField(
            label: l.mailComposeSubjectLabel,
            controller: _subjectCtrl,
            hint: l.mailComposeSubjectHint,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.mailComposeBodyLabel,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                l.mailComposeHtmlToggle,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              Switch(
                value: _useHtml,
                onChanged: _sending
                    ? null
                    : (value) => setState(() => _useHtml = value),
              ),
            ],
          ),
          TextField(
            controller: _bodyCtrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: _useHtml
                  ? l.mailComposeHtmlHint
                  : l.mailComposeTextHint,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: l.mailComposeAttachmentsLabel),
          const SizedBox(height: 8),
          if (_attachments.isEmpty)
            Text(
              l.mailComposeAttachmentsEmpty,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ..._attachments.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final attachment = entry.value;
                return _AttachmentRow(
                  attachment: attachment,
                  onRemove: () => setState(() => _attachments.removeAt(index)),
                );
              },
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _sending || _uploadingAttachment
                      ? null
                      : _pickAndUploadAttachment,
                  icon: _uploadingAttachment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(_uploadingAttachment
                      ? l.mailComposeUploading
                      : l.mailComposeUploadAttachment),
                ),
                OutlinedButton.icon(
                  onPressed: _sending ? null : _addAttachment,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: Text(l.mailComposeAddAttachment),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: l.mailComposeInvoiceOptions),
          const SizedBox(height: 8),
          _LabeledField(
            label: l.mailComposeInvoiceIdsLabel,
            controller: _invoiceIdsCtrl,
            hint: l.mailComposeInvoiceIdsHint,
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _attachInvoicePdf,
            title: Text(l.mailComposeAttachInvoicePdf),
            onChanged: _sending
                ? null
                : (value) => setState(() => _attachInvoicePdf = value),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _includeInvoiceLinks,
            title: Text(l.mailComposeIncludeInvoiceLinks),
            onChanged: _sending
                ? null
                : (value) => setState(() => _includeInvoiceLinks = value),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? l.mailComposeSending : l.mailComposeSend),
            ),
          ),
        ],
      ),
    );
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
      setState(() => _attachments.add(result));
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
      });
    } catch (e) {
      _showError(l.mailComposeUploadFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    final to = _splitEmails(_toCtrl.text);
    if (to.isEmpty) {
      _showError(l.mailComposeToRequired);
      return;
    }

    final cc = _splitEmails(_ccCtrl.text);
    final bcc = _splitEmails(_bccCtrl.text);
    final subject = _subjectCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (subject.isEmpty) {
      _showError(l.mailComposeSubjectRequired);
      return;
    }
    if (body.isEmpty) {
      _showError(l.mailComposeBodyRequired);
      return;
    }

    final invoiceIds = _splitValues(_invoiceIdsCtrl.text);

    setState(() => _sending = true);
    try {
      final request = MailSendRequest(
        to: to,
        cc: cc,
        bcc: bcc,
        subject: subject,
        textBody: _useHtml ? null : body,
        htmlBody: _useHtml ? body : null,
        attachments: _attachments,
        invoiceIds: invoiceIds,
        attachInvoicePdf: invoiceIds.isEmpty ? null : _attachInvoicePdf,
        includeInvoiceLinks: invoiceIds.isEmpty ? null : _includeInvoiceLinks,
      );
      await context.read<MailDomain>().sendMessage(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.mailComposeSentToast)),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      _showError(l.mailComposeSendFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> _splitEmails(String raw) => _splitValues(raw);

  List<String> _splitValues(String raw) {
    return raw
        .split(RegExp(r'[;,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Text(
      title,
      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachment,
    required this.onRemove,
  });

  final MailOutgoingAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final name = attachment.filename?.trim().isNotEmpty == true
        ? attachment.filename!.trim()
        : attachment.storageKey ?? '-';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      child: ListTile(
        leading: const Icon(Icons.attach_file),
        title: Text(name, style: t.bodySmall),
        subtitle: Text(
          attachment.storageKey ?? '-',
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

String _inferMimeType(PlatformFile file) {
  final ext = file.extension?.toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'txt':
      return 'text/plain';
    case 'html':
    case 'htm':
      return 'text/html';
    case 'csv':
      return 'text/csv';
    case 'json':
      return 'application/json';
    default:
      return 'application/octet-stream';
  }
}
