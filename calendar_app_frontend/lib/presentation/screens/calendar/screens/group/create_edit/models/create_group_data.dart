import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  AutovalidateMode _validation = AutovalidateMode.disabled;
  XFile? _logo;
  Uint8List? _logoBytes;
  bool _pickingLogo = false;
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
    _scroll.dispose();
    super.dispose();
  }

  String _t(String es, String en) => _isSpanish ? es : en;

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  bool _validate() {
    setState(() => _validation = AutovalidateMode.onUserInteraction);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FormFieldState<dynamic>? firstInvalid;
        void visit(Element element) {
          if (element is StatefulElement && element.state is FormFieldState) {
            final field = element.state as FormFieldState<dynamic>;
            if (field.hasError) firstInvalid ??= field;
          }
          element.visitChildren(visit);
        }

        _formKey.currentContext?.visitChildElements(visit);
        if (firstInvalid != null) {
          Scrollable.ensureVisible(firstInvalid!.context,
              duration: const Duration(milliseconds: 250), alignment: 0.15);
        }
      });
    }
    return valid;
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _validation = AutovalidateMode.disabled;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _next() {
    if (_validate()) _goTo(_step + 1);
  }

  Future<void> _pickLogo() async {
    setState(() => _pickingLogo = true);
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _logo = file;
          _logoBytes = bytes;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t('No se pudo abrir la imagen. Inténtalo de nuevo.',
                'Could not open the image. Please try again.'))));
      }
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
    }
  }

  Future<void> _create(GroupEditorViewModel vm) async {
    if (!_validate()) return;
    vm.setImage(_logo);
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
          final isWide = MediaQuery.sizeOf(context).width >= 700;
          if (!isWide) {
            return Scaffold(
              body: SafeArea(child: SizedBox.expand(child: content)),
            );
          }
          return LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 760,
                  maxHeight: constraints.maxHeight,
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: content,
                ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          color: cs.primary.withValues(alpha: 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.domain_add_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                    _t('Crear negocio', 'Create business'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  )),
                  IconButton(
                    tooltip: _t('Cerrar', 'Close'),
                    onPressed: vm.isSubmitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _progress(context),
            ],
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: AbsorbPointer(
            absorbing: vm.isSubmitting,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Form(
                key: _formKey,
                autovalidateMode: _validation,
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _identityStep(vm),
                    1 => _legalStep(),
                    2 => _invoiceStep(),
                    _ => _teamStep(),
                  },
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: _footer(context, vm),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, GroupEditorViewModel vm) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final stepText = Text(
            _t('Paso ${_step + 1} de 4', 'Step ${_step + 1} of 4'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          );
          final cancel = TextButton(
            onPressed:
                vm.isSubmitting ? null : () => Navigator.of(context).maybePop(),
            child: Text(_t('Cancelar', 'Cancel')),
          );
          final back = _step == 0
              ? null
              : OutlinedButton.icon(
                  onPressed: vm.isSubmitting ? null : () => _goTo(_step - 1),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(_t('Atrás', 'Back')),
                );
          final primary = FilledButton(
            onPressed: vm.isSubmitting
                ? null
                : _step < 3
                    ? _next
                    : () => _create(vm),
            style: FilledButton.styleFrom(minimumSize: const Size(140, 42)),
            child: vm.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _step < 3
                            ? _t('Continuar', 'Continue')
                            : _t('Crear negocio', 'Create business'),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _step < 3
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          );
          final skip = _step == 3
              ? TextButton(
                  onPressed: vm.isSubmitting ? null : () => _create(vm),
                  child: Text(_t('Omitir equipo', 'Skip team')),
                )
              : null;

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [stepText, const Spacer(), cancel]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (back != null) back,
                    if (back != null && skip != null) const SizedBox(width: 8),
                    if (skip != null) skip,
                  ],
                ),
                if (back != null || skip != null) const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: primary),
              ],
            );
          }

          return Row(
            children: [
              stepText,
              const Spacer(),
              cancel,
              if (skip != null) skip,
              if (back != null) ...[const SizedBox(width: 8), back],
              const SizedBox(width: 8),
              primary,
            ],
          );
        },
      );

  Widget _progress(BuildContext context) {
    final labels = _isSpanish
        ? ['Identidad', 'Datos fiscales', 'Facturación', 'Equipo']
        : ['Identity', 'Legal details', 'Invoicing', 'Team'];
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 560) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${_t('Paso ${_step + 1} de 4', 'Step ${_step + 1} of 4')} · ${labels[_step]}',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: (_step + 1) / 4,
              minHeight: 4,
              borderRadius: BorderRadius.circular(8)),
        ]);
      }
      return Row(
          children: List.generate(labels.length, (index) {
        final active = index == _step;
        final complete = index < _step;
        return Expanded(
            child: TextButton(
          onPressed:
              complete && !context.read<GroupEditorViewModel>().isSubmitting
                  ? () => _goTo(index)
                  : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            backgroundColor: active
                ? cs.primaryContainer.withValues(alpha: 0.7)
                : Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      active || complete ? cs.primary : cs.surfaceContainerHigh,
                  foregroundColor:
                      active || complete ? cs.onPrimary : cs.onSurfaceVariant,
                  child: complete
                      ? const Icon(Icons.check_rounded, size: 14)
                      : Text('${index + 1}',
                          style: const TextStyle(fontSize: 11))),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(labels[index],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: active ? cs.primary : cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500))),
            ]),
            const SizedBox(height: 6),
            Container(
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: active || complete
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ]),
        ));
      }));
    });
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
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _logoBytes == null
                ? Container(
                    width: 64,
                    height: 64,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.storefront_outlined,
                        size: 28,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer))
                : Image.memory(_logoBytes!,
                    width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_t('Logo del negocio', 'Business logo'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                    _t('Opcional · visible en tus facturas',
                        'Optional · shown on your invoices'),
                    style: Theme.of(context).textTheme.bodySmall),
                Wrap(spacing: 4, children: [
                  TextButton.icon(
                      onPressed: _pickingLogo ? null : _pickLogo,
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 18),
                      label: Text(_pickingLogo
                          ? _t('Abriendo…', 'Opening…')
                          : _logo == null
                              ? _t('Añadir logo', 'Add logo')
                              : _t('Cambiar', 'Change'))),
                  if (_logo != null)
                    TextButton(
                        onPressed: () => setState(() {
                              _logo = null;
                              _logoBytes = null;
                            }),
                        child: Text(_t('Eliminar', 'Remove'))),
                ]),
              ])),
        ]),
        const SizedBox(height: 20),
        _field(
          _name,
          _t('Nombre del negocio', 'Business name'),
          required: true,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _businessType,
          isExpanded: true,
          validator: (value) => value == null
              ? _t('Selecciona un tipo de negocio.', 'Choose a business type.')
              : null,
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
          minLines: 2,
          maxLines: 4,
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
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _legalName.text = _name.text.trim()),
              icon: const Icon(Icons.copy_outlined, size: 16),
              label:
                  Text(_t('Usar el nombre del negocio', 'Use business name')),
            )),
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
        _paired(
            _field(
              _city,
              _t('Ciudad', 'City'),
              required: true,
            ),
            _field(
              _postalCode,
              _t('Código postal', 'Postal code'),
              required: true,
            )),
        const SizedBox(height: 14),
        _paired(
            _field(
              _province,
              _t('Provincia (opcional)', 'Region (optional)'),
            ),
            _field(
              _country,
              _t('País', 'Country'),
              required: true,
            )),
        const SizedBox(height: 14),
        _paired(
            _field(
              _email,
              _t(
                'Correo del negocio (opcional)',
                'Business email (optional)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            _field(
              _website,
              _t('Página web (opcional)', 'Website (optional)'),
              keyboardType: TextInputType.url,
            )),
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
            "Choose the default settings for your business documents.",
          ),
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _invoiceLanguage,
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
        _paired(
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: _decoration(_t('Moneda', 'Currency')),
              items: const ['EUR', 'USD', 'GBP']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _currency = value ?? 'EUR'),
            ),
            DropdownButtonFormField<double>(
              initialValue: _vatRate,
              decoration: _decoration(_t('IVA predeterminado', 'Default VAT')),
              items: const [0.0, 4.0, 10.0, 21.0]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('${value.toInt()}%'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _vatRate = value ?? 21),
            )),
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
        const SizedBox(height: 20),
        _section(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('Ejemplo de cálculo', 'Example calculation'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
              _t('Vista orientativa con una base de 100.',
                  'Illustration using a base amount of 100.'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _summaryRow(_t('Base imponible', 'Subtotal'), '100.00 $_currency'),
          _summaryRow('IVA / VAT (${_vatRate.toInt()}%)',
              '${_vatRate.toStringAsFixed(2)} $_currency'),
          const Divider(),
          _summaryRow(_t('Total', 'Total'),
              '${(100 + _vatRate).toStringAsFixed(2)} $_currency'),
        ])),
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
            key: ObjectKey(invite),
            padding: const EdgeInsets.only(bottom: 16),
            child: _section(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(
                            _t('Persona ${index + 1}', 'Person ${index + 1}'),
                            style: Theme.of(context).textTheme.titleSmall)),
                    IconButton(
                        tooltip: _t('Eliminar invitación', 'Remove invitation'),
                        onPressed: () {
                          setState(() => _invites.removeAt(index));
                          // Dispose after the field has unmounted.
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => invite.email.dispose());
                        },
                        icon: const Icon(Icons.close_rounded, size: 20)),
                  ]),
                  const SizedBox(height: 8),
                  _paired(
                    TextFormField(
                      controller: invite.email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: _decoration(
                          _t('Correo electrónico', 'Email address')),
                      validator: (value) {
                        final email = (value ?? '').trim().toLowerCase();
                        if (email.isEmpty) return null;
                        if (!_isValidEmail(email)) {
                          return _t('Introduce un correo válido.',
                              'Enter a valid email address.');
                        }
                        if (_invites
                                .where((other) =>
                                    other.email.text.trim().toLowerCase() ==
                                    email)
                                .length >
                            1) {
                          return _t('Este correo ya está en la lista.',
                              'This email is already in the list.');
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: invite.role,
                      isExpanded: true,
                      decoration: _decoration(_t('Rol', 'Role')),
                      items: [
                        DropdownMenuItem(
                            value: 'member',
                            child: Text(_t('Miembro', 'Member'))),
                        DropdownMenuItem(
                            value: 'co-admin',
                            child: Text(_t('Co-administrador', 'Co-admin'))),
                        DropdownMenuItem(
                            value: 'admin',
                            child: Text(_t('Administrador', 'Admin'))),
                      ],
                      onChanged: (value) =>
                          setState(() => invite.role = value ?? 'member'),
                    ),
                  ),
                ])),
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
        const SizedBox(height: 24),
        _section(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t('Revisa tu negocio', 'Review your business'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _summaryRow(_t('Negocio', 'Business'), _name.text),
          _summaryRow(_t('Razón social', 'Legal name'), _legalName.text),
          _summaryRow(_t('NIF / CIF', 'Tax ID'), _taxId.text),
          _summaryRow(_t('Dirección', 'Address'),
              '${_street.text}, ${_postalCode.text} ${_city.text}, ${_country.text}'),
          _summaryRow(_t('Facturación', 'Invoicing'),
              '$_currency · ${_vatRate.toInt()}% IVA / VAT · ${_invoiceLanguage == 'es' ? 'Español' : 'English'}'),
          Wrap(spacing: 8, children: [
            TextButton(
                onPressed: () => _goTo(0),
                child: Text(_t('Editar identidad', 'Edit identity'))),
            TextButton(
                onPressed: () => _goTo(1),
                child: Text(_t('Editar datos fiscales', 'Edit legal details'))),
            TextButton(
                onPressed: () => _goTo(2),
                child: Text(_t('Editar facturación', 'Edit invoicing'))),
          ]),
        ])),
      ],
    );
  }

  Widget _heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
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
    int? minLines,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        validator: (value) {
          final text = (value ?? '').trim();
          if (required && text.isEmpty) {
            return _t('Completa este campo.', 'This field is required.');
          }
          if (keyboardType == TextInputType.emailAddress &&
              text.isNotEmpty &&
              !_isValidEmail(text)) {
            return _t(
                'Introduce un correo válido.', 'Enter a valid email address.');
          }
          return null;
        },
        decoration: _decoration(required ? '$label *' : label),
      );

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorMaxLines: 3,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      );

  Widget _section({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      );

  Widget _paired(Widget first, Widget second) => LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 560
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [first, const SizedBox(height: 14), second])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: first),
                const SizedBox(width: 14),
                Expanded(child: second)
              ]),
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
