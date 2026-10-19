import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/services/clients/client_api.dart';

/// Fetches a private image only when a client with an image is displayed.
class ClientPropertyImage extends StatefulWidget {
  const ClientPropertyImage(
      {super.key,
      required this.client,
      this.bytes,
      this.hideSavedImage = false,
      this.width = 120,
      this.height = 88});
  final GroupClient client;
  final Uint8List? bytes;
  final bool hideSavedImage;
  final double width;
  final double height;

  @override
  State<ClientPropertyImage> createState() => _ClientPropertyImageState();
}

class _ClientPropertyImageState extends State<ClientPropertyImage> {
  Future<String?>? _url;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClientPropertyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client.id != widget.client.id ||
        oldWidget.client.imageVersion != widget.client.imageVersion ||
        oldWidget.hideSavedImage != widget.hideSavedImage ||
        oldWidget.bytes != widget.bytes) {
      _load();
    }
  }

  void _load() {
    _url = widget.client.imageVersion == null ||
            widget.hideSavedImage ||
            widget.bytes != null
        ? null
        : ClientsApi().imageUrl(widget.client.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = widget.client.name.trim();
    Widget fallback() => ColoredBox(
        color: cs.primaryContainer,
        child: Center(
            child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: cs.onPrimaryContainer))));
    return Semantics(
      label: '${AppLocalizations.of(context)!.clientImageLabel}: $name',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.bytes != null
              ? Image.memory(widget.bytes!,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback())
              : FutureBuilder<String?>(
                  future: _url,
                  builder: (context, snapshot) {
                    // Never retain the previous client's image while changing selection.
                    final url = snapshot.connectionState == ConnectionState.done
                        ? snapshot.data
                        : null;
                    return url == null
                        ? fallback()
                        : Image.network(url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => fallback());
                  }),
        ),
      ),
    );
  }
}
