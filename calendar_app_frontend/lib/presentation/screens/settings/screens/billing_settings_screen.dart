import 'package:flutter/material.dart';
import 'package:hexora/services/invoicing/business_billing_settings_api.dart';

class BillingSettingsScreen extends StatefulWidget {
  const BillingSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<BillingSettingsScreen> createState() => _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends State<BillingSettingsScreen> {
  final _api = BusinessBillingSettingsApi();
  BusinessBillingSettings? _settings;
  String _language = 'es';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEs => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _api.load(widget.groupId);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _language = settings.defaultInvoiceLanguage ??
            (Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'es');
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _settings?.canEdit != true) return;
    setState(() => _saving = true);
    try {
      final settings = await _api.save(widget.groupId, _language);
      if (!mounted) return;
      setState(() => _settings = settings);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEs
            ? 'Idioma de facturación guardado.'
            : 'Invoice language saved.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEs ? 'Facturación' : 'Billing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isEs
                                    ? 'Idioma de facturación'
                                    : 'Invoice language',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isEs
                                    ? 'El idioma seleccionado se utilizará para las nuevas facturas. Las facturas existentes conservarán su idioma original.'
                                    : 'The selected language will be used for new invoices. Existing invoices will keep their original language.',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 20),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'es', label: Text('Español (ES)')),
                                  ButtonSegment(value: 'en', label: Text('English (EN)')),
                                ],
                                selected: {_language},
                                onSelectionChanged: _settings?.canEdit == true
                                    ? (value) => setState(() => _language = value.first)
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _InvoiceLanguagePreview(language: _language),
                              if (_settings?.canEdit != true) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _isEs
                                      ? 'Solo los administradores de la empresa pueden modificar esta preferencia.'
                                      : 'Only business administrators can change this preference.',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                              const SizedBox(height: 20),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: FilledButton(
                                  onPressed: _settings?.canEdit == true && !_saving
                                      ? _save
                                      : null,
                                  child: Text(_saving
                                      ? (_isEs ? 'Guardando…' : 'Saving…')
                                      : (_isEs ? 'Guardar cambios' : 'Save changes')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _InvoiceLanguagePreview extends StatelessWidget {
  const _InvoiceLanguagePreview({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    final en = language == 'en';
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .35),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(en ? 'INVOICE' : 'FACTURA',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text('${en ? 'Invoice No.' : 'Núm. de factura'}: 2026-001'),
          Text('${en ? 'Issue date' : 'Fecha de emisión'}: 24/11/2026'),
          const Divider(height: 24),
          Row(children: [
            Expanded(child: Text(en ? 'Description' : 'Descripción')),
            Text(en ? 'Total' : 'Total'),
          ]),
          const SizedBox(height: 8),
          Row(children: const [
            Expanded(child: Text('Servicio / Service')),
            Text('121,00 €'),
          ]),
        ],
      ),
    );
  }
}
