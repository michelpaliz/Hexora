import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/settings/widgets/nav_tile.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({
    super.key,
    required this.isSpanish,
    required this.onEmail,
  });

  final bool isSpanish;
  final ValueChanged<String> onEmail;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        NavTile(
          leading:
              Icon(Icons.support_agent_rounded, size: 18, color: cs.primary),
          iconBgColor: cs.primary.withValues(alpha: 0.12),
          title: isSpanish ? 'Soporte al cliente' : 'Customer support',
          subtitle: 'support@hexora.dev',
          onTap: () => onEmail('support@hexora.dev'),
        ),
        Divider(
          height: 0,
          indent: 63,
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
        NavTile(
          leading:
              Icon(Icons.receipt_long_outlined, size: 18, color: cs.secondary),
          iconBgColor: cs.secondary.withValues(alpha: 0.12),
          title: isSpanish
              ? 'Facturación y suscripciones'
              : 'Billing and subscriptions',
          subtitle: 'billing@hexora.dev',
          onTap: () => onEmail('billing@hexora.dev'),
        ),
        Divider(
          height: 0,
          indent: 63,
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
        NavTile(
          leading:
              Icon(Icons.mail_outline_rounded, size: 18, color: cs.tertiary),
          iconBgColor: cs.tertiary.withValues(alpha: 0.12),
          title: isSpanish ? 'Consultas generales' : 'General enquiries',
          subtitle: 'hello@hexora.dev',
          onTap: () => onEmail('hello@hexora.dev'),
        ),
      ],
    );
  }
}
