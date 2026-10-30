import 'package:flutter/material.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/auth/auth_gate.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/domain/last_group_selection.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:provider/provider.dart';

/// Restores a business-scoped route after browser refresh drops route arguments.
class GroupRouteRecovery extends StatefulWidget {
  const GroupRouteRecovery({super.key, required this.routeName});

  final String routeName;

  @override
  State<GroupRouteRecovery> createState() => _GroupRouteRecoveryState();
}

class _GroupRouteRecoveryState extends State<GroupRouteRecovery> {
  bool _loading = true;
  bool _needsSignIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  Future<void> _restore() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      if (auth.currentUser == null) await auth.initialize();
      if (!mounted) return;
      final user = auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
          _needsSignIn = true;
        });
        return;
      }

      String? savedGroupId;
      try {
        savedGroupId = await LastGroupSelection.load(user.id);
      } catch (_) {
        // A single-business account can still recover without local storage.
      }
      final groupId = savedGroupId != null && savedGroupId.isNotEmpty
          ? savedGroupId
          : user.groupIds.length == 1
              ? user.groupIds.single
              : null;
      if (groupId == null || groupId.isEmpty) {
        throw StateError('No saved business');
      }
      if (!mounted) return;
      // Never trust local storage alone: fetch through the authenticated API.
      final groupDomain = context.read<GroupDomain>();
      final group = await groupDomain.groupRepository.getGroupById(groupId);
      if (!mounted) return;
      context.read<UserDomain>().setCurrentUser(user);
      groupDomain.setCurrentUser(user);
      groupDomain.currentGroup = group;
      Navigator.of(context).pushReplacementNamed(
        widget.routeName,
        arguments: group,
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsSignIn) return const AuthGate();
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(isEs ? 'Recuperando tu negocio…' : 'Restoring your business…'),
                ] else ...[
                  const Icon(Icons.business_outlined, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    isEs
                        ? 'No se pudo recuperar este negocio'
                        : 'Could not restore this business',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEs
                        ? 'Puede que ya no tengas acceso o que la conexión haya fallado.'
                        : 'You may no longer have access, or the connection may have failed.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _restore,
                    child: Text(isEs ? 'Reintentar' : 'Retry'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.splashRoute,
                      (_) => false,
                    ),
                    child: Text(isEs ? 'Elegir otro negocio' : 'Choose another business'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MissingRouteDataScreen extends StatelessWidget {
  const MissingRouteDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined, size: 40),
            const SizedBox(height: 12),
            Text(isEs ? 'No se puede restaurar esta pantalla' : 'This screen cannot be restored'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.splashRoute,
                (_) => false,
              ),
              child: Text(isEs ? 'Volver al inicio' : 'Return home'),
            ),
          ],
        ),
      ),
    );
  }
}
