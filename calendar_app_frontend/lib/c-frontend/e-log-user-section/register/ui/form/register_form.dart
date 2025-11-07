import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/c-frontend/e-log-user-section/register/ui/form/button_style_helper.dart';
import 'package:hexora/c-frontend/e-log-user-section/register/utils/legal_text_helper.dart';
import 'package:hexora/c-frontend/e-log-user-section/register/utils/password_utils.dart';
import 'package:hexora/f-themes/app_colors/palette/color_properties.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/text_field/static/text_field_widget.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/text_field/static/textfield_styles.dart'
    show TextFieldStyles;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../register_controller.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  late final RegisterController controller;
  bool _showPassword = false;
  ButtonStyle? _myCustomButtonStyle;

  // Password strength (0..1) + label
  double _strength = 0.0;
  String _strengthLabel = '';

  // Button enabled state
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    controller = RegisterController();

    controller.name.addListener(_recomputeCanSubmit);
    controller.email.addListener(_recomputeCanSubmit);
    controller.password.addListener(_recomputeCanSubmit);

    _recomputeCanSubmit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myCustomButtonStyle ??= ColorProperties.defaultButton();
  }

  @override
  void dispose() {
    controller.name.removeListener(_recomputeCanSubmit);
    controller.email.removeListener(_recomputeCanSubmit);
    controller.password.removeListener(_recomputeCanSubmit);
    controller.dispose();
    super.dispose();
  }

  void _recomputeCanSubmit() {
    final nameOk = controller.name.text.trim().isNotEmpty;
    final emailOk =
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(controller.email.text.trim());
    final pwOk = controller.password.text.length >= 6;
    final next = nameOk && emailOk && pwOk;
    if (next != _canSubmit) {
      setState(() => _canSubmit = next);
    }
  }

  void _handlePasswordChanged(String value) {
    final result = computePasswordStrength(context, value);
    setState(() {
      _strength = result.value;
      _strengthLabel = result.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context); // ✅ themed text styles

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 👋 Welcome Section
          Text(
            l10n.welcomeTitle,
            style: t.displayMedium.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.welcomeSubtitle,
            style: t.bodyMedium.copyWith(color: cs.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 28),

          // Name
          TextFieldWidget(
            controller: controller.name,
            keyboardType: TextInputType.text,
            decoration: TextFieldStyles.saucyInputDecoration(
              labelText: l10n.name,
              hintText: l10n.nameHint,
              suffixIcon: Icons.person,
            ),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? l10n.nameRequired : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFieldWidget(
            controller: controller.email,
            keyboardType: TextInputType.emailAddress,
            decoration: TextFieldStyles.saucyInputDecoration(
              labelText: l10n.email,
              hintText: l10n.emailHint,
              suffixIcon: Icons.email,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.emailRequired;
              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim());
              return ok ? null : l10n.invalidEmail;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFieldWidget(
            controller: controller.password,
            keyboardType: TextInputType.visiblePassword,
            obscureText: !_showPassword,
            decoration: TextFieldStyles.saucyInputDecoration(
              labelText: l10n.password,
              hintText: l10n.passwordHint,
              suffixIcon: Icons.lock,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility),
                tooltip: _showPassword ? l10n.hidePassword : l10n.showPassword,
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return l10n.passwordRequired;
              if (val.length < 6) return l10n.passwordLength;
              return null;
            },
            onChanged: _handlePasswordChanged,
          ),

          // Password strength meter
          if (_strengthLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _strength,
                      minHeight: 8,
                      backgroundColor: cs.surfaceVariant.withOpacity(0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _strength >= 0.85
                            ? Colors.green
                            : (_strength >= 0.5 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _strengthLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ButtonStyleHelper.resolved(context, enabled: _canSubmit),
              onPressed: _canSubmit
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;
                      final name = controller.name.text.trim();
                      final email = controller.email.text.trim();
                      final password = controller.password.text;

                      try {
                        await authService.createUser(
                          name: name,
                          email: email,
                          password: password,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account created')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration failed: $e')),
                        );
                      }
                    }
                  : null,
              child: Text(l10n.register, style: t.buttonText), // ✅
            ),
          ),

          // Legal text (helper)
          const SizedBox(height: 14),
          Center(child: buildLegalText(context)),
        ],
      ),
    );
  }
}
