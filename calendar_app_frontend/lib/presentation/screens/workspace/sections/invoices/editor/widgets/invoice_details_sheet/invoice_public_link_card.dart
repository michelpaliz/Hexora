import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';

class InvoicePublicLinkCard extends StatefulWidget {
  const InvoicePublicLinkCard({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  State<InvoicePublicLinkCard> createState() => _InvoicePublicLinkCardState();
}

class _InvoicePublicLinkCardState extends State<InvoicePublicLinkCard> {
  final _api = InvoicesApi();
  bool _loading = true;
  bool _busy = false;
  String? _url;
  bool _hasLink = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant InvoicePublicLinkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoiceId != widget.invoiceId) _load();
  }

  Future<void> _load() async {
    final requestedId = widget.invoiceId;
    setState(() {
      _loading = true;
      _error = null;
      _url = null;
      _hasLink = false;
    });
    try {
      final result = await _api.getPublicLink(requestedId);
      if (mounted && widget.invoiceId == requestedId) {
        setState(() {
          _url = result['url']?.toString();
          _hasLink = result['hasLink'] == true;
        });
      }
    } catch (_) {
      if (mounted && widget.invoiceId == requestedId) {
        setState(() => _error = 'No se pudo cargar el enlace público.');
      }
    } finally {
      if (mounted && widget.invoiceId == requestedId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _change({required bool revoke}) async {
    if (revoke || _url != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
              revoke ? 'Revocar enlace público' : 'Regenerar enlace público'),
          content: Text(revoke
              ? 'El QR ya impreso dejará de funcionar. Puedes generar otro enlace después.'
              : 'El enlace y el QR anteriores dejarán de funcionar. Descarga y envía de nuevo el PDF para compartir el nuevo QR.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(revoke ? 'Revocar' : 'Regenerar')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = revoke
          ? await _api.revokePublicLink(widget.invoiceId)
          : await _api.regeneratePublicLink(widget.invoiceId);
      if (mounted) {
        setState(() {
          _url = result['url']?.toString();
          _hasLink = result['hasLink'] == true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'No se pudo actualizar el enlace. Comprueba tus permisos.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Factura digital', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text(
            'El QR del PDF abre el estado de pago actualizado. No sustituye al QR fiscal.',
            style: TextStyle(fontSize: 12)),
        if (_loading)
          const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2)),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: cs.error, fontSize: 12))),
        if (!_loading && _error == null) ...[
          const SizedBox(height: 8),
          Text(
              _url == null
                  ? (_hasLink
                      ? 'Enlace revocado.'
                      : 'Esta factura se emitió antes de activar el QR digital.')
                  : _url!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          Wrap(spacing: 8, children: [
            if (_url != null) ...[
              TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: _url!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Enlace copiado')));
                          }
                        },
                  icon: const Icon(Icons.copy_outlined, size: 17),
                  label: const Text('Copiar enlace')),
              TextButton(
                  onPressed: _busy ? null : () => _change(revoke: true),
                  child: const Text('Revocar')),
              TextButton(
                  onPressed: _busy ? null : () => _change(revoke: false),
                  child: const Text('Regenerar')),
            ] else if (_hasLink)
              TextButton(
                  onPressed: _busy ? null : () => _change(revoke: false),
                  child: const Text('Regenerar enlace')),
          ]),
        ],
      ]),
    );
  }
}
