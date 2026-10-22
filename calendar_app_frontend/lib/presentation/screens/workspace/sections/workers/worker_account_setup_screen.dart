import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';

/// Provisions an account for a new or existing worker.
class WorkerAccountSetupScreen extends StatefulWidget {
  final Group group;
  const WorkerAccountSetupScreen({super.key, required this.group});

  @override
  State<WorkerAccountSetupScreen> createState() =>
      _WorkerAccountSetupScreenState();
}

class _WorkerAccountSetupScreenState extends State<WorkerAccountSetupScreen> {
  List<Worker> _workers = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userDomain = context.read<UserDomain>();
      final repository = context.read<ITimeTrackingRepository>();
      final token = await userDomain.getAuthToken();
      final workers = await repository.getWorkers(
        widget.group.id,
        token,
        status: WorkerStatus.active,
      );
      if (mounted) setState(() => _workers = workers);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setup(Worker worker) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _WorkerAccountSetupSheet(group: widget.group, worker: worker),
    );
    if (created == true) {
      _load();
    }
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WorkerAccountSetupSheet(group: widget.group),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final userId = context.watch<UserDomain>().user?.id;
    final role = widget.group.userRoles[userId]?.toLowerCase();
    if (userId == null ||
        (widget.group.ownerId != userId &&
            role != 'owner' &&
            role != 'admin' &&
            role != 'co-admin')) {
      return const Center(
          child: Text(
              'Solo administradores pueden crear cuentas de trabajadores.'));
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child:
              FilledButton.tonal(onPressed: _load, child: const Text('Retry')));
    }
    final pending = _workers.where((worker) => !worker.hasAccount).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Cuentas de trabajadores',
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Crea un trabajador con acceso, o añade acceso a uno existente. Podrá entrar con su correo y contraseña.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Crear trabajador con acceso'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Trabajadores sin cuenta', style: t.titleLarge),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            _EmptyState(onRefresh: _load)
          else
            ...pending.map((worker) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text((worker.displayName ?? '?')
                            .characters
                            .first
                            .toUpperCase())),
                    title: Text(worker.displayName ?? 'Trabajador'),
                    subtitle: const Text('Sin cuenta de acceso'),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => _setup(worker),
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Crear acceso'),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_user_outlined, size: 42),
          const SizedBox(height: 10),
          const Text('Todos los trabajadores activos tienen cuenta.'),
          TextButton(onPressed: onRefresh, child: const Text('Actualizar')),
        ]),
      ));
}

class _WorkerAccountSetupSheet extends StatefulWidget {
  final Group group;
  final Worker? worker;
  const _WorkerAccountSetupSheet({required this.group, this.worker});
  @override
  State<_WorkerAccountSetupSheet> createState() =>
      _WorkerAccountSetupSheetState();
}

class _WorkerAccountSetupSheetState extends State<_WorkerAccountSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'worker';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userDomain = context.read<UserDomain>();
      final repository = context.read<ITimeTrackingRepository>();
      final token = await userDomain.getAuthToken();
      await repository.createWorkerAccount(
        widget.group.id,
        widget.worker?.id,
        token,
        employeeName: widget.worker?.displayName?.trim().isNotEmpty == true
            ? widget.worker!.displayName!.trim()
            : _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        temporaryPassword: _password.text,
        role: _role,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.worker == null
                          ? 'Crear trabajador con acceso'
                          : 'Crear acceso para ${widget.worker!.displayName ?? 'trabajador'}'),
                      const SizedBox(height: 16),
                      if (widget.worker?.displayName?.trim().isNotEmpty !=
                          true) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                              const InputDecoration(labelText: 'Nombre'),
                          validator: (value) =>
                              (value?.trim().isNotEmpty == true &&
                                      value!.trim().length <= 120)
                                  ? null
                                  : 'Introduce un nombre válido.',
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                          controller: _email,
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Correo electrónico'),
                          validator: (value) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value?.trim() ?? '')
                                  ? null
                                  : 'Introduce un correo válido.'),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _password,
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                              labelText: 'Contraseña temporal'),
                          validator: (value) => (value?.length ?? 0) >= 8 &&
                                  (value?.length ?? 0) <= 128
                              ? null
                              : 'Usa entre 8 y 128 caracteres.'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: const [
                            DropdownMenuItem(
                                value: 'worker', child: Text('Trabajador')),
                            DropdownMenuItem(
                                value: 'supervisor', child: Text('Supervisor')),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) =>
                                  setState(() => _role = value ?? 'worker')),
                      const SizedBox(height: 8),
                      const Text(
                          'El trabajador deberá cambiar esta contraseña al iniciar sesión por primera vez.'),
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _submit,
                            child: Text(_saving ? 'Creando…' : 'Crear cuenta'),
                          )),
                    ]))),
      ));
}
