import 'package:flutter/material.dart';
import 'package:hexora/models/groups/invitations/invite.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/invite/domain/invite_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:provider/provider.dart';

class InvitationLinkScreen extends StatefulWidget {
  const InvitationLinkScreen({required this.token, super.key});

  factory InvitationLinkScreen.fromRoute(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    final routeName = ModalRoute.of(context)?.settings.name;
    final routeToken = routeName == null
        ? null
        : Uri.tryParse(routeName)?.queryParameters['invitationToken'];
    final browserUri = Uri.base.fragment.startsWith('/')
        ? Uri.tryParse(Uri.base.fragment)
        : Uri.base;
    return InvitationLinkScreen(
      token: argument is String
          ? argument
          : routeToken ?? browserUri?.queryParameters['invitationToken'] ?? '',
    );
  }

  final String token;

  @override
  State<InvitationLinkScreen> createState() => _InvitationLinkScreenState();
}

class _InvitationLinkScreenState extends State<InvitationLinkScreen> {
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) {
      setState(() {
        _error = StateError('Missing invitation token');
        _loading = false;
      });
      return;
    }
    try {
      final data = await context.read<InvitationDomain>().resolveToken(widget.token);
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond({required bool accept}) async {
    final raw = _data?['invitation'];
    if (raw is! Map) return;
    final invitation = Invitation.fromJson(Map<String, dynamic>.from(raw));
    final es = Localizations.localeOf(context).languageCode == 'es';
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
              title: Text(accept
                  ? (es ? 'Aceptar invitación' : 'Accept invitation')
                  : (es ? 'Rechazar invitación' : 'Decline invitation')),
              content: Text(accept
                  ? (es
                      ? 'Te unirás a este negocio con el rol indicado.'
                      : 'You will join this business with the displayed role.')
                  : (es
                      ? 'La invitación quedará rechazada.'
                      : 'The invitation will be marked as declined.')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(es ? 'Cancelar' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(accept
                      ? (es ? 'Aceptar' : 'Accept')
                      : (es ? 'Rechazar' : 'Decline')),
                ),
              ],
            ),
          ) ??
          false;
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      final domain = context.read<InvitationDomain>();
      if (accept) {
        final accepted = await domain.acceptOrThrow(invitation.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(es ? 'Invitación aceptada.' : 'Invitation accepted.'),
        ));
        await _openAcceptedBusiness(accepted, es: es);
        return;
      } else {
        await domain.declineOrThrow(invitation.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(es ? 'Invitación rechazada.' : 'Invitation declined.'),
      ));
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homePage,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(es
            ? 'No se pudo actualizar la invitación.'
            : 'The invitation could not be updated.'),
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openAcceptedBusiness(
    Invitation invitation, {
    required bool es,
  }) async {
    try {
      final userDomain = context.read<UserDomain>();
      final groupDomain = context.read<GroupDomain>();
      await groupDomain.refreshGroupsForCurrentUser(userDomain);
      final group = await groupDomain.groupRepository.getGroupById(
        invitation.groupId,
      );
      if (!mounted) return;
      groupDomain.currentGroup = group;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.groupDashboard,
        (route) => false,
        arguments: {
          'group': group,
          'invitationOnboardingRole': invitation.role.wire,
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(es
            ? 'Te uniste al negocio, pero no se pudo abrir automáticamente.'
            : 'You joined the business, but it could not be opened automatically.'),
      ));
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homePage,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final group = _data?['group'];
    final invitation = _data?['invitation'];
    final groupMap = group is Map ? Map<String, dynamic>.from(group) : null;
    final invitationMap =
        invitation is Map ? Map<String, dynamic>.from(invitation) : null;
    final role = invitationMap?['role']?.toString() ?? 'member';
    final roleLabel = switch (role) {
      'admin' => es ? 'Administrador' : 'Administrator',
      'co-admin' => es ? 'Coadministrador' : 'Co-administrator',
      _ => es ? 'Miembro' : 'Member',
    };
    final roleDescription = switch (role) {
      'admin' => es
          ? 'Puede gestionar el negocio, sus miembros y su configuración.'
          : 'Can manage the business, its members, and its settings.',
      'co-admin' => es
          ? 'Puede ayudar a gestionar miembros y operaciones del negocio.'
          : 'Can help manage members and business operations.',
      _ => es
          ? 'Puede acceder y trabajar en las áreas permitidas del negocio.'
          : 'Can access and work in the permitted business areas.',
    };

    return Scaffold(
      appBar: AppBar(title: Text(es ? 'Invitación' : 'Invitation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? _ErrorState(onRetry: _load, spanish: es)
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(Icons.business_rounded, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                groupMap?['name']?.toString() ?? '',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if ((groupMap?['description']?.toString() ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  groupMap!['description'].toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Text(
                                '${es ? 'Rol' : 'Role'}: $roleLabel',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                roleDescription,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _respond(accept: true),
                                child: Text(es ? 'Aceptar invitación' : 'Accept invitation'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _respond(accept: false),
                                child: Text(es ? 'Rechazar' : 'Decline'),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.spanish});
  final VoidCallback onRetry;
  final bool spanish;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off_rounded, size: 48),
          const SizedBox(height: 12),
          Text(spanish
              ? 'El enlace no es válido, ha caducado o pertenece a otra cuenta.'
              : 'This link is invalid, expired, or belongs to another account.'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(spanish ? 'Reintentar' : 'Try again'),
          ),
        ],
      );
}
