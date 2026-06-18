import 'package:flutter/material.dart';
import 'package:hexora/a-models/telegram/telegram.dart';

/// Shows connected Telegram account info
class TelegramConnectedAccountWidget extends StatelessWidget {
  const TelegramConnectedAccountWidget({
    super.key,
    required this.account,
    required this.onDisconnect,
    this.isLoading = false,
  });

  final TelegramAccount account;
  final VoidCallback onDisconnect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green[50],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Connected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  account.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),

                // Full name or phone
                if (account.phoneNumber != null)
                  Text(
                    account.phoneNumber!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),

                // Linked at
                const SizedBox(height: 8),
                Text(
                  'Linked on ${_formatDate(account.linkedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Disconnect button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () => _showDisconnectConfirmation(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[600]!),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Text('Disconnect Account'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisconnectConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Telegram?'),
        content: Text(
          'This will remove the Telegram account linked to your profile. You can reconnect anytime.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDisconnect();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

/// Shows account not connected state
class TelegramNotConnectedWidget extends StatelessWidget {
  const TelegramNotConnectedWidget({
    super.key,
    required this.onConnect,
  });

  static const _kTelegramBlue = Color(0xFF2AABEE);

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _kTelegramBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.telegram, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Connect Telegram',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Link your account to access chats and export messages directly from Hexora.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 28),

            // Feature bullets
            const _FeatureRow(
              icon: Icons.chat_bubble_outline_rounded,
              text: 'Browse your Telegram chats and groups',
            ),
            const SizedBox(height: 10),
            const _FeatureRow(
              icon: Icons.file_download_outlined,
              text: 'Export messages, media, and documents',
            ),
            const SizedBox(height: 10),
            const _FeatureRow(
              icon: Icons.lock_outline_rounded,
              text: 'Secure QR login — no password stored',
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.qr_code_rounded, size: 20),
                label: const Text('Connect with QR code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTelegramBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2AABEE)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
          ),
        ),
      ],
    );
  }
}
