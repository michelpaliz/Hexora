// create_edit/widgets/images/group_image.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/image_picker_controller.dart';

class GroupImage extends StatefulWidget {
  /// Existing remote image URL (can be null).
  final String? imageUrl;

  /// If you want to show an upload spinner over the avatar.
  final bool isUploading;

  /// Called when the user picks a new image (provides the XFile).
  final Future<void> Function(XFile file)? onPicked;

  /// Called when the user taps remove.
  /// If you also want to clear the remote on the server, do it in this callback.
  final Future<void> Function()? onRemove;

  /// Optional: override labels / icons area (defaults provided).
  final String editLabel;
  final String removeLabel;

  /// Avatar sizing.
  final double size;
  final double borderRadius;

  const GroupImage({
    super.key,
    this.imageUrl,
    this.isUploading = false,
    this.onPicked,
    this.onRemove,
    this.editLabel = 'Change',
    this.removeLabel = 'Remove',
    this.size = 96,
    this.borderRadius = 16,
  });

  @override
  State<GroupImage> createState() => _GroupImageState();
}

class _GroupImageState extends State<GroupImage> {
  final _pickerCtrl = ImagePickerController();
  XFile? _localPicked;

  Future<void> _handlePick() async {
    final file = await _pickerCtrl.pickImageFromGallery();
    if (file == null) return;
    setState(() => _localPicked = file);
    if (widget.onPicked != null) {
      await widget.onPicked!(file);
    }
  }

  Future<void> _handleRemove() async {
    setState(() => _localPicked = null);
    if (widget.onRemove != null) {
      await widget.onRemove!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = _localPicked != null
        ? FileImage(File(_localPicked!.path)) as ImageProvider
        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ? NetworkImage(widget.imageUrl!)
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: theme.dividerColor),
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: imageProvider == null
                  ? Icon(Icons.group,
                      size: widget.size * 0.5, color: theme.hintColor)
                  : null,
            ),
            if (widget.isUploading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: widget.isUploading ? null : _handlePick,
              icon: const Icon(Icons.edit),
              label: Text(widget.editLabel),
            ),
            const SizedBox(width: 8),
            if (imageProvider != null || (widget.imageUrl?.isNotEmpty ?? false))
              TextButton.icon(
                onPressed: widget.isUploading ? null : _handleRemove,
                icon: const Icon(Icons.delete_outline),
                label: Text(widget.removeLabel),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
              ),
          ],
        ),
      ],
    );
  }
}
