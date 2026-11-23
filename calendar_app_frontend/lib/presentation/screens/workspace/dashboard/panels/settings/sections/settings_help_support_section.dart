import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/settings/widgets/nav_tile.dart';
import 'package:hexora/presentation/screens/settings/widgets/section_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsHelpSupportSection extends StatelessWidget {
  const SettingsHelpSupportSection({
    super.key,
    required this.group,
  });

  static const _supportEmail = 'support@hexora.dev';

  final Group group;

  Future<void> _openSupportEmail(
    BuildContext context, {
    required String subject,
    required String requestTemplate,
  }) async {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': subject,
        'body': '$requestTemplate\n\n'
            'Business: ${group.name}\n'
            'Business ID: ${group.id}\n\n'
            '${isEs ? 'No incluyas contraseñas ni datos bancarios.' : 'Do not include passwords or banking credentials.'}',
      },
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEs
              ? 'No se pudo abrir el correo. Escríbenos a $_supportEmail.'
              : 'Could not open email. Contact us at $_supportEmail.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEs ? 'Ayuda y soporte' : 'Help & support',
            subtitle: isEs
                ? 'Pide ayuda, informa de un problema o comparte una idea.'
                : 'Get help, report a problem, or share an idea.',
            textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
            subtitleStyle: typography.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
            showDivider: false,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          SectionCard(
            compact: true,
            child: Column(
              children: [
                NavTile(
                  compact: true,
                  leading: Icon(Icons.support_agent_rounded,
                      size: 18, color: cs.primary),
                  iconBgColor: cs.primary.withValues(alpha: 0.12),
                  title: isEs ? 'Obtener ayuda' : 'Get help',
                  subtitle: isEs
                      ? 'Contacta con el equipo de soporte de Hexora.'
                      : 'Contact the Hexora support team.',
                  onTap: () => _openSupportEmail(
                    context,
                    subject: isEs
                        ? 'Solicitud de ayuda de Hexora'
                        : 'Hexora help request',
                    requestTemplate: isEs
                        ? '¿Con qué necesitas ayuda?\n'
                            'Describe lo que quieres hacer:'
                        : 'What do you need help with?\n'
                            'Describe what you are trying to do:',
                  ),
                ),
                Divider(
                  height: 0,
                  indent: 63,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                NavTile(
                  compact: true,
                  leading: Icon(Icons.bug_report_outlined,
                      size: 18, color: cs.error),
                  iconBgColor: cs.error.withValues(alpha: 0.10),
                  title: isEs ? 'Informar de un problema' : 'Report a problem',
                  subtitle: isEs
                      ? 'Cuéntanos qué ocurrió y cómo reproducirlo.'
                      : 'Tell us what happened and how to reproduce it.',
                  onTap: () => _openSupportEmail(
                    context,
                    subject: isEs
                        ? 'Informe de problema de Hexora'
                        : 'Hexora problem report',
                    requestTemplate: isEs
                        ? '¿Qué ocurrió?\n\nPasos para reproducirlo:\n1. \n2. \n3. \n\n¿Qué esperabas que ocurriera?'
                        : 'What happened?\n\nSteps to reproduce:\n1. \n2. \n3. \n\nWhat did you expect to happen?',
                  ),
                ),
                Divider(
                  height: 0,
                  indent: 63,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
                NavTile(
                  compact: true,
                  leading: Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: cs.primary),
                  iconBgColor: cs.primary.withValues(alpha: 0.12),
                  title: isEs ? 'Sugerir una mejora' : 'Suggest an improvement',
                  subtitle: isEs
                      ? 'Comparte una idea para mejorar Hexora.'
                      : 'Share an idea that could improve Hexora.',
                  onTap: () => _openSupportEmail(
                    context,
                    subject: isEs
                        ? 'Sugerencia para Hexora'
                        : 'Hexora improvement suggestion',
                    requestTemplate: isEs
                        ? 'Describe tu sugerencia:\n\n¿Cómo te ayudaría?'
                        : 'Describe your suggestion:\n\nHow would it help you?',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${isEs ? 'Correo de soporte' : 'Support email'}: $_supportEmail',
            style: typography.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
