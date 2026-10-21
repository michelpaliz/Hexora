import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';

/// Provisions credentials for existing active employee records; it never creates
/// a replacement employee or retains a temporary password in widget state.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
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
          Text('Worker account setup',
              style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Give active employees a username and a temporary password. They will be required to change it on first sign-in.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
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
                    title: Text(worker.displayName ?? 'Unnamed worker'),
                    subtitle: const Text('No sign-in account'),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => _setup(worker),
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Set up'),
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
          const Text('All active workers have accounts.'),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ]),
      ));
}

class _WorkerAccountSetupSheet extends StatefulWidget {
  final Group group;
  final Worker worker;
  const _WorkerAccountSetupSheet({required this.group, required this.worker});
  @override
  State<_WorkerAccountSetupSheet> createState() =>
      _WorkerAccountSetupSheetState();
}

class _WorkerAccountSetupSheetState extends State<_WorkerAccountSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username =
      TextEditingController(text: _suggestUsername());
  final _password = TextEditingController();
  String _role = 'worker';
  bool _saving = false;

  String _suggestUsername() {
    final raw = (widget.worker.displayName ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '');
    return raw.length <= 40 ? raw : raw.substring(0, 40);
  }

  @override
  void dispose() {
    _username.dispose();
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
        widget.worker.id,
        token,
        employeeName: widget.worker.displayName ?? 'Worker',
        username: _username.text.trim(),
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
        child: Form(
            key: _formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set up ${widget.worker.displayName ?? 'worker'}'),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _username,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) => RegExp(r'^[a-z0-9._-]{3,40}$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Use 3–40 lowercase letters, numbers, dots, underscores, or hyphens.'),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _password,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          labelText: 'Temporary password'),
                      validator: (value) => (value?.length ?? 0) >= 8
                          ? null
                          : 'Use at least 8 characters.'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                            value: 'worker', child: Text('Worker')),
                        DropdownMenuItem(
                            value: 'supervisor', child: Text('Supervisor')),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) =>
                              setState(() => _role = value ?? 'worker')),
                  const SizedBox(height: 8),
                  const Text(
                      'The worker must change this password on their first login.'),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: Text(_saving ? 'Creating…' : 'Create account'),
                      )),
                ])),
      ));
}
