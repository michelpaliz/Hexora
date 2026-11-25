import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/widgets/images/group_image.dart';
import 'package:hexora/presentation/viewmodels/groups/group_view_model.dart';
import 'package:hexora/presentation/viewmodels/groups/ui_messenger.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/create_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/invite_members_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/search_users_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/update_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:provider/provider.dart';

class _TeamInviteDraft {
  _TeamInviteDraft() : email = TextEditingController();

  final TextEditingController email;
  String role = 'member';
}

class CreateGroupData extends StatefulWidget {
  const CreateGroupData({super.key});

  @override
  State<CreateGroupData> createState() => _CreateGroupDataState();
}

class _CreateGroupDataState extends State<CreateGroupData> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _legalName = TextEditingController();
  final _taxId = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();

  int _step = 0;
  String? _businessType;
  String _invoiceLanguage = 'es';
  String _currency = 'EUR';
  double _vatRate = 21;
  final List<_TeamInviteDraft> _invites = [_TeamInviteDraft()];

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final es = _isSpanish;
      _country.text = es ? 'España' : 'Spain';
      _invoiceLanguage = es ? 'es' : 'en';
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _legalName,
      _taxId,
      _street,
      _city,
      _province,
      _postalCode,
      _country,
      _email,
      _website,
    ]) {
      controller.dispose();
    }
    for (final invite in _invites) {
      invite.email.dispose();
    }
    super.dispose();
  }

  String _t(String es, String en) => _isSpanish ? es : en;

  bool _canContinue() {
    if (_step == 0) {
      return _name.text.trim().isNotEmpty && _businessType != null;
    }
    if (_step == 1) {
      return [
        _legalName,
        _taxId,
        _street,
        _city,
        _postalCode,
        _country,
      ].every((controller) => controller.text.trim().isNotEmpty);
    }
    if (_step == 3) {
      final emails = _invites
          .map((invite) => invite.email.text.trim().toLowerCase())
          .where((email) => email.isNotEmpty)
          .toList();
      return emails.every(_isValidEmail) && emails.toSet().length == emails.length;
    }
    return true;
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  void _next() {
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Completa los campos obligatorios.',
            'Complete the required fields.',
          )),
        ),
      );
      return;
    }
    setState(() => _step += 1);
  }

  Future<void> _create(GroupEditorViewModel vm) async {
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Revisa los correos. No pueden estar repetidos.',
            'Check the email addresses. Duplicates are not allowed.',
          )),
        ),
      );
      return;
    }
    vm
      ..setName(_name.text)
      ..setDescription(_description.text)
      ..configureBusinessSetup(
        businessType: _businessType!,
        legalName: _legalName.text,
        taxId: _taxId.text,
        addressStreet: _street.text,
        addressCity: _city.text,
        addressProvince: _province.text,
        addressPostalCode: _postalCode.text,
        addressCountry: _country.text,
        businessEmail: _email.text,
        website: _website.text,
        currency: _currency,
        vatRate: _vatRate,
        invoiceLanguage: _invoiceLanguage,
      )
      ..configureTeamInvitations(
        _invites
            .where((invite) => invite.email.text.trim().isNotEmpty)
            .map((invite) => {
                  'email': invite.email.text,
                  'role': invite.role,
                })
            .toList(),
      );
    await vm.submitGroupFromUI();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserDomain>().user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider<GroupEditorViewModel>(
      create: (c) => GroupEditorViewModel(
        currentUser: currentUser,
        ui: MaterialUiMessenger(context),
        createGroup: c.read<CreateGroupUseCase>(),
        inviteMembers: c.read<InviteMembersUseCase>(),
        uploadPhoto: c.read<UploadGroupPhotoUseCase>(),
        searchUsersUseCase: c.read<SearchUsersUseCase>(),
        updateGroup: c.read<UpdateGroupUseCase>(),
      ),
      child: Builder(
        builder: (context) {
          final vm = context.watch<GroupEditorViewModel>();
          final content = _wizard(context, vm);
          final isWide = kIsWeb || MediaQuery.of(context).size.width >= 900;
          if (!isWide) {
            return Scaffold(
              appBar:
                  AppBar(title: Text(_t('Crear negocio', 'Create business'))),
              body: content,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 24),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wizard(BuildContext context, GroupEditorViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          color: cs.primary.withValues(alpha: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.domain_add_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(
                    _t('Crear negocio', 'Create business'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _progress(context),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: [
                  _identityStep(vm),
                  _legalStep(),
                  _invoiceStep(),
                  _teamStep(),
                ][_step],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              if (_step > 0)
                OutlinedButton.icon(
                  onPressed: vm.isSubmitting
                      ? null
                      : () => setState(() => _step -= 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(_t('Atrás', 'Back')),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: vm.isSubmitting
                    ? null
                    : _step < 3
                        ? _next
                        : () => _create(vm),
                icon: vm.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _step < 3
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                      ),
                label: Text(
                  _step < 3
                      ? _t('Continuar', 'Continue')
                      : _t('Crear negocio', 'Create business'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progress(BuildContext context) {
    final labels = _isSpanish
        ? ['Identidad', 'Datos fiscales', 'Facturación', 'Equipo']
        : ['Identity', 'Legal details', 'Invoicing', 'Team'];
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= _step;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    active ? cs.primary : cs.surfaceContainerHigh,
                foregroundColor:
                    active ? cs.onPrimary : cs.onSurfaceVariant,
                child:
                    Text('${index + 1}', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  labels[index],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (index < labels.length - 1)
                Container(
                  width: 18,
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: active ? cs.primary : cs.outlineVariant,
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _identityStep(GroupEditorViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          _t('Identidad del negocio', 'Business identity'),
          _t(
            'Añade la información que ayudará a identificar tu espacio.',
            'Add the information used to identify your workspace.',
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              GroupImage(onPicked: vm.setImage),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Logo opcional · también aparecerá en tus facturas',
                  'Optional logo · it will also appear on invoices',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _field(
          _name,
          _t('Nombre del negocio', 'Business name'),
          required: true,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _businessType,
          decoration: _decoration(_t('Tipo de negocio *', 'Business type *')),
          items: _businessTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type.$1,
                  child: Text(_isSpanish ? type.$2 : type.$3),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _businessType = value),
        ),
        const SizedBox(height: 14),
        _field(
          _description,
          _t('Descripción (opcional)', 'Description (optional)'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _legalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          _t('Datos fiscales y contacto', 'Legal and contact details'),
          _t(
            'Estos datos se usarán como emisor en facturas y presupuestos.',
            'These details identify the issuer on invoices and estimates.',
          ),
        ),
        _field(
          _legalName,
          _t('Razón social', 'Legal name'),
          required: true,
        ),
        const SizedBox(height: 14),
        _field(
          _taxId,
          _t('CIF / NIF / VAT', 'Tax ID / VAT number'),
          required: true,
        ),
        const SizedBox(height: 14),
        _field(
          _street,
          _t('Dirección', 'Street address'),
          required: true,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(
                _city,
                _t('Ciudad', 'City'),
                required: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _postalCode,
                _t('Código postal', 'Postal code'),
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(
                _province,
                _t('Provincia (opcional)', 'Region (optional)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _country,
                _t('País', 'Country'),
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(
                _email,
                _t(
                  'Correo del negocio (opcional)',
                  'Business email (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _website,
                _t('Página web (opcional)', 'Website (optional)'),
                keyboardType: TextInputType.url,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _invoiceStep() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          _t('Preferencias de facturación', 'Invoice preferences'),
          _t(
            'Elige los valores iniciales para los documentos de este negocio.',
            'Choose the initial defaults for this business documents.',
          ),
        ),
        DropdownButtonFormField<String>(
          value: _invoiceLanguage,
          decoration:
              _decoration(_t('Idioma de las facturas', 'Invoice language')),
          items: const [
            DropdownMenuItem(value: 'es', child: Text('Español')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) =>
              setState(() => _invoiceLanguage = value ?? 'es'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: _decoration(_t('Moneda', 'Currency')),
                items: const ['EUR', 'USD', 'GBP']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _currency = value ?? 'EUR'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<double>(
                value: _vatRate,
                decoration:
                    _decoration(_t('IVA predeterminado', 'Default VAT')),
                items: const [0.0, 4.0, 10.0, 21.0]
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text('${value.toInt()}%'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _vatRate = value ?? 21),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(
                    'Podrás editar estos datos más adelante desde la configuración del negocio y los datos de facturación.',
                    'You can edit these details later from Business settings and Invoice company details.',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _summaryRow(_t('Negocio', 'Business'), _name.text),
        _summaryRow(_t('Razón social', 'Legal name'), _legalName.text),
        _summaryRow(_t('Identificación fiscal', 'Tax ID'), _taxId.text),
        _summaryRow(
          _t('Idioma', 'Language'),
          _invoiceLanguage == 'es' ? 'Español' : 'English',
        ),
      ],
    );
  }

  Widget _teamStep() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          _t('Invita a tu equipo', 'Invite your team'),
          _t(
            'Este paso es opcional. También podrás invitar personas más tarde desde Configuración → Miembros.',
            'This step is optional. You can also invite people later from Settings → Members.',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mark_email_unread_outlined, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t(
                    'Si todavía no tienen cuenta, deberán registrarse con el mismo correo para aceptar la invitación.',
                    'If they do not have an account yet, they must register with the same email address to accept the invitation.',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(_invites.length, (index) {
          final invite = _invites[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: invite.email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(_t('Correo electrónico', 'Email address')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: invite.role,
                    decoration: _decoration(_t('Rol', 'Role')),
                    items: [
                      DropdownMenuItem(
                        value: 'member',
                        child: Text(_t('Miembro', 'Member')),
                      ),
                      DropdownMenuItem(
                        value: 'co-admin',
                        child: Text(_t('Co-administrador', 'Co-admin')),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(_t('Administrador', 'Admin')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => invite.role = value ?? 'member'),
                  ),
                ),
                if (_invites.length > 1) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: _t('Eliminar invitación', 'Remove invitation'),
                    onPressed: () {
                      invite.email.dispose();
                      setState(() => _invites.removeAt(index));
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _invites.add(_TeamInviteDraft())),
          icon: const Icon(Icons.add_rounded),
          label: Text(_t('Añadir otra persona', 'Add another person')),
        ),
        const SizedBox(height: 16),
        Text(
          _t(
            'Puedes dejar los correos vacíos para omitir este paso.',
            'Leave the email fields empty to skip this step.',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _decoration(required ? '$label *' : label),
      );

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(value.trim().isEmpty ? '—' : value.trim())),
          ],
        ),
      );

  static const _businessTypes = <(String, String, String)>[
    ('gardening', 'Jardinería y piscinas', 'Gardening and pools'),
    ('maintenance', 'Mantenimiento', 'Maintenance'),
    ('cleaning', 'Limpieza', 'Cleaning'),
    ('construction', 'Construcción', 'Construction'),
    (
      'professional_services',
      'Servicios profesionales',
      'Professional services'
    ),
    ('retail', 'Comercio', 'Retail'),
    ('hospitality', 'Hostelería', 'Hospitality'),
    ('education', 'Educación', 'Education'),
    ('health', 'Salud', 'Healthcare'),
    ('technology', 'Tecnología', 'Technology'),
    ('other', 'Otro', 'Other'),
  ];
}
