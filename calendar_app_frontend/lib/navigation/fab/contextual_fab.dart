import 'package:flutter/material.dart';
import 'package:hexora/models/group_model/group/group.dart';
import 'package:hexora/navigation/fab/fab_action.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';

class ContextualFab extends StatelessWidget {
  const ContextualFab({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;

    final settings = ModalRoute.of(context)?.settings;
    final routeName = settings?.name ?? '';
    final args = settings?.arguments;
    final groupArg = args is Group ? args : null;

    final action = resolveFabAction(
      context: context,
      routeName: routeName,
      groupArg: groupArg,
      accentColor: baseColor,
    );

    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final tooltip = groupArg != null || routeName == AppRoutes.agenda
        ? (isSpanish ? 'Añadir evento' : 'Add event')
        : routeName == AppRoutes.showNotifications
            ? (isSpanish ? 'Borrar notificaciones' : 'Clear notifications')
            : routeName == AppRoutes.profileDetails
                ? (isSpanish ? 'Acciones de perfil' : 'Profile actions')
                : (isSpanish ? 'Crear grupo' : 'Create group');

    return FloatingActionButton(
      tooltip: tooltip,
      onPressed: action.onPressed,
      elevation: 2,
      highlightElevation: 4,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      child: Icon(action.icon, size: 24),
    );
  }
}
