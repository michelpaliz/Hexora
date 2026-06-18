import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class MailHtmlContent extends StatelessWidget {
  const MailHtmlContent({
    super.key,
    required this.html,
    required this.textColor,
    required this.linkColor,
    this.fontFamily,
    this.fontSize = 14,
    this.lineHeight = 1.6,
    this.paragraphSpacing = 12,
  });

  final String html;
  final Color textColor;
  final Color linkColor;
  final String? fontFamily;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: _withForcedMailHtmlColors(
        html,
        textColor: textColor,
        linkColor: linkColor,
      ),
      onLinkTap: (url, _, __) {
        if (url == null || url.trim().isEmpty) return;
        unawaited(_openUrl(url.trim()));
      },
      extensions: [
        ImageExtension(
          builder: (extensionContext) => _MailHtmlImage(
            src: extensionContext.attributes['src'] ?? '',
            alt: extensionContext.attributes['alt'],
            width: _readImageWidth(extensionContext),
            height: _readImageHeight(extensionContext),
          ),
        ),
      ],
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: textColor,
          fontSize: FontSize(fontSize),
          fontFamily: fontFamily,
          lineHeight: LineHeight(lineHeight),
        ),
        'p': Style(margin: Margins.only(bottom: paragraphSpacing)),
        'a': Style(
          color: linkColor,
          textDecoration: TextDecoration.underline,
        ),
        'img': Style(
          margin: Margins.only(bottom: paragraphSpacing),
        ),
      },
    );
  }
}

class _MailHtmlImage extends StatelessWidget {
  const _MailHtmlImage({
    required this.src,
    required this.alt,
    required this.width,
    required this.height,
  });

  final String src;
  final String? alt;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final trimmedSrc = src.trim();
    if (trimmedSrc.isEmpty) {
      return _MailImagePlaceholder(
        label: alt?.trim().isNotEmpty == true ? alt!.trim() : 'Image',
      );
    }

    final normalizedSrc = _normalizeImageSource(trimmedSrc);
    final imageWidth = width;
    final imageHeight = height;

    if (normalizedSrc.startsWith('cid:')) {
      return _MailImagePlaceholder(
        label: alt?.trim().isNotEmpty == true ? alt!.trim() : 'Inline image',
      );
    }

    if (_isSvgDataUri(normalizedSrc)) {
      final svgBytes = _decodeSvgDataUri(normalizedSrc);
      if (svgBytes != null) {
        return SvgPicture.memory(
          Uint8List.fromList(svgBytes),
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _MailImageLoader(
            width: imageWidth,
            height: imageHeight,
          ),
        );
      }
    }

    if (_isRasterDataUri(normalizedSrc)) {
      final bytes = _decodeRasterDataUri(normalizedSrc);
      if (bytes != null) {
        return Image.memory(
          Uint8List.fromList(bytes),
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _MailImagePlaceholder(
            label: alt?.trim().isNotEmpty == true ? alt!.trim() : 'Image',
          ),
        );
      }
    }

    if (_isSvgUrl(normalizedSrc)) {
      return SvgPicture.network(
        normalizedSrc,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _MailImageLoader(
          width: imageWidth,
          height: imageHeight,
        ),
      );
    }

    if (_isNetworkUrl(normalizedSrc)) {
      return CachedNetworkImage(
        imageUrl: normalizedSrc,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.contain,
        placeholder: (_, __) => _MailImageLoader(
          width: imageWidth,
          height: imageHeight,
        ),
        errorWidget: (_, __, ___) => _MailImagePlaceholder(
          label: alt?.trim().isNotEmpty == true ? alt!.trim() : 'Image',
        ),
      );
    }

    return _MailImagePlaceholder(
      label: alt?.trim().isNotEmpty == true ? alt!.trim() : trimmedSrc,
    );
  }
}

class _MailImageLoader extends StatelessWidget {
  const _MailImageLoader({
    required this.width,
    required this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height ?? 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _MailImagePlaceholder extends StatelessWidget {
  const _MailImagePlaceholder({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double? _readImageWidth(ExtensionContext context) {
  final widthAttr = double.tryParse((context.attributes['width'] ?? '').trim());
  if (widthAttr != null) return widthAttr;
  final styled = context.styledElement;
  if (styled is ImageElement) return styled.width?.value;
  return null;
}

double? _readImageHeight(ExtensionContext context) {
  final heightAttr =
      double.tryParse((context.attributes['height'] ?? '').trim());
  if (heightAttr != null) return heightAttr;
  final styled = context.styledElement;
  if (styled is ImageElement) return styled.height?.value;
  return null;
}

String _normalizeImageSource(String src) {
  if (src.startsWith('//')) return 'https:$src';
  return src;
}

bool _isNetworkUrl(String src) {
  final uri = Uri.tryParse(src);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

bool _isSvgUrl(String src) {
  if (!_isNetworkUrl(src)) return false;
  final uri = Uri.parse(src);
  final path = uri.path.toLowerCase();
  return path.endsWith('.svg') || path.contains('.svg?');
}

bool _isSvgDataUri(String src) =>
    src.toLowerCase().startsWith('data:image/svg+xml');

bool _isRasterDataUri(String src) =>
    src.toLowerCase().startsWith('data:image/') && !_isSvgDataUri(src);

List<int>? _decodeRasterDataUri(String src) {
  final commaIndex = src.indexOf(',');
  if (commaIndex == -1) return null;
  final metadata = src.substring(0, commaIndex).toLowerCase();
  final payload = src.substring(commaIndex + 1);
  if (metadata.contains(';base64')) {
    return base64.decode(payload);
  }
  return Uri.decodeComponent(payload).codeUnits;
}

List<int>? _decodeSvgDataUri(String src) {
  final commaIndex = src.indexOf(',');
  if (commaIndex == -1) return null;
  final metadata = src.substring(0, commaIndex).toLowerCase();
  final payload = src.substring(commaIndex + 1);
  if (metadata.contains(';base64')) {
    return base64.decode(payload);
  }
  return utf8.encode(Uri.decodeComponent(payload));
}

Future<void> _openUrl(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}

String _withForcedMailHtmlColors(
  String rawHtml, {
  required Color textColor,
  required Color linkColor,
}) {
  if (rawHtml.trim().isEmpty) return rawHtml;
  final textHex = _cssHex(textColor);
  final linkHex = _cssHex(linkColor);
  final styleBlock = '''
<style>
  body, body * {
    color: $textHex !important;
    background-color: transparent !important;
  }
  a, a * {
    color: $linkHex !important;
  }
</style>
''';
  return '$styleBlock$rawHtml';
}

String _cssHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}
