import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _kTelegramBlue = Color(0xFF2AABEE);

/// QR Code widget for Telegram connection
class TelegramQrWidget extends StatelessWidget {
  const TelegramQrWidget({
    super.key,
    required this.qrLink,
    required this.onRefreshPressed,
    this.isExpired = false,
    this.isLoading = false,
  });

  final String qrLink;
  final VoidCallback onRefreshPressed;
  final bool isExpired;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasQrData = qrLink.trim().isNotEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step list
            const _StepList(),
            const SizedBox(height: 28),

            // QR card
            _QrCard(
              qrLink: qrLink,
              hasQrData: hasQrData,
              isExpired: isExpired,
              isLoading: isLoading,
              onRefreshPressed: onRefreshPressed,
            ),

            const SizedBox(height: 16),

            // Copy link button (replaces raw link display)
            if (hasQrData && !isLoading)
              _CopyLinkButton(qrLink: qrLink),
          ],
        ),
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StepRow(
          number: 1,
          text: 'Open Telegram on your phone',
        ),
        SizedBox(height: 8),
        _StepRow(
          number: 2,
          text: 'Go to Settings → Devices → Link Desktop Device',
        ),
        SizedBox(height: 8),
        _StepRow(
          number: 3,
          text: 'Point your camera at the QR code below',
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _kTelegramBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.qrLink,
    required this.hasQrData,
    required this.isExpired,
    required this.isLoading,
    required this.onRefreshPressed,
  });

  final String qrLink;
  final bool hasQrData;
  final bool isExpired;
  final bool isLoading;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // QR area
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildQrContent(context),
                ),
              ),

              // Expired overlay
              if (isExpired)
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_off_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'QR Expired',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onRefreshPressed,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Refresh button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onRefreshPressed,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kTelegramBlue,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isLoading ? 'Refreshing…' : 'Refresh QR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTelegramBlue,
                side: const BorderSide(color: _kTelegramBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrContent(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kTelegramBlue),
      );
    }
    if (!hasQrData) {
      return const _QrFallbackState(
        icon: Icons.sync_problem_rounded,
        message: 'Waiting for QR link',
      );
    }
    return QrImageView(
      data: qrLink,
      version: QrVersions.auto,
      size: 220,
      backgroundColor: Colors.white,
      gapless: false,
      semanticsLabel: 'Telegram login QR code',
      errorStateBuilder: (context, _) => const _QrFallbackState(
        icon: Icons.qr_code_2_rounded,
        message: 'Unable to render QR code',
      ),
    );
  }
}

class _CopyLinkButton extends StatefulWidget {
  const _CopyLinkButton({required this.qrLink});

  final String qrLink;

  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.qrLink));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _copy,
      icon: Icon(
        _copied ? Icons.check_rounded : Icons.copy_rounded,
        size: 16,
      ),
      label: Text(_copied ? 'Link copied!' : 'Copy login link'),
      style: TextButton.styleFrom(
        foregroundColor: _copied ? Colors.green[600] : Colors.grey[600],
      ),
    );
  }
}

class _QrFallbackState extends StatelessWidget {
  const _QrFallbackState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Fallback code input for 2FA / verification
class TelegramCodeInputWidget extends StatefulWidget {
  const TelegramCodeInputWidget({
    super.key,
    required this.onSubmit,
    required this.isLoading,
    this.error,
    this.isPasswordMode = false,
  });

  final Function(String) onSubmit;
  final bool isLoading;
  final String? error;
  final bool isPasswordMode;

  @override
  State<TelegramCodeInputWidget> createState() =>
      _TelegramCodeInputWidgetState();
}

class _TelegramCodeInputWidgetState extends State<TelegramCodeInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.isPasswordMode
                    ? Icons.lock_rounded
                    : Icons.sms_rounded,
                size: 32,
                color: _kTelegramBlue,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isPasswordMode
                    ? 'Two-step verification'
                    : 'Enter verification code',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isPasswordMode
                    ? 'Enter your Telegram cloud password to continue.'
                    : 'A code was sent to your Telegram app. Enter it below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                enabled: !widget.isLoading,
                obscureText: widget.isPasswordMode,
                keyboardType: widget.isPasswordMode
                    ? TextInputType.visiblePassword
                    : TextInputType.number,
                decoration: InputDecoration(
                  hintText:
                      widget.isPasswordMode ? 'Password' : 'e.g. 12345',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kTelegramBlue),
                  ),
                  errorText: widget.error,
                  suffixIcon: widget.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kTelegramBlue,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.onSubmit(_controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kTelegramBlue,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    widget.isPasswordMode ? 'Verify Password' : 'Verify Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
