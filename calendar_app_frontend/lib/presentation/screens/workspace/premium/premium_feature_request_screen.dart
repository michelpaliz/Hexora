import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_access.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:provider/provider.dart';

enum PremiumFeatureRequest { email, banking, aiChat, teamChat }

class PremiumFeatureGate extends StatelessWidget {
  const PremiumFeatureGate({
    super.key,
    required this.group,
    required this.feature,
    required this.child,
    this.managerOnly = true,
    this.embedded = true,
  });

  final Group? group;
  final PremiumFeatureRequest feature;
  final Widget child;
  final bool managerOnly;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final userId = context.read<UserDomain?>()?.user?.id;
    final policyFeature = switch (feature) {
      PremiumFeatureRequest.email => PremiumFeature.email,
      PremiumFeatureRequest.banking => PremiumFeature.banking,
      PremiumFeatureRequest.aiChat => PremiumFeature.aiChat,
      PremiumFeatureRequest.teamChat => PremiumFeature.teamChat,
    };
    final allowed = managerOnly
        ? canManagePremiumFeature(group, userId, policyFeature)
        : hasPremiumFeature(group, policyFeature) &&
            userId != null &&
            group != null &&
            (group!.ownerId == userId ||
                group!.userIds.contains(userId) ||
                group!.userRoles.containsKey(userId));
    return allowed
        ? child
        : PremiumFeatureRequestScreen(
            feature: feature, group: group, embedded: embedded);
  }
}

class PremiumFeatureRequestScreen extends StatefulWidget {
  const PremiumFeatureRequestScreen({
    super.key,
    required this.feature,
    this.group,
    this.embedded = false,
  });

  final PremiumFeatureRequest feature;
  final Group? group;
  final bool embedded;

  @override
  State<PremiumFeatureRequestScreen> createState() =>
      _PremiumFeatureRequestScreenState();
}

class _PremiumFeatureRequestScreenState
    extends State<PremiumFeatureRequestScreen> {
  final _message = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _requestAccess() async {
    if (_sending || widget.group == null) return;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    setState(() => _sending = true);
    try {
      final response = await AuthenticatedHttpClient.post(
        Uri.parse('${ApiConstants.baseUrl}/premium/requests'),
        body: jsonEncode({
          'groupId': widget.group!.id,
          'feature': widget.feature.name,
          'message': _message.text.trim(),
        }),
      );
      if (response.statusCode != 202) {
        throw Exception(isEs
            ? 'No se pudo enviar la solicitud.'
            : 'Could not send the request.');
      }
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final isBanking = widget.feature == PremiumFeatureRequest.banking;
    final title = isEs ? 'Función premium' : 'Premium feature';
    final featureLabel = switch (widget.feature) {
      PremiumFeatureRequest.banking =>
        isEs ? 'Banca y movimientos' : 'Banking and transactions',
      PremiumFeatureRequest.email =>
        isEs ? 'Envío de correos' : 'Email sending',
      PremiumFeatureRequest.aiChat => isEs ? 'Chat con IA' : 'AI chat',
      PremiumFeatureRequest.teamChat =>
        isEs ? 'Chat cooperativo' : 'Cooperative chat',
    };
    final description = isEs
        ? 'Solicita acceso para activar esta función en tu empresa.'
        : 'Request access to enable this feature for your company.';
    final colors = Theme.of(context).colorScheme;
    final icon = isBanking
        ? Icons.account_balance_rounded
        : widget.feature == PremiumFeatureRequest.email
            ? Icons.email_rounded
            : Icons.chat_rounded;

    final panel = ConstrainedBox(
      key: const ValueKey('premium-request-dialog'),
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        featureLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!widget.embedded)
                  IconButton(
                    tooltip: isEs ? 'Cerrar' : 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            if (widget.group != null) ...[
              const SizedBox(height: 5),
              Text(
                widget.group!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            if (!_sent)
              TextField(
                controller: _message,
                maxLength: 2000,
                minLines: 2,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: isEs ? 'Mensaje (opcional)' : 'Message (optional)',
                  hintText: isEs
                      ? 'Cuéntanos brevemente cómo quieres usarla.'
                      : 'Briefly tell us how you plan to use it.',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            if (_sent)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 19, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(isEs
                          ? 'Solicitud enviada a Hexora.'
                          : 'Request sent to Hexora.'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.embedded)
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(_sent
                        ? (isEs ? 'Cerrar' : 'Close')
                        : (isEs ? 'Cancelar' : 'Cancel')),
                  ),
                if (!widget.embedded) const SizedBox(width: 8),
                if (!_sent)
                  FilledButton.icon(
                    onPressed: _sending || widget.group == null
                        ? null
                        : _requestAccess,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(isEs ? 'Solicitar acceso' : 'Request access'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: panel,
        ),
      );
    }
    return Scaffold(
      backgroundColor: colors.scrim.withValues(alpha: .28),
      body: SafeArea(
        child: Center(
          child: Dialog(
            insetPadding: const EdgeInsets.all(24),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: panel,
          ),
        ),
      ),
    );
  }
}
