// create_edit/widgets/images/group_image.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

class GroupImage extends StatefulWidget {
  /// Existing remote image URL (can be null).
  final String? imageUrl;

  /// Show a spinner overlay when uploading.
  final bool isUploading;

  /// Called when the user picks a new image (provides the XFile).
  final Future<void> Function(XFile file)? onPicked;

  /// Called when the user taps remove (clear server in the callback).
  final Future<void> Function()? onRemove;

  /// Sizing & shape.
  final double size;
  final double borderRadius;

  const GroupImage({
    super.key,
    this.imageUrl,
    this.isUploading = false,
    this.onPicked,
    this.onRemove,
    this.size = 100,
    this.borderRadius = 16,
  });

  @override
  State<GroupImage> createState() => _GroupImageState();
}

class _GroupImageState extends State<GroupImage> {
  final _picker = ImagePicker();
  XFile? _localPicked;

  Future<void> _pick() async {
    if (widget.isUploading) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _localPicked = file);
    if (widget.onPicked != null) await widget.onPicked!(file);
  }

  Future<void> _remove() async {
    if (widget.isUploading) return;
    setState(() => _localPicked = null);
    if (widget.onRemove != null) await widget.onRemove!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final imageProvider = _localPicked != null
        ? FileImage(File(_localPicked!.path)) as ImageProvider
        : (widget.imageUrl?.isNotEmpty ?? false)
            ? NetworkImage(widget.imageUrl!)
            : null;

    final hasImage =
        imageProvider != null || (widget.imageUrl?.isNotEmpty ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Image container with gradient border
        GestureDetector(
          onTap: _pick,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gradient border ring
              Container(
                width: widget.size + 6,
                height: widget.size + 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius + 3),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.tertiary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // Image container
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  image: imageProvider != null
                      ? DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageProvider == null
                    ? Icon(
                        Icons.groups_rounded,
                        size: widget.size * 0.45,
                        color: cs.onSurfaceVariant.withOpacity(.6),
                      )
                    : null,
              ),

              // Uploading overlay
              if (widget.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

              // Camera badge (only show when not uploading)
              if (!widget.isUploading)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action buttons (compact row)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit/Change button
            FilledButton.icon(
              onPressed: widget.isUploading ? null : _pick,
              icon: Icon(
                hasImage
                    ? Icons.edit_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 18,
              ),
              label: Text(
                hasImage ? l.editImage : l.addPhoto,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Remove button (only show if image exists)
            if (hasImage) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: widget.isUploading ? null : _remove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withOpacity(.4)),
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(44, 44),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: cs.error,
                ),
              ),
            ],
          ],
        ),

        // Helper text
        const SizedBox(height: 6),
        Text(
          hasImage ? l.tapToChangePhoto : l.tapToAddPhoto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
        ),
      ],
    );
  }
}
