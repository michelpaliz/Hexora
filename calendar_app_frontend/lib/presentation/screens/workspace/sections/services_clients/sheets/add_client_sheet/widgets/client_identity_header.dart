import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';

class ClientIdentityHeader extends StatefulWidget {
  const ClientIdentityHeader({
    super.key,
    required this.client,
    required this.name,
    this.email,
    this.bytes,
    this.removed = false,
    this.disabled = false,
    this.uploading = false,
    this.trailing,
    required this.onChanged,
    required this.onRemove,
  });

  final GroupClient client;
  final String name;
  final String? email;
  final Uint8List? bytes;
  final bool removed;
  final bool disabled;
  final bool uploading;
  final Widget? trailing;
  final void Function(Uint8List bytes, String name) onChanged;
  final VoidCallback onRemove;

  @override
  State<ClientIdentityHeader> createState() => _ClientIdentityHeaderState();
}

class _ClientIdentityHeaderState extends State<ClientIdentityHeader> {
  static const double _avatarSize = 44;

  bool _picking = false;

  Future<void> _pick() async {
    if (widget.disabled || widget.uploading) return;
    setState(() => _picking = true);
    final l = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (!mounted || result == null || widget.disabled) return;
      final file = result.files.single;
      if (file.bytes == null || file.size == 0 || file.size > 5 * 1024 * 1024) {
        throw const FormatException();
      }
      widget.onChanged(file.bytes!, file.name);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.clientImageInvalid)),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    final hasImage = widget.bytes != null ||
        (!widget.removed && widget.client.imageVersion != null);
    final busy = _picking || widget.uploading;
    final interactable = !widget.disabled && !busy;

    final name = widget.name.trim();
    final email = widget.email?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: hasImage ? l.clientImageReplace : l.clientImageAdd,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: interactable ? _pick : null,
                child: SizedBox(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: ClipOval(
                    child: ClientPropertyImage(
                      client: widget.client,
                      bytes: widget.bytes,
                      hideSavedImage: widget.removed,
                      width: _avatarSize,
                      height: _avatarSize,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: _AvatarActionBadge(
                  onTap: interactable ? _pick : null,
                  tooltip: hasImage ? l.clientImageReplace : l.clientImageAdd,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  icon:
                      hasImage ? Icons.edit_rounded : Icons.camera_alt_rounded,
                ),
              ),
              if (hasImage)
                Positioned(
                  right: -2,
                  top: -2,
                  child: _AvatarActionBadge(
                    onTap: interactable ? widget.onRemove : null,
                    tooltip: l.clientImageRemove,
                    backgroundColor: cs.surface,
                    foregroundColor: cs.error,
                    icon: Icons.close_rounded,
                  ),
                ),
              if (busy)
                Positioned.fill(
                  child: ClipOval(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.38),
                      child: const Center(
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );
  }
}

class _AvatarActionBadge extends StatelessWidget {
  const _AvatarActionBadge({
    required this.onTap,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final VoidCallback? onTap;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 13, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
