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
            userId != null && group != null &&
            (group!.ownerId == userId ||
                group!.userIds.contains(userId) ||
                group!.userRoles.containsKey(userId));
    return allowed
        ? child
        : PremiumFeatureRequestScreen(feature: feature, group: group, embedded: embedded);
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
  State<PremiumFeatureRequestScreen> createState() => _PremiumFeatureRequestScreenState();
}

class _PremiumFeatureRequestScreenState extends State<PremiumFeatureRequestScreen> {
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
        throw Exception(isEs ? 'No se pudo enviar la solicitud.' : 'Could not send the request.');
      }
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
    final title = isEs
        ? 'Función premium'
        : 'Premium feature';
    final featureLabel = switch (widget.feature) {
      PremiumFeatureRequest.banking => isEs ? 'Banca y movimientos' : 'Banking and transactions',
      PremiumFeatureRequest.email => isEs ? 'Envío de correos' : 'Email sending',
      PremiumFeatureRequest.aiChat => isEs ? 'Chat con IA' : 'AI chat',
      PremiumFeatureRequest.teamChat => isEs ? 'Chat cooperativo' : 'Cooperative chat',
    };
    final description = isEs
        ? 'Esta función está disponible para cuentas premium. Contacta con Hexora para solicitar acceso para tu empresa.'
        : 'This feature is available for premium accounts. Contact Hexora to request access for your company.';

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBanking ? Icons.account_balance_rounded :
                    widget.feature == PremiumFeatureRequest.email ? Icons.email_rounded : Icons.chat_rounded,
                  size: 54,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(featureLabel, style: Theme.of(context).textTheme.titleMedium),
                if (widget.group != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.group!.name,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 14),
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 22),
                if (!_sent)
                  TextField(
                    controller: _message,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isEs ? 'Mensaje (opcional)' : 'Message (optional)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                if (_sent)
                  Text(isEs ? 'Solicitud enviada a Hexora.' : 'Request sent to Hexora.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _sent || _sending || widget.group == null ? null : _requestAccess,
                  icon: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.mail_outline_rounded),
                  label: Text(isEs ? 'Enviar solicitud a Hexora' : 'Send request to Hexora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(appBar: AppBar(title: Text(title)), body: content);
  }
}
