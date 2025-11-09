import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/d-event-section/utils/show_error_dialog.dart';
import 'package:hexora/c-frontend/e-log-user-section/login/logic/login_init.dart';
import 'package:hexora/c-frontend/j-routes/appRoutes.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/color_properties.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/text_field_widget.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/textfield_styles.dart'
    show TextFieldStyles;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../register_controller.dart';

Widget buildUserFields(RegisterController controller, BuildContext context) {
  final loc = AppLocalizations.of(context)!;

  return Column(
    children: [
      TextFieldWidget(
        controller: controller.userName,
        decoration: _decoration(
          loc.userName,
          loc.userNameHint,
          Icons.verified_user_rounded,
        ),
        keyboardType: TextInputType.text,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9_]+$')),
          LengthLimitingTextInputFormatter(10),
        ],
        validator: (val) => val!.isEmpty ? loc.userNameRequired : null,
      ),
      const SizedBox(height: 10),
      TextFieldWidget(
        controller: controller.name,
        decoration: _decoration(loc.name, loc.nameHint, Icons.person),
        keyboardType: TextInputType.text,
        validator: (val) => val!.isEmpty ? loc.nameRequired : null,
      ),
      const SizedBox(height: 10),
      TextFieldWidget(
        controller: controller.email,
        decoration: _decoration('Email', loc.emailHint, Icons.email),
        keyboardType: TextInputType.emailAddress,
        validator: (val) => val!.isEmpty ? loc.emailRequired : null,
      ),
      const SizedBox(height: 10),
      TextFieldWidget(
        controller: controller.password,
        decoration: _decoration(loc.password, loc.passwordHint, Icons.lock),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        validator: (val) => val!.length < 6 ? loc.passwordLength : null,
      ),
      const SizedBox(height: 10),
      TextFieldWidget(
        controller: controller.confirmPassword,
        decoration: _decoration(
          loc.confirmPassword,
          loc.confirmPassword,
          Icons.lock,
        ),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        validator: (val) =>
            val != controller.password.text ? loc.passwordNotMatch : null,
      ),
    ],
  );
}

Widget buildRegisterButton(
  RegisterController controller,
  BuildContext context,
  GlobalKey<FormState> formKey,
  AuthService authService, // ✅ Updated
) {
  return Container(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ColorProperties.defaultButton(),
      onPressed: () async {
        if (!formKey.currentState!.validate()) return;

        final email = controller.email.text.trim();
        final password = controller.password.text;
        final confirmPassword = controller.confirmPassword.text;
        final name = controller.name.text.trim();

        if (password != confirmPassword) {
          await showErrorDialog(
            context,
            AppLocalizations.of(context)!.passwordNotMatch,
          );
          return;
        }

        try {
          final registrationStatus = await authService.createUser(
            name: name,
            email: email,
            password: password,
          );

          final loginInit = LoginInitializer(
            authService: authService, // ✅ Changed
            userDomain: Provider.of<UserDomain>(context, listen: false),
            groupDomain: Provider.of<GroupDomain>(
              context,
              listen: false,
            ),
          );

          await loginInit.initializeUserAndServices(email, password);

          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.homePage, (route) => false);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Registration Status'),
                content: Text(registrationStatus),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        } on WeakPasswordException {
          await showErrorDialog(
            context,
            AppLocalizations.of(context)!.weakPassword,
          );
        } on EmailAlreadyUseAuthException {
          await showErrorDialog(
            context,
            AppLocalizations.of(context)!.emailTaken,
          );
        } on InvalidEmailAuthException {
          await showErrorDialog(
            context,
            AppLocalizations.of(context)!.invalidEmail,
          );
        } on GenericAuthException {
          await showErrorDialog(
            context,
            AppLocalizations.of(context)!.registrationError,
          );
        }
      },
      child: Text(
        AppLocalizations.of(context)!.register,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

Widget buildLoginButton(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.pushNamed(context, AppRoutes.loginRoute),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: AppLocalizations.of(context)!.alreadyRegistered,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
            ),
          ),
          TextSpan(
            text: AppLocalizations.of(context)!.login,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _decoration(String label, String hint, IconData icon) {
  return TextFieldStyles.saucyInputDecoration(
    hintText: hint,
    labelText: label,
    suffixIcon: icon,
  );
}
