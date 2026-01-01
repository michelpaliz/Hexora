import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';

import 'enable_banking_link_store.dart';

class EnableBankingCallbackScreen extends StatefulWidget {
  const EnableBankingCallbackScreen({super.key});

  static const String routeName = AppRoutes.enableBankingCallback;

  @override
  State<EnableBankingCallbackScreen> createState() =>
      _EnableBankingCallbackScreenState();
}

class _EnableBankingCallbackScreenState extends State<EnableBankingCallbackScreen> {
  bool _saving = true;
  EnableBankingLinkStatus? _status;
  String? _parseError;
  bool _didInit = false;

  bool? _parseBool(String? v) {
    if (v == null) return null;
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _saveFromQuery();
  }

  Future<void> _saveFromQuery() async {
    try {
      final name = ModalRoute.of(context)?.settings.name ?? '';
      final uri = Uri.parse(name);
      final linked = _parseBool(uri.queryParameters['linked']);
      final sessionId = uri.queryParameters['session_id'];
      final error = uri.queryParameters['error'];

      await EnableBankingLinkStore.save(
        linked: linked,
        sessionId: sessionId,
        error: error,
      );
      _status = await EnableBankingLinkStore.load();
    } catch (e) {
      _parseError = e.toString();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _status?.linked == null
        ? 'Unknown'
        : (_status!.linked! ? 'Linked' : 'Not linked');

    return Scaffold(
      appBar: AppBar(title: const Text('Enable Banking Callback')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _saving
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Saving callback status...'),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Status: $label',
                              style: Theme.of(context).textTheme.titleLarge),
                          if (_status?.sessionId != null &&
                              _status!.sessionId!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('session_id: ${_status!.sessionId!}'),
                          ],
                          if (_status?.error != null &&
                              _status!.error!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('error: ${_status!.error!}',
                                style: TextStyle(color: cs.error)),
                          ],
                          if (_parseError != null) ...[
                            const SizedBox(height: 12),
                            Text('Parse error: $_parseError',
                                style: TextStyle(color: cs.error)),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Enable Banking'),
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.enableBanking,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
