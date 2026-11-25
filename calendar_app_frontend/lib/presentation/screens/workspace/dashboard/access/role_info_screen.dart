import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/screens/workspace/sections/role_info/role_capability_summaries.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_avatar.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';

typedef SasFetcher = Future<String?> Function(String blobName);

/// Compact role and permissions information for the current business member.
/// Capabilities remain sourced from the existing role model; this is presentation only.
class RoleInfoScreen extends StatelessWidget {
  const RoleInfoScreen({
    super.key,
    required this.group,
    required this.user,
    required this.role,
    required this.fetchReadSas,
  });

  final Group group;
  final User user;
  final GroupRole role;
  final SasFetcher fetchReadSas;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final roleLabel = roleLabelOf(context, role);
    final capabilities = roleCapabilitySummaries(role, l);
    final isSpanish = l.localeName.toLowerCase().startsWith('es');
    final key = _roleKey(role);
    final categories =
        _categories(capabilities, key: key, isSpanish: isSpanish);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isSpanish ? 'Mi rol y permisos' : 'My role and permissions'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              UserAvatar(user: user, fetchReadSas: fetchReadSas, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (_username(user) != null)
                      Text(
                        _username(user)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              _RoleBadge(role: role, label: roleLabel),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.symmetric(
                  horizontal: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.business_rounded, size: 19, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AccessSummary(
            title: key == 'owner'
                ? (isSpanish ? 'Acceso completo' : 'Full access')
                : (isSpanish ? 'Acceso según tu rol' : 'Role-based access'),
            description: key == 'owner'
                ? (isSpanish
                    ? 'Puedes administrar la configuración, facturación, miembros y operaciones del negocio.'
                    : 'You can manage the business settings, billing, members, and operations.')
                : (isSpanish
                    ? 'Puedes realizar las acciones permitidas para tu rol en este negocio.'
                    : 'You can perform the actions allowed by your role in this business.'),
          ),
          const SizedBox(height: 20),
          Text(
            isSpanish ? 'Permisos' : 'Permissions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ...categories.map(
            (category) => _PermissionGroup(
              title: category.title,
              items: category.items,
              sensitive: category.sensitive,
            ),
          ),
        ],
      ),
    );
  }

  static String _roleKey(GroupRole role) =>
      role.wire.toLowerCase().replaceAll('-', '').replaceAll('_', '');

  static String _displayName(User user) {
    for (final value in [user.displayName, user.name, user.userName]) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    final email = user.email.trim();
    return email.contains('@') ? email.split('@').first : 'User';
  }

  static String? _username(User user) {
    final handle = user.userName.trim();
    if (handle.isEmpty) return null;
    final at = handle.startsWith('@') ? handle : '@$handle';
    if (at == (user.displayName ?? '').trim() || at == user.name.trim()) {
      return null;
    }
    return at;
  }

  static List<_PermissionCategory> _categories(
    List<String> capabilities, {
    required String key,
    required bool isSpanish,
  }) {
    final labels = isSpanish
        ? const [
            'Administración del negocio',
            'Facturación y suscripción',
            'Gestión de miembros',
            'Calendarios y eventos',
            'Propiedad del negocio'
          ]
        : const [
            'Business administration',
            'Billing and subscription',
            'Member management',
            'Calendars and events',
            'Business ownership'
          ];
    final grouped = List.generate(5, (_) => <String>[]);
    for (var i = 0; i < capabilities.length; i++) {
      final text = capabilities[i];
      final lower = text.toLowerCase();
      final index = key == 'owner'
          ? switch (i) { 0 => 0, 1 => 1, 2 => 2, 3 => 3, _ => 4 }
          : (lower.contains('member') || lower.contains('miembr') ? 2 : 3);
      grouped[index].add(text);
    }
    return [
      for (var i = 0; i < labels.length; i++)
        if (grouped[i].isNotEmpty)
          _PermissionCategory(
              title: labels[i], items: grouped[i], sensitive: i == 4),
    ];
  }
}

class _PermissionCategory {
  const _PermissionCategory({
    required this.title,
    required this.items,
    required this.sensitive,
  });

  final String title;
  final List<String> items;
  final bool sensitive;
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.label});
  final GroupRole role;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: cs.primaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: 14, color: cs.onPrimaryContainer),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AccessSummary extends StatelessWidget {
  const _AccessSummary({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_rounded, size: 21, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(description, style: tt.bodySmall?.copyWith(height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionGroup extends StatelessWidget {
  const _PermissionGroup(
      {required this.title, required this.items, required this.sensitive});
  final String title;
  final List<String> items;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: tt.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: sensitive ? cs.error : cs.primary),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(item,
                          style: tt.bodySmall?.copyWith(height: 1.35))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
