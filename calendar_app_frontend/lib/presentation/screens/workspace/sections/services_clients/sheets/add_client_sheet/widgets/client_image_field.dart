import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';

class ClientImageField extends StatefulWidget {
  const ClientImageField(
      {super.key,
      required this.client,
      required this.onChanged,
      required this.onRemove,
      this.bytes,
      this.removed = false,
      this.disabled = false});
  final GroupClient client;
  final Uint8List? bytes;
  final bool removed;
  final bool disabled;
  final void Function(Uint8List bytes, String name) onChanged;
  final VoidCallback onRemove;

  @override
  State<ClientImageField> createState() => _ClientImageFieldState();
}

class _ClientImageFieldState extends State<ClientImageField> {
  bool _picking = false;

  Future<void> _pick() async {
    setState(() => _picking = true);
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
          withData: true);
      if (!mounted || result == null || widget.disabled) return;
      final file = result.files.single;
      if (file.bytes == null || file.size == 0 || file.size > 5 * 1024 * 1024) {
        throw const FormatException();
      }
      widget.onChanged(file.bytes!, file.name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.clientImageInvalid)));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasImage = widget.bytes != null ||
        (!widget.removed && widget.client.imageVersion != null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.clientImageLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClientPropertyImage(
              client: widget.client,
              bytes: widget.bytes,
              hideSavedImage: widget.removed,
              width: 88,
              height: 88),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(l.clientImageHint,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                      onPressed: widget.disabled || _picking ? null : _pick,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                          hasImage ? l.clientImageReplace : l.clientImageAdd)),
                  if (hasImage)
                    TextButton.icon(
                        onPressed: widget.disabled || _picking
                            ? null
                            : widget.onRemove,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.clientImageRemove)),
                ]),
              ])),
        ]),
      ]),
    );
  }
}
