part of '../mail_console_screen.dart';

class _MailAccountSetup extends StatefulWidget {
  const _MailAccountSetup({
    super.key,
    required this.groupId,
    required this.initialAccount,
    required this.error,
    required this.canCancel,
    required this.canManage,
    this.embedded = false,
    this.showEmbeddedHeader = true,
    required this.onCancel,
    required this.onSaved,
  });

  final String? groupId;
  final Map<String, dynamic>? initialAccount;
  final String? error;
  final bool canCancel;
  final bool canManage;
  final bool embedded;
  final bool showEmbeddedHeader;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onSaved;

  @override
  State<_MailAccountSetup> createState() => _MailAccountSetupState();
}

class _MailAccountSetupState extends State<_MailAccountSetup> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _displayName;
  late final TextEditingController _imapHost;
  late final TextEditingController _imapPort;
  late final TextEditingController _imapUser;
  late final TextEditingController _imapPassword;
  late final TextEditingController _smtpHost;
  late final TextEditingController _smtpPort;
  late final TextEditingController _smtpUser;
  late final TextEditingController _smtpPassword;
  late bool _imapSecure;
  late bool _smtpSecure;
  bool _saving = false;
  bool _showPasswords = false;
  String? _error;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';
  String _t(String es, String en) => _isSpanish ? es : en;

  @override
  void initState() {
    super.initState();
    final account = widget.initialAccount ?? const <String, dynamic>{};
    String value(String key, [String fallback = '']) =>
        account[key]?.toString() ?? fallback;
    _email = TextEditingController(text: value('emailAddress'));
    _displayName = TextEditingController(text: value('displayName'));
    _imapHost = TextEditingController(text: value('imapHost'));
    _imapPort = TextEditingController(text: value('imapPort', '993'));
    _imapUser = TextEditingController(text: value('imapUser'));
    _imapPassword = TextEditingController();
    _smtpHost = TextEditingController(text: value('smtpHost'));
    _smtpPort = TextEditingController(text: value('smtpPort', '465'));
    _smtpUser = TextEditingController(text: value('smtpUser'));
    _smtpPassword = TextEditingController();
    _imapSecure = account['imapSecure'] != false;
    _smtpSecure = account['smtpSecure'] != false;
    _error = widget.error;
  }

  @override
  void dispose() {
    for (final controller in [
      _email,
      _displayName,
      _imapHost,
      _imapPort,
      _imapUser,
      _imapPassword,
      _smtpHost,
      _smtpPort,
      _smtpUser,
      _smtpPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty)
      return _t('Campo obligatorio', 'Required field');
    return null;
  }

  String? _passwordValidator(String? value) {
    if (widget.initialAccount != null) return null;
    return _required(value);
  }

  String? _portValidator(String? value) {
    final port = int.tryParse((value ?? '').trim());
    if (port == null || port < 1 || port > 65535) {
      return _t('Puerto no válido', 'Invalid port');
    }
    return null;
  }

  void _applyProvider(String provider) {
    final isGmail = provider == 'gmail';
    setState(() {
      _imapHost.text = isGmail ? 'imap.gmail.com' : 'outlook.office365.com';
      _imapPort.text = '993';
      _smtpHost.text = isGmail ? 'smtp.gmail.com' : 'smtp.office365.com';
      _smtpPort.text = isGmail ? '465' : '587';
      _imapSecure = true;
      _smtpSecure = isGmail;
      if (_email.text.trim().isNotEmpty) {
        _imapUser.text = _email.text.trim();
        _smtpUser.text = _email.text.trim();
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final groupId = widget.groupId?.trim() ?? '';
    if (groupId.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? '${ApiConstants.baseUrl}/mail/account'
        : '${ApiConstants.baseUrl}/api/mail/account';
    try {
      final response = await AuthenticatedHttpClient.put(
        Uri.parse(base).replace(queryParameters: {'groupId': groupId}),
        client: context.read<http.Client>(),
        body: jsonEncode({
          'groupId': groupId,
          'emailAddress': _email.text.trim(),
          'displayName': _displayName.text.trim(),
          'imapHost': _imapHost.text.trim(),
          'imapPort': int.parse(_imapPort.text.trim()),
          'imapSecure': _imapSecure,
          'imapUser': _imapUser.text.trim(),
          if (_imapPassword.text.isNotEmpty) 'imapPassword': _imapPassword.text,
          'smtpHost': _smtpHost.text.trim(),
          'smtpPort': int.parse(_smtpPort.text.trim()),
          'smtpSecure': _smtpSecure,
          'smtpUser': _smtpUser.text.trim(),
          if (_smtpPassword.text.isNotEmpty) 'smtpPassword': _smtpPassword.text,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = response.body;
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] != null)
            message = body['error'].toString();
        } catch (_) {}
        throw Exception(message);
      }
      final decoded = jsonDecode(response.body);
      widget.onSaved((decoded as Map).cast<String, dynamic>());
    } catch (error) {
      if (mounted)
        setState(
            () => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool password = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: widget.canManage && !_saving,
      obscureText: password && !_showPasswords,
      keyboardType: keyboardType,
      validator: validator ?? _required,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: password
            ? IconButton(
                onPressed: () =>
                    setState(() => _showPasswords = !_showPasswords),
                icon: Icon(
                    _showPasswords ? Icons.visibility_off : Icons.visibility),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!widget.canManage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _t('Un administrador de este negocio debe configurar la cuenta de correo.',
                'A business administrator must configure the email account.'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _t('Conecta una cuenta que pertenezca a este negocio. Los mensajes solo estarán disponibles dentro de este negocio.',
                    'Connect an account owned by this business. Its messages will only be available inside this business.'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _applyProvider('gmail'),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Gmail'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _applyProvider('outlook'),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Microsoft 365'),
                ),
              ]),
              const SizedBox(height: 20),
              _field(_email, _t('Correo del negocio', 'Business email'),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_displayName, _t('Nombre del remitente', 'Sender name'),
                  validator: (_) => null),
              const SizedBox(height: 24),
              Text('IMAP', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _field(_imapHost, _t('Servidor IMAP', 'IMAP host')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(_imapPort, _t('Puerto IMAP', 'IMAP port'),
                        keyboardType: TextInputType.number,
                        validator: _portValidator)),
                const SizedBox(width: 12),
                Expanded(
                    child: SwitchListTile(
                  value: _imapSecure,
                  onChanged: (value) => setState(() => _imapSecure = value),
                  title: Text(_t('Conexión segura', 'Secure connection')),
                )),
              ]),
              const SizedBox(height: 12),
              _field(_imapUser, _t('Usuario IMAP', 'IMAP username')),
              const SizedBox(height: 12),
              _field(_imapPassword, _t('Contraseña IMAP', 'IMAP password'),
                  password: true, validator: _passwordValidator),
              const SizedBox(height: 24),
              Text('SMTP', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _field(_smtpHost, _t('Servidor SMTP', 'SMTP host')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(_smtpPort, _t('Puerto SMTP', 'SMTP port'),
                        keyboardType: TextInputType.number,
                        validator: _portValidator)),
                const SizedBox(width: 12),
                Expanded(
                    child: SwitchListTile(
                  value: _smtpSecure,
                  onChanged: (value) => setState(() => _smtpSecure = value),
                  title: Text(_t('Conexión segura', 'Secure connection')),
                )),
              ]),
              const SizedBox(height: 12),
              _field(_smtpUser, _t('Usuario SMTP', 'SMTP username')),
              const SizedBox(height: 12),
              _field(_smtpPassword, _t('Contraseña SMTP', 'SMTP password'),
                  password: true, validator: _passwordValidator),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(_saving
                    ? _t('Verificando...', 'Verifying...')
                    : _t('Verificar y guardar', 'Verify and save')),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showEmbeddedHeader)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.canCancel)
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _t('Cuenta de correo del negocio',
                            'Business email account'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: widget.canCancel
            ? IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title:
            Text(_t('Cuenta de correo del negocio', 'Business email account')),
      ),
      body: body,
    );
  }
}
