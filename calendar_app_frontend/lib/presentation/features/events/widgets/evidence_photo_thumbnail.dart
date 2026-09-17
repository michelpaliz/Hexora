import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a completion-evidence photo thumbnail, fetching its (short-lived)
/// view URL once per widget lifetime, with tap-to-zoom via [InteractiveViewer].
class EvidencePhotoThumbnail extends StatefulWidget {
  const EvidencePhotoThumbnail({
    super.key,
    required this.fetchUrl,
    this.size = 64,
  });

  final Future<String> Function() fetchUrl;
  final double size;

  @override
  State<EvidencePhotoThumbnail> createState() =>
      _EvidencePhotoThumbnailState();
}

class _EvidencePhotoThumbnailState extends State<EvidencePhotoThumbnail> {
  late final Future<String> _urlFuture = widget.fetchUrl();

  void _openZoom(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 8.0,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        final cs = Theme.of(context).colorScheme;
        if (!snapshot.hasData) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final url = snapshot.data!;
        return GestureDetector(
          onTap: () => _openZoom(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: widget.size,
                height: widget.size,
                color: cs.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}
